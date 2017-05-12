use strict;
use warnings;
use Test::More 0.96;
use utf8;

use Test::DZil;
use Test::Fatal;

sub _new_tzil {
    return Builder->from_config(
        { dist_root => 'corpus/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    { version => 3.1415 },
                    'GatherDir', [ 'RewriteVersion', { skip_version_provider => 1 } ]
                ),
            },
        },
    );
}

# Just to make sure nothing leaks through when doing
# V=0.01 dzil test
delete $ENV{TRIAL};
delete $ENV{V};
delete $ENV{RELEASE_STATUS};

sub _regex_for_version {
    my ( $q, $version, $trailing ) = @_;
    my $exp = $trailing
      ? qr{^our \$VERSION = $q\Q$version\E$q; \Q$trailing\E}m
      : qr{^our \$VERSION = $q\Q$version\E$q;}m;
    return $exp;
}
my $tzil = _new_tzil;
$tzil->chrome->logger->set_debug(1);
$tzil->build;

pass("dzil build");

like(
    $tzil->slurp_file('build/lib/DZT/Sample.pm'),
    _regex_for_version( q['], '3.1415', '' ),
    "version from dist.ini used",
);

done_testing;
