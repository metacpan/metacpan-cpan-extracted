#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use HTTP::MultiPartParser;

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
    [ '',
      [ ], 'End of stream encountered while parsing preamble' ],
    [ '--xxx',
      [ ], 'End of stream encountered while parsing boundary' ],
    [ '--xxx--',
      [ ], 'End of stream encountered while parsing closing boundary' ],
    [ '--xxx----',
      [ ], 'Closing boundary does not terminate with CRLF' ],
    [ '--xxx__',
      [ ], 'Boundary does not terminate with CRLF or hyphens' ],
    [ "--xxx${CRLF}Foo",
      [ ], 'End of stream encountered while parsing part header' ],
    [ "--xxx${CRLF}${CRLF}${CRLF}",
      [ [[], undef] ], 'End of stream encountered while parsing part body' ],
    [ "--xxx${CRLF}${CRLF}${CRLF}${CRLF}--xxx--${CRLF}xx",
      [ [[], ''] ], 'Nonempty epilogue' ],
    [ "--xxx${CRLF}${SP}Foo${CRLF}${CRLF}",
      [ ], 'Continuation line seen before first header' ],
    [ "--xxx${CRLF}${HT}Foo${CRLF}${CRLF}",
      [ ], 'Continuation line seen before first header' ],
    [ "--xxx${CRLF}Foo${CRLF}${CRLF}",
      [ ], 'Malformed header line' ],
);

foreach my $test (@tests) {
    my ($content, $exp_parts, $exp_error) = @$test;

    my ($got_parts, $got_error) = parse($content);

    (my $name = $content) =~ s/([^\x21-\x7E])/sprintf '\x%.2X', ord $1/eg;

    cmp_deeply($got_parts, $exp_parts, "parts ($name)");
    is($got_error, $exp_error, "error ($name)");
}

done_testing();

