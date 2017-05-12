
use strict;
use warnings;

use Test::More tests => 50;
use Test::NoWarnings;

use lib './lib';

use File::Util qw
(
   SL   NL   escape_filename     ebcdic
   valid_filename   strip_path   needs_binmode
);

my $f = File::Util->new();

# check asignability
my $NL = NL; my $SL = SL;

# newlines
ok NL eq $NL, 'NL constant matches variable';

# path seperator
ok SL eq $SL, 'SL constant matches variable';

# test file escaping with substitute escape char
# with additional char to escape as well.
ok escape_filename( q[./foo/bar/baz.t/], '+', '.' ) eq '++foo+bar+baz+t+',
   'escaped filename with custom escape';

# test file escaping with defaults
ok escape_filename(q[.\foo\bar\baz.t]) eq '._foo_bar_baz.t',
   'escaped filename with defaults';

# path stripping in general
is strip_path(__FILE__), '004_portable.t', 'stripped path to this file OK';
is strip_path('C:\foo'), 'foo', 'stripped path to abs win path OK';
is strip_path('C:\foo\bar\baz.txt'), 'baz.txt',
   'stripped path to deeper abs win path OK';

# illegal filename character intolerance
ok !valid_filename(qq[?foo]), qq[?foo is NOT a valid filename];
ok !valid_filename(qq[>foo]), qq[>foo is NOT a valid filename];
ok !valid_filename(qq[<foo]), qq[<foo is NOT a valid filename];
ok !valid_filename(qq[<foo]), qq[<foo is NOT a valid filename];
ok !valid_filename(qq[<foo]), qq[<foo is NOT a valid filename];
ok !valid_filename(qq[<foo]), qq[<foo is NOT a valid filename];
ok !valid_filename(qq[:foo]), qq[:foo is NOT a valid filename];
ok !valid_filename(qq[*foo]), qq[*foo is NOT a valid filename];
ok !valid_filename(qq[/foo]), qq[/foo is NOT a valid filename];
ok !valid_filename(qq[\\foo]), qq[\\foo is NOT a valid filename];
ok !valid_filename(qq["foo]), qq["foo is NOT a valid filename];
ok !valid_filename(qq[\tfoo]), qq[\\tfoo is NOT a valid filename];
ok !valid_filename(qq[\013foo]), qq[\\013foo is NOT a valid filename];
ok !valid_filename(qq[\012foo]), qq[\\012foo is NOT a valid filename];
ok !valid_filename(qq[\015foo]), qq[\\015foo is NOT a valid filename];

# strange but legal filename character tolerance
ok valid_filename(q['foo]), q['foo is a valid filename] ;
ok valid_filename(';foo'), ';foo is a valid filename' ;
ok valid_filename('$foo'), '$foo is a valid filename' ;
ok valid_filename('%foo'), '%foo is a valid filename' ;
ok valid_filename('`foo'), '`foo is a valid filename' ;
ok valid_filename('!foo'), '!foo is a valid filename' ;
ok valid_filename('@foo'), '@foo is a valid filename' ;
ok valid_filename('#foo'), '#foo is a valid filename' ;
ok valid_filename('^foo'), '^foo is a valid filename' ;
ok valid_filename('&foo'), '&foo is a valid filename' ;
ok valid_filename('-foo'), '-foo is a valid filename' ;
ok valid_filename('_foo'), '_foo is a valid filename' ;
ok valid_filename('+foo'), '+foo is a valid filename' ;
ok valid_filename('=foo'), '=foo is a valid filename' ;
ok valid_filename('(foo'), '(foo is a valid filename' ;
ok valid_filename(')foo'), ')foo is a valid filename' ;
ok valid_filename('{foo'), '{foo is a valid filename' ;
ok valid_filename('}foo'), '}foo is a valid filename' ;
ok valid_filename('[foo'), '[foo is a valid filename' ;
ok valid_filename(']foo'), ']foo is a valid filename' ;
ok valid_filename('~foo'), '~foo is a valid filename' ;
ok valid_filename('.foo'), '.foo is a valid filename' ;
ok valid_filename( q/;$%`!@#^&-_+=(){}[]~baz.foo'/ ),
   q/;$%`!@#^&-_+=(){}[]~baz.foo' is a valid filename/;

ok valid_filename('C:\foo'), 'C:\foo is a valid filename';

# these tests are here for coverage purposes.  Since they are more or less
# constants, based only on the host OS, there's no point in testing them
# against anything other than the testing File::Util already did in order
# to determine the values of these constants.  We just test to make sure
# the value is either 1 or 0
ok needs_binmode =~ /^[10]$/, 'needs_binmode is 1 or 0';
ok ebcdic        =~ /^[10]$/, 'ebcdic is 1 or 0';

# directory listing tests...
# remove '.' and '..' directory entries
ok( sub{
   ( $f->_dropdots( qw/. .. foo/ ) )[0] eq 'foo'
      ? 'dots removed'
      : 'failed to remove dots'
}->() eq 'dots removed', 'removed fsdots OK' );

exit;
