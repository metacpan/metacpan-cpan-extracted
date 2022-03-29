# -*- Perl -*-
#
# a parser for logic expressions

package Logic::Expr::Parser;
our $VERSION = '0.02';
use Logic::Expr ':all';
use base 'Parser::MGC';    # 0.21 or higher required

# LE_NOT is handled outside the scope of this pair of variables
our %le_map = (
    '&'  => LE_AND,
    '|'  => LE_OR,
    'v'  => LE_OR,
    '->' => LE_COND,
    '==' => LE_BICOND,
);
our $le_regex = qr/->|==|[&|v]/;

sub on_parse_end { Logic::Expr->new( expr => $_[1] ) }

sub parse
{
    my ($self) = @_;
    my $first = $self->_parse_term;
    my ( $operator, $second );
    $self->maybe(
        sub {
            $operator = $le_map{ $self->expect($le_regex) };
            $second   = $self->_parse_term;
        }
    );
    defined $operator ? [ $operator, $first, $second ] : $first;
}

sub _parse_term
{
    my ($self) = @_;
    my $neg    = $self->maybe( sub { $self->expect(qr/!+|~+/) } );
    my $term   = $self->any_of(
        sub { $self->scope_of( "(", \&parse, ")" ) },
        sub {
            my $atom = $self->expect(qr/[A-Z]+/);
            unless ( exists $Logic::Expr::atoms{$atom} ) {
                push @Logic::Expr::bools, TRUE;
                $Logic::Expr::atoms{$atom} = \$Logic::Expr::bools[-1];
            }
            $Logic::Expr::atoms{$atom};
        },
    );
    # simplify !!!X to !X and !!X to X
    ( defined $neg and length($neg) & 1 ) ? [ LE_NOT, $term ] : $term;
}

1;
__END__

=head1 NAME

Logic::Expr - logical expression parsing and related routines

=head1 SYNOPSIS

  use Logic::Expr::Parser;

  # Parser::MGC also supports "from_file"
  my $le = Logic::Expr::Parser->new->from_string('Xv~Y');

  # and then see Logic::Expr for uses of the $le object

=head1 DESCRIPTION

This module parses logic expressions and returns a L<Logic::Expr>
object, which in turn has various methods for acting on the expression
thus parsed.

L<Parser::MGC> is the parent class used to parse the expressions;
B<from_string> and B<from_file> are the most relevant methods.

=head1 SYNTAX SANS EBNF

The usual atomic letters (C<X>, C<Y>, etc) are extended to include words
in capital letters to allow for more than 26 atoms, or at least more
descriptive names, for better or worse.

Operators include C<!> or C<~> for negation of the subsequent atom or
parenthesized term, and the binary operators

  | v  or            TTTF lojban .a
  &    and           TFFF lojban .e
  ->   conditional   TFTT lojban .a with first term negated
  ==   biconditional TFFT lojban .o

which taken together allow for such expressions as

  X&!Y
  GILBERT&SULLIVAN
  (CAT|DOG)->FISH
  ALIENvPREDICATOR
  ETC

=head1 MINUTIAE

Code coverage tools can be persnickety about these sorts of things.

=over 4

=item B<on_parse_end>

Internal L<Parser::MGC> hook function.

=item B<parse>

Internal L<Parser::MGC> function.

=back

=head1 BUGS

None known.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
