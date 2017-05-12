# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-AR-Word.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
use utf8;
use strict;
use warnings;

BEGIN { use_ok('Lingua::AR::Word') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $word=Lingua::AR::Word->new("القامع");
ok(defined $word, "new() returned something");
ok($word->isa('Lingua::AR::Word'), "and it's the right class");
is($word->{_word},"القامع");
is($word->{_stem},"قمع");
is($word->{_arabtex},"AlqAm`");
is($word->{_word},$word->get_word());
is($word->{_stem},$word->get_stem());
is($word->{_arabtex},$word->get_arabtex());
