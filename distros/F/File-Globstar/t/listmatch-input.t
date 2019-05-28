# Copyright (C) 2016-2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use common::sense;

use Test::More;

use File::Globstar::ListMatch;

sub unref;
sub compile_re;
sub get_blessings;

my ($matcher, $input, @patterns);

$input = [qw (Tom Dick Harry)];
$matcher = File::Globstar::ListMatch->new($input);
is_deeply [unref $matcher->patterns], [
    compile_re('^Tom$'),
    compile_re('^Dick$'),
    compile_re('^Harry$'),
], 'array input';

$input = <<EOF;
FooBar
BarBaz
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    compile_re('^FooBar$'),
    compile_re('^BarBaz$'),
], 'string input';

$input = <<EOF;
# Comment
FooBar
# Comment
BarBaz
# Comment
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    compile_re('^FooBar$'),
    compile_re('^BarBaz$'),
], 'discard comments';

my $space = ' ';
my $whitespace = "\x09\x0a\x0b\x0c\x0d$space";

$input = <<EOF;

FooBar
$whitespace
BarBaz
$whitespace$whitespace
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    compile_re('^FooBar$'),
    compile_re('^BarBaz$')
], 'discard empty lines';

$input = <<EOF;
foo\\bar
foo\\\\bar
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    compile_re('^foobar$'),
    compile_re('^foo\\\\bar$')
], 'backslash escape regular characters';

$input = <<EOF;
trailing space$whitespace
escaped space\\$space
not escaped space\\\\$space
escaped space again\\\\\\\\\\$space$whitespace
\\$space
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    compile_re('^trailing\ space$'),
    compile_re('^escaped\ space\ $'),
    compile_re('^not\ escaped\ space\\\\$'),
    compile_re('^escaped\ space\ again\\\\\\\\\ $'),
    compile_re('^\ $'),
], 'trailing whitespace';

open HANDLE, '<', 't/patterns'
    or die "Cannot open 't/patterns' for reading: $!";
$matcher = File::Globstar::ListMatch->new(*HANDLE, filename => 't/patterns');
is_deeply [unref $matcher->patterns], [
    compile_re('^foo$'),
    compile_re('^bar$'),
    compile_re('^baz$'),
], 'read from GLOB';

open my $fh, '<', 't/patterns'
    or die "Cannot open 't/patterns' for reading: $!";
$matcher = File::Globstar::ListMatch->new($fh, filename => 't/patterns');
is_deeply [unref $matcher->patterns], [
    compile_re('^foo$'),
    compile_re('^bar$'),
    compile_re('^baz$'),
], 'read from GLOB';

$matcher = File::Globstar::ListMatch->new('t/patterns');
is_deeply [unref $matcher->patterns], [
    compile_re('^foo$'),
    compile_re('^bar$'),
    compile_re('^baz$'),
], 'read from GLOB';

$input = <<EOF;
regular
!negated
/full-match
!/negated-full-match
directory/
!negated-directory/
!negated/full-match-directory/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
use constant RE_NONE => 0x0;
use constant RE_NEGATED => 0x1;
use constant RE_FULL_MATCH => 0x2;
use constant RE_DIRECTORY => 0x4;
is_deeply [unref $matcher->patterns], [
    compile_re('^regular$'),
    compile_re('^negated$'),
    compile_re('^full\-match$'),
    compile_re('^negated\-full\-match$'),
    compile_re('^directory$'),
    compile_re('^negated\-directory$'),
    compile_re('^negated\/full\-match\-directory$'),
], 'strip-off';
is_deeply [get_blessings $matcher->patterns], [
    RE_NONE,
    RE_NEGATED,
    RE_FULL_MATCH,
    RE_NEGATED | RE_FULL_MATCH,
    RE_DIRECTORY,
    RE_NEGATED | RE_DIRECTORY,
    RE_NEGATED | RE_DIRECTORY | RE_FULL_MATCH,
], 'blessings';

done_testing;

sub unref {
    my (@patterns) = @_;

    return map { "$$_" } @patterns;
}

sub compile_re {
    my ($regex) = @_;

    my $ref = qr{$regex};

    return "$$ref";
}

sub get_blessings {
    my (@patterns) = @_;

    return map { ref $_ } @patterns;
}
