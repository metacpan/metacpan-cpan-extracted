use strict;
use warnings;
use Test::More;

my $MODULE = 'ExtUtils::CppGuess';
use_ok($MODULE);

my $guess = $MODULE->new;
isa_ok $guess, $MODULE;

diag 'EUMM:', explain { $guess->makemaker_options };
diag '---';
diag 'MB:', explain { $guess->module_build_options };

diag '---';
my $config = $guess->_config;
diag 'Config:', explain {
  map { $_=>$config->{$_} } grep /cc|ld/, keys %$config
};

for (qw(
  is_sunstudio
  is_msvc is_gcc is_clang compiler_command linker_flags
  iostream_fname cpp_flavor_defs
)) {
  diag "Method: $_ = ", explain $guess->$_;
}

done_testing;
