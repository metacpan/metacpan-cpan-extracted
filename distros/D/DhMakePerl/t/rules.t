#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
    use_ok('Debian::Rules');
};

my $r = Debian::Rules->new(
    { lines => [ "#!/usr/bin/make -f\n", "%:\n", "\tdh \$\@\n" ] } );

is( @{ $r->lines  }, 3,  'lines initialized properly' );
ok( $r->is_dhtiny, "Detects simple dhtiny-style rules" );

$r = Debian::Rules->new(
    {   lines => [
            "#!/usr/bin/make -f\n",
            "%:\n",
            "\tdh \$\@ --with=quilt\n",
            "\n",
            "# something else goes here\n",
        ]
    }
);
ok( $r->is_dhtiny, "Detects dh in dhtiny+quilt" );
ok( $r->is_quiltified, "Detects --with=quilt" );
$r->drop_quilt;
is( $r->lines->[2], "\tdh \$\@\n", 'Dequiltification works' );
is( scalar @{ $r->lines }, 5, "Dequiltification doesn't cut lines" );

$r = Debian::Rules->new(
    {   lines => [
            "#!/usr/bin/make -f\n",
            "%:\n",
            "\tdh --with=quilt \$\@\n",
            "\n",
            "# something else goes here\n",
        ]
    }
);
$r->drop_quilt;
is( $r->lines->[2], "\tdh \$\@\n", 'Dequiltification works with --with=quilt in the middle' );
