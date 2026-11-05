use strict;
use warnings;
use utf8;
use Test::More;
use GoSaveTool::Text qw(stats limits words title sentence slug camel snake kebab clean %LIMITS);

# The checks of @gosavetool/text
is_deeply stats('Hello world. It’s 2026!'), { words => 4, chars => 23, charsNoSpaces => 20, lines => 1, sentences => 2, readSeconds => 1 }, 'stats';
my $st = stats("Hello world. It’s 2026!\nSecond line.");
is_deeply [@$st{qw(words lines sentences)}], [6, 2, 3], 'stats over two lines';
is stats('')->{lines}, 0, 'empty text has no lines';
is stats("\x{1F600}a")->{chars}, 2, 'an emoji is one character';
is_deeply limits('x' x 300, 'x-post'), { 'x-post' => { limit => 280, used => 300, left => -20, fits => 0 } }, 'limits';
is scalar keys %{ limits('a') }, scalar keys %LIMITS, 'all limits';
is title('the lord of the rings: return of the king'), 'The Lord of the Rings: Return of the King', 'title';
is sentence('HELLO WORLD. how ARE you?'), 'Hello world. How are you?', 'sentence';
is slug('Ölçü Birimi & Çeviri!'), 'olcu-birimi-ceviri', 'slug with Turkish letters';
is slug('Straße café'), 'strasse-cafe', 'slug with accents';
is camel('best posting time'), 'bestPostingTime', 'camel';
is snake('bestPostingTime'), 'best_posting_time', 'snake';
is kebab('Best Posting_Time'), 'best-posting-time', 'kebab';
is_deeply [words('HTMLParser v2Beta')], ['HTMLParser', 'v2', 'Beta'], 'words';
is clean("a   b  \n\n\n\nc\t"), "a b\n\nc", 'clean';
is clean("a  \r\n\r\n\r\n\r\nb"), "a\r\n\r\nb", 'clean keeps CRLF';

done_testing;
