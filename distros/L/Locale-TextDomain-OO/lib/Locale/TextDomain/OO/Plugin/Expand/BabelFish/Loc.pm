package Locale::TextDomain::OO::Plugin::Expand::BabelFish::Loc; ## no critic (TidyCode)

use strict;
use warnings;
use Locale::Utils::PlaceholderBabelFish;
use Moo::Role;

our $VERSION = '1.027';

requires qw(
    translate
    filter
    run_filter
);

has expand_babel_fish_loc => (
    is      => 'rw',
    default => sub {
        return Locale::Utils::PlaceholderBabelFish->new;
    },
);

sub loc_b {
    my ($self, $msgid, @args) = @_;

    my $translation = $self->translate(
        undef,
        $msgid,
        undef,
        undef,
        undef,
        sub { $self->expand_babel_fish_loc->plural_code(shift) },
    );
    @args and $translation = $self->expand_babel_fish_loc->expand_babel_fish(
        $translation,
        @args == 1
            ? ( ref $args[0] eq 'HASH' ? %{ $args[0] } : $args[0] )
            : @args,
    );
    $self->filter
        and $self->run_filter(\$translation);

    return $translation;
}

sub loc_bp {
    my ($self, $msgctxt, $msgid, @args) = @_;

    my $translation = $self->translate(
        $msgctxt,
        $msgid,
        undef,
        undef,
        undef,
        sub { $self->expand_babel_fish_loc->plural_code(shift) },
    );
    @args and $translation = $self->expand_babel_fish_loc->expand_babel_fish(
        $translation,
        @args == 1
            ? ( ref $args[0] eq 'HASH' ? %{ $args[0] } : $args[0] )
            : @args,
    );
    $self->filter
        and $self->run_filter(\$translation);

    return $translation;
}

BEGIN {
    # Dummy methods for string marking.
    my $dummy = sub {
        my (undef, @more) = @_;
        return wantarray ? @more : $more[0];
    };
    no warnings qw(redefine); ## no critic (NoWarnings)
    *Nloc_b  = $dummy;
    *Nloc_bp = $dummy;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Expand::BabelFish::Loc - Additional BabelFish methods, prefixed with loc_b

$Id: $

$HeadURL: $

=head1 VERSION

1.027

=head1 DESCRIPTION

This module provides translation with BabelFish writing.

Use this plugin for multiple plurals in one phrase
otherwise use
L<Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc|Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc>
because that writing is much easier to read for a translation office.
Gettext writing has no or constructs and less cryptic chars inside.
The translation office needs no programmer experience.

=head1 SYNOPSIS

    my $loc = Locale::Text::TextDomain::OO->new(
        plugins => [ qw (
            Expand::BabelFish::Loc
            ...
        )],
        ...
    );

Optional type formatting or grammar stuff see
L<Locale::Utils::PlaceholderBabelFish|Locale::Utils::PlaceholderBabelFish>
for possible methods.

    $loc->expand_babel_fish_loc->modifier_code($code_ref);

=head1 SUBROUTINES/METHODS

=head2 method expand_babel_fish_loc

Returns the Locale::Utils::PlaceholderBabelFish object
to be able to set some options.

    my $expander_object = $self->expand_babel_fish_loc;

e.g.

    $self->expand_babel_fish_loc->plural_code(
        $loc->plural_code,
    );

    $self->expand_babel_fish_loc->modifier_code(
        sub {
            my ( $value, $attribute ) = @_;
            if ( $attribute eq 'numf' ) {
                # modify that numeric $value
                # e.g. change 1234.56 to 1.234,56 or 1,234.56
                ...
            }
            elsif ( $attribute eq 'accusative' ) {
                # modify the string with that grammar rule
                # e.g. needed for East-European languages
                # write grammar rules only on msgstr/msgstr_plural[n]
                # and not on msgid
                ...
            }
            ...
            return $value;
        },
    );

=head2 translation methods

How to build the method name?

Use loc_b and append this with "p".

 .------------------------------------------------------------------------.
 | Snippet | Description                                                  |
 |---------+--------------------------------------------------------------|
 | p       | Context is the first parameter.                              |
 '------------------------------------------------------------------------'

=head3 method loc_b

Translate only

    print $loc->loc_b(
        'Hello World!',
    );

=head3 method loc_bp

Context

    print $loc->loc_bp(
        'time', # Context
        'to',
    );

    print $loc->loc_bp(
        'destination', # Context
        'to',
    );

=head2 Methods to mark the translation for extraction only

How to build the method name?

Use Nloc_b and append this with "p".

 .------------------------------------------------------------------------.
 | Snippet | Description                                                  |
 |---------+--------------------------------------------------------------|
 | p       | Context is the first parameter.                              |
 '------------------------------------------------------------------------'

=head3 methods Nloc_b, Nloc_bp

The extractor looks for C<loc_b('...>
and has no problem with C<< $loc->Nloc_b('... >>.

This is the idea of the N-Methods.

    $loc->Nloc_b('...');
    $loc->Nloc_bp('...', '...');

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Locale::Utils::PlaceholderBabelFish|Locale::Utils::PlaceholderBabelFish>

L<Moo::Role|Moo::Role>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

L<Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc|Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
