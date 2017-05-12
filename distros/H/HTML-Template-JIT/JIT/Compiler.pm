package HTML::Template::JIT::Compiler;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use HTML::Template;
use Carp qw(croak confess);
use File::Path qw(mkpath rmtree);

sub compile {
  my %args = @_;
  my $self = bless({});

  # parse the template as usual
  $self->{template} = HTML::Template->new(%args);
  
  # setup state
  $self->{jit_path}          = $args{jit_path};
  $self->{package}           = $args{package};
  $self->{package_dir}       = $args{package_dir};
  $self->{package_path}      = $args{package_path};
  $self->{jit_pool}          = [];
  $self->{jit_sym}           = 0;
  $self->{jit_debug}         = $args{jit_debug};
  $self->{text_size}         = 0;
  $self->{loop_context_vars} = $args{loop_context_vars};
  $self->{max_depth}         = 0;
  $self->{global_vars}       = $args{global_vars};
  $self->{print_to_stdout}   = $args{print_to_stdout};
  $self->{case_sensitive}    = $args{case_sensitive};

  # compile internal representation into a chunk of C code

  # get code for param function
  my @code = $self->_output();

  if ($self->{jit_debug}) {
    print STDERR "###################### CODE START ######################\n\n";
    open(INDENT, "| indent -kr > code.tmp");
    print INDENT join("\n", @code);
    close INDENT;
    open(CODE, 'code.tmp');
    print STDERR join('', <CODE>);
    close(CODE);
    unlink('code.tmp');    
    print STDERR "\n\n###################### CODE END ######################\n\n";
  }

  $self->_write_module(\@code);

  # try to load the module and return package handle if successful
  my $result;
  eval { $result = require $self->{package_path}; };
  return 1 if $result;

  # don't leave failed compiles lying around unless we're debuging
  rmtree($self->{package_dir}, 0, 0) unless $self->{jit_debug};
  die $@ if $@;
  return 0;
}

# writes out the module file
sub _write_module {
  my ($self, $code) = @_;

  # make directory
  mkpath($self->{package_dir}, 0, 0700);
  
  # open module file
  open(MODULE, ">$self->{package_path}") or die "Unable to open $self->{package_path} for output : $!";
  
  my $inline_debug = "";
  my $optimize = "-O3";
  if ($self->{jit_debug}) {
    $inline_debug = ", CLEAN_AFTER_BUILD => 0";
    $optimize = "-g";
  }

  # print out preamble
  print MODULE <<END;
package $self->{package};
use base 'HTML::Template::JIT::Base';

use Inline C => Config => OPTIMIZE => "$optimize", DIRECTORY => "$self->{package_dir}" $inline_debug;
use Inline C => <<'CODE_END';

END

  # print out code
  print MODULE join("\n", @$code), "\nCODE_END\n";

  # output the param hash
  print MODULE "our \%param_hash = (\n", join(',', $self->_param_hash([])), ");\n";
  
  # empty param map
  print MODULE "our \%param_map;\n";

  # note case sensitivity
  print MODULE "our \$case_sensitive = $self->{case_sensitive};\n";

  print MODULE "\n1;\n";

  # all done
  close MODULE;
}

