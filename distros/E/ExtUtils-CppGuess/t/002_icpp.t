use strict;
use warnings;
use Data::Dumper;
use Test::More;
use ExtUtils::CppGuess;

my @DATA = (
  [
    { os => 'MSWin32', cc => 'cl', config => {ccflags => ''} },
    {
      is_msvc => 1, is_gcc => 0,
      compiler_command => 'cl -TP -EHsc',
      linker_flags => 'msvcprt.lib',
    },
  ],
  [
    { os => 'MSWin32', cc => 'gcc', config => {ccflags => ''} },
    {
      is_msvc => undef, is_gcc => 1,
      compiler_command => 'g++ -xc++',
      linker_flags => '-lstdc++',
    },
  ],
  [
    { os => 'freebsd', cc => 'gcc', config => {ccflags => ''}, osvers => 9 },
    {
      is_msvc => undef, is_gcc => 1,
      compiler_command => 'g++ -xc++',
      linker_flags => '-lstdc++',
    },
  ],
  [
    { os => 'freebsd', cc => 'gcc', config => {gccversion => 'Clang', ccflags => ''}, osvers => 10 },
    {
      is_msvc => undef, is_gcc => 1,
      compiler_command => 'clang++ -Wno-reserved-user-defined-literal',
      linker_flags => '-lc++',
    },
  ],
  [
    { os => 'netbsd', cc => 'gcc', config => {ccflags => ''} },
    {
      is_msvc => undef, is_gcc => 1,
      compiler_command => 'g++ -xc++',
      linker_flags => '-lstdc++ -lgcc_s',
    },
  ],
  [
    { os => 'linux', cc => 'clang', config => {gccversion => 'Clang', ccflags => ''} },
    {
      is_msvc => undef, is_gcc => 1,
      compiler_command => 'clang++ -xc++ -Wno-reserved-user-defined-literal',
      linker_flags => '-lstdc++',
    },
  ],
  [
    { os => 'linux', cc => 'gcc', config => {ccflags => ''} },
    {
      is_msvc => undef, is_gcc => 1,
      compiler_command => 'g++ -xc++',
      linker_flags => '-lstdc++',
    },
  ],
);
my @METHODS = qw(is_msvc is_gcc compiler_command linker_flags);
$Data::Dumper::Indent = $Data::Dumper::Sortkeys = $Data::Dumper::Terse = 1;

run_test(@$_) for @DATA;

done_testing;

sub run_test {
  my ($args, $expect) = @_;
  my $guess = ExtUtils::CppGuess->new(%$args);
  my %got = map {$_ => $guess->$_} @METHODS;
  is_deeply \%got, $expect or diag Dumper [ $args, \%got, $expect ];
}
