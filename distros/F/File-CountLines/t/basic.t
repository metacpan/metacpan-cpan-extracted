use Test::More tests => 21;
use strict;
use warnings;

use File::Temp qw(tempfile);
use lib 'lib';
use lib '../lib';
use File::CountLines qw(count_lines);
use charnames ':full';
my $cr = "\N{CARRIAGE RETURN}";
my $lf = "\N{LINE FEED}";

my @tests = (
    ["a\nb\nc",     2, 'basic sanity',                  []],
    ["a",           0, 'no newline',                    []],
    ["",            0, 'empty file',                    []],
    ["\na\n\n",     3, 'multiple successive newlines',  []],
    ["$cr $lf $cr", 1, 'count a linefeed',              [style => 'lf']],
    ["$cr $lf $cr", 2, 'count two carriage returns',    [style => 'cr']],
    ["a",           0, 'no newline (lf)',               [style => 'lf']],
    ["a",           0, 'no newline (cr)',               [style => 'cr']],
    ["a$cr$lf b $cr $lf $cr$lf c", 2 , 'crlf',          [style => 'crlf']],
    ["abababa",     2, 'multi-char separator (1)',      [separator => 'aba']],
    ["aaaabaa",     3, 'multi-char separator',          [separator => 'aa']],
    ["aaaabaa",     3, 'multi-char overlapping with block size',          
        [separator => 'aa', blocksize => 3]],
    ["aaaabaa",     3, 'multi-char, cut at block size',          
        [separator => 'aa', blocksize => 2]],
# TODO: blocksize < length(sep) 
#    ["aaaabaa",     3, 'multi-char, block size 1',          
#        [separator => 'aa', blocksize => 1]],
    ["\a\0\0b\0",   3, 'Zero byte as separator',        [separator => "\0"]],
    ["\\\\\\b\\",   4, 'Backslash as separator',        [separator => "\\"]],
    ["{}}a{}",      3, 'Curly braces as separator',     [separator => "}" ]],
    ["{}}a{}",      2, 'Curly braces as separator',     [separator => "{" ]],

);

for (@tests) {
    my ($handle, $file) = tempfile();
    print $handle $_->[0];
    close $handle or warn "Can't close file: $!";
    is count_lines($file, @{$_->[3]}), $_->[1], $_->[2];
    unlink $file or warn "Can't remove temporary test file `$file': $!";
}

# test that it dies for non-existent files:
for (1, 2) {
    my ($handle, $file) = tempfile();
    close $handle;
    unlink $file;

    SKIP: {
        if (-e $file) {
            skip "Can't find a non-existing file for croak testing", 1;
        } else {
            # XXX there could be a race condtion between the -e and this
            # test, but I don't know how to avoid this
            ok !eval { count_lines($file, separator => 'x' x $_); 1 }, 
               'Dies on non-existing file';
        }
    }
}

ok !eval { count_lines; 1 },        'Dies without filename';
ok !eval { count_lines(undef); 1 }, 'Dies with undef filename';
