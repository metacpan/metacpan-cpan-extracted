use Module::Build::Compat;

my $build = 
  Module::Build->new(module_name   => 'Log::Info',
                     dist_abstract => 'Single interface for log output',
                     dist_author   => 'M J Pearce <fluffy@cpan.org>',
                     license       => 'perl',
                     requires      => 
                       +{ 'perl'                      => '5.10.0',
                          'Term::ProgressBar'         => '2.00',
                          'IPC::Run'                  => '0.44',
                          'Log::Log4perl'             => '1.23',
                          'IO::All'                   => '0.39',
                          'Log::Dispatch::FileRotate' => '1.19',
                          'Log::Dispatch'             => '2.22',
                        },
                    );

$build->create_build_script;
if ( ! -e 'Makefile.PL' ) {
  Module::Build::Compat->create_makefile_pl('passthrough', $build);
  chmod 0644, 'Makefile.PL'
    or die "failed to chmod Makefile.PL: $!\n";
}
