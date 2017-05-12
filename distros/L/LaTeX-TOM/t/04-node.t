#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use LaTeX::TOM;
use Test::More tests => 56;

my $parser = LaTeX::TOM->new;
my $tree = $parser->parseFile(File::Spec->catfile($Bin, 'data', 'tex.in'));

my @expected_all = (
    [ 'TEXT', ''                        ],
    [ 'COMMAND', 'NeedsTeXFormat'       ],
    [ 'TEXT', 'LaTeX2e'                 ],
    [ 'TEXT', "\n"                      ],
    [ 'COMMAND', 'documentclass'        ],
    [ 'TEXT', 'book'                    ],
    [ 'TEXT', "\n"                      ],
    [ 'COMMAND', 'title'                ],
    [ 'TEXT', 'Some Test Doc'           ],
    [ 'TEXT', "\n"                      ],
    [ 'ENVIRONMENT', 'document'         ],
    [ 'TEXT', "\n"
            . "    \\maketitle\n"
            . "    \\mainmatter\n"
            . "    "                    ],
    [ 'COMMAND', 'chapter*'             ],
    [ 'TEXT', "Preface"                 ],
    [ 'TEXT', "\n    "                  ],
    [ 'COMMAND', 'input'                ],
    [ 'TEXT', 't/data/input.tex'        ],
    [ 'TEXT', "\n"                      ],
    [ 'TEXT', "\n"                      ],
);

my @expected_top = (
    [ 'TEXT', ''                        ],
    [ 'COMMAND', 'NeedsTeXFormat'       ],
    [ 'TEXT', "\n"                      ],
    [ 'COMMAND', 'documentclass'        ],
    [ 'TEXT', "\n"                      ],
    [ 'COMMAND', 'title'                ],
    [ 'TEXT', "\n"                      ],
    [ 'ENVIRONMENT', 'document'         ],
    [ 'TEXT', "\n"                      ],
    [ 'TEXT', "\n"
            . "    \\maketitle\n"
            . "    \\mainmatter\n"
            . "    "                    ],
);

verify_nodes(@{$tree->getAllNodes}, \@expected_all);
verify_nodes($tree->getTopLevelNodes, \@expected_top);

sub verify_nodes
{
    my $expected = pop;
    my @nodes = @_;

    foreach my $node (@nodes) {
        my $node_type = $node->getNodeType;
        my $expected = shift @$expected;

        my $desc = $expected->[1];

        my $cnt = 0;
        $cnt++ while $desc =~ /\n/g;

        if (!length $desc) {
            $desc = 'undef';
        }
        elsif ($cnt >= 1 && $desc !~ /\w/) {
            $desc = 'newline';
            $desc .= 's' if $cnt > 1;
        }
        else {
            $desc =~ s/\n//g;
            $desc =~ tr/ //d;
        }

        if (my ($type) = $node_type =~ /^(TEXT|COMMENT)$/) {
            ok($expected->[0] =~ $type, $type);
            ok($expected->[1] eq $node->getNodeText, $desc);
        }
        elsif ($node_type eq 'ENVIRONMENT') {
            ok($expected->[0] =~ $node_type, $node_type);
            ok($expected->[1] eq $node->getEnvironmentClass, $desc);
        }
        elsif ($node_type eq 'COMMAND') {
            ok($expected->[0] =~ $node_type, $node_type);
            ok($expected->[1] =~ $node->getCommandName, $desc);
        }
    }
}
