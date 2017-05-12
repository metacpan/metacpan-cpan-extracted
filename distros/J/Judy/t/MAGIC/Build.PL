#!perl
use Module::Build;

# Locate Judy-0.0.1/inc/Alien/Judy.pm
use File::Basename ();
use File::Spec ();
my ( $judy_dir, $magic_dir );
BEGIN {
    $magic_dir = File::Basename::dirname( $0 );
    $judy_dir  = File::Spec->catdir(
        $magic_dir, # Judy-0.01/t/MAGIC/
        '..',       # Judy-0.01/t/
        '..',       # Judy-0.01/
    );
    my $inc_dir = File::Spec->catdir(
        $judy_dir, # Judy-0.01/
        'inc'      # Judy-0.01/inc
    );
    unshift @INC, $inc_dir;
}
use Alien::Judy;

# Copy Judy-0.01/typemap to Judy-0.01/t/MAGIC/typemap
use File::Copy ();
my $src_typemap = File::Spec->catfile(
    $judy_dir,
    'typemap'
);
my $tgt_typemap = File::Spec->catfile(
    $magic_dir,
    'typemap'
);
File::Copy::copy( $src_typemap, $tgt_typemap );

my $build = Module::Build->new(
    module_name => 'MAGIC',
    licence => 'perl',
    configure_requires => {
        'Module::Build'  => 0,
        'Cwd'            => 0,
        'File::Basename' => 0,
        'File::Spec'     => 0,
        'Alien::Judy'   => '0.13',
    },
    build_requires => {
        'ExtUtils::CBuilder' => '0',
    },
    include_dirs => [ $judy_dir, Alien::Judy::inc_dirs() ],
);
$build->create_build_script;
