use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use lib "$FindBin::Bin/../inc";
use ExtUtils::CppGuess;
use ILCPPConfig::OldCompilerGuess ();

my( $old_compiler, $old_libs )
  = ILCPPConfig::OldCompilerGuess::guess_compiler();
my $guess = ExtUtils::CppGuess->new;
my( $compiler,     $libs     )
  = map $guess->$_, qw(compiler_command linker_flags);

TODO: {
  local $TODO = "Probably will fail: These tests document differences in " .
                "config detection methods.";
  is( $compiler, $old_compiler,
    "Compiler / flags for EU::CG versus Makefile.PL guess method." );
  is( $libs, $old_libs,
    "Libraries for EU::CG versus Makefile.PL guess method." );
}

diag "\nCompiler guesses:\n" .
     "\tEU::CppGuess:    [$compiler],\n" .
     "\tOld Makefile.PL: [$old_compiler].\n";

diag "Linker guesses:\n"     .
     "\tEU::CppGuess:    [$libs],\n" .
     "\tOld Makefile.PL: [$old_libs].";

done_testing();
