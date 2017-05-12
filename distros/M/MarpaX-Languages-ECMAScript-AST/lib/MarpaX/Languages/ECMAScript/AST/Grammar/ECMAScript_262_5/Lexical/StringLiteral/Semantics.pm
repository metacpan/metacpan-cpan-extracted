use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral::Semantics;
use Carp qw/croak/;
use constant {
    BS        => "\N{U+0008}",
    HT        => "\N{U+0009}",
    LF        => "\N{U+000A}",
    VT        => "\N{U+000B}",
    FF        => "\N{U+000C}",
    CR        => "\N{U+000D}",
    DQUOTE    => "\N{U+0022}",
    SQUOTE    => "\N{U+0027}",
    BACKSLASH => "\N{U+005C}"
};

# ABSTRACT: ECMAScript 262, Edition 5, lexical string grammar actions

our $VERSION = '0.020'; # VERSION



sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}

sub _secondArg             { return $_[2] }
sub _emptyString           { return ''; }
sub _concat                { return join('', @_[1..$#_]); }

sub _OctalEscapeSequence01 { return chr(                                   oct($_[1])); }
sub _OctalEscapeSequence02 { return chr(                  8 * oct($_[1]) + oct($_[2])); }
sub _OctalEscapeSequence03 { return chr(64 * oct($_[1]) + 8 * oct($_[2]) + oct($_[3])); }

sub _SingleEscapeCharacter {
    if    ($_[1] eq 'b')  { return  BS;        }
    elsif ($_[1] eq 't')  { return  HT;        }
    elsif ($_[1] eq 'n')  { return  LF;        }
    elsif ($_[1] eq 'v')  { return  VT;        }
    elsif ($_[1] eq 'f')  { return  FF;        }
    elsif ($_[1] eq 'r')  { return  CR;        }
    elsif ($_[1] eq '"')  { return  DQUOTE;    }
    elsif ($_[1] eq '\'') { return  SQUOTE;    }
    elsif ($_[1] eq '\\') { return  BACKSLASH; }
    else {
	croak "Invalid single escape character: $_[1]";
    }
}

sub _HexEscapeSequence { return chr(16 * hex($_[1]) + hex($_[2])); }
sub _UnicodeEscapeSequence { return chr(4096 * hex($_[2]) + 256 * hex($_[3]) + 16 * hex($_[4]) + hex($_[5])); }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral::Semantics - ECMAScript 262, Edition 5, lexical string grammar actions

=head1 VERSION

version 0.020

=head1 DESCRIPTION

This modules give the actions associated to ECMAScript_262_5 lexical string grammar.

=head2 new($class)

Instantiate a new object.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
