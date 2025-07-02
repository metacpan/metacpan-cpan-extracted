use strict;
use warnings;

package JSON::Pointer::Marpa;

# Keeping the following $VERSION declaration on a single line is important.
#<<<
use version 0.9915; our $VERSION = version->declare( '1.0.2' );
#>>>

use Marpa::R2   ();
use URI::Escape qw( uri_unescape );

use JSON::Pointer::Marpa::Semantics ();

my $dsl = <<'END_OF_DSL';
lexeme default = latm  => 1

# Pseudo-rules:
:start ::= pointer
# Increasing the priority of the array_index lexeme from 0 (the default) to 1
# avoids parse ambiguity errors of the "ambiguous symch" type
:lexeme ~ array_index      priority => 1
# The next array index refers to the (nonexistent) array element after the last
# array element.
:lexeme ~ next_array_index priority => 2
:lexeme ~ unescaped
:lexeme ~ escaped_slash
:lexeme ~ escaped_tilde

# Structural (G1) rules:
pointer          ::= pointer_segment*    action => get_crv
pointer_segment  ::= '/' reference_token
reference_token  ::= next_array_index    action => next_array_index_dereferencing
                     | array_index       action => array_index_dereferencing
                     | object_name       action => object_name_dereferencing
reference_token  ::=                     action => object_name_dereferencing
object_name      ::= object_name_part+   action => concat
object_name_part ::= unescaped           action => ::first
                     | escaped_slash     action => SLASH
                     | escaped_tilde     action => TILDE

# Lexical (L0) rules:
escaped_tilde ~ '~0'
escaped_slash ~ '~1'
# Leading zeros in the hexadecimal number representation of the Unicode code
# point between the curly braces are omitted.
unescaped     ~ [\x{00}-\x{2E}\x{30}-\x{7D}\x{7F}-\x{10FFFF}]+

array_index      ~ zero | positive digits
next_array_index ~ '-'
digits           ~ [\d]*
positive         ~ [1-9]
zero             ~ [0]
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new(
  {
    source            => \$dsl,
    trace_file_handle => *STDERR
  }
);

sub get {
  my ( undef, $json_document, $json_pointer ) = @_;

  # FIXME: properly differentiate between the 2 different representations
  # (RFC6901 section 5 and section 6) of a JSON pointer. uri_unescape() has
  # to be called only(!) for the URI fragment identifier representation type
  # (section 6). Backslash unescaping has to be done for the JSON string
  # representation (section 5) type.
  $json_pointer = uri_unescape( $json_pointer ) if $json_pointer =~ s/\A#//; ## no critic (RequireExtendedFormatting)

  my $recognizer = Marpa::R2::Scanless::R->new(
    {
      grammar => $grammar
      #trace_terminals => 1,
      #trace_values    => 1,
    }
  );
  $recognizer->read( \$json_pointer );

  ${ $recognizer->value( JSON::Pointer::Marpa::Semantics->new( $json_document ) ) }
}

1
