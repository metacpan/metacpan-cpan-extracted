use Test2::Bundle::Extended;

BEGIN {
    $INC{'Foo.pm'} = __FILE__;
    package Foo;

    our @EXPORT = qw/foo bar/;
    our %EXPORT_ANON = (
        '$foo' => \'foo',
        '@foo' => [qw/f o o/],
        '%foo' => {f => 'oo'},
    );

    sub foo { 'foo' }

    sub bar { 'bar' };
}

BEGIN {
    sub foo { 'not lexical' }
    sub bar { 'not lexical' }
}

is(foo(), 'not lexical', "Original foo");
is(bar(), 'not lexical', "Original bar");

{
    use Lexical::Importer Foo => 'foo';
    is(foo(), 'foo', "Got lexical foo");
}

{
    use Lexical::Importer Foo => 'bar';
    is(bar(), 'bar', "Got lexical bar");
}

is(foo(), 'not lexical', "Original foo");
is(bar(), 'not lexical', "Original bar");

use Lexical::Importer Foo => qw/foo bar/;
is(foo(), 'foo', "Got lexical foo");
is(bar(), 'bar', "Got lexical bar");
is(__PACKAGE__->foo, 'not lexical', "Method dispatch find package sub");
is(__PACKAGE__->bar, 'not lexical', "Method dispatch find package sub");

no Lexical::Importer;
is(foo(), 'not lexical', "Original foo");
is(bar(), 'not lexical', "Original bar");

{
    our $foo = 'not lexical';
    our @foo = ('not', 'lexical');
    our %foo = (not => 'lexical');

    is($foo, 'not lexical',       'package $foo');
    is(\@foo, ['not', 'lexical'], 'package @foo');
    is(\%foo, {not => 'lexical'}, 'package %foo');

    {
        my $foo = 'not imported';
        my @foo = ('not', 'imported');
        my %foo = (not => 'imported');

        is($foo, 'not imported',       'my $foo');
        is(\@foo, ['not', 'imported'], 'my @foo');
        is(\%foo, {not => 'imported'}, 'my %foo');

        {
            use Lexical::Importer Foo => qw/$foo @foo %foo/;

            is($foo, 'foo',        'imported $foo');
            is(\@foo, [qw/f o o/], 'imported @foo');
            is(\%foo, {f => 'oo'}, 'imported %foo');
        }

        is($foo, 'not imported',       'my $foo');
        is(\@foo, ['not', 'imported'], 'my @foo');
        is(\%foo, {not => 'imported'}, 'my %foo');
    }

    is($foo, 'not lexical',       'package $foo');
    is(\@foo, ['not', 'lexical'], 'package @foo');
    is(\%foo, {not => 'lexical'}, 'package %foo');
}

done_testing;
