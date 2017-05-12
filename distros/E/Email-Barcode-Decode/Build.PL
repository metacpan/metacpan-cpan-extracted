use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Email::Barcode::Decode',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Email/Barcode/Decode.pm',
    requires => {
        'Email::MIME'           => 0,
        'File::Temp'            => 0,
        'Path::Class'           => '0.33',
        'Class::Accessor::Fast' => 0,
        'Carp'                  => 0,
        'File::Find::Rule'      => 0,
        'Image::Magick'         => 0,
        'Barcode::ZBar'         => 0,
        'Capture::Tiny'         => 0,
        'File::Which'           => 0,
    },
    build_requires => {
        'Test::More'      => 0,
    },
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    add_to_cleanup      => [ 'Email-Barcode-Decode-*' ],
    create_readme       => 1,
);

$builder->create_build_script();
