use strict;
use warnings;
use utf8;
use Test::More;
use Localizer::Dictionary;

my $dict = Localizer::Dictionary->new();
$dict->add_entry_position('Hi %1', 'foo.tt', 10);
ok $dict->exists_msgid('Hi %1');
ok !$dict->exists_msgid('Good night %1');

done_testing;

