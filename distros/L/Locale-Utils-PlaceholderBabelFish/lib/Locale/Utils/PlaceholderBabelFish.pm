package Locale::Utils::PlaceholderBabelFish; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use HTML::Entities qw(encode_entities);
use List::Util qw(min);
use Moo;
use MooX::StrictConstructor;
use MooX::Types::MooseLike::Base qw(Bool CodeRef);
use Scalar::Util qw(looks_like_number);
use namespace::autoclean;

our $VERSION = '0.006';

has is_strict => (
    is  => 'rw',
    isa => Bool,
);

sub default_modifier_code {
    return sub {
        my ( $value, $attributes ) = @_;

        if ( $attributes =~ m{ \b html \b }xms ) {
            $value = encode_entities( $value, q{<>&"} );
        }

        return $value;
    }
};

has modifier_code => (
    is      => 'rw',
    isa     => CodeRef,
    clearer => 'clear_modifier_code',
    lazy    => 1,
    default => \&default_modifier_code,
);

has plural_code => (
    is      => 'rw',
    isa     => CodeRef,
    lazy    => 1,
    default => sub {
        return sub {
            my $n = shift;
            0 + (
                $n != 1 # en
            );
        };
    },
    clearer => 'clear_plural_code',
);

sub _mangle_value {
    my ($self, $placeholder, $value, $attribute) = @_;

    defined $value
        or return $self->is_strict ? $placeholder : q{};
    defined $attribute
        or return $value;
    $self->modifier_code
        or return $value;
    $value = $self->modifier_code->($value, $attribute);
    defined $value
        or confess 'modifier_code returns nothing or undef';

    return $value;
}

sub expand_babel_fish {
    my ($self, $text, @args) = @_;

    defined $text
        or return $text;
    my $arg_ref = @args == 1
        ? ( ref $args[0] eq 'HASH' ? $args[0] : { count => $args[0] } )
        : {
            @args % 2
            ? confess 'Arguments expected pairwise'
            : @args
        };

    # placeholders
    my $regex = join q{|}, map { quotemeta } keys %{$arg_ref};
    ## no critic (EscapedMetacharacters)
    $text =~ s{
        ( \\ [#] )                     # escaped
        |
        (
            [#] \{
            ( $regex )                 # placeholder
            (?: [ ]* [:] ( [^\}]+ ) )? # attribute
            \}
        )
    }
    {
        $1
        ? $1
        : $self->_mangle_value($2, $arg_ref->{$3}, $4)
    }xmsge;
    ## use critic (EscapedMetacharacters)

    # plural
    my $replace_code = sub {
        my ( $match, $inner, $count ) = @_;

        looks_like_number($count)
            or return $match;
        $inner =~ s{ \\ [|] }{\0}xmsg;
        my @special_plurals;
        my @plurals
            = map {
                m{ \A [=] ( \d+ ) \s+ ( .* ) \z }xms
                    ? do {
                        push @special_plurals, [$1, $2];
                        ();
                    }
                    : $_;
            }
            map { ## no critic (ComplexMappings)
                my $item = $_;
                $item =~ s{ \0 }{\\|}xmsg;
                $item;
            }
            split qr{ [|] }xms, $inner;
        for my $plural ( @special_plurals ) {
            if ( defined $plural->[0] && $plural->[0] == $count ) {
                return $plural->[1];
            }
        }
        @plurals
            or return $match;
        my $index = $self->plural_code->($count);
        $index = min( $index, $#plurals );

        return $plurals[$index];
    };
    ## no critic (EscapedMetacharacters)
    $text =~ s{
        ( \\ \( \( )           # $1: escaped
        |
        (                      # $2: match
            \( \(              # open
            ( .*? )            # $3: inner
            \) \)              # close
            (?: [:] ( \w+ ) )? # $4: count variable name
        )
    }
    {
        $1
        ? $1
        : $replace_code->( $2, $3, $4 ? $arg_ref->{$4} : $arg_ref->{count} )
    }xmsge;
    ## use critic (EscapedMetacharacters)

    # unescape
    $text =~ s{ \\ (.) }{$1}xmsg;

    return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::Utils::PlaceholderBabelFish - Utils to expand BabelFish palaceholders

$Id: PlaceholderBabelFish.pm 663 2017-07-16 09:59:32Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/Locale-Utils-PlaceholderBabelFish/trunk/lib/Locale/Utils/PlaceholderBabelFish.pm $

=head1 VERSION

0.006

=head1 SYNOPSIS

    use Locale::Utils::PlaceholderBabelFish;

    my $obj = Locale::Utils::PlaceholderBabelFish->new(
        # optional is_strict switch
        is_strict => 1,
        # optional modifier code
        modifier_code => sub {
            my ( $value, $attribute ) = @_;
            return
                $attribute =~ m{ \b numf \b }xms
                ? format_number($value)
                : $attribute =~ m{ \b html \b }xms
                ? encode_entiaccusative($value)
                : $value;
        },
        # optional plural code
        plural_code => sub { # the default for English
            my $n = shift;
            0 + (
                $n != 1 # en
            );
        },
    );

    $expanded = $obj->expand_babel_fish($text, $count);
    $expanded = $obj->expand_babel_fish($text, $arg_ref);
    $expanded = $obj->expand_babel_fish($text, \%arg_of);

=head1 DESCRIPTION

Utils to expand placeholders in BabelFish style.

Placeholders are also extendable with attributes to run the modifier code.
That is an extention to BabelFish style.

=head1 SUBROUTINES/METHODS

=head2 method new

see SYNOPSIS

=head2 method is_strict

If is_strict is false: undef will be converted to q{}.
If is_strict is true: no replacement.

    $obj->is_strict(1); # boolean true or false;

=head2 method default_modifier_code

Implements the html attribute.
For plain text messages in HTML the whole message will be escaped.
In case of HTML messages the placeholder data have to escaped.

    # class method
    my $modifier_code = Locale::Utils::PlaceholderBabelFish->default_modifier_code;
    # object method
    my $modifier_code = $obj->default_modifier_code;

    # call example
    $value = $modifier_code->($value, $attributes);

=head2 method modifier_code, clear_modifier_code

The modifier code handles named attributes
to modify the given placeholder value.

If the placeholder name is C<#{foo:bar}> then foo is the placeholder name
and bar the attribute name.
Space in front of the attribute name is allowed, e.g. C<#{foo :bar}>.

    my $code_ref = sub {
        my ( $value, $attributes ) = @_;
        return
            $attributes =~ m{ \b numf \b }
            ? $value =~ tr{.}{,}
            : $attribute =~ m{ \b accusative \b }xms
            ? accusative($value)
            : $value;
    };
    $obj->modifier_code($code_ref);

To switch off this code - clear them.

    $obj->clear_modifier_code;

=head2 method expand_babel_fish

Expands strings containing BabelFish placeholders.

variables and attributes

    #{name}
    #{name :attr_name}

plural with default C<count> or other name for count

    ((Singular|Plural))
    ((Singular|Plural)):other

plural with special count 0

    ((=0 Zero|Singular|Plural))
    ((=0 Zero|Singular|Plural)):other

plural with placeholder

    ((#{count} Singular|#{count} Plural))
    ((#{other} Singular|#{other} Plural)):other

plural with placeholder and attributes

    ((#{count :attr_name} Singular|#{count} Plural))
    ((#{other :attr_name} Singular|#{other} Plural)):other

    $expanded = $obj->expand_babel_fish($babel_fish_text, $count);
    $expanded = $obj->expand_babel_fish($babel_fish_text, count => $count);
    $expanded = $obj->expand_babel_fish($babel_fish_text, { count => $count, key => $value });

=head1 JAVASCRIPT

Inside of this distribution is a directory named javascript.
For more information see:
L<Locale::TextDomain::OO::JavaScript|Locale::TextDomain::OO::JavaScript>

This script depends on L<http://jquery.com/>.

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run the *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<List::Util|List::Util>

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<MooX::Types::MooseLike|MooX::Types::MooseLike>

L<Scalar::Util|Scalar::Util>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<https://github.com/nodeca/babelfish>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
