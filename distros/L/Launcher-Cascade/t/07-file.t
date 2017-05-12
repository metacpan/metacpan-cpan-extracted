#!perl -T

use Test::More tests => 11;

use Launcher::Cascade::FileReader;

my $f = new Launcher::Cascade::FileReader
    -path => '/tmp/test.txt';

is($f->_prepare_command(),   q{< /tmp/test.txt},                                  'local file');

$f->host('host.domain');
is($f->_prepare_command(),   q{ssh host.domain 'cat /tmp/test.txt' |},            'remote file');

$f->user('joe');
is($f->_prepare_command(),   q{ssh joe@host.domain 'cat /tmp/test.txt' |},        'remote file with user');

$f->path("date '+%Y-%m-%d' |");
is($f->_prepare_command(),   q{ssh joe@host.domain 'date '\\''+%Y-%m-%d'\\''' |}, 'remote command with user');

$f->user(undef);
is($f->_prepare_command(),   q{ssh host.domain 'date '\\''+%Y-%m-%d'\\''' |},     'remote command');

$f->host(undef);
is($f->_prepare_command(),   q{date '+%Y-%m-%d' |},                               'local command');

$f->path($0);
$f->context_before(2);
$f->context_after(3);
is($f->search(qr/[f]oobar/), -1,                                                  'failed search');
is($f->search(qr/[f]oobar/,  qr/Launcher::Cascade::FileReader/), 1,               'successfull search');

my $context_aref = $f->context();
is(scalar(@$context_aref),   6,                                                   'righ amount of context');
is($context_aref->[0],        "use Test::More tests => 11;\n",                    'correct first line of context');
is($context_aref->[-1],       "    -path => '/tmp/test.txt';\n",                  'correct last line of context');
