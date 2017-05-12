#!perl
use Module::Build;
my $build = Module::Build->new(
    module_name        => 'Devel::Cover::Report::Clover',
    create_makefile_pl => 'traditional',
    create_readme      => 'README',
    license            => 'perl',
    no_index           => { 'directory' => [ 'cover_db_test', 't', ], },
    requires           => {
        'Class::Accessor' => 0,
        'Devel::Cover'    => 0,
        'HTML::Parser'    => 0,    # For HTML::Entities
        'Template'        => 0,
    },
    recommends     => { 'Test::MockTime' => 0, },
    build_requires => {
        'Devel::Cover'     => '0',
        'File::Path'       => '2.06',
        'File::Which'      => '1.08',
        'FindBin'          => '0',
        'List::Util'       => '0',
        'TAP::Harness'     => '0',
        'Test::Exception'  => '0',
        'Test::MockObject' => '0',
        'Test::More'       => '0',
    },
    meta_add           => {
        resources  => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://github.com/captin411/devel-cover-report-clover',
            repository => 'https://github.com/captin411/devel-cover-report-clover.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Cover-Report-Clover',
        },
    },
);
$build->add_build_element('tt');
$build->create_build_script;
