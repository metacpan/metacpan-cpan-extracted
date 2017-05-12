package HTML::Template::Pro;

use 5.005;
use strict;
use integer; # no floating point math so far!
use HTML::Template::Pro::WrapAssociate;
use File::Spec; # generate paths that work on all platforms
use Scalar::Util qw(tainted);
use Carp;
require DynaLoader;
require Exporter;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(DynaLoader Exporter);

$VERSION = '0.9510';

@EXPORT_OK = qw/ASK_NAME_DEFAULT ASK_NAME_AS_IS ASK_NAME_LOWERCASE ASK_NAME_UPPERCASE ASK_NAME_MASK/;
%EXPORT_TAGS = (const => [qw/ASK_NAME_DEFAULT ASK_NAME_AS_IS ASK_NAME_LOWERCASE ASK_NAME_UPPERCASE ASK_NAME_MASK/]);

# constants for tmpl_var_case
use constant {
    ASK_NAME_DEFAULT	=> 0,
    ASK_NAME_AS_IS	=> 1,
    ASK_NAME_LOWERCASE	=> 2,
    ASK_NAME_UPPERCASE	=> 4,
};
use constant ASK_NAME_MASK => ASK_NAME_AS_IS | ASK_NAME_LOWERCASE | ASK_NAME_UPPERCASE;


bootstrap HTML::Template::Pro $VERSION;

## when HTML::Template is not loaded,
## all calls to HTML::Template will be sent to HTML::Template::Pro,
## otherwise native HTML::Template will be used
push @HTML::Template::ISA,       qw/HTML::Template::Pro/;
push @HTML::Template::Expr::ISA, qw/HTML::Template::Pro/;

# Preloaded methods go here.

# internal C library init -- required
_init();
# internal C library unload -- it is better to comment it:
# when process terminates, memory is freed anyway
# but END {} can be called between calls (as SpeedyCGI does)
# END {_done()}

# initialize preset function table
use vars qw(%FUNC);
%FUNC = 
 (
  # note that length,defined,sin,cos,log,tan,... are built-in
   'sprintf' => sub { sprintf(shift, @_); },
   'substr'  => sub { 
     return substr($_[0], $_[1]) if @_ == 2; 
     return substr($_[0], $_[1], $_[2]);
   },
   'lc'      => sub { lc($_[0]); },
   'lcfirst' => sub { lcfirst($_[0]); },
   'uc'      => sub { uc($_[0]); },
   'ucfirst' => sub { ucfirst($_[0]); },
#   'length'  => sub { length($_[0]); },
#   'defined' => sub { defined($_[0]); },
#   'abs'     => sub { abs($_[0]); },
#   'hex'     => sub { hex($_[0]); },
#   'oct'     => sub { oct($_[0]); },
   'rand'    => sub { rand($_[0]); },
   'srand'   => sub { srand($_[0]); },
  );

