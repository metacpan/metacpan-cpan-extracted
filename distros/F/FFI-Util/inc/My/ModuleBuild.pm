package My::ModuleBuild;

use strict;
use warnings;
use 5.008001;
use ExtUtils::CChecker;
use File::Spec;
use File::Basename ();
use base qw( Module::Build::FFI );

sub new
{
  my($class, %args) = @_;

  my $cc = ExtUtils::CChecker->new( quiet => 1 );
  
  $cc->push_include_dirs(
    File::Spec->rel2abs(
      File::Spec->catdir(
        File::Basename::dirname(__FILE__),
        File::Spec->updir,
        File::Spec->updir,
        'ffi',
      )
    )
  );

  foreach my $header (qw( stdint stdlib stddef string time sys/stat ))
  {
    my $macro = uc $header;
    $macro =~ s{/}{_}g;
    $cc->try_compile_run(
      source     => "#include <$header.h>\nint main(int argc, char *argv[]) { return 0; }\n",
      define     => "HAS_$macro\_H",
    );
  }

  foreach my $type (qw( size_t time_t dev_t gid_t uid_t ))
  {
    $cc->try_compile_run(
      source => "#include \"ffi_util_config.h\"\nint main(int argc, char *argv[]) { $type foo; return 0; }\n",
      define => "HAS_" . uc $type,
    );
  }
  
  $args{extra_compiler_flags} = join ' ', @{ $cc->extra_compiler_flags };
  
  $class->SUPER::new(%args);
}

1;
