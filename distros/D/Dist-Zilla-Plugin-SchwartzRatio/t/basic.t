use strict;
use warnings;

use Test::More 0.96;
use Test::Deep;

use Test::DZil;
use Dist::Zilla::Plugin::SchwartzRatio;

use Test::MockObject;
use MetaCPAN::Client;
use List::Lazy qw/ lazy_fixed_list /;

package FakeRelease {
    use Moose;
    has version => ( is => 'ro' );
    has date    => ( is => 'ro' );
}

my $fake_client = Test::MockObject->new;
my $releases = Test::MockObject->new;
$releases->set_series( next 
    => map { 
        FakeRelease->new( version => '1.1.'.$_, date => '2017-01-0'.$_) 
    } 1..3 
);

$fake_client->set_always( release => $releases );

{ 
    no warnings; 
    sub MetaCPAN::Client::new { $fake_client }
}

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
        FakeRelease
        SchwartzRatio
    /,
);

my $tzil = Builder->from_config(
    { dist_root => 'corpus' },
    { add_files => { 'source/dist.ini' => $dist_ini } },
);

$tzil->release;

cmp_deeply(
    $tzil->chrome->logger->events,
    superbagof(
        map {
        superhashof({
            level => 'info',
            message => re(qr/v1.1.$_, 2017-01-0$_/) })
        } 1..3
    ),
    'versions are listed',
);

done_testing;
