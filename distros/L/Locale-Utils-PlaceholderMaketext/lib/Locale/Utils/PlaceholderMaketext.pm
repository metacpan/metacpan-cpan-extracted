package Locale::Utils::PlaceholderMaketext; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(looks_like_number);
use Moo;
use MooX::StrictConstructor;
use MooX::Types::MooseLike::Base qw(Bool Str CodeRef);
use namespace::autoclean;

our $VERSION = '1.005';

has is_strict => (
    is  => 'rw',
    isa => Bool,
);

has is_escape_percent_sign => (
    is  => 'rw',
    isa => Bool,
);

has space => (
    is      => 'rw',
    isa     => Str,
    default => sub { q{ } },
);

sub reset_space { return shift->space( q{ } ) }

has formatter_code => (
    is      => 'rw',
    isa     => CodeRef,
    clearer => 'clear_formatter_code',
);

sub maketext_to_gettext {
    my ($self, $string) = @_;

    defined $string
        or return $string;
    my $is_escape_percent_sign  = $self->is_escape_percent_sign;
    ## no critic (ComplexRegexes)
    $string =~ s{
        [~] ( [~\[\]] )                      # $1 - unescape
        |
        ( [%] )                              # $2 - escape
        |
        \[
        (?:
            ( [[:alpha:]*\#] [[:alpha:]_]* ) # $3 - function name
            [,]
            [_] ( [1-9] \d* )                # $4 - variable
            ( [^\]]* )                       # $5 - arguments
            |                                # or
            [_] ( [1-9] \d* )                # $6 - variable
        )
        \]
    }
    {
        $1
        ? $1
        : $2
        ? $is_escape_percent_sign ? "%$2" : $2
        : $6
        ? "%$6"
        : "%$3(%$4$5)"
    }xmsge;
    ## use critic (ComplexRegexes)

    return $string;
}

sub gettext_to_maketext {
    my (undef, $string) = @_;

    defined $string
        or return $string;
    ## no critic (ComplexRegexes)
    $string =~ s{
        [%] ( [%] )                          # $1 - unescape
        |
        ( [~\[\]] )                          # $2 - escape
        |
        [%]
        (?:
            ( [[:alpha:]*\#] [[:alpha:]_]* ) # $3 - function name
            [(]
            [%] ( [1-9] \d* )                # $4 - variable
            ( [^)]* )                        # $5 - arguments
            [)]
            |                                # or
            ( [1-9] \d* )                    # $6 - variable
        )
    }
    {
        $1
        ? $1
        : $2
        ? "~$2"
        : $6
        ? "[_$6]"
        : "[$3,_$4$5]"
    }xmsge;
    ## use critic (ComplexRegexes)

    return $string;
}

# Expand the placeholders

sub _replace { ## no critic (ManyArgs)
    my ($self, $arg_ref, $text, $index_quant, $singular, $plural, $zero, $index_string) = @_;

    if (defined $index_quant) { # quant
        my $number = $arg_ref->[$index_quant - 1];
        if ( ! looks_like_number($number) ) {
            $number = $self->is_strict ? return $text : 0;
        }
        my $formatted
            = $self->formatter_code
            ? $self->formatter_code->($number, 'numeric', 'quant')
            : $number;
        my $space = $self->space;
        return
            +( defined $zero && $number == 0 )
            ? $zero
            : $number == 1
            ? (
                defined $singular
                ? "$formatted$space$singular"
                : return $text
            )
            : (
                defined $plural
                ? "$formatted$space$plural"
                : defined $singular
                ? "$formatted$space$singular"
                : return $text
            );
    }
    # replace only
    my $string = $arg_ref->[$index_string - 1];
    defined $string
        or return $self->is_strict ? $text : q{};

    return
        $self->formatter_code
        ? $self->formatter_code->(
            $string,
            looks_like_number($string) ? 'numeric' : 'string',
        )
        : $string;
}

sub expand_maketext {
    my ($self, $text, @args) = @_;

    defined $text
        or return $text;
    my $arg_ref = ( @args == 1 && ref $args[0] eq 'ARRAY' )
        ? $args[0]
        : [ @args ];

    ## no critic (ComplexRegexes)
    $text =~ s{
        [~] ( [~\[\]] )                # $1: escaped
        |
        (                              # $2: text
            \[ (?:
                (?: quant | [*] )
                [,] [_] ( \d+ )        # $3: n
                [,] ( [^,\]]* )        # $4: singular
                (?: [,] ( [^,\]]* ) )? # $5: plural
                (?: [,] ( [^,\]]* ) )? # $6: zero
                |
                [_] ( \d+ )            # $7: n
            ) \]
        )
    }
    {
        $1
        ? $1
        : $self->_replace($arg_ref, $2, $3, $4, $5, $6, $7)
    }xmsge;
    ## use critic (ComplexRegexes)

    return $text;
}

