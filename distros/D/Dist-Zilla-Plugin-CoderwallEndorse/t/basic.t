use strict;
use warnings;

use Test::More 0.96;

use Test::DZil;
use JSON::Any;

my $dist_ini = dist_ini(
    {
        name     => 'DZT-Sample',
        abstract => 'Sample DZ Dist',
        author   => 'E. Xavier Ample <example@example.org>',
        license  => 'Perl_5',
        copyright_holder => 'E. Xavier Ample',
        version => '1.0.0',
    },
    qw/
        GatherDir
    /,
    [ 'CoderwallEndorse' => {
        users => 'yanick:Yanick, bob:Bob'
    }],
);

my $tzil = Builder->from_config(
    { dist_root => 'corpus' },
    { add_files => { 
            'source/dist.ini' => $dist_ini,
            'source/README.mkdn' => <<'END_MKDN',
yadah 

# AUTHORS

* Yanick Champoux

* Bob Sumfin


END_MKDN
    } },
);

$tzil->build;

my $readme = $tzil->slurp_file( 'build/README.mkdn' );

for my $auth ( qw/ Yanick Bob / ) {
    like $readme => qr/$auth.*?\[endorse\]/, "$auth link is present";
}

done_testing;
