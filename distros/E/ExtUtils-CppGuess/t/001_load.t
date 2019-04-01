use strict;
use warnings;
use Data::Dumper;
use Test::More;

my $MODULE = 'ExtUtils::CppGuess';
use_ok($MODULE);

my $guess = $MODULE->new;
isa_ok $guess, $MODULE;

$Data::Dumper::Indent = $Data::Dumper::Sortkeys = $Data::Dumper::Terse = 1;

diag 'EUMM:', Dumper { $guess->makemaker_options };
diag '---';
diag 'MB:', Dumper { $guess->module_build_options };

diag '---';
my $config = $guess->_config;
diag 'Config:', Dumper {
  map { $_=>$config->{$_} } grep /cc|ld/, keys %$config
};

for (qw(
  is_sunstudio
  is_msvc is_gcc is_clang compiler_command linker_flags
  iostream_fname cpp_flavor_defs
)) {
  diag "Method: $_ = ", Dumper $guess->$_;
}

done_testing;
