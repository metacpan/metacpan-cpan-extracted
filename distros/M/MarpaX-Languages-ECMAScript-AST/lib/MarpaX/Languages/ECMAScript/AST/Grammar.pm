use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar;

# ABSTRACT: ECMAScript grammar written in Marpa BNF

use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5;
use MarpaX::Languages::ECMAScript::AST::Exceptions qw/:all/;

our $VERSION = '0.020'; # VERSION


sub new {
  my ($class, $grammarName, %grammarSpecificOptions) = @_;

  my $self = {};
  if (! defined($grammarName)) {
    InternalError(error => 'Usage: new($grammar_Name)');
  } elsif ($grammarName eq 'ECMAScript-262-5') {
    $self->{_grammarAlias} = 'ECMAScript_262_5';
    $self->{_grammar} = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5->new(%grammarSpecificOptions);
  } else {
    InternalError(error => "Unsupported grammar name $grammarName");
  }
  bless($self, $class);

  return $self;
}


sub program {
    my ($self) = @_;
    return $self->{_grammar}->program;
}


sub grammarAlias {
    my ($self) = @_;
    return $self->{_grammarAlias};
}


sub template {
    my ($self) = @_;
    return $self->{_grammar}->template;
}


sub stringNumericLiteral {
    my ($self) = @_;
    return $self->{_grammar}->stringNumericLiteral;
}


sub pattern {
    my ($self) = @_;
    return $self->{_grammar}->pattern;
}


sub JSON {
    my ($self) = @_;
    return $self->{_grammar}->JSON;
}


sub URI {
    my ($self) = @_;
    return $self->{_grammar}->URI;
}


sub spacesAny {
    my ($self) = @_;
    return $self->{_grammar}->spacesAny;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar - ECMAScript grammar written in Marpa BNF

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use MarpaX::Languages::ECMAScript::AST::Grammar;

    my $grammar = MarpaX::Languages::ECMAScript::AST::Grammar->new('ECMAScript-262-5');
    my $grammar_content = $grammar->content();
    my $grammar_option = $grammar->grammar_option();
    my $recce_option = $grammar->recce_option();

=head1 DESCRIPTION

This modules returns ECMAScript grammar(s) written in Marpa BNF.
Current grammars are:
=over
=item *
ECMAScript-262-5. The ECMAScript-262, Edition 5, as of L<http://www.ecma-international.org/publications/standards/Ecma-262.htm>.
=back

=head1 SUBROUTINES/METHODS

=head2 new($class, $grammarName, %grammarSpecificOptions)

Instance a new object. Takes the name of the grammar as argument. Remaining arguments are passed to the sub grammar method. Supported grammars are:

=over

=item ECMAScript-262-5

ECMAScript-262, Edition 5

=back

=head2 program($self)

Returns the program grammar as a reference to hash that is

=over

=item grammar

A MarpaX::Languages::ECMAScript::AST::Grammar::Base object

=item impl

A MarpaX::Languages::ECMAScript::AST::Impl object

=back

=head2 grammarAlias($self)

Returns the grammar alias, i.e. the one really used in this distribution.

=head2 template($self)

Returns the generic template associated to grammarName.

=head2 stringNumericLiteral($self)

Returns the stringNumericLiteral grammar.

=head2 pattern($self)

Returns the pattern grammar.

=head2 JSON($self)

Returns the JSON grammar.

=head2 URI($self)

Returns the URI grammar.

=head2 spacesAny($self)

Returns the spacesAny grammar.

=head1 SEE ALSO

L<Marpa::R2>

L<MarpaX::Languages::ECMAScript::AST>

L<MarpaX::Languages::ECMAScript::AST::Grammar::Base>

L<MarpaX::Languages::ECMAScript::AST::Impl>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