sub expand_gettext {
    my ($self, $text, @args) = @_;

    defined $text
        or return $text;
    my $arg_ref = ( @args == 1 && ref $args[0] eq 'ARRAY' )
        ? $args[0]
        : [ @args ];

    ## no critic (ComplexRegexes)
    $text =~ s{
        [%] ( % )                 # $1: escaped
        |
        (                         # $2: text
            [%] (?: quant | [*] )
            [(]
            [%] ( \d+ )           # $3: n
            [,] ( [^,)]* )        # $4: singular
            (?: [,] ( [^,)]* ) )? # $5: plural
            (?: [,] ( [^,)]* ) )? # $6: zero
            [)]
            |
            [%] ( \d+ )           # $7: n
        )
    }
    {
        $1
        ? $1
        : $self->_replace($arg_ref, $2, $3, $4, $5, $6, $7)
    }xmsge;
    ## use critic (ComplexRegexes)

    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::Utils::PlaceholderMaketext - Utils to expand maketext palaceholders

$Id: PlaceholderMaketext.pm 665 2017-07-16 10:12:00Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/Locale-Utils-PlaceholderMaketext/trunk/lib/Locale/Utils/PlaceholderMaketext.pm $

=head1 VERSION

1.005

=head1 SYNOPSIS

    use Locale::Utils::PlaceholderMaketext;

    my $obj = Locale::Utils::PlaceholderMaketext->new(
        # optional is_strict switch
        is_strict              => 1,
        # optional escape of % to %%
        is_escape_percent_sign => 1,
        # optional fromatter code
        formatter_code         => sub { ... },
        # space between number and singular/plural at function quant
        space                  => "\N{NO-BREAK SPACE}",
    );

    $expanded = $obj->expand_maketext($text, @args);
    $expanded = $obj->expand_maketext($text, \@args);

=head1 DESCRIPTION

Utils to transform text from maketext to gettext style and reverse.
Utils to expand placeholders in maketext or gettext style.

Locale::Maketext encapsulates the expander.
To use the expander in other modules it is not possible.
Use this module instead.
Use method formatter_code and feel free how to format numerics.
Use method sapce to prevent the linebreak bitween number and singular/plural.

=head1 SUBROUTINES/METHODS

=head2 method new

see SYNOPSIS

=head2 method maketext_to_gettext

Maps maketext strings with

 %
 [_1]
 [quant,_2,singular]
 [quant,_3,singular,plural]
 [quant,_4,singular,plural,zero]
 [*,_5,singular]
 [*,_6,singular,plural]
 [*,_7,singular,plural,zero]

inside to

 %%
 %1
 %quant(%2,singluar)
 %quant(%3,singluar,plural)
 %quant(%4,singluar,plural,zero)
 %*(%5,singluar)
 %*(%6,singluar,plural)
 %*(%7,singluar,plural,zero)

inside.
% to %% depends on is_escape_percent_sign

    $gettext_string = $obj->maketext_to_gettext($maketext_string);

This method can called as class method too.

    $gettext_string
        = Locale::Utils::PlaceholderMaketext->maketext_to_gettext($maketext_string);

=head2 method gettext_to_maketext

It is the same like method maktetext_to_gettext only the other direction.

    $maketext_string = $obj->gettext_to_maketext($gettext_string);

This method can called as class method too.

    $maketext_string
        = Locale::Utils::PlaceholderMaketext->gettext_to_maketext($gettext_string);

=head2 method space, reset_space

Set the space bitween number and singular/plural.
Prevent the linebreak after the number using no-break space.
The default of space is C<q{ }>.

    $obj->space( "\N{NO-BREAK SPACE}" ); # unicode example
    $obj->reset_space; # to reset to the default q{ }

=head2 method is_strict

If is_strict is true:
For normal replacement undef will be converted to q{}.
For quant undef will be converted to 0.

    $obj->is_strict(1); # boolean true or false;

=head2 method is_escape_percent_sign

If is_ecscpe_percent_sign is true:
A single % willbe escaped to %%.

    $obj->is_escape_percent_sign(1); # boolean true or false;

=head2 method formatter_code, clear_formatter_code

If it is needed to localize e.g. the numerics
than describe this in a code reference.

    my $code_ref = sub {
        my ($value, $type, $function_name) = @_;

        # $value is never undefined
        # $type is 'numeric' or 'string'
        # $function_name is 'quant' or undef
        ...

        return $value;
    };
    $obj->formatter_code($code_ref);

Than method expand_maketext and expand_gettext
will run this code before the substitution of placeholders.

To switch off this code - clear them.

    $obj->clear_formatter_code;

=head2 method expand_maketext

Expands strings containing maketext placeholders.

maketext style:

 [_1]
 [quant,_1,singular]
 [quant,_1,singular,plural]
 [quant,_1,singular,plural,zero]
 [*,_1,singular]
 [*,_1,singular,plural]
 [*,_1,singular,plural,zero]

    $expanded = $obj->expand_maketext($maketext_text, @args);

or

    $expanded = $obj->expand_maketext($maketext_text, \@args);

=head2 method expand_gettext

Expands strings containing gettext placeholders.

gettext style:

 %1
 %quant(%1,singular)
 %quant(%1,singular,plural)
 %quant(%1,singular,plural,zero)
 %*(%1,singular)
 %*(%1,singular,plural)
 %*(%1,singular,plural,zero)

    $expanded = $obj->expand_maketext($gettext_text, @args);

or

    $expanded = $obj->expand_maketext($gettext_text, \@args);

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run the *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Scalar::Util|Scalar::Util>

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<MooX::Types::MooseLike|MooX::Types::MooseLike>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<Locale::Maketext|Locale::Maketext>

L<http://en.wikipedia.org/wiki/Gettext>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
