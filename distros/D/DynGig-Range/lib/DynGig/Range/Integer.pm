=head1 NAME

DynGig::Range::Integer - Integer set arithmetics.

=cut
package DynGig::Range::Integer;

use base DynGig::Range::Integer::Parse;
use base DynGig::Range::Integer::Object;

use warnings;
use strict;

use overload '""' => \&string;

=head1 SYNOPOSIS

 use DynGig::Range::Integer;

 my @list = DynGig::Range::Integer->expand( '3,4~9,-6~7,&6~10' );
 my $string = DynGig::Range::Integer->serial( '3', '6', '7~9' );

 my $r1 = DynGig::Range::Integer->new( '3', '6', '7~9' );
 my $r2 = DynGig::Range::Integer->new( '3,6~7' );
 my $r3 = DynGig::Range::Integer->new( '3,4~9,-6~7,&6~10' );

 my $r4 = $r2 - $r3;
 my $r5 = $r2 + $r3;
 my @r5 = $r5->list();

 $r5 &= $r1;

 print $r5, "\n";

=head1 DESCRIPTION

=head2 string()

Overloads B<"">.

=cut
sub string
{
    my ( $this ) = @_;
    DynGig::Range::Integer::Object::string( $this, $this->symbol() );
}

=head1 SEE ALSO

Implements DynGig::Range::Integer::Object and DynGig::Range::Integer::Parse.
See DynGig::Range::Integer::Object for additional methods.

=head1 NOTE

See DynGig::Range

=cut

1;

__END__
