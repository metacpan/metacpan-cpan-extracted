
use strict;
use Test;
use Devel::FindBlessedRefs qw(:all);

plan tests => 3;

my $testar = [
    (bless {test=>"yes1"}, "MyTestPackage"),
    (bless {test=>"yes2"}, "MyTestPackage"),
];

eval "use Scalar::Util";
if( $@ ) {
    warn " skipping all tests, no Scalar::Util found\n";
    skip(1,1,1) for 1 .. 3;
    exit 0;
}

my $hrm = sub { "hrm" };
find_refs_by_coderef(sub {
    my ($r) = @_;

    if( my $t = (ref $r) ) {
        if( Scalar::Util::blessed( $r ) ) {
            if( $r->isa("MyTestPackage") ) {
                ok(1);
            }
        }

        if( $t eq "CODE" and $r == $hrm ) {
            ok(1);
        }
    }
});
