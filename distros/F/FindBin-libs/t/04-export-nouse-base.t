package Testophile;

use v5.8;

use Test::More;

use Cwd         qw( abs_path        );
use List::Util  qw( first           );
use Symbol      qw( qualify_to_ref  );

$\ = "\n";
$, = "\n\t";

# note: /bin does not exist on W32 systems. need to 
# attempt adding it here in order to have something
# to find at all.
#
# likely case is that adding it to the the current
# directory is likely to work.

my @basz    = qw( bin lib );

plan tests => 2 * @basz;

require FindBin::libs;

for my $base ( @basz )
{
    my $dir = "/$base";

    SKIP:
    {
        -e $dir
        or skip "System lacks '$dir' directory" => 2;

        eval
        {
            FindBin::libs->import
            (
                "base=$base", 
                qw
                (
                    noprint
                    export
                    nouse
                    ignore=
                )
            );

            1
        }
        or skip "Failed search: '$base', $@" => 2;

        my $expect  = abs_path $dir;
        my $ref     = qualify_to_ref $base;

        ok @{ *$ref }, "Installed $ref";

        first { $_ eq $expect } @{ *$ref }
        ? pass "Found '$expect' (/lib)"
        : fail "Missing: '/lib'"
        ;
    }
}

# this is not a module

0

__END__
