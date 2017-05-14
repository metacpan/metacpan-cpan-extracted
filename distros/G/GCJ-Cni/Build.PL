#check for required things
#print "Checking for gcj...\n";
#if ( $gcj_test = system("gcj -v 2>&1 /dev/null") ) {
#	print "You do not appear to have GNU GCJ installed\n";
#	print "If you believe it is installed please check to make sure it is in your PATH\n";
#	exit(1);
#}


use Module::Build;

my $class = Module::Build->subclass(
  class => 'My::Builder',
  code => q{
    sub ACTION_swig {
      my $self = shift;
      #$self->do_system('swig -c++ -nodefault -perl -outdir lib/GCJ/ -o lib/GCJ/Cni.xs lib/GCJ/Cni.i');
      $self->do_system('swig -c++ -perl -outdir lib/GCJ/ -o lib/GCJ/Cni.xs lib/GCJ/Cni.i');
    }
  }
);

my $build = $class->new
 ( module_name => 'GCJ::Cni',
   dist_version => '0.03',
   dist_author => 'David Rusek <rusekd@cpan.org>',
   dist_abstract => 'Perl Wrapper around GNU Compiler for Java CNI interface',
   license => 'perl',
   #PL_files => { 'lib/GCJ/Cni.pm.PL' => [ 'lib/GCJ/Cni.pm', 'lib/GCJ/Cni.xs' ] },
   dynamic_config => 1,
   extra_compiler_flags => [ '-x', 'c++', '-include', 'gcj/cni.h' ],
   #extra_compiler_flags => [ '-x', 'c++' ],
   extra_linker_flags => [ '-lgcj' ],
   create_makefile_pl => 'passthrough',
 );

$build->create_build_script;
