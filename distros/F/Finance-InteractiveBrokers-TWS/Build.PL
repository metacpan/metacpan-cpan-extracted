use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Finance::InteractiveBrokers::TWS',
    license             => 'perl',
    dist_author         => 'Jay Strauss <tws_at_heyjay.com>',
    dist_version_from   => 'lib/Finance/InteractiveBrokers/TWS.pm',
    requires => {
        'File::Spec'        => 0,
        'Inline::Java'      => .5092,
        'Class::InsideOut'  => 0,
        'Test::More'        => 0,
        'version'           => 0,

    },
);

$builder->create_build_script();


use Config;
use File::Spec;

my $comp_dir = $Config{sitelib};

foreach (qw/Finance InteractiveBrokers TWS _Inline/) {

    $comp_dir = File::Spec->catfile($comp_dir, $_);
    mkdir $comp_dir;
}
