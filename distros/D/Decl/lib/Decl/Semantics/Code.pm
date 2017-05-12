package Decl::Semantics::Code;

use warnings;
use strict;

use base qw(Decl::Node);
use Decl::Util;
use Data::Dumper;

=head1 NAME

Decl::Semantics::Code - implements some code (perl or otherwise) in a declarative framework.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This class serves two purposes: first, it's an example of what a semantic node class should look like, and second, it
will probably end up being the class that builds most of the code references in a declarative program.

=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what tags this plugin claims to implement and the
parsers used to build its content.

=cut
sub defines { ('on', 'do', 'perl', 'sub'); }
our %build_handlers = ( perl => { node => sub { Decl::Semantics::Code->new (@_) }, body => 'none' } );
sub tags_defined { Decl->new_data(<<EOF); }
on
do
sub
filter
perl (body=text)
EOF

=head2 build_payload, build_macro_payload, fixvars, fixcall, fixevent, fixfind, make_code, make_macro_code, parse_select, make_select, make_dml, make_output, make_ifnew

The C<build_payload> function is then called when this object's payload is built (i.e. in the stage when we're adding semantics to our
parsed syntax).  The payload of a code object is its callable code result.

The C<make_code> function builds code in an event context; it actually calls C<make_macro_code>, which does the same in an arbitrary
node context that you supply (but that defaults to the event context of the code node).

The parent's payload will always have been created by the time this function is called.

The C<make_select> function is by far the most complex of our code generators, as it has to find an iterator source and build a while loop,
or a DBI database and build a query and select loop.  The parsing is split out into C<parse_select> in order to make it usable from elsewhere.

The C<make_dml> function handles the non-select DBI keywords (just 'insert', 'update', and 'delete').

The C<fix*> functions munge various things around in our code generation scheme.

The C<make_output> function handles text blocks for output delineated with "<<".

The C<make_ifnew> is probably going overboard with specific select tweaks; I really need to start thinking harder about real macros in the code.

=cut

sub fixvars  { '$self->{v}->{\'' . $_[0] . '\'}' }
sub fixcall  {
   return '$self->' . $_[0] if ($_[0] eq 'output' ||
                                $_[0] eq 'write'  ||
                                $_[0] eq 'log');
   '$cx->' . $_[0]
}
sub fixevent { '$cx->do(\'' . $_[0] . '\')' }

sub fixfind  { '$self->find_context(' . $_[0] . ')' }
   
our $next_counter = 1;

