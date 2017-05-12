use Module::Build;

Module::Build->new(
   module_name => 'Fuse::PDF',
   dist_author => 'Chris Dolan <cdolan@cpan.org>',
   license => 'perl',
   requires => {
      'perl' => '5.8.0',        # authored against 5.8.6
      'Fuse' => '0.08',         # prefer 0.09 and beyond
      'CAM::PDF' => '1.11',     # authored against 1.11 which has revision support
      'Readonly' => '1.00',     # authored against 1.03
      'MIME::Base64' => 3.0,    # authored against 3.07

      # for completeness, and CPANTS:
      'Carp' => 0,
      'POSIX' => 0,
      'Fcntl' => 0,
   },
   recommends => {
      # Needed for mount_pdf program
      'Getopt::Long' => '2.0',         # authored against 2.37    
      'Pod::Usage' => '1.0',           # authored against 1.35

      # Optional in tests, skipped if not present
      'Test::Pod' => 0,                # authored against 1.26
      'Test::Pod::Coverage' => 0,      # authored against 1.08
   },
   build_requires => {
      'Test::More' => 0.62,                   # authored against 0.72
      'Test::Class' => 0,                     # authored against 0.24
      'Test::Virtual::Filesystem' => '0.08',  # usually synchronized with t/fusepdf.t
   },
   script_files => [qw(
      bin/mount_pdf
   )],
   create_readme => 1,
   create_makefile_pl => 'traditional',
)->create_build_script;
