use strict;
use warnings;

use Capture::Tiny 'capture';

use File::Slurper 'read_text';
use File::Spec;

use Test::More;

# ------------------------

my($script)                   = File::Spec -> catfile('scripts', 'synopsis.pl');
my($stdout, $stderr, @result) = capture {`$^X $script`};
$result[0]                    = join('', @result);
my($expected)                 = read_text(File::Spec -> catfile('t', 'synopsis.html') );

ok($result[0] eq $expected);

done_testing();
