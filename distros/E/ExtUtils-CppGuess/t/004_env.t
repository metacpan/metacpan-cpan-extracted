use strict;
use warnings;
use Test::More;

@ENV{qw(CXX)} = qw(czz);
my $MODULE = 'ExtUtils::CppGuess';
use_ok($MODULE);

my $guess = $MODULE->new;
isa_ok $guess, $MODULE;

diag 'EUMM env:', explain { $guess->makemaker_options };

like $guess->compiler_command, qr/czz/;

done_testing;
