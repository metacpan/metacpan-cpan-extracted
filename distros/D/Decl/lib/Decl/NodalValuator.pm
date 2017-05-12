package Decl::NodalValuator;

use warnings;
use strict;
use Decl::Node;
use Decl::Template;
use Data::Dumper;


=head1 NAME

Decl::NodalValuator - implements the template valuator used in a nodal environment.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This isn't really an object module; it's just a place to instantiate a template engine.  Templates are defined in L<Decl::Template>, and the main
L<Decl> class instantiates a souped-up version of that vanilla engine that can do some fancy Decl-specific stuff.

=head2 instantiate()

Instantiates a template engine with a nodal valuator.  TODO: implement and use an error if a field is not filled in during expression.

=cut

sub instantiate {
   Decl::Template->new(
      valuator      => \&valuator,
      leave_misses  => 0,
      spanners => { foreach => \&do_foreach,
                    select  => \&do_foreach, },
   );
}

=head2 valuator($name, $node)

Like all template valuators, this takes a name and a value context.  By default, the value context is a Node (duh), but we can also pass in a
hashref or an arrayref of alternative data sources.  This gives us as much flexibility as possible when expressing our data.

=cut

sub valuator {
   my ($name, $node) = @_;
   return $node->{$name} if (ref $node eq 'HASH');
   return $node->express_value($name) if (UNIVERSAL::can($node, 'isa') and $node->can('express_value'));
   if (ref $node eq 'ARRAY') {
      foreach (@$node) {
         my $v = valuator ($name, $_);
         return $v if defined $v;
      }
   }
   undef;
}

=head2 do_foreach

The C<do_foreach> function implements a .foreach spanner in nodal templates that retrieves data from the structure and hands it off to the repeat
loop code for formatting.

=cut

sub do_foreach {
   my ($self, $command, $values, $valuator) = @_;
   
   my ($keyword, $target, $source, @vars) = Decl::Semantics::Code::parse_select($$command[1]);  # Same syntax as ^foreach in code
   
   if ($keyword eq 'error') { # Couldn't parse the foreach
      return $self->express_repeat ($command, [
                                                 { error => "'.foreach/select " . $$command[1] ."' can't be parsed"},
                                                 $values
                                              ], $valuator);
   }

   my @results = ();
   if ($keyword eq 'foreach') { # a local data access
      my ($datasource, $type) = $values->find_data($source);   # TODO: error handling if source not found.

      if (not @vars and $datasource->is ('data')) {
        # Take vars from definition of data source.
         push @vars, $datasource->parmlist;
      }
   
      if ($type ne 'data') {  # We can only iterate over data (for now, anyway).
         return $self->express_repeat ($command, [
                                                    { error => 'source not data'},
                                                    $values
                                                 ], $valuator);
      }
   
      my $iterator = $datasource->iterate;
      while (my $line = $iterator->next) {
         # http://stackoverflow.com/questions/38345/is-there-an-elegant-zip-to-interleave-two-lists-in-perl-5
         # This is a nice one-liner that takes the names of the variables and their values, in separate lists,
         # zips the two lists together, and makes it a hashref suitable for template interpretation.
         push @results, { (@vars, @$line)[ map { $_, $_ + @vars } ( 0 .. $#vars ) ] };
      }
   } else { # a select!
      my $dbh = $values->find_context ('database')->payload;  # TODO: error handling
      my $sth = $dbh->prepare ('select ' . $target . ' from ' . $source);  # TODO: error handling here, too
      $sth->execute();
      while (my $row = $sth->fetchrow_hashref()) {
         push @results, $row;
      }
   }

   $self->express_repeat ($command, $values, $valuator, @results);
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::NodalValuator
