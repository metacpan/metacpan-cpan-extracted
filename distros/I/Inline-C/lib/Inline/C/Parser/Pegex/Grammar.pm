package Inline::C::Parser::Pegex::Grammar;

use Pegex::Base;
extends 'Pegex::Grammar';

# Actual Pegex grammar text is in this file:
use constant file => 'ext/inline-c-pgx/inline-c.pgx';

# This method is autocompiled using:
#
#   `perl -Ilib -MInline::C::Parser::Pegex::Grammar=compile`
#
sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.58)
  {
    '+grammar' => 'inline-c',
    '+toprule' => 'code',
    '+version' => '0.0.1',
    'ALL' => {
      '.rgx' => qr/\G[\s\S]/
    },
    'COMMA' => {
      '.rgx' => qr/\G,/
    },
    'LPAREN' => {
      '.rgx' => qr/\G\(/
    },
    '_' => {
      '.rgx' => qr/\G\s*/
    },
    'anything_else' => {
      '.rgx' => qr/\G.*(?:\r?\n|\z)/
    },
    'arg' => {
      '.rgx' => qr/\G(?:\s*(?:(?:(?:unsigned|long|extern|const)\b\s*)*((?:\w+))\s*(\**)|(?:(?:unsigned|long|extern|const)\b\s*)*\**)\s*\s*((?:\w+))|(\.\.\.))/
    },
    'arg_decl' => {
      '.rgx' => qr/\G(\s*(?:(?:(?:unsigned|long|extern|const)\b\s*)*((?:\w+))\s*(\**)|(?:(?:unsigned|long|extern|const)\b\s*)*\**)\s*\s*(?:\w+)*|\.\.\.)/
    },
    'code' => {
      '+min' => 1,
      '.ref' => 'part'
    },
    'comment' => {
      '.any' => [
        {
          '.rgx' => qr/\G\s*\/\/[^\n]*\n/
        },
        {
          '.rgx' => qr/\G\s*\/\*(?:[^\*]+|\*(?!\/))*\*\/([\t]*)?/
        }
      ]
    },
    'function_declaration' => {
      '.all' => [
        {
          '.ref' => 'rtype'
        },
        {
          '.rgx' => qr/\G((?:\w+))/
        },
        {
          '.ref' => '_'
        },
        {
          '.ref' => 'LPAREN'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'arg_decl'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'COMMA'
                },
                {
                  '.ref' => 'arg_decl'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G\s*\)\s*;\s*/
        }
      ]
    },
    'function_definition' => {
      '.all' => [
        {
          '.ref' => 'rtype'
        },
        {
          '.rgx' => qr/\G((?:\w+))/
        },
        {
          '.ref' => '_'
        },
        {
          '.ref' => 'LPAREN'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'arg'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'COMMA'
                },
                {
                  '.ref' => 'arg'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G\s*\)\s*\{\s*/
        }
      ]
    },
    'part' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ALL'
        },
        {
          '.any' => [
            {
              '.ref' => 'comment'
            },
            {
              '.ref' => 'function_definition'
            },
            {
              '.ref' => 'function_declaration'
            },
            {
              '.ref' => 'anything_else'
            }
          ]
        }
      ]
    },
    'rtype' => {
      '.rgx' => qr/\G\s*(?:(?:(?:unsigned|long|extern|const)\b\s*)*((?:\w+))\s*(\**)|(?:(?:unsigned|long|extern|const)\b\s*)+\**)\s*/
    }
  }
}

1;
