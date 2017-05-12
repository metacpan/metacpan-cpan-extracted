package Finance::FIX;

use warnings;
use strict;

=head1 NAME

Finance::FIX - Parse FIX protocol messages.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Finance::FIX;

  # Instantiate.
  my $fix = Finance::FIX->new;

  # Parse string containing a FIX message.
  # Returns an array of FIX nodes, broken down into array refs of tags and values.
  my $message = $fix->parse($message);

  require Data::Dumper;
  print Data::Dumper::Dumper( $message ), "\n";
 
=head1 METHODS

=head2 new

Instantiate new Finance::FIX object.

=cut
sub new {
  my $class = shift;
  return bless { @_ }, $class;
}

=head2 parse($message)

Parse B<$message>, returning array ref of FIX message nodes, broken down into array refs of tags
and values.

=cut
sub parse {
  my ( $self, $message ) = @_;
  my $nodes;
  for my $node ( split /\x01/, $message ) { # Split on "SOH"
    push @$nodes, [ split /=/, $node, 2 ];  # Split tag and value on "="
  }
  return $nodes;
}

=head1 AUTHOR

Blair Christensen, C<< <blair.christensen at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-fix at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-FIX>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::FIX

You can also look for information at:

=over 4

=item * Source Repository

L<https://github.com/blairc/finance-fix.perl>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-FIX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-FIX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-FIX>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-FIX/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Financial_Information_eXchange>, L<http://www.fixprotocol.org/>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Blair Christensen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Finance::FIX
