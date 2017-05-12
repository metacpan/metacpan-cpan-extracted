use 5.020002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'LibJIT',
    VERSION_FROM      => 'lib/LibJIT.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/LibJIT.pm', # retrieve abstract from module
    AUTHOR            => 'Vickenty Fesunov <cpan+libjit@setattr.net>',
    LICENSE           => 'lgpl_2_1',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => ['-ljit'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(),
              {name=>"JIT_PROT_EXEC_READ", macro=>"1"},
              {name=>"JIT_PROT_EXEC_READ_WRITE", macro=>"1"},
              {name=>"JIT_PROT_NONE", macro=>"1"},
              {name=>"JIT_PROT_READ", macro=>"1"},
              {name=>"JIT_PROT_READ_WRITE", macro=>"1"},
              {name=>"jit_abi_cdecl", macro=>"1"},
              {name=>"jit_abi_fastcall", macro=>"1"},
              {name=>"jit_abi_stdcall", macro=>"1"},
              {name=>"jit_abi_vararg", macro=>"1"},
              {name=>"jit_label_undefined", macro=>1});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'LibJIT',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