sub new {
    my $class=shift;
    my %param;
    my $options={param_map=>\%param,
		functions => {},
		filter => [],
		# ---- supported -------
		debug => 0,
		max_includes => 10,
		global_vars => 0,
		no_includes => 0,
		search_path_on_include => 0,
		loop_context_vars => 0,
		path => [],
		associate => [],
		case_sensitive => 0,
		__strict_compatibility => 1,
		force_untaint => 0,
		# ---- unsupported distinct -------
		die_on_bad_params => 0,
		strict => 0,
		# ---- unsupported -------
#		vanguard_compatibility_mode => 0,
#=============================================
# The following options are harmless caching-specific.
# They are ignored silently because there is nothing to cache.
#=============================================
#		stack_debug => 0,
#		timing => 0,
#		cache => 0,		
#		blind_cache => 0,
#		file_cache => 0,
#		file_cache_dir => '',
#		file_cache_dir_mode => 0700,
#		cache_debug => 0,
#		shared_cache_debug => 0,
#		memory_debug => 0,
#		shared_cache => 0,
#		double_cache => 0,
#		double_file_cache => 0,
#		ipc_key => 'TMPL',
#		ipc_mode => 0666,
#		ipc_segment_size => 65536,
#		ipc_max_size => 0,
#============================================
		@_};

    # make sure taint mode is on if force_untaint flag is set
    if ($options->{force_untaint} && ! ${^TAINT}) {
	croak("HTML::Template->new() : 'force_untaint' option set but perl does not run in taint mode!");
    }

    # associate should be an array if it's not already
    if (ref($options->{associate}) ne 'ARRAY') {
	$options->{associate} = [ $options->{associate} ];
    }
    # path should be an array if it's not already
    if (ref($options->{path}) ne 'ARRAY') {
	$options->{path} = [ $options->{path} ];
    }
    # filter should be an array if it's not already
    if (ref($options->{filter}) ne 'ARRAY') {
	$options->{filter} = [ $options->{filter} ];
    }

    my $case_sensitive = $options->{case_sensitive};
    my $__strict_compatibility = $options->{__strict_compatibility};
    # wrap associated objects into tied hash and
    # make sure objects in associate are support param()
    $options->{associate} = [
	map {HTML::Template::Pro::WrapAssociate->_wrap($_, $case_sensitive, $__strict_compatibility)} 
	@{$options->{associate}}
	];

    # check for syntax errors:
    my $source_count = 0;
    exists($options->{filename}) and $source_count++;
    exists($options->{filehandle}) and $source_count++;
    exists($options->{arrayref}) and $source_count++;
    exists($options->{scalarref}) and $source_count++;
    if ($source_count != 1) {
	croak("HTML::Template->new called with multiple (or no) template sources specified!  A valid call to new() has exactly one filename => 'file' OR exactly one scalarref => \\\$scalar OR exactly one arrayref => \\\@array OR exactly one filehandle => \*FH");
    }
    if ($options->{arrayref}) {
	die "bad value of arrayref" unless UNIVERSAL::isa($_[0], 'ARRAY');
	my $template=join('',@{$options->{arrayref}});
	$options->{scalarref}=\$template;
    }
    if ($options->{filehandle}) {
	local $/; # enable "slurp" mode
	local *FH=$options->{filehandle};
	my $template=<FH>;
	$options->{scalarref}=\$template;
    }

    # merging built_in funcs with user-defined funcs
    $options->{expr_func}={%FUNC, %{$options->{functions}}};

    # hack to be fully compatible with HTML::Template; 
    # caused serious memory leak. it should be done on XS level, if needed.
    # &safe_circular_reference($options,'options') ???
    #$options->{options}=$options; 
    bless $options,$class;
    $options->_call_filters($options->{scalarref}) if $options->{scalarref} and @{$options->{filter}};

    return $options; # == $self
}

# a few shortcuts to new(), of possible use...
sub new_file {
  my $pkg = shift; return $pkg->new('filename', @_);
}
sub new_filehandle {
  my $pkg = shift; return $pkg->new('filehandle', @_);
}
sub new_array_ref {
  my $pkg = shift; return $pkg->new('arrayref', @_);
}
sub new_scalar_ref {
  my $pkg = shift; return $pkg->new('scalarref', @_);
}

sub output {
    my $self=shift;
    my %oparam=(@_);
    my $print_to = $oparam{print_to};

    if (defined wantarray && ! $print_to) {
	return exec_tmpl_string($self);
    } else {
	exec_tmpl($self,$print_to);
    }
}

sub clear_params {
  my $self = shift;
  %{$self->{param_map}}=();
}

sub param {
  my $self = shift;
  #my $options = $self->{options};
  my $param_map = $self->{param_map};
  # compatibility with HTML::Template
  # the one-parameter case - could be a parameter value request or a
  # hash-ref.
  if (scalar @_==0) {
      return keys (%$param_map);
  } elsif (scalar @_==1) {
      if (ref($_[0]) and UNIVERSAL::isa($_[0], 'HASH')) {
	  # ref to hash of params --- simply dereference it
	  return $self->param(%{$_[0]});
      } else {
	  my $key=$self->{case_sensitive} ? $_[0] : lc($_[0]);
	  return $param_map->{$key} || $param_map->{$_[0]};
      }
  }
  # loop below is obvious but wrong for perl
  # while (@_) {$param_map->{shift(@_)}=shift(@_);}
  if ($self->{case_sensitive}) {
      while (@_) {
	  my $key=shift;
	  my $val=shift;
	  $param_map->{$key}=$val;
      }
  } else {
      while (@_) {
	  my $key=shift;
	  my $val=shift;
	  if (ref($val)) {
	      if (UNIVERSAL::isa($val, 'ARRAY')) {
		  $param_map->{lc($key)}=[map {_lowercase_keys($_)} @$val];
	      } else {
		  $param_map->{lc($key)}=$val;
	      }
	  } else {
	      $param_map->{lc($key)}=$val;
	  }
      }
  }
}

sub register_function {
  my($self, $name, $sub) = @_;
  if ( ref($sub) eq 'CODE' ) {
      if (ref $self) {
          # per object call
          $self->{expr_func}->{$name} = $sub;
          $self->{expr_func_user_list}->{$name} = 1;
      } else {
          # per class call
          $FUNC{$name} = $sub;
      }
  } elsif ( defined $sub ) {
      croak("HTML::Template::Pro : last arg of register_function must be subroutine reference\n")
  } else {
      if (ref $self) {
          if ( defined $name ) {
              return $self->{expr_func}->{$name};
          } else {
              return keys %{ $self->{expr_func_user_list} };
          }
      } else {
          return keys %FUNC;
      }
  }
}

