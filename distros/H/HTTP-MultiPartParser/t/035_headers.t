#!perl

use strict;
use warnings;

use HTTP::MultiPartParser;
use Test::More;
use Test::Deep;

sub parse {
    my ($content) = @_;

    my ($error, @res);
    my $parser = HTTP::MultiPartParser->new(
        boundary  => 'xxx',
        on_header => sub { push @res, [ $_[0], undef ]},
        on_body   => sub { $res[-1][1] .= $_[0] },
        on_error  => sub { $error .= "@_"  },
    );

    $parser->parse($content);
    $parser->finish;

    return (\@res, $error);
}

BEGIN {
    use vars qw[$CRLF $SP $HT];
    *CRLF = \"\x0D\x0A";
    *SP   = \"\x20";
    *HT   = \"\x09";
}

my @tests = (
    [ "--xxx${CRLF}Foo: Foo${CRLF}Bar: Bar${CRLF}${CRLF}${CRLF}--xxx--${CRLF}",
      [ [ ['Foo: Foo', 'Bar: Bar'], ''] ], undef ],
    [ "--xxx${CRLF}Foo: Foo${CRLF}${SP}Bar${CRLF}${CRLF}${CRLF}--xxx--${CRLF}",
      [ [ ['Foo: Foo Bar'], ''] ], undef ],
    [ "--xxx${CRLF}Foo: ${CRLF}${HT}Bar${CRLF}${HT}${CRLF}${HT}Baz${CRLF}${CRLF}${CRLF}--xxx--${CRLF}",
      [ [ ['Foo: Bar Baz'], ''] ], undef ],
    [ "--xxx${CRLF}Foo: ${CRLF}${SP}Bar${CRLF}${SP}${CRLF}${SP}Baz${CRLF}${CRLF}${CRLF}--xxx--${CRLF}",
      [ [ ['Foo: Bar Baz'], ''] ], undef ],
);

foreach my $test (@tests) {
    my ($content, $exp_parts, $exp_error) = @$test;

    my ($got_parts, $got_error) = parse($content);

    (my $name = $content) =~ s/([^\x21-\x7E])/sprintf '\x%.2X', ord $1/eg;

    cmp_deeply($got_parts, $exp_parts, "parts ($name)");
    is($got_error, $exp_error, "error ($name)");
}

done_testing();

