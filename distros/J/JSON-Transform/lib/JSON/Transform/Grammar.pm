package JSON::Transform::Grammar;

use strict;
use warnings;
use base 'Pegex::Grammar';
use constant file => './json-transform.pgx';

=head1 NAME

JSON::Transform::Grammar - JSON::Transform grammar

=head1 SYNOPSIS

  use Pegex::Parser;
  use JSON::Transform::Grammar;
  use Pegex::Tree::Wrap;
  use Pegex::Input;

  my $parser = Pegex::Parser->new(
    grammar => JSON::Transform::Grammar->new,
    receiver => Pegex::Tree::Wrap->new,
  );
  my $text = '"" <% [ $V+`id`:$K ]';
  my $input = Pegex::Input->new(string => $text);
  my $got = $parser->parse($input);

=head1 DESCRIPTION

This is a subclass of L<Pegex::Grammar>, with the JSON::Transform grammar.

=head1 METHODS

=head2 make_tree

Override method from L<Pegex::Grammar>.

=cut

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.67)
  {
    '+grammar' => 'json-transform',
    '+include' => 'pegex-atoms',
    '+toprule' => 'transforms',
    '+version' => '0.01',
    'BACK' => {
      '.rgx' => qr/\G\\/
    },
    'colonPair' => {
      '.all' => [
        {
          '-flat' => 1,
          '.ref' => 'exprStringValue'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'exprSingleValue'
        }
      ]
    },
    'exprApplyJsonPointer' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*<(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'jsonPointer'
        }
      ]
    },
    'exprArrayLiteral' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\.\[(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'exprSingleValue'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '-skip' => 1,
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*,(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
                },
                {
                  '.ref' => 'exprSingleValue'
                }
              ]
            },
            {
              '+max' => 1,
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*,(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\](?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'exprArrayMapping' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\[(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'exprSingleValue'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\](?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'exprKeyAdd' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\@(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '-flat' => 1,
          '.ref' => 'colonPair'
        }
      ]
    },
    'exprKeyRemove' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\#(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '-flat' => 1,
          '.ref' => 'exprStringValue'
        }
      ]
    },
    'exprMapping' => {
      '.all' => [
        {
          '-wrap' => 1,
          '.ref' => 'opFrom'
        },
        {
          '.any' => [
            {
              '.ref' => 'exprArrayMapping'
            },
            {
              '.ref' => 'exprObjectMapping'
            },
            {
              '.ref' => 'exprSingleValue'
            }
          ]
        }
      ]
    },
    'exprObjectLiteral' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\.\{(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'colonPair'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '-skip' => 1,
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*,(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
                },
                {
                  '.ref' => 'colonPair'
                }
              ]
            },
            {
              '+max' => 1,
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*,(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'exprObjectMapping' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '-flat' => 1,
          '.ref' => 'colonPair'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'exprSingleValue' => {
      '.all' => [
        {
          '.any' => [
            {
              '.ref' => 'jsonPointer'
            },
            {
              '.ref' => 'variableUser'
            },
            {
              '.ref' => 'variableSystem'
            },
            {
              '.ref' => 'exprStringQuoted'
            },
            {
              '.ref' => 'exprArrayLiteral'
            },
            {
              '.ref' => 'exprObjectLiteral'
            }
          ]
        },
        {
          '+max' => 1,
          '-flat' => 1,
          '.ref' => 'singleValueMod'
        }
      ]
    },
    'exprStringQuoted' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G`/
        },
        {
          '+min' => 0,
          '.any' => [
            {
              '-flat' => 1,
              '.ref' => 'stringValueCommon'
            },
            {
              '.ref' => 'jsonBackslashGrave'
            },
            {
              '.ref' => 'jsonOtherNotGrave'
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G`/
        }
      ]
    },
    'exprStringValue' => {
      '.any' => [
        {
          '.ref' => 'jsonPointer'
        },
        {
          '.ref' => 'variableUser'
        },
        {
          '.ref' => 'variableSystem'
        },
        {
          '.ref' => 'exprStringQuoted'
        }
      ]
    },
    'jsonBackslashDollar' => {
      '.all' => [
        {
          '-skip' => 1,
          '.ref' => 'BACK'
        },
        {
          '.rgx' => qr/\G(\$)/
        }
      ]
    },
    'jsonBackslashDouble' => {
      '.all' => [
        {
          '-skip' => 1,
          '.ref' => 'BACK'
        },
        {
          '.rgx' => qr/\G(")/
        }
      ]
    },
    'jsonBackslashGrave' => {
      '.all' => [
        {
          '-skip' => 1,
          '.ref' => 'BACK'
        },
        {
          '.rgx' => qr/\G(`)/
        }
      ]
    },
    'jsonBackslashQuote' => {
      '.all' => [
        {
          '-skip' => 1,
          '.ref' => 'BACK'
        },
        {
          '.rgx' => qr/\G([\\\/bfnrt])/
        }
      ]
    },
    'jsonOtherNotDouble' => {
      '.rgx' => qr/\G([^"\x00-\x1f\\\$]+)/
    },
    'jsonOtherNotGrave' => {
      '.rgx' => qr/\G([^`\x00-\x1f\\\$]+)/
    },
    'jsonPointer' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G"/
        },
        {
          '+min' => 0,
          '.any' => [
            {
              '-flat' => 1,
              '.ref' => 'stringValueCommon'
            },
            {
              '.ref' => 'jsonBackslashDouble'
            },
            {
              '.ref' => 'jsonOtherNotDouble'
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G"/
        }
      ]
    },
    'jsonUnicode' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G\\u/
        },
        {
          '.rgx' => qr/\G([0-9a-fA-F]{4})/
        }
      ]
    },
    'opArrayFrom' => {
      '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*(<\@)(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
    },
    'opCopyFrom' => {
      '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*(<\-)(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
    },
    'opFrom' => {
      '.any' => [
        {
          '.ref' => 'opArrayFrom'
        },
        {
          '.ref' => 'opObjectFrom'
        }
      ]
    },
    'opMoveFrom' => {
      '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*(<<)(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
    },
    'opObjectFrom' => {
      '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*(<%)(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
    },
    'singleValueMod' => {
      '.any' => [
        {
          '.ref' => 'exprKeyAdd'
        },
        {
          '.ref' => 'exprKeyRemove'
        },
        {
          '.ref' => 'exprApplyJsonPointer'
        }
      ]
    },
    'stringValueCommon' => {
      '.any' => [
        {
          '.ref' => 'jsonUnicode'
        },
        {
          '.ref' => 'jsonBackslashQuote'
        },
        {
          '.ref' => 'jsonBackslashDollar'
        },
        {
          '.ref' => 'variableUser'
        },
        {
          '.ref' => 'variableSystem'
        }
      ]
    },
    'transformCopy' => {
      '.all' => [
        {
          '.any' => [
            {
              '.ref' => 'jsonPointer'
            },
            {
              '.ref' => 'variableUser'
            }
          ]
        },
        {
          '-skip' => 1,
          '.ref' => 'opCopyFrom'
        },
        {
          '.ref' => 'exprSingleValue'
        },
        {
          '+max' => 1,
          '.ref' => 'exprMapping'
        }
      ]
    },
    'transformImpliedDest' => {
      '.all' => [
        {
          '.ref' => 'jsonPointer'
        },
        {
          '.ref' => 'exprMapping'
        }
      ]
    },
    'transformMove' => {
      '.all' => [
        {
          '.ref' => 'jsonPointer'
        },
        {
          '-skip' => 1,
          '.ref' => 'opMoveFrom'
        },
        {
          '.ref' => 'jsonPointer'
        }
      ]
    },
    'transformation' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.any' => [
            {
              '.ref' => 'transformImpliedDest'
            },
            {
              '.ref' => 'transformCopy'
            },
            {
              '.ref' => 'transformMove'
            },
            {
              '-skip' => 1,
              '.ref' => 'ws2'
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'transforms' => {
      '+min' => 1,
      '-flat' => 1,
      '.ref' => 'transformation'
    },
    'variableSystem' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\$/
        },
        {
          '.rgx' => qr/\G([A-Z]*)/
        }
      ]
    },
    'variableUser' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\$/
        },
        {
          '.rgx' => qr/\G([a-z][a-zA-Z]*)/
        }
      ]
    },
    'ws2' => {
      '.rgx' => qr/\G(?:\s|\x{FEFF}|[\ \t]*\-\-[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))+/
    }
  }
}

1;