sub _lowercase_keys {
    my $orighash=shift;
    my $newhash={};
    my ($key,$val);
    unless (UNIVERSAL::isa($orighash, 'HASH')) {
	Carp::carp "HTML::Template::Pro:_lowercase_keys:in param_tree: found strange parameter $orighash while hash was expected";
	return;
    }
    while (($key,$val)=each %$orighash) {
	if (ref($val)) {
	    if (UNIVERSAL::isa($val, 'ARRAY')) {
		$newhash->{lc($key)}=[map {_lowercase_keys($_)} @$val];
	    } else {
		$newhash->{lc($key)}=$val;
	    }
	} else {
	    $newhash->{lc($key)}=$val;
	}
    }
    return $newhash;
}

# sub _load_file {
#     my $filepath=shift;
#     open my $fh, $filepath or die $!;
#     local $/; # enable localized slurp mode
#     my $content = <$fh>;
#     close $fh;
#     return $content;
# }

## HTML::Template based

#### callback function called from C library ##############
# Note that this _get_filepath perl code is deprecated;  ##
# by default built-in find_file implementation is used.  ##
# use magic option __use_perl_find_file => 1 to re-enable it.
###########################################################
sub _get_filepath {
  my ($self, $filename, $last_visited_file) = @_;
  # look for the included file...
  my $filepath;
  if ((not defined $last_visited_file) or $self->{search_path_on_include}) {
      $filepath = $self->_find_file($filename);
  } else {
      $filepath = $self->_find_file($filename, 
				    [File::Spec->splitdir($last_visited_file)]
				    );
  }
  carp "HTML::Template::Pro (using callback): template $filename not found!"  unless $filepath;
  return $filepath;
}

