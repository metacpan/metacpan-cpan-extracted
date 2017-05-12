package MultiFile;

use MultiFile::First;
use MultiFile::Second;

=item go

... go gadget tester

=cut
sub go {
    my $x = 1 + MultiFile::First::go() + MultiFile::Second::go();
    return $x;
}

1;

package MultiFile::Sub;

use MultiFile::First;
use MultiFile::Second;

sub go {
    my $x = 1 + MultiFile::First::go() + MultiFile::Second::go();
    my $y = shift || 0;
    if( $x < $y ) {
        return $y;
    }
    else {
        return $x;
    }
}

1;
__END__
=head1 Test pod

more here

and here
=cut
