use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'File::Monitor::Simple',
      dist_author => ['Sebastian Riedel, <sri@cpan.org>',
                      'Andy Grundman, <andy@hybridized.org>',
                      'Mark Stosberg, <mark@summersault.com>', ],
      license         => 'perl',
      requires => {
        'Class::Accessor::Fast' => 0,
        'File::Find::Rule'      => 0,
        'File::Modified'        => 0,
        'File::Spec'            => 0,
      },
    )->create_build_script;
