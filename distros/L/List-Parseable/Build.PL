use Module::Build;
use strict;
use warnings;

my %requires = (
                 'perl'                     => '5.000',
                 'Sort::DataTypes'          => '3.00',
                 'Storable'                 => '0',
                 'Text::Balanced'           => '0',
               );
my %build_mods = (
                 'Test::Inter'              => '0',
               );


my $build = Module::Build->new(
        license            => 'perl',
        dist_version       => '1.06',
        dist_author        => 'Sullivan Beck <sbeck@cpan.org>',
        module_name        => 'List::Parseable',
        dist_abstract      => 'routines to work with lists containing a simple language',
        requires           => \%requires,
        build_requires     => \%build_mods,
        sign               => 1,
);

$build->create_build_script;
