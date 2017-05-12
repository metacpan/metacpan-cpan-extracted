
use strict;
use vars qw(@tests);

BEGIN {
    $^W = 1;

    @tests = (
      [ '',           ''            ],
      [ '&apos;',     '&#39;'       ],
      [ '&amp;amp;',  '&amp;amp;'   ],
      [ '&#38;amp;',  '&amp;amp;'   ],
      [ '&*',         '&amp;*'      ],
      [ '&#31337;',   '&#31337;'    ],
      [ '&#00337;',   '&#337;'      ],
      [ '&#xF78A;',   '&#xF78A;'    ],
      [ '&#XF78A;',   '&#xF78A;'    ],
      [ '&#x00F78A;', '&#xF78A;'    ],
      [ '&#X00F78A;', '&#xF78A;'    ],
      [ '&foo;',      '&foo;'       ],
      [ '&Foo3;',     '&Foo3;'      ],
      [ "\0",         ' '           ],
    );

    foreach my $pair (
      ['<','&lt;'],
      ['>','&gt;'],
      ['&','&amp;'],
      ['"','&quot;'],
      ["'",'&#39;'],
      ['a','a'],
    ) {
        my ($in, $out) = @$pair;

        push @tests, [ $in, $out ];
        push @tests, [ $out, $out ];

        my $dec = ord $in;
        push @tests, [ "&#$dec;", $out ];
        push @tests, [ "&#0$dec;", $out ];
        push @tests, [ "&#000$dec;", $out ];

        my $hex = sprintf '%x', $dec;
        push @tests, [ "&#x$hex;", $out ];
        push @tests, [ "&#X$hex;", $out ];
        push @tests, [ "&#x0$hex;", $out ];
        push @tests, [ "&#X0$hex;", $out ];
        push @tests, [ "&#x000$hex;", $out ];
        push @tests, [ "&#X000$hex;", $out ];

        if ($hex =~ /[a-f]/) {
            $hex = uc $hex;
            push @tests, [ "&#x$hex;", $out ];
            push @tests, [ "&#X$hex;", $out ];
            push @tests, [ "&#x0$hex;", $out ];
            push @tests, [ "&#X0$hex;", $out ];
            push @tests, [ "&#x000$hex;", $out ];
            push @tests, [ "&#X000$hex;", $out ];
        }
    }
                    
}

use Test::More tests => 4 * scalar(@tests);

use HTML::StripScripts;
my $f = HTML::StripScripts->new;

foreach my $test (@tests) {
    my ($in, $out) = @$test;

    $f->input_start_document;
    $f->input_text($in);
    $f->input_end_document;
    is( $f->filtered_document, $out, "text input [$in]" );

    $f->input_start_document;
    $f->input_text("=$in=");
    $f->input_end_document;
    is( $f->filtered_document, "=$out=", "text input [=$in=]" );

    my $esc = $in;
    $esc =~ s/"/&quot;/g;

    $f->input_start_document;
    $f->input_start(qq{<img alt="$esc">});
    $f->input_end_document;
    is( $f->filtered_document, qq{<img alt="$out" />}, "img alt input [$in]" );

    $f->input_start_document;
    $f->input_start(qq{<img alt="=$esc=">});
    $f->input_end_document;
    is( $f->filtered_document, qq{<img alt="=$out=" />}, "img alt input [=$in=]" );
}

