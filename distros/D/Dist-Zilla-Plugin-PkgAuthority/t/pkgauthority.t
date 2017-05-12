use strict;
use warnings;
use Test::More 0.88;

use autodie;
use Test::DZil;
use Test::Fatal;

my $with_authority = qq{
   package DZT::WAuth;
   our \$AUTHORITY = 'cpan:PAUSEID';
   1;
};

my $with_authority_two_lines = qq{
   package DZT::WAuthTwoLines;
   our \$AUTHORITY;
   \$AUTHORITY = 'cpan:PAUSEID;
   1;
};

my $xsloader_authority = qq{
   package DZT::XSLoader;
   use XSLoader;
   XSLoader::load __PACKAGE__, \$DZT::XSLoader::AUTHORITY;
   1;
};

my $tester = Builder->from_config(
    { dist_root => 't/dist/DZT'  },
    { add_files =>
        {
            'source/lib/DZT/WAuth.pm'         => $with_authority,
            'source/lib/DZT/WAuthTwoLines.pm' => $with_authority_two_lines,
            'source/lib/DZT/XSLoader.pm'      => $xsloader_authority,
        }
    },
);

$tester->build;

like(
    $tester->slurp_file('build/lib/DZT.pm'),
    qr{^\s*\$\QDZT::AUTHORITY = 'cpan:PAUSEID';\E\s*$}m,
    "added version to DZT",
);

unlike(
    $tester->slurp_file('build/lib/DZT/WAuth.pm'),
    qr{^\s*\$\QDZT::WAuth::AUTHORITY = 'cpan:PAUSEID';\E\s*$}m,
    "*not* added to DZT::WAuth; we have one already",
);

unlike(
    $tester->slurp_file('build/lib/DZT/WAuthTwoLines.pm'),
    qr{^\s*\$\QDZT::WAuthTwoLines::VERSION = 'cpan:PAUSEID';\E\s*$}m,
    "*not* added to DZT::WAuthTwoLines; we have one already",
);

like(
    $tester->slurp_file('build/lib/DZT/XSLoader.pm'),
    qr{^\s*\$\QDZT::XSLoader::AUTHORITY = 'cpan:PAUSEID';\E\s*$}m,
    "added version to DZT::XSLoader",
);

done_testing;