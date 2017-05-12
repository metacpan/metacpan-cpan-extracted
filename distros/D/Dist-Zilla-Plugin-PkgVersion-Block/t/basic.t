use strict;
use Test::More;

use autodie;
use Test::DZil;

my $classic = q{
package DZT::Classic;
1;
};

my $single = q{
package DZT::Single {
    say 'hello';
}
1;
};

my $double = q{
package DZT::First {
    say 'hello';
};

package DZT::Second {
    say 'hello';
}
1;
};

my $with_ver = q{
package DZT::WithVer 1.2 {

}
1;
};
my $private = q{
package
   DZT::Private {

}
1;
};

my $tzil = Builder->from_config(
    { dist_root => 'corpus/', },
    { add_files => {
            'source/lib/DZT/Classic.pm' => $classic,
            'source/lib/DZT/Single.pm' => $single,
            'source/lib/DZT/Double.pm' => $double,
            'source/lib/DZT/WithVer.pm' => $with_ver,
            'source/lib/DZT/Private.pm' => $private,
            'source/dist.ini' => simple_ini('GatherDir', 'PkgVersion::Block', 'ExecDir'),
        },
    },
);
$tzil->build;

my $dzt_classic = $tzil->slurp_file('build/lib/DZT/Classic.pm');
like($dzt_classic, qr{^package DZT::Classic;\n}m, "Untouched classic style.");


my $dzt_single = $tzil->slurp_file('build/lib/DZT/Single.pm');
is($dzt_single, q{
package DZT::Single 0.001 {
    say 'hello';
}
1;
}, 'Added version.');


# Semicolon necessary under PPI 1.218 (https://github.com/adamkennedy/PPI/issues/70)
my $dzt_double = $tzil->slurp_file('build/lib/DZT/Double.pm');
is($dzt_double, q{
package DZT::First 0.001 {
    say 'hello';
};

package DZT::Second 0.001 {
    say 'hello';
}
1;
}, 'Added version to both packages.');


my $dzt_with_ver = $tzil->slurp_file('build/lib/DZT/WithVer.pm');
is($dzt_with_ver, q{
package DZT::WithVer 1.2 {

}
1;
}, 'Untouched already declared version.');


my $dzt_private = $tzil->slurp_file('build/lib/DZT/Private.pm');
is($dzt_private, q{
package
   DZT::Private {

}
1;
}, 'Untouched private package.');

done_testing;
