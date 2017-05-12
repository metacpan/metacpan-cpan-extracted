package Locale::MakePhrase::Language::en;
our $VERSION = 0.2;

=head1 NAME

Locale::MakePhrase::Langage::en - Custom language handling for English.

=head1 DESCRIPTION

This module implements custom language handling capabilites, for the
English language.

=head1 API

The following methods are implemented:

=cut

use strict;
use warnings;
use utf8;
use Data::Dumper;
use base qw(Locale::MakePhrase::Language);
use Locale::MakePhrase::Utils qw(left);

#--------------------------------------------------------------------------

=head2 $self new([...])

[ Inherited from L<Locale::MakePhrase::Language>. ]

No options are necessary for this module.

If you are using this as an example, you would implement the
C<init([...])> method, then return a reference to C<$self>.

=cut

#--------------------------------------------------------------------------

=head2 boolean y_or_n($keypress)

Implements handling of B<y> or B<n> keypress for English languages.

=cut

sub y_or_n {
  my $y = lc(left($_[1]));
  return 0 unless $y eq 'y';
  1;
}

1;
__END__
#--------------------------------------------------------------------------

