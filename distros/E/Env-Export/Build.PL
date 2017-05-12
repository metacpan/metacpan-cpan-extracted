###############################################################################
#
#   Module::Build file for Env::Export
#
###############################################################################

use 5.006001;
use strict;
use warnings;

use File::Spec;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Env::Export::Builder',
    code => q|
        sub ACTION_dist
        {
            my $self = shift;

            # Create the text ChangeLog
            $self->do_system('changelog2x',
                             qw(--template text
                                --input ChangeLog.xml
                                --output ChangeLog));
            # Create the text README
            $self->do_system('textile2x',
                             qw(--format plaintext
                                --input README.textile
                                --output README));

            $self->SUPER::ACTION_manifest();
            $self->SUPER::ACTION_dist();
        }
|);

my $builder = $class->new(
    module_name        => 'Env::Export',
    license            => 'perl',
    dist_author        => 'Randy J. Ray <rjray@blackperl.com>',
    dist_abstract      =>
    'Automatically export environment variables as constant-subs',
    dist_version       => '0.22',
    build_requires     =>
    {
        'File::Spec'    => '3.0',
        'Module::Build' => '0.28',
        'Test::More'    => '0.80',
    },
    requires           =>
    {
        'perl' => '5.006001',
    },
    add_to_cleanup     => [ qw(Env-Export-*
                               ChangeLog
                               README
                               MANIFEST
                               MANIFEST.bak
                               META.yml
                               Makefile.PL) ],
    meta_merge         =>
    {
        resources =>
        {
            homepage   => 'http://search.cpan.org/dist/Env-Export',
            bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Env-Export',
            repository => 'https://github.com/rjray/env-export',
        }
    },

    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

exit 0;