sub _find_file {
  my ($options, $filename, $extra_path) = @_;
  my $filepath;

  # first check for a full path
  return File::Spec->canonpath($filename)
    if (File::Spec->file_name_is_absolute($filename) and (-e $filename));

  # try the extra_path if one was specified
  if (defined($extra_path)) {
    $extra_path->[$#{$extra_path}] = $filename;
    $filepath = File::Spec->canonpath(File::Spec->catfile(@$extra_path));
    return File::Spec->canonpath($filepath) if -e $filepath;
  }

  # try pre-prending HTML_Template_Root
  if (defined($ENV{HTML_TEMPLATE_ROOT})) {
    $filepath =  File::Spec->catfile($ENV{HTML_TEMPLATE_ROOT}, $filename);
    return File::Spec->canonpath($filepath) if -e $filepath;
  }

  # try "path" option list..
  foreach my $path (@{$options->{path}}) {
    $filepath = File::Spec->catfile($path, $filename);
    return File::Spec->canonpath($filepath) if -e $filepath;
  }

  # try even a relative path from the current directory...
  return File::Spec->canonpath($filename) if -e $filename;

  # try "path" option list with HTML_TEMPLATE_ROOT prepended...
  if (defined($ENV{HTML_TEMPLATE_ROOT})) {
    foreach my $path (@{$options->{path}}) {
      $filepath = File::Spec->catfile($ENV{HTML_TEMPLATE_ROOT}, $path, $filename);
      return File::Spec->canonpath($filepath) if -e $filepath;
    }
  }
  
  return undef;
}

sub _load_template {
  my $self = shift;
  my $filepath=shift;
  my $template = "";
    confess("HTML::Template->new() : Cannot open file $filepath : $!")
        unless defined(open(TEMPLATE, $filepath));
    # read into scalar
    while (read(TEMPLATE, $template, 10240, length($template))) {}
    close(TEMPLATE);
  $self->_call_filters(\$template) if @{$self->{filter}};
  return \$template;
}

# handle calling user defined filters
sub _call_filters {
  my $self = shift;
  my $template_ref = shift;
  my $options = $self;#->{options};

  my ($format, $sub);
  foreach my $filter (@{$options->{filter}}) {
    croak("HTML::Template->new() : bad value set for filter parameter - must be a code ref or a hash ref.")
      unless ref $filter;

    # translate into CODE->HASH
    $filter = { 'format' => 'scalar', 'sub' => $filter }
      if (ref $filter eq 'CODE');

    if (ref $filter eq 'HASH') {
      $format = $filter->{'format'};
      $sub = $filter->{'sub'};

      # check types and values
      croak("HTML::Template->new() : bad value set for filter parameter - hash must contain \"format\" key and \"sub\" key.")
        unless defined $format and defined $sub;
      croak("HTML::Template->new() : bad value set for filter parameter - \"format\" must be either 'array' or 'scalar'")
        unless $format eq 'array' or $format eq 'scalar';
      croak("HTML::Template->new() : bad value set for filter parameter - \"sub\" must be a code ref")
        unless ref $sub and ref $sub eq 'CODE';

      # catch errors
      eval {
        if ($format eq 'scalar') {
          # call
          $sub->($template_ref);
        } else {
	  # modulate
	  my @array = map { $_."\n" } split("\n", $$template_ref);
          # call
          $sub->(\@array);
	  # demodulate
	  $$template_ref = join("", @array);
        }
      };
      croak("HTML::Template->new() : fatal error occured during filter call: $@") if $@;
    } else {
      croak("HTML::Template->new() : bad value set for filter parameter - must be code ref or hash ref");
    }
  }
  # all done
  return $template_ref;
}

1;
__END__

=head1 NAME

HTML::Template::Pro - Perl/XS module to use HTML Templates from CGI scripts

=head1 SYNOPSIS

It is moved out and split.

See L<HTML::Template::SYNTAX/SYNOPSIS> for introduction 
to HTML::Template and syntax of template files.

See L<HTML::Template::PerlInterface/SYNOPSIS> for perl interface
of HTML::Template, HTML::Template::Expr and HTML::Template::Pro.

=head1 DESCRIPTION

Original HTML::Template is written by Sam Tregar, sam@tregar.com
with contributions of many people mentioned there.
Their efforts caused HTML::Template to be mature html tempate engine
which separate perl code and html design.
Yet powerful, HTML::Template is slow, especially if mod_perl isn't 
available or in case of disk usage and memory limitations.

HTML::Template::Pro is a fast lightweight C/Perl+XS reimplementation
of HTML::Template (as of 2.9) and HTML::Template::Expr (as of 0.0.7). 
It is not intended to be a complete replacement, 
but to be a fast implementation of HTML::Template if you don't need 
querying, the extended facility of HTML::Template.
Designed for heavy upload, resource limitations, abcence of mod_perl.

HTML::Template::Pro has complete support of filters and HTML::Template::Expr's 
tag EXPR="<expression>", including user-defined functions and
construction <TMPL_INCLUDE EXPR="...">.

HTML::Template work cycle uses 2 steps. First, it loads and parse template.
Then it accepts param() calls until you call output().
output() is its second phase where it produces a page from the parsed tree
of template, obtained in the 1st step.

HTML::Template::Pro loads, parse and outputs template on fly, 
when you call $tmpl->output(), in one pass. The corresponding code is 
written in C and glued to Perl using Perl+XS. As a result,
comparing to HTML::Template in ordinary calls, it runs 
10-25 times faster. Comparing to HTML::Template with all caching enabled
under mod_perl, it still 1-3 times faster. At that HTML::Template caching 
requires considerable amount of memory (per process, shareable, or on disk) 
to be permanently filled with parsed trees, whereas HTML::Template::Pro 
don't consumes memory for caches and use mmap() for reading templates on disk.

Introduction to HTML::Template and syntax of template files is described 
in L<HTML::Template::SYNTAX>.
Perl interface of HTML::Template and HTML::Template::Pro is described 
in L<HTML::Template::PerlInterface>.

=head1 SEE ALSO

L<HTML::Template::SYNTAX>, L<HTML::Template::PerlInterface>.

Progect page is http://html-tmpl-pro.sourceforge.net
 (and http://sourceforge.net/projects/html-tmpl-pro)

Original modules are L<HTML::Template>, L<HTML::Template::Expr>.
Their progect page is http://html-template.sourceforge.net

=head1 BUGS

See L<HTML::Template::PerlInterface/BUGS>

=head1 AUTHOR

I. Vlasenko, E<lt>viy@altlinux.orgE<gt>

with contributions of
Bruni Emiliano, E<lt>info at ebruni.itE<gt>
Stanislav Yadykin, E<lt>tosick at altlinux.ruE<gt>
Viacheslav Sheveliov E<lt>slavash at aha.ruE<gt>
Shigeki Morimoto E<lt>shigeki.morimoto at mixi.co.jpE<gt>
Kirill Rebenok E<lt>kirill at rebenok.plE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by I. Yu. Vlasenko.
Pieces of code in Pro.pm and documentation of HTML::Template are
copyright (C) 2000-2002 Sam Tregar (sam@tregar.com)

The template syntax, interface conventions and a large piece of documentation 
of HTML::Template::Pro are based on CPAN module HTML::Template 
by Sam Tregar, sam@tregar.com.

This library is free software; you can redistribute it and/or modify it under 
either the LGPL2+ or under the same terms as Perl itself, either Perl version 
5.8.4 or, at your option, any later version of Perl 5 you may have available.

=cut
