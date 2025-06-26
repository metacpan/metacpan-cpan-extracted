use strict;
use warnings;

use 5.24.0;

use experimental qw/ signatures /;

use Test2::V0;

use Test::DZil;
use Dist::Zilla::Plugin::MetaYAML;
use JSON::Any;

sub dzil_yield(%help_wanted) {

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
            MetaJSON
            FakeRelease
        /,
        [ 'HelpWanted' => \%help_wanted ],
    );

    my $tzil = Builder->from_config(
        { dist_root => 'corpus' },
        { add_files => { 'source/dist.ini' => $dist_ini } },
    );

    $tzil->build;

    my $meta = JSON::Any->new->decode( $tzil->slurp_file('build/META.json'));
    return [ sort @{ $meta->{x_help_wanted} || [] } ];
}

is dzil_yield(positions => 'maintainer co-maintainer documentation coder translator tester'),
    [ sort qw( maintainer developer translator documenter tester ) ];

is dzil_yield(tester => 1, coder => 1),
    [ sort qw( developer tester ) ];

is dzil_yield(positions => 'helper documentation'),
    [ sort qw( documenter helper ) ];

done_testing;
