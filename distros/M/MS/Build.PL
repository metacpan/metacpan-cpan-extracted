use 5.012;

use strict;
use warnings;
use Module::Build;

# need subclass to clean up index files post-test (otherwise coverage tests,
# etc, tend to give inaccurate results)
my $mb_cleanup = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );
sub ACTION_test {
    my $self = shift;
    $self->SUPER::ACTION_test;
    unlink $_ for (glob "t/corpus/*.idx");
}
SUBCLASS

my $builder = $mb_cleanup->new(
    module_name        => 'MS',
    license            => 'GPL_3',
    dist_author        => q{Jeremy Volkening <jdv@base2bio.com>},
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Module::Build' => 0,
        'Test::Fatal'   => 0,
        'Test::More'    => 0,
        'BioX::Seq'     => 0,
    },
    requires => {
        'Compress::BGZF'    => 0,
        'Data::Lock'        => 0,
        'File::ShareDir'    => 0,
        'HTTP::Tiny'        => 0,
        'Module::Pluggable' => 0,
        'Net::FTP'          => 0,
        'PerlIO::gzip'      => 0,
        'URI'               => 0,
        'XML::Parser'       => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/jvolkening/p5-MS'
        }
    },
    add_to_cleanup => [
        'MS-*',
        't/corpus/*.idx',
        'cover_db',
    ],
    create_license => 1,
    share_dir => 'share',
);
$builder->create_build_script;
