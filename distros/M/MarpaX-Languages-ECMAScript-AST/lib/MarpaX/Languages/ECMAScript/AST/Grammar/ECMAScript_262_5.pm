use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5;
use MarpaX::Languages::ECMAScript::AST::Impl;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Program;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::JSON;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::URI;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Template;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::SpacesAny;

# ABSTRACT: ECMAScript-262, Edition 5, grammar

our $VERSION = '0.020'; # VERSION


sub new {
  my ($class, %opts) = @_;

  my $self  = {};

  bless($self, $class);

  $self->_init(%opts);

  return $self;
}

sub _init {
    my ($self, %opts) = @_;

    my $spacesAny = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::SpacesAny->new();
    $self->{_spacesAny} = {
	grammar => $spacesAny,
	impl => MarpaX::Languages::ECMAScript::AST::Impl->new($spacesAny->grammar_option(), $spacesAny->recce_option())
    };

    my $program = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Program->new();
    $self->{_program} = {
	grammar => $program,
	impl => MarpaX::Languages::ECMAScript::AST::Impl->new($program->grammar_option(), $program->recce_option())
    };
    $program->spacesAny($self->spacesAny);

    my $JSON = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::JSON->new();
    $self->{_JSON} = {
	grammar => $JSON,
	impl => MarpaX::Languages::ECMAScript::AST::Impl->new($JSON->grammar_option(), $JSON->recce_option())
    };

    my $URI = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::URI->new();
    $self->{_URI} = {
	grammar => $URI,
	impl => MarpaX::Languages::ECMAScript::AST::Impl->new($URI->grammar_option(), $URI->recce_option())
    };

    my $stringNumericLiteralOptionsp = exists($opts{StringNumericLiteral}) ? $opts{StringNumericLiteral} : undef;
    my $stringNumericLiteral = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral->new($stringNumericLiteralOptionsp);
    $self->{_stringNumericLiteral} = {
	grammar => $stringNumericLiteral,
	impl => MarpaX::Languages::ECMAScript::AST::Impl->new($stringNumericLiteral->grammar_option(), $stringNumericLiteral->recce_option())
    };

    my $pattern = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern->new();
    $self->{_pattern} = {
	grammar => $pattern,
	impl => MarpaX::Languages::ECMAScript::AST::Impl->new($pattern->grammar_option(), $pattern->recce_option())
    };

    my $templateOptionsp = exists($opts{Template}) ? $opts{Template} : undef;
    $self->{_template} = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Template->new($templateOptionsp);

}


sub program {
    my ($self) = @_;

    return $self->{_program};
}


sub JSON {
    my ($self) = @_;

    return $self->{_JSON};
}


sub URI {
    my ($self) = @_;

    return $self->{_URI};
}


sub template {
    my ($self) = @_;

    return $self->{_template};
}


sub stringNumericLiteral {
    my ($self) = @_;

    return $self->{_stringNumericLiteral};
}


sub pattern {
    my ($self) = @_;

    return $self->{_pattern};
}


sub spacesAny {
    my ($self) = @_;

    return $self->{_spacesAny};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5 - ECMAScript-262, Edition 5, grammar

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5;

    my $ecma = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5->new();

    my $program = $ecma->program();

=head1 DESCRIPTION

This modules returns all grammars needed for the ECMAScript 262, Edition 5 grammars written in Marpa BNF, as of L<http://www.ecma-international.org/publications/standards/Ecma-262.htm>. ONLY the Program and JSON grammars provides an AST. The StringNumericLiteral and Pattern grammars, if needed by another engine but a perl executable, will have to be provided expicitely. StringNumericLiteral and Pattern parse tree values presented here are meaningful only for a perl engine.

From a perl engine point of view, there two main notion of numbers: native (i.e. the ones in the math library with which perl was build), and the Math::Big* family. Therefore the parse tree value of the StringNumericLiteral is abstracted to handle both cases.

The Pattern parse tree value provides an anoynmous subroutine to be used directly as a Regexp.prototype.exec call.

=head1 SUBROUTINES/METHODS

=head2 new($class, %opts)

Instance a new object. Takes as optional argument a hash that may contain the following key/values:

=over

=item Template

Reference to hash containing options for MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Template. These options can be:

=over

=item g1Callback

G1 callback (CODE ref)

=item g1CallbackArgs

G1 callback arguments (ARRAY ref). The g1 callback is called like: &$g1Callback(@{$g1CallbackArgs}, \$rc, $ruleId, $value, $index, $lhs, @rhs), where $value is the AST parse tree value of RHS No $index of this G1 rule number $ruleId, whose full definition is $lhs ::= @rhs. If the callback is defined, this will always be executed first, and it must return a true value putting its eventual result in $rc. Only when it returns true, lexemes are processed.

=item lexemeCallback

lexeme callback (CODE ref).

=item lexemeCallbackArgs

Lexeme callback arguments (ARRAY ref). The lexeme callback is called like: &$lexemeCallback(@{$lexemeCallbackArgs}, \$rc, $name, $ruleId, $value, $index, $lhs, @rhs), where $value is the AST parse tree value of RHS No $index of this G1 rule number $ruleId, whose full definition is $lhs ::= @rhs. The RHS being a lexeme, $name contains the lexeme's name. If the callback is defined, this will always be executed first, and it must return a true value putting its result in $rc, otherwise default behaviour applies: return the lexeme value as-is.

=back

=item StringNumericLiteral

Reference to hash containing options for MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral. These options can be:

=over

=item semantics_package

Semantic package providing host implementation of a Number.

=back

=back

=head2 program()

Returns the program grammar as a hash reference that is

=over

=item grammar

A MarpaX::Languages::ECMAScript::AST::Grammar::Base object

=item impl

A MarpaX::Languages::ECMAScript::AST::Impl object

=back

=head2 JSON()

Returns the JSON grammar as a hash reference that is

=over

=item grammar

A MarpaX::Languages::ECMAScript::AST::Grammar::Base object

=item impl

A MarpaX::Languages::ECMAScript::AST::Impl object

=back

=head2 URI()

Returns the URI grammar as a hash reference that is

=over

=item grammar

A MarpaX::Languages::ECMAScript::AST::Grammar::Base object

=item impl

A MarpaX::Languages::ECMAScript::AST::Impl object

=back

=head2 template()

Returns the template associated to this grammar. This is a MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Template object.

=head2 stringNumericLiteral()

Returns the StringNumericLiteral grammar as a hash reference that is

=over

=item grammar

A MarpaX::Languages::ECMAScript::AST::Grammar::Base object

=item impl

A MarpaX::Languages::ECMAScript::AST::Impl object

=back

=head2 pattern()

Returns the Pattern grammar as a hash reference that is

=over

=item grammar

A MarpaX::Languages::ECMAScript::AST::Grammar::Base object

=item impl

A MarpaX::Languages::ECMAScript::AST::Impl object

=back

=head2 spacesAny()

Returns the SpacesAny grammar as a hash reference that is

=over

=item grammar

A MarpaX::Languages::ECMAScript::AST::Grammar::Base object

=item impl

A MarpaX::Languages::ECMAScript::AST::Impl object

=back

=head1 SEE ALSO

L<MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral>

L<MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern>

L<MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Template>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
