package Grammar::Marpa;

use strict;
use warnings;
use 5.018;
use utf8;
use overload ('qr' => 'regexify', fallback => 0);

use Marpa::R2;

our $VERSION = '2.004';

sub regexify {
    my ($grammar) = @_;
    use re 'eval';
    return qr/(?{Grammar::Marpa::parse($grammar, "$_")})/;
}

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $ebnf = ref($_[0]) eq 'HASH' ? undef : shift(@_);
    my $pkg;
    my %args;
    if (ref ($_[-1]) eq 'HASH') {
        %args = %{pop(@_)};
        $pkg = shift(@_) // (caller)[0];
    }
    elsif (@_ % 2) {
        $pkg = shift;
        %args = @_;
    }
    else {
        $pkg = (caller)[0];
        %args = @_;
    }
    my %Gargs;
    $Gargs{ bless_package } = delete $args{ bless_package } if $args{ bless_package };
    $Gargs{ trace_file_handle } = $args{ trace_file_handle } if $args{ trace_file_handle };
    $ebnf //= delete $args{ source };
    $ebnf = $$ebnf if ref($ebnf);
    my $G = Marpa::R2::Scanless::G->new({ source => \$ebnf, %Gargs });
    return bless [ $G, $pkg, \%args ] => $class;
}

sub parse {
    my ($grammar, $string) = @_;
    my $R = Marpa::R2::Scanless::R->new({ grammar => $grammar->[ 0 ], semantics_package => $grammar->[ 1 ], %{$grammar->[ 2 ]} });
    $R->read(\$string);
    my $V = $R->value or return;
    return $$V;
}

package Grammar;

sub Marpa {
    return Grammar::Marpa->new(@_);
}

1;

__END__

=head1 NAME

Grammar::Marpa - Regexp-overloading wrapper around Marpa::R2::Scanless

=head1 VERSION

Version 2.004

=head1 SYNOPSIS

    use Grammar::Marpa;

    my $dsl = <<'END_OF_DSL';
    :default ::= action => ::first
    :start ::= Expression
    Expression ::= Term
    Term ::= Factor
           | Term '+' Term action => do_add
    Factor ::= Number
             | Factor '*' Factor action => do_multiply
    Number ~ digits
    digits ~ [\d]+
    :discard ~ whitespace
    whitespace ~ [\s]+
    END_OF_DSL

    sub M::do_add {
        my (undef, $t1, undef, $t2) = @_;
        return $t1 + $t2;
    }

    sub M::do_multiply {
        my (undef, $t1, undef, $t2) = @_;
        return $t1 * $t2;
    }

    my $g = Grammar::Marpa->new({ source => $dsl, semantics_package => 'M');

    '1 + 2 * 3' =~ $g;

    say $^R; # '7'

=head1 DESCRIPTION

This module provides a quick & dirty interface to Marpa::R2's Scanless
interface, including overloading the '=~' operator in a way that is only
I<slightly> inconvenient.

=head1 CONSTRUCTORS

=head2 Grammar::Marpa->new()

B<PREFERRED:> Create a new grammar object, based on the provided arguments,
which take one of the following forms:

=over

=item GRAMMAR, PACKAGE

Specify the source EBNF and the Semantics Package. If no Semantics Package is
provided, the Semantics must provided by the calling package.

=item ARGS

Hash or hashref containing arguments for both the Grammar and the Recognizer
objects that are contained inside this object. Valid keys include (inter alia):

=over

=item bless_package

=item semantics_package

=item trace_file_handle

=item trace_terminals

=item trace_values

=back

See the appropriate documentation for Marpa::R2::Scanless to understand the
meanings of those arguments.

=back

You may also combine the GRAMMAR argument, the optional PACKAGE argument, and
any additional options as a hash or hashref.

=head2 Grammar::Marpa(GRAMMAR, PACKAGE)

B<DEPRECATED:> Create a new grammar object, based on a well-formed SLIF EBNF
grammar (which must be provided as a scalar string) and using the specified
package to provide the semantics of the grammar.

=head1 USAGE

=head2 Parsing

Once you have a grammar object, you can parse a string by performing either of

    $string =~ $grammar;

    $value = $grammar->parse($string);

=head2 Getting the result

If you have parsed a string with the '=~' overload, the $^R variable will
contain the value of the last parse.

If you parse a string usintg the parse() method, the return value will be the
value of that parse.

=head1 DIFFERENCES FROM v1.000

The previous version of this module would Carp::confess() if no parse was found.

The current version simply returns implicit undef.

=head1 LICENSE

Artistic 2.0

=cut