# construct the output function
sub _output {
  my $self = shift;
  my $template = $self->{template};

  # construct body of output
  my @code = $self->_output_template($template, 0);
  
  # write global pool
  unshift @code, '', $self->_write_pool();

  # setup result size based on gathered stats with a little extra for variables
  my $size = int ($self->{text_size} + ($self->{text_size} * .10));

  # head code for output function, deferred to allow for $size and
  # max_depth setup
  unshift @code, <<END;
SV * output(SV *self) { 
  SV *result = NEWSV(0, $size);
  HV *param_map[($self->{max_depth} + 1)];
  SV ** temp_svp;
  SV * temp_sv;
  int i;
  STRLEN len;
  unsigned char c;
  char buf[4];

  SvPOK_on(result);
  param_map[0] = get_hv("$self->{package}::param_map", 0);

END

  # finish output function
  push @code, "return result;", "}";

  return @code;
}

# output the body of a single scope (top-level or loop)
sub _output_template {
  my ($self, $template, $offset) = @_;
  $self->{max_depth} = $offset 
    if $offset > $self->{max_depth};
  
  my (@code, @top, %vars, @pool, %blocks, $type, $name, $var, 
      $do_escape, $has_default);
  
  # setup some convenience aliases ala HTML::Template::output()
  use vars qw($line  @parse_stack  %param_map); 
  local      (*line, *parse_stack, *param_map);
  *parse_stack = $template->{parse_stack};
  *param_map   = $template->{param_map};
  
  my %reverse_param_map = map { $param_map{$_} => $_ } keys %param_map;
  my $parse_stack_length = $#parse_stack;
  
  for (my $x = 0; $x <= $parse_stack_length; $x++) {
    *line = \$parse_stack[$x];
    $type = ref($line);
    
    # need any block closings on this line?
    push(@code, "}" x $blocks{$x}) if $blocks{$x};

    if ($type eq 'SCALAR') {
      # append string and add size to text_size counter
      if ($self->{print_to_stdout}) {
        push @code, _print_string($$line);
      } else {
        push @code, _concat_string($$line);
        $self->{text_size} += length $$line;
      }

    } elsif ($type eq 'HTML::Template::VAR') {
      # get name for this variable from reverse map
      $name = $reverse_param_map{$line};

      # check var cache - can't use it for escaped variables
      if (exists $vars{$name}) {
        $var = $vars{$name};
      } 
      
      # load a new one if needed
      else {
        $var = $self->_get_var("SV *", "&PL_sv_undef", \@pool);
        push @top, _load_var($name, $var, $offset, $self->{global_vars});
        $vars{$name} = $var;
      }
      
      # escape var if needed
      if ($do_escape) {
        push @code, _escape_var($var, $do_escape);
      }

      # append the var
      push @code, ($self->{print_to_stdout} ? _print_var($var,  $do_escape, $has_default) : 
                                              _concat_var($var, $do_escape, $has_default));

      # reset flags
      undef $do_escape;
      undef $has_default;

    } elsif ($type eq 'HTML::Template::DEFAULT') {
      $has_default = $$line;

    } elsif ($type eq 'HTML::Template::LOOP') {
      # get loop template
      my $loop_template = $line->[HTML::Template::LOOP::TEMPLATE_HASH]{$x};

      # allocate an hv for the loop param_map
      my $loop_offset = $offset + 1;

      # remember text_size before loop
      my $old_text_size = $self->{text_size};

      # output the loop start
      push @code, $self->_start_loop($reverse_param_map{$line}, $offset, 
				     $loop_offset);

      # output the loop code
      push @code, $self->_output_template($loop_template, $loop_offset);
      
      # send the loop
      push @code, $self->_end_loop();

      # guesstimate average loop run of 10 and pre-allocate space for
      # text accordingly.  This is a bit silly but something has to be
      # done to account for loops increasing result size...
      $self->{text_size} += (($self->{text_size} - $old_text_size) * 9);
      
    } elsif ($type eq 'HTML::Template::COND') {
      # if, unless and else
      
      # store block end loc
      $blocks{$line->[HTML::Template::COND::JUMP_ADDRESS]}++;

      # get name for this var
      $name = $reverse_param_map{$line->[HTML::Template::COND::VARIABLE]};

      # load a new var unless we have this one
      if (exists $vars{$name}) {
        $var = $vars{$name};
      } else {
        $var = $self->_get_var("SV *", "&PL_sv_undef", \@pool);
        push @top, _load_var($name, $var, $offset, $self->{global_vars});
        $vars{$name} = $var;
      }

      # output conditional
      push(@code, $self->_cond($line->[HTML::Template::COND::JUMP_IF_TRUE], 
			       $line->[HTML::Template::COND::VARIABLE_TYPE] == HTML::Template::COND::VARIABLE_TYPE_VAR,
                               $var,
                               $line->[HTML::Template::COND::UNCONDITIONAL_JUMP], 
			      ));
    } elsif ($type eq 'HTML::Template::ESCAPE') {
      $do_escape = 'HTML';
    } elsif ($type eq 'HTML::Template::URLESCAPE') {
      $do_escape = 'URL';
    } elsif ($type eq 'HTML::Template::JSESCAPE') {
      $do_escape = 'JS';
    } elsif ($type eq 'HTML::Template::NOOP') {
      # noop
    } else {
      confess("Unsupported object type in parse stack : $type");
    }
  }

  # output pool of variables used in body
  unshift @code, '{', $self->_write_pool(\@pool), @top;
  push @code, '}';

  return @code;
}

# output a conditional expression
sub _cond {
  my ($self, $is_unless, $is_var, $var, $is_uncond) = @_;
  my @code;

  if ($is_uncond) {
    push(@code, "else {");
  } else {
    if ($is_var) {
      if ($is_unless) {
        # unless var
        push(@code, "if (!SvTRUE($var)) {");
      } else {
        # if var
        push(@code, "if (SvTRUE($var)) {");
      }
    } else {
      if ($is_unless) {
        # unless loop
        push(@code, "if ($var == &PL_sv_undef || av_len((AV *) SvRV($var)) == -1) {");
      } else {
        # if loop
        push(@code, "if ($var != &PL_sv_undef && av_len((AV *) SvRV($var)) != -1) {");
      }
    }
  }

  return @code;
}

# start a loop
sub _start_loop {
  my ($self, $name, $offset, $loop_offset) = @_;
  my $name_string = _quote_string($name);
  my $name_len    = length($name_string);
  my @pool;
  my $av          = $self->_get_var("AV *", 0, \@pool);
  my $av_len      = $self->_get_var("I32", 0, \@pool);
  my $counter     = $self->_get_var("I32", 0, \@pool);
  my @code;

  my $odd;
  if ($self->{loop_context_vars}) {
    $odd = $self->_get_var("I32", 0, \@pool);
    push(@code, "$odd = 0;");
  }

  push @code, <<END;
temp_svp = hv_fetch(param_map[$offset], "$name_string", $name_len, 0);
if (temp_svp && (*temp_svp != &PL_sv_undef)) {
   $av = (AV *) SvRV(*temp_svp);      
   $av_len = av_len($av);

   for($counter = 0; $counter <= $av_len; $counter++) {
      param_map[$loop_offset] = (HV *) SvRV(*(av_fetch($av, $counter, 0)));
END

  if ($self->{loop_context_vars}) {
    push @code, <<END;
      if ($counter == 0) {
	hv_store(param_map[$loop_offset], "__first__", 9, &PL_sv_yes, 0);
	hv_store(param_map[$loop_offset], "__inner__", 9, &PL_sv_no, 0);
	if ($av_len == 0) 
        hv_store(param_map[$loop_offset], "__last__",  8,  &PL_sv_yes, 0);
      } else if ($counter == $av_len) {
        hv_store(param_map[$loop_offset], "__first__", 9, &PL_sv_no, 0);
        hv_store(param_map[$loop_offset], "__inner__", 9, &PL_sv_no, 0);
        hv_store(param_map[$loop_offset], "__last__",  8,  &PL_sv_yes, 0);
      } else {
        hv_store(param_map[$loop_offset], "__first__", 9, &PL_sv_no, 0);
        hv_store(param_map[$loop_offset], "__inner__", 9, &PL_sv_yes, 0);
        hv_store(param_map[$loop_offset], "__last__",  8,  &PL_sv_no, 0);
      }

      hv_store(param_map[$loop_offset], "__odd__", 7, (($odd = !$odd) ? &PL_sv_yes : &PL_sv_no), 0);
      hv_store(param_map[$loop_offset], "__counter__", 11, newSViv($counter + 1), 0);
END

  }

  unshift @code, "{", $self->_write_pool(\@pool);

  return @code;
}

# end a loop
sub _end_loop {
  return '}}}';
}

# construct %param_hash
sub _param_hash {
  my ($self, $path) = @_;
  my $template = $self->{template};

  my @params;
  if (@$path) {
    @params = $template->query(LOOP => $path);
  } else {
    @params = $template->param();
  }

  my @out;
  foreach my $name (@params) {
    my $type = $template->query(name => [ @$path, $name ]);
    if ($type eq 'VAR') {
      push @out, "'$name'", 1;
    } else {
      push @out, "'$name'", "\n{" . join(', ', $self->_param_hash([ @$path, $name ])) . "\n}\n";
    }
  }
	 
  return @out;
}


# get a fresh var of the requested C type from the pool
sub _get_var {
  my ($self, $type, $default, $pool) = @_;
  $pool = $self->{jit_pool} unless defined $pool;
  my $sym = "sym_" . $self->{jit_sym}++;
  push @$pool, $type, ($default ? "$sym = $default" : $sym);
  return $sym;
}

# write out the code to initialize the pool
sub _write_pool {
  my ($self, $pool) = @_;
  $pool = $self->{jit_pool} unless defined $pool;
  my @code;
  
  for (my $index = 0; $index < @$pool; $index += 2) {
      push(@code, $pool->[$index] . ' ' . $pool->[$index + 1] . ";");
  }
  @$pool = ();
  return @code;
}

# concatenate a string onto result
sub _concat_string {
  return "" unless $_[0];
  my $len = length($_[0]);
  my $string = _quote_string($_[0]);

  return "sv_catpvn(result, \"$string\", $len);"
}

# concatenate a string onto result
sub _print_string {
  return "" unless $_[0];
  my $string = _quote_string($_[0]);
  return "PerlIO_stdoutf(\"$string\");";
}

# loads a variable into a lexical pool variable
sub _load_var {
  my ($name, $var, $offset, $global) = @_;
  my $string = _quote_string($name);
  my $len    = length($name);
  
  return <<END if $global and $offset;
for (i = $offset; i >= 0; i--) {
   if (hv_exists(param_map[i], "$string", $len)) {
      $var = *(hv_fetch(param_map[i], "$string", $len, 0));
      if ($var != &PL_sv_undef) break;
   }
}
END

  return <<END;
if (hv_exists(param_map[$offset], "$string", $len))
   $var = *(hv_fetch(param_map[$offset], "$string", $len, 0));
END
}  

# loads a variable and escapes it
sub _escape_var {
  my ($var, $escape) = @_;
  
  # apply escaping to a mortal copy in temp_sv
  my @code = (<<END);
if ($var != &PL_sv_undef) {
  SvPV_force($var, len);
  temp_sv = sv_mortalcopy($var);
  len = 0;
  while (len < SvCUR(temp_sv)) {
    c = *(SvPVX(temp_sv) + len);
END

  # perform the appropriate escapes
  if ($escape eq 'HTML') {
      push @code, <<END;
    switch (c) {
      case '&':
        sv_insert(temp_sv, len, 1, "&amp;",  5);
        len += 4;
        break;
      case '"':
        sv_insert(temp_sv, len, 1, "&quot;", 6);
        len += 5;
        break;
      case '>':
        sv_insert(temp_sv, len, 1, "&gt;",   4);
        len += 3;
        break;
      case '<':
        sv_insert(temp_sv, len, 1, "&lt;",   4);
        len += 3;
        break;
      case '\\'':
        sv_insert(temp_sv, len, 1, "&#39;",  5);
        len += 4;
        break;
    }
END
  } elsif ($escape eq 'URL') {
      push @code, <<END;
    if (!(isALNUM(c) || (c == '-') || (c == '.'))) {
       sprintf(buf, "%%%02X", c);
       sv_insert(temp_sv, len, 1, buf, 3);
       len += 2;
    }
END
  } elsif ($escape eq 'JS') {
      push @code, <<'END';
    switch (c) {
      case '\\':
      case '\'':
      case '"':
        sprintf(buf, "\\%c", c);
        sv_insert(temp_sv, len, 1, buf, 2);
        len += 1;
        break;
      case '\n':
        sprintf(buf, "\\n");
        sv_insert(temp_sv, len, 1, buf, 2);
        len += 1;
        break;
      case '\r':
        sprintf(buf, "\\r");
        sv_insert(temp_sv, len, 1, buf, 2);
        len += 1;
    }
END
      
  } else {
    die "Unknown escape type '$escape'.";
  }

  push @code, <<END;
    len++;
  }
}
END

  return @code;
}

# concatenate a var onto result
sub _concat_var {
  return "if ($_[0] != &PL_sv_undef) sv_catsv(result, " . 
    ($_[1] ? "temp_sv" : $_[0]) . ");" .
        (defined $_[2] ? " else " . _concat_string($_[2]) : "");
}

# print a var to stdout
sub _print_var {
  return "if ($_[0] != &PL_sv_undef) PerlIO_stdoutf(SvPV_nolen(" .
    ($_[1] ? "temp_sv" : $_[0]) . "));" .
      (defined $_[2] ? " else " . _print_string($_[2]) : "");
}

# turn a string into something that C will accept inside
# double-quotes.  or should I go the array of bytes route?  I think
# that might be the only way to get UTF-8 working.  It's such hell to
# debug though...
sub _quote_string {
  my $string = shift;
  $string    =~ s/\\/\\\\/g;
  $string    =~ s/"/\\"/g;
  $string    =~ s/\r/\\r/g;
  $string    =~ s/\n/\\n/g;
  $string    =~ s/\t/\\t/g;
  return $string;
}  

1;

__END__

=pod

=head1 NAME

HTML::Template::JIT::Compiler - Compiler for HTML::Template::JIT

=head1 SYNOPSIS

  use HTML::Template::JIT::Compiler;

  HTML::Template::JIT->compile(...); 

=head1 DESCRIPTION

This module is used internally by HTML::Template::JIT to compile
template files.  Don't use it directly - use HTML::Template::JIT
instead.

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

=head1 LICENSE

HTML::Template::JIT : Just-in-time compiler for HTML::Template

Copyright (C) 2001 Sam Tregar (sam@tregar.com)

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,
or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