sub parse_select {   # 2011-08-27 - factored out of make_select below - made possible once more by the magic of unit testing!
   my ($foreach) = @_;
   my @vars = ();
   my $keyword = '';

   if ($foreach =~ /^\s*(.*?)\s+in\s+(.*?)\s*$/) {
      my ($target, $source) = ($1, $2);
      @vars = split /\s*[, ]\s*/, $target;
      return ('foreach', $target, $source, @vars);
   }
   
   if ($foreach =~ /^\s*(.*?)\s+from\s+(.*?)\s*$/) {
      my ($target, $source) = ($1, $2);
      my $t = $target;
      $t =~ s/^(distinct|all)\s+//;
      @vars = map { s/^.* //; $_ } split (/\s*,\s*/, $t);
      return ('select', $target, $source, @vars)
   }
   if ($foreach !~ /\s/) {
      return ('foreach', '', $foreach);
   }
   
   return ('error');
}

sub make_select {
   my ($self, $foreach, $keyword) = @_;
   my $cx = $self->event_context;
   
   my ($target, $source);
   my @vars = ();
   my @last_vars = ();
   
   ($keyword, $target, $source, @vars) = parse_select($foreach);
   @last_vars = map { '_last_' . $_ . '_value' } @vars;
   
   if ($keyword eq 'error') {
      $self->error("'^foreach/select $foreach' can't be parsed");
      return 'if (0) {';
   }
   
   my $unique = $next_counter++;
   my $ret;

   if ($keyword eq 'foreach') { # Normal data
      my ($datasource, $type) = $self->find_data($source);   # TODO: error handling if source not found.
   
      if (not $target and $datasource->is ('data')) {
         # Take target from definition of data source.
         push @vars, $datasource->parmlist;
         push @last_vars, map { '_last_' . $_ . '_value' } $datasource->parmlist;
      }
   
      if ($type eq 'text') {
         my $my = '';
         if (@vars) {
            $target = 'my $' . shift @vars;
            $my = 'my ($' . join (', $', @vars) . '); ' if @vars;
            $my .= 'my ($' . join (', $', @last_vars) . '); ' if @last_vars;
         } else {
            $target = '$_';
         }
         $ret .= '{ ';
         $ret .= 'my @text_node = $self->find_data(\'' . $source . '\'); ';
         $ret .= 'my $iterator = $text_node[0]->iterate; ';
         $ret .= 'while (' . $target . ' = $iterator->next) { ';
         $ret .= $my;
      } elsif ($type eq 'data') {
         $ret .= '{ ';
         $ret .= 'my @data_node = $self->find_data(\'' . $source . '\'); ';
         $ret .= 'my $iterator = $data_node[0]->iterate; ';
         $ret .= 'while (my $line = $iterator->next) { ';
         $ret .= 'my ($' . join (', $', @vars) . ') = @$line;';
         $ret .= 'my ($' . join (', $', @last_vars) . ') = @$line;';
      } else {
         $self->error ("node foreach not implemented yet");
         $ret = 'if (0) {';
      }
   } else { # Database (e.g. DBI) select
      # This is kind of the default mode for DBI; absent specification to the contrary, we find the first database handle and use it.
      # But "source" is where everything is coming from, so if we can munge in in some way, this is where that will happen.
      
      if ($vars[0] eq '*') {
         $ret .= '{ ';
         $ret .=    'my $dbh = $self->find_context(\'database\')->payload; ';
         $ret .=    'my $sth = $dbh->prepare ("select ' . $target . ' from ' . $source . '"); ';
         $ret .=    '$sth->execute(); ';
         $ret .=    'while (my $row = $sth->fetchrow_hashref()) {';
      } else {
         $ret .= '{ ';
         $ret .=    'my $dbh = $self->find_context(\'database\')->payload; ';
         $ret .=    'my $sth = $dbh->prepare ("select ' . $target . ' from ' . $source . '"); ';
         $ret .=    '$sth->execute(); ';
         $ret .=    'my ($' . join (', $', @vars) . '); ';
         $ret .=    'my ($' . join (', $', @last_vars) . '); ';
         $ret .=    '$sth->bind_columns (\$'. join (', \$', @vars) . '); ';
         $ret .=    'while ($sth->fetch()) {';
      }
   }
   
   $ret;
}

sub make_dml {
   my ($self, $foreach, $keyword) = @_;
   my $cx = $self->event_context;
}

sub make_output {
   my ($output, $flag) = @_;

   my $r;
   if ($flag eq '"') {
      $r = '$self->output(<<"EOF");' . "\n";
   } else {
      $r = '$self->output($Decl::template_engine->express(<<\'EOF\', $cx));' . "\n";
   }
   $r   .= $output;
   $r   .= "EOF\n";
   return $r;
}

sub make_ifnew {
   my ($v) = @_;
   return 'if (not defined $_last_' . $v . '_value or $_last_' . $v . '_value ne $' . $v . ') {' . "\n" .
          '   $_last_' . $v . '_value = $' . $v . ';' . "\n";
}

sub make_code {
   my $self = shift;
   my $code = shift;
   
   make_macro_code($self, $code, undef, @_);
}
   
sub make_macro_code {
   my $self = shift;
   my $code = shift;
   my $outer_cx = shift || $self->event_context;
   
   my $sem = $outer_cx->semantics;
   my $subs = $self->subs();

   my $preamble = 'my $cx = shift || $outer_cx;' . "\n";
   if (@_) {
      $preamble .= 'my ($' . join (', $', @_) . ') = @_;' . "\n\n";  # I love generating code.
   }
   foreach my $subname (keys %$subs) {
      $preamble .= 'local *' . $subname . ' = $subs->{\'' . $subname . '\'}->{sub};' . "\n";
   }
   $code = $preamble . $code;
   $code =~ s/\^db( *)->/\$self->find_context('database')->dbh->/g;
   $code =~ s/\$\^(\w+)/fixvars($1)/ge;
   $code =~ s/\^!(\w+)/fixevent($1)/ge;
   $code =~ s/\^\((.*?)\)/fixfind($1)/ge; # TODO: balanced parens would be a lot more convincing in that regexp...
   $code =~ s/\^foreach (.*) {{/$self->make_select($1, 'foreach')/ge;
   $code =~ s/\^select (.*) {{/$self->make_select($1, 'select')/ge;
   $code =~ s/\^if-new (.*) {/make_ifnew($1)/ge;
   $code =~ s/\^(insert .*);/$self->make_dml($1)/ge;
   $code =~ s/\^(delete .*);/$self->make_dml($1)/ge;
   $code =~ s/\^(update .*);/$self->make_dml($1)/ge;
   $code =~ s/\^(\w+)/fixcall($1)/ge;
   
   my $lcode = '';
   my $mode = 0;
   my $indent = 0;
   my $output;
   my $flag = '';
   foreach my $line (split /\n/, $code) {
      if ($mode) {
         my $leader = substr($line, 0, $indent);
         if ($leader =~ /^[\s<]*$/) {
            $output .= substr($line, $indent) . "\n";
         } else {
            $lcode .= make_output($output, $flag);
            $mode = 0;
            $lcode .= $line . "\n";
         }
      } else {
         if ($line =~ /^\s*<</) {
            my $olen = length($line);
            $line =~ s/^\s*<<//;
            $flag = substr($line, 0, 1);
            $line =~ s/$flag\s*//;
            $indent = $olen - length ($line);
            $output = $line . "\n";
            $mode = 1;
         } else {
            $lcode .= $line . "\n";
         }
      }
   }
   if ($mode) {
      $lcode .= make_output($output, $flag);
   }

   my $sub = eval "sub {" . $lcode . "\n}";
   $self->error ($@) if $@;  # TODO: man, this is just the wrong way to do this.
   print STDERR $@ if $@;

   if (wantarray) {
      return ($sub, $lcode);
   } else {
      return $sub;
   }
}

sub build_payload { # TODO: split this out into build_code and build_payload
   my $self = shift;
   my $is_event = shift;   # @_ is now the list of 'my' variables the code expects, by name.
   build_macro_payload($self, $is_event, undef, @_);
   $self->{callable} = 'sub' if $self->is('sub');
   $self;
}

sub build_macro_payload {
   my $self = shift;
   my $is_event = shift;
   my $cx = shift || $self->event_context;

   return $self if $self->{built};
   $self->{built} = 1;
   
   if (!@_) {   # Didn't get any 'my' variables explicitly defined.
      @_ = $self->optionlist;
   }     
   
   # Here's the tricky part.  We have to build some code and evaluate it when asked.  This could get arbitrarily complex.
   # If we have a code body, that's our code. If we have both a body and a "code" (i.e. a one-line bracketed body), then
   # the "code" takes precedence (e.g. Wx toolbars).
   if ($self->code) {  # TODO: this wasn't covered by the unit tests!
      my $code = $self->code;
      $code =~ s/^{//;
      $code =~ s/}$//;
      #print "code is $code\n";
      ($self->{sub}, $self->{gencode}) = make_macro_code ($self, $code, $cx, @_);
      #print STDERR "1gencode is " . $self->{gencode} . "\n";
      $self->{callable} = 1;
      $self->{owncode} = 1;
   } elsif ($self->body) {
      ($self->{sub}, $self->{gencode}) = make_macro_code ($self, $self->body, $cx, @_);
      #print STDERR "gencode is " . $self->{gencode} . "\n";

      $self->{callable} = 1;
      $self->{owncode} = 1;
   } else {
      # No body means we're just going to build each of our children, and try to execute each of them in sequence when called.
      # No body and no callable children means we're not callable either.
      #print "making child-based caller:" . $self->myline . "\n";
      my $child_code = 0;
      foreach ($self->nodes) {
         $_->build;
         $child_code = $child_code || $_->{callable};
      }
   
      $self->{callable} = $child_code ? 1 : 0;
      $self->{sub} = sub { $self->go(); };
      $self->{owncode} = 0;
   }

   $self->{event} = $self->is ('on') ? 1 : 0;
   if ($self->{callable} && ($is_event || ($self->is ('on') and $self->name))) {
      $cx->register_event ($self->name, $self->{sub});
   }

   $self->{payload} = $self->{sub} unless $self->{payload};  # TODO: this seems fishy.
   return $self;
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::Semantics::Code
