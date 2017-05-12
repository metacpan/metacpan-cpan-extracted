=head1 NAME

DynGig::Range::String - Set arithemtics.

=cut
package DynGig::Range::String;

use base DynGig::Range::String::Parse;
use base DynGig::Range::String::Object;

use warnings;
use strict;

=head1 SYNOPOSIS

 use DynGig::Range::String;

 my @list = DynGig::Range::String->expand( 'abc001', 'abc002~abc013' );
 my $string = DynGig::Range::String->serial( 'abc001~13' );

 my $r1 = DynGig::Range::String->new( 'abc001', 'abc002~abc013' );
 my $r2 = DynGig::Range::String->new( 'bcd003', 'abc008' );
 my $r3 = $r1 + $r2;
 my $r4 = $r1 - $r2;
 my $r5 = $r1 & $r2;

 $r5 &= $r1;

 print $r5, "\n";

=head1 DESCRIPTION

=head2 string()

Overloads B<"">.

=cut
use overload '""' => \&string;

sub string
{
    my ( $this ) = @_;
    DynGig::Range::String::Object::string( $this, $this->symbol() );
}

=head1 SEE ALSO

Implements DynGig::Range::String::Object and DynGig::Range::String::Parse.
See DynGig::Range::String::Object for additional methods.

=head1 NOTE

See DynGig::Range

=cut

1;

__END__
