use warnings;
use strict;
use Test::More;
use Test::Exception;

use Log::Fast;


plan tests => 5;


my $LOG = Log::Fast->new();
my $BUF = q{};
open my $fh, '>', \$BUF;
$LOG->config({ fh=>$fh });
sub _log() { seek $fh, 0, 0; substr $BUF, 0, length $BUF, q{} }


use utf8;
$SIG{__WARN__} = sub { die $_[0] if $_[0] =~ /Wide char/ };
$LOG->config({ prefix => 'Уровень %L: ' });
lives_ok { $LOG->ERR('This is a сообщение') }       'Unicode message processed';
my $utf8 = _log();
ok !utf8::is_utf8($utf8),                           'log contain bytes';
ok utf8::valid($utf8),                              'the bytes form valid UTF8';
my $unicode = $utf8;
ok utf8::decode($unicode),                          'decoded to Unicode';
is $unicode, "Уровень ERR: This is a сообщение\n",  'message content match';

