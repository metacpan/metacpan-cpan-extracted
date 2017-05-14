use Module::Build;

my $class = Module::Build->subclass( code => <<'EOC' );
  sub ACTION_java {
    my $self = shift;
    $self->do_system("gcj", ('-C', <src/*.java>) );
    while ( my $java_class = <src/*.java> ) {
      $java_class =~ s/\.java$//;
      $self->do_system("gcjh", $java_class);
    }
    #$self->do_system("gcj", ('-c', <src/*.java>, '-I', 'src', '-o', 'src/java.o') );
    $self->do_system("gcj", ('-fjni', '-c', <src/*.java>, '-I', 'src', '-o', 'src/java.o') );
    $self->add_to_cleanup(<src/*.h>, <src/*.class>, <src/*.o>);
    #$self->notes( java_built => 1 );
  }

  sub ACTION_code {
    my $self = shift;
    $self->dispatch('java') if not $self->notes('java_built');
    $self->SUPER::ACTION_code();
  }

  sub ACTION_swig {
    my $self = shift;
    $self->do_system('swig -c++ -perl -outdir lib/Java/ -o lib/Java/Wrapper.xs lib/Java/Wrapper.i');
  }
EOC
  
my $build = $class->new
 ( module_name => 'Java::Import',
   dist_version => '0.03',
   dist_abstract => 'Perl library for calling Java from Perl',
   dist_author => 'David Rusek <rusekd@cpan.org>',
   license => 'perl',
   requires => { 'GCJ::Cni' => 0 },
   #PL_files => { 'lib/Java/Wrapper.pm.PL' => [ 'lib/Java/Wrapper.pm', 'lib/Java/Wrapper.xs' ] },
   include_dirs => [ 'src' ],
   dynamic_config => 1,
   #c_source => 'src',
   java_source => 'src',
   extra_compiler_flags => [ '-x', 'c++', '-include', 'gcj/cni.h' ],
   extra_linker_flags => [ 'src/java.o', '-lgcj', '-lstdc++' ],
   create_makefile_pl => 'passthrough'
 );


$build->create_build_script;
