package Decl::Semantics::Data;

use warnings;
use strict;

use base qw(Decl::Node);
use Text::ParseWords;
use Iterator::Simple qw(:all);

=head1 NAME

Decl::Semantics::Data - implements a data table.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

The data class implements tabular data.  This is different from the definition of the table itself, which will be used
(later) to identify external data sources.  Tabular data can be seen as a memory table or an in-memory cursor for ongoing tabular data manipulation.

Note also that *tree* data can be retrieved any old time, as it's inherent in the structure of our declarative language.  Explicitly declared tabular
data is really just to save some typing and for the sake of some efficiency in retrieval.

Tabular data is space-delimited and obeys quotes in the same way as the Unix shell (it uses L<Text::ParseWords>).  For instance:

   data (field1, field2, field3)
      value1       "first row"  3
      value2       "second row" 19
      value3       "third row"  20
      
An iterator retrieved for this field would return three values (the names of the fields are for other people to know what we've got):

   ['value1', 'first row',  3]
   ['value2', 'second row', 19]
   ['value3', 'third row',  20]
   
The data tag can also have a code body that returns such an iterator; really, the data tag is just a holder for an iterator that returns lists of
data, in the same way that the text tag is a holder for an iterator that returns strings.  (And any node can be seen as an iterator that returns other nodes.)

The "foreach" command writes code appropriate to a given iterator, so for the example above, we might embed this:

   ^foreach field1, field2 in data {
      print "$field1: $field2\n";
   }
   
This would translate into something like this Perl code:

   my @data8792 = $self->find_data("data");
   my $i8792 = $data8792[0]->iterate;
   while ($row8792 = $i8792->next) {
      my ($field1, $field2) = @$row8792;
      
      print "$field1: $field2\n";
   }

(Except all that generated stuff would be on one line, to avoid confusing warning messages if and when we get around to intercepting warning messages.)

For other types of iterator, it would do something slightly different.


=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what xmlapi tags this plugin claims to implement.

=cut
sub defines { ('data'); }
our %build_handlers = ( data => { node => sub { Decl::Semantics::Data->new (@_) }, body => 'none' } );
sub tags_defined { Decl->new_data(<<EOF); }
data (body=text)
EOF

=head2 iterate

The C<iterate> function is called when we want to iterate over the contents of the data node.  It inherits from the generic line-by-line iteration
functionality of the Node class, but splits its lines into words using L<Text::ParseWords>.

=cut

sub iterate {
   my $self = shift;
   
   my $iterator = $self->SUPER::iterate();
   
   iterator {
      my $next;
      while (not $next = $iterator->next) {
         return unless defined $next;
         $next =~ s/\s+$//;
         next unless $next;
      }
      return unless defined $next;
      my @words = parse_line('\s+', 0, $next);
      return \@words;
   }
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

1; # End of Decl::Semantics::Data
