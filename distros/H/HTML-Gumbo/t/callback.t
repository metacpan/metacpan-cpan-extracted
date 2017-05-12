use strict;
use warnings;
use Test::More;

use_ok('HTML::Gumbo');

my $parser = HTML::Gumbo->new;
{
    my $input = <<'END';
<!DOCTYPE html>
<!--This is a comment-->
<h1>hello world!</h1>
<img disabled boo="foo" />
END
    my @expected = (
        ['document start', {name => 'html', public => '', system => ''}],
        ['comment', 'This is a comment'],
        ['start', 'html', []],
        ['start', 'head', []],
        ['end', 'head'],
        ['start', 'body', []],

        ['start', 'h1', []],
        ['text', 'hello world!'],
        ['end', 'h1'],
        ['space', "\n"],

        ['start', 'img', [disabled => "", boo => "foo"]],
        ['space', "\n"],

        ['end', 'body'],
        ['end', 'html'],
        ['document end'],
    );
    my @got;
    my $res = $parser->parse($input, format => 'callback', callback => sub {
        push @got, [@_];
    });
    is_deeply(\@got, \@expected);
}

{
    my $input = <<'END';
<div></div>
END
    my @expected = (
        ['document start', undef],
        ['start', 'div', []],
        ['end', 'div'],
        ['space', "\n"],
        ['document end'],
    );
    my @got;
    my $res = $parser->parse($input, fragment_namespace => 'HTML', format => 'callback', callback => sub {
        push @got, [@_];
    });
    is_deeply(\@got, \@expected);
}

done_testing();
