#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Differences;

BEGIN {
    use_ok( 'MarpaX::Languages::ECMAScript::AST' ) || print "Bail out!\n";
}

my $ecmaAst = MarpaX::Languages::ECMAScript::AST->new();
my $pattern = $ecmaAst->pattern;

my %DATA = (
    # reg                            input         index multiline ignoreCase   Value
    #                                                                           [lastPos, [ @matches ] ]
    'a|ab'                     => [[ 'abc',            0,        0,         0,  [ 1, [] ] ],
                                  ],
    '((a)|(ab))((c)|(bc))'     => [[ 'abc',            0,        0,         0,  [ 3, ['a','a',undef,'bc',undef,'bc'] ] ],
                                  ],
    'a[a-z]{2,4}'              => [[ 'abcdefghi',      0,        0,         0,  [ 5, [] ] ],
                                  ],
    'a[a-z]{2,4}'              => [[ 'ABabEFcdI',      0,        0,         1,  [ 5, [] ] ],
                                  ],
    'a[a-z]{2,4}'              => [[ "\N{U+00D7}",     0,        0,         1,  0 ],
                                  ],
    "[\N{U+00DF}]"             => [[ "\N{U+00DF}",     0,        0,         1,  [ 1, [] ] ],
                                  ],
    'a[a-z]{6,4}'              => [[ 'abcdefghi',      0,        0,         0,  undef ],
                                  ],
    '(a[a-z]{2,4})'            => [[ 'abcdefghi',      0,        0,         0,  [ 5, ['abcde'] ] ],
                                  ],
    'a[a-z]{2,4}?'             => [[ 'abcdefghi',      0,        0,         0,  [ 3, [] ] ],
                                  ],
    '(a[a-z]{2,4}?)'           => [[ 'abcdefghi',      0,        0,         0,  [ 3, ['abc'] ] ],
                                  ],
    '(aa|aabaac|ba|b|c)*'      => [[ 'aabaac',         0,        0,         0,  [ 4, ['ba'] ] ],
                                  ],
    '(z)((a+)?(b+)?(c))*'      => [[ 'zaacbbbcac',     0,        0,         0,  [10, ['z', 'ac', 'a', undef, 'c'] ] ],
                                  ],
    '(a*)*'                    => [[ 'b',              0,        0,         0,  [ 0, [undef] ] ],
                                  ],
    '(a*)b\1+'                 => [[ 'baaaac',         0,        0,         0,  [ 1, [''] ] ],
                                  ],
    '(?=(a+))'                 => [[ 'baaabac',        0,        0,         0,    0 ],
                                  ],
    '(?=(a+))'                 => [[ 'aaabac',         0,        0,         0,  [ 0, ['aaa'] ] ],
                                  ],
    '(?=(a+))a*b\1'            => [[ 'abac',           0,        0,         0,  [ 3, ['a'] ] ],
                                  ],
    '(.*?)a(?!(a+)b\2c)\2(.*)' => [[ 'baaabaac',       0,        0,         0,  [ 8, ['ba', undef, 'abaac'] ] ],
                                  ],
    '(?:(ABC)|(123)){2}'       => [[ 'ABC123',         0,        0,         0,  [ 6, [undef, '123'] ] ],
                                  [  '123ABC',         0,        0,         0,  [ 6, ['ABC', undef] ] ],
                                  ],
    '\\d{3}\\-?\\d{2}\\-?\\d{4}' => [[ '123-45-6789',  0,        0,         0,  [11, [] ] ],
                                  ],
    '\\d{1,}\\-?\\d{2}\\-?\\d{4}' => [[ '123-45-6789', 0,        0,         0,  [11, [] ] ],
                                  ],
    '^\\d{3}\\-?\\d{2}\\-?\\d{4}' => [[ '123-45-6789', 0,        0,         0,  [11, [] ] ],
                                  ],
    '\\d{3}\\-?\\d{2}\\-?\\d{4}$' => [[ '123-45-6789', 0,        0,         0,  [11, [] ] ],
                                  ],
    '[a-zA-Z0-9]'                 => [[ 'a',           0,        0,         0,  [ 1, [] ] ],
                                  ],
    '[-Za]'                       => [[ 'a',           0,        0,         0,  [ 1, [] ] ],
                                  ],
    '[-Za-z]'                     => [[ 'a',           0,        0,         0,  [ 1, [] ] ],
                                  ],
    '[^0-9]'                      => [[ 'a',           0,        0,         0,  [ 1, [] ] ],
                                  ],
    #
    # Inspired from http://javascript.info/tutorial/word-boundary
    #
    '(\\bdog\\b)'                 => [[ 'dog',         0,        0,         0,  [3, ['dog'] ] ],
                                  ],
    '(\\b0og\\b)'                 => [[ '0og',         0,        0,         0,  [3, ['0og'] ] ],
                                  ],
    '(\\bDog\\b)'                 => [[ 'Dog',         0,        0,         0,  [3, ['Dog'] ] ],
                                  ],
    '(\\b_og\\b)'                 => [[ '_og',         0,        0,         0,  [3, ['_og'] ] ],
                                  ],
    '(\\bdog\\b)'                 => [[ ' og',         0,        0,         0,  0 ],
                                  ],
    '(\\bdog\\b)'                 => [[ '!og',         0,        0,         0,  0 ],
                                  ],
    '(\\bdog\\b)'                 => [[ ':og',         0,        0,         0,  0 ],
                                  ],
    '(\\bdog\\b)'                 => [[ '^og',         0,        0,         0,  0 ],
                                  ],
    '(\\bdog\\b)'                 => [[ '|og',         0,        0,         0,  0 ],
                                  ],
    '(\\Bdog\\b)'                 => [[ 'dog',         0,        0,         0,  0 ],
                                  ],
    '(\\bdog\\B)'                 => [[ 'dog',         0,        0,         0,  0 ],
                                  ],
    '(\\bdog\\B)orcat'            => [[ 'dogorcat',    0,        0,         0,  [8, ['dog'] ] ],
                                  ],
    '(\\d\\s\\w\\w\\w\\w)'        => [[ '1 year',      0,        0,         0,  [6, ['1 year'] ] ],
                                  ],
    '(\\W)'                       => [[ "'",           0,        0,         0,  [1, ["'"] ] ],
                                  ],
    '(ch.r)'                      => [[ 'char',        0,        0,         0,  [4, ['char'] ] ],
                                  ],
    '(ch.r)'                      => [[ 'ch r',        0,        0,         0,  [4, ['ch r'] ] ],
                                  ],
    '(ch.r)'                      => [[ 'chr',         0,        0,         0,  0 ],
                                  ],
    '([\\D\\w]+)'                 => [[ 'ch r',        0,        0,         0,  [4, ['ch r'] ] ],
                                  ],
    '([\\d\\w]+)'                 => [[ 'chr',         0,        0,         0,  [3, ['chr'] ] ],
                                  ],
    '(^\\d+)'                     => [[ "\n33rd",      1,        1,         0,  [3, ['33'] ] ],
                                  ],
    #
    # Inspired by http://mathiasbynens.be/notes/javascript-escapes
    #
    '(\\u00A9)'                   => [[ "\N{U+00A9}",  0,        0,         0,  [1, ["\N{U+00A9}"] ] ],
                                  ],
    '(\\u00a9)'                   => [[ "\N{U+00A9}",  0,        0,         0,  [1, ["\N{U+00A9}"] ] ],
                                  ],
    '(\\xa9)'                     => [[ "\N{U+00A9}",  0,        0,         0,  [1, ["\N{U+00A9}"] ] ],
                                  ],
    '(\\cJ)'                      => [[ "\n",          0,        0,         0,  [1, ["\n"] ] ],
                                  ],
    '(\\n)'                       => [[ "\n",          0,        0,         0,  [1, ["\n"] ] ],
                                  ],
    '(\\(\\n\\))'                 => [[ "(\n)",        0,        0,         0,  [3, ["(\n)"] ] ],
                                  ],
    '([\\10])'                    => [[ "\N{U+000A}",  0,        0,         0,  [1, ["\N{U+000A}"] ] ],
                                  ],
    #
    # Inspired by http://stackoverflow.com/questions/17438100/whats-the-use-of-the-b-backspace-regex
    #
    '([\\b])'                     => [[ "\N{U+0008}test",  0,    0,          0,  [1, ["\N{U+0008}"] ] ],
                                  ],
    '([\\u0008])'                 => [[ "\N{U+0008}test",  0,    0,          0,  [1, ["\N{U+0008}"] ] ],
                                  ],

    );
my $ntest = 0;
foreach (keys %DATA) {
    my $regexp = $_;
    my $parse = eval {$pattern->{grammar}->parse($regexp, $pattern->{impl})};
    my $code = defined($parse) ? eval { $pattern->{grammar}->value($pattern->{impl}) } : sub {undef};
    if ($@) {
        print STDERR $@;
        $code = sub {undef};
    }
    foreach (@{$DATA{$_}}) {
	my ($input, $index, $multiline, $ignoreCase, $result) = @{$_};
	++$ntest;
	my $value = eval {&$code($input, $index, $multiline, $ignoreCase)};
	eq_or_diff($value, $result, "/$regexp/.exec(\"$input\")");
    }
}

done_testing(1 + $ntest);
