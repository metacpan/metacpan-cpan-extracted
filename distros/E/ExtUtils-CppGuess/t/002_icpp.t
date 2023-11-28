use strict;
use warnings;
use Test::More;
use ExtUtils::CppGuess;

delete $ENV{CXX};

my @DATA = (
  [
    { os => 'MSWin32', cc => 'cl', config => {ccflags => ''} },
    {
      is_sunstudio => 0,
      is_msvc => 1, is_gcc => 0, is_clang => 0,
      compiler_command => 'cl -TP -EHsc',
      linker_flags => 'msvcprt.lib',
    },
  ],
  [
    { os => 'MSWin32', cc => 'gcc', config => {ccflags => '', ldflags => ''} },
    {
      is_sunstudio => 0,
      is_msvc => undef, is_gcc => 1, is_clang => 0,
      compiler_command => 'g++ -xc++',
      linker_flags => '-lstdc++',
    },
  ],
  [
    { os => 'MSWin32', cc => 'gcc', config => {ccflags => '', ldflags => 'static-libstdc++'} },
    {
      is_sunstudio => 0,
      is_msvc => undef, is_gcc => 1, is_clang => 0,
      compiler_command => 'g++ -xc++',
      linker_flags => '',
    },
  ],
  [
    { os => 'freebsd', cc => 'gcc', config => {ccflags => ''}, osvers => 9 },
    {
      is_sunstudio => 0,
      is_msvc => undef, is_gcc => 1, is_clang => 0,
      compiler_command => 'g++ -xc++',
      linker_flags => '-lstdc++',
    },
  ],
  [
    { os => 'freebsd', cc => 'gcc', config => {gccversion => 'Clang', ccflags => ''}, osvers => 10 },
    {
      is_sunstudio => undef,
      is_msvc => undef, is_gcc => undef, is_clang => 1,
      compiler_command => 'clang++ -Wno-reserved-user-defined-literal',
      linker_flags => '-lc++',
    },
  ],
  [
    { os => 'netbsd', cc => 'gcc', config => {ccflags => ''} },
    {
      is_sunstudio => 0,
      is_msvc => undef, is_gcc => 1, is_clang => 0,
      compiler_command => 'g++ -xc++',
      linker_flags => '-lstdc++ -lgcc_s',
    },
  ],
  [
    { os => 'linux', cc => 'clang', config => {gccversion => 'Clang', ccflags => ''} },
    {
      is_sunstudio => 0,
      is_msvc => undef, is_gcc => undef, is_clang => 1,
      compiler_command => 'clang++ -xc++ -Wno-reserved-user-defined-literal',
      linker_flags => '-lstdc++',
    },
  ],
  [
    { os => 'linux', cc => 'gcc', config => {ccflags => ''} },
    {
      is_sunstudio => 0,
      is_msvc => undef, is_gcc => 1, is_clang => 0,
      compiler_command => 'g++ -xc++',
      linker_flags => '-lstdc++',
    },
  ],
  [
    { os => 'linux', cc => '/opt/SUNWspro/bin/cc', config => {ccflags => ''} },
    {
      is_sunstudio => 1,
      is_msvc => undef, is_gcc => undef, is_clang => undef,
      compiler_command => 'CC',
      linker_flags => '',
    },
  ],
);
my @METHODS = qw(
  is_msvc is_gcc is_clang is_sunstudio
  compiler_command linker_flags
);

run_test(@$_) for @DATA;

# mock some compiler output
my $old_capture = \&ExtUtils::CppGuess::_capture;
our $CAPTURES;
{
  no warnings "redefine";
  *ExtUtils::CppGuess::_capture =
    sub {
      my @cmd = @_;
      if (my $result = $CAPTURES->{"@cmd"}) {
        note "Mocking output of @cmd: $result";
        return $result;
      }
      goto &$old_capture;
    };
}
my @CAPS =
    (
     [
       { cc => "cc", config => { ccflags => '' } },
       {
         is_sunstudio => 0,
         is_msvc => undef, is_gcc => undef, is_clang => 1,
         compiler_command => 'clang++ -xc++ -Wno-reserved-user-defined-literal',
         linker_flags => '-lstdc++',
       },
       { "cc --version" => "OpenBSD clang version 10.0.1" },
     ],
     [
       { cc => "clang-15", config => { ccflags => '' } },
       {
         is_sunstudio => 0,
         is_msvc => undef, is_gcc => undef, is_clang => 1,
         compiler_command => 'clang++ -xc++ -Wno-reserved-user-defined-literal',
         linker_flags => '-lstdc++',
       },
       { "clang-15 --version" => "Debian clang version 15.0.7" },
     ],
     [
       { cc => "cc", config => { ccflags => '' } },
       {
         is_sunstudio => 0,
         is_msvc => undef, is_gcc => 1, is_clang => 0,
         compiler_command => 'g++ -xc++',
         linker_flags => '-lstdc++',
       },
       { "cc --version" => "cc (Debian 12.2.0-14) 12.2.0" },
     ],
    );

for my $test (@CAPS) {
    my ($args, $expect, $cap) = @$test;
    local $CAPTURES = $cap;
    run_test($args, $expect);
}

done_testing;

sub run_test {
  my ($args, $expect) = @_;
  my $guess = ExtUtils::CppGuess->new(%$args);
  my %got = map {$_ => $guess->$_} @METHODS;
  is_deeply \%got, $expect or diag explain [ $args, \%got, $expect ];
}
