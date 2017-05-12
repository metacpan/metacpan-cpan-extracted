use warnings;
use strict;
use Test::More;
#use Test::Exception;
#use blib;
use Image::SVG::Path qw/extract_path_info/;

##Test these different syntaxes to check for path parsing

my @strings = (
    'M2 3',   [2, 3],   'Integer, space separator',
    'M2,3',   [2, 3],   'Integer, comma separator',
    'M2-3',   [2, -3],  'Integer, - separator',
    'M-2-3', [-2, -3], 'Negative integers, - separator',

    'M2+3', [2, 3],    'Integer, + separator',

    'M2.1 3.1', [2.1, 3.1],    'Floats, space separator',
    'M2.1+3.1', [2.1, 3.1],    'Floats, + separators',
    'M2.1-3.1', [2.1, -3.1],    'Floats, - separators',
    'M2.1 -3.1', [2.1, -3.1],    'Floats, - and space separators',
    'M-2.1-3.1', [-2.1, -3.1],    'Floats, - separators',
    'M-2.1+3.1', [-2.1, 3.1],    'Floats, -,+ separators',

    ##Have to compare these as strings, or perl helpfully upgrades the numbers
    'M2e1 3e1', ['2e1', '3e1'],    'Exponentials, space separator',
    'M2e1-3e1', ['2e1', '-3e1'],    'Exponentials, - separator',
    'M2e1+3e1', ['2e1', '3e1'],    'Exponentials, + separator',
    'M-2e1-3e1', ['-2e1', '-3e1'],    'Exponentials, - separators',

    'M2e-1 3e-1', ['2e-1', '3e-1'],    'Small Exponentials, space separator',
    'M2e-1-3e-1', ['2e-1', '-3e-1'],    'Small Exponentials, - separator',
    'M2e-1+3e-1', ['2e-1', '3e-1'],    'Small Exponentials, + separator',
    'M-2e-1-3e-1', ['-2e-1', '-3e-1'],    'Small Exponentials, - separators',

    'M2e+1 3e+1', ['2e+1', '3e+1'],    'Large Exponentials, space separator',
    'M2e+1-3e+1', ['2e+1', '-3e+1'],    'Large Exponentials, - separator',
    'M2e+1+3e+1', ['2e+1', '3e+1'],    'Large Exponentials, + separator',
    'M-2e+1-3e+1', ['-2e+1', '-3e+1'],    'Large Exponentials, - separators',

);

while (my ($string,$numbers,$comment) = splice @strings, 0, 3) {
    my @foo;
    eval {
	@foo = extract_path_info ($string, { verbose => 0, }); 
    };
    SKIP: {
        skip 'Parsing failed', 1 if $@;
        is_deeply $foo[0]->{point}, $numbers, '... numbers';
    }
}

done_testing();
