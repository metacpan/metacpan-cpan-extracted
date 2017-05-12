use Module::Build;
use IO::File;
use File::Spec;

my $root = File::Spec->rootdir;

my $class = Module::Build->subclass(code => <<'EOC');
    sub process_conf_files {
        my $self  = shift;
        my $files = IO::File->new('MANIFEST');
        while (<$files>) {
            next unless m!^conf/!;
            chomp;
            $self->copy_if_modified( $_ => 'blib' );
        }
    }
EOC

my $build = $class->new(
    module_name => 'Gwybodaeth',
    license => 'bsd',
    dist_author => 'Iestyn Pryce, <imp25@cam.ac.uk>',
    requires => {
                'perl' => '>= 5.8.0',
                'XML::Twig' => '>=3.32',
                'Text::CSV' => '>=1.10',
                'Carp' => 0,
                'LWP' => 0,
                'CGI' => 0,
                'CGI::Carp' => 0,
                'Tie::InsertOrderHash' => 0,
                },
    build_requires => {
                        'Test::More' => 0,
                        'Test::Output' => 0,
                        'Test::Exception' => 0,
                        'Module::Build' => '>=0.26',
                      },
    configure_requires => {
                        'Module::Build' => '>=0.26',
                          },
    recursive_test_files => 1,
    script_files => [ File::Spec->catfile('script','gwybodaeth'), 
                      File::Spec->catfile('script','gwybodaeth.cgi') ],
    install_path => { conf => File::Spec->catfile("$root",'etc','gwybodaeth') },
    dist_abstract => 'Scripts and classes for RDF-izing data',
    );

$build->add_build_element('conf');
$build->create_build_script;
