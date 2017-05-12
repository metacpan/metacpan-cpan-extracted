package Locale::TextDomain::OO::Plugin::Expand::Gettext; ## no critic (TidyCode)

use strict;
use warnings;
use Locale::Utils::PlaceholderNamed;
use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.014';

requires qw(
    translate
    filter
    run_filter
);

has expand_gettext => (
    is      => 'rw',
    default => sub {
        return Locale::Utils::PlaceholderNamed->new;
    },
);

sub __x {
    my ($self, $msgid, @args) = @_;

    my $translation = $self->translate(undef, $msgid);
    @args and $translation = $self->expand_gettext->expand_named(
        $translation,
        @args == 1 ? %{ $args[0] } : @args,
    );
    $self->filter
        and $self->run_filter(\$translation);

    return $translation;
}

sub __nx {
    my ($self, $msgid, $msgid_plural, $count, @args) = @_;

    my $translation = $self->translate(undef, $msgid, $msgid_plural, $count, 1);
    @args and $translation = $self->expand_gettext->expand_named(
        $translation,
        @args == 1 ? %{ $args[0] } : @args,
    );
    $self->filter
        and $self->run_filter(\$translation);

    return $translation;
}

sub __px {
    my ($self, $msgctxt, $msgid, @args) = @_;

    my $translation = $self->translate($msgctxt, $msgid);
    @args and $translation = $self->expand_gettext->expand_named(
        $translation,
        @args == 1 ? %{ $args[0] } : @args,
    );
    $self->filter
        and $self->run_filter(\$translation);

    return $translation;
}

sub __npx { ## no critic (ManyArgs)
    my ($self, $msgctxt, $msgid, $msgid_plural, $count, @args) = @_;

    my $translation = $self->translate($msgctxt, $msgid, $msgid_plural, $count, 1);
    @args and $translation = $self->expand_gettext->expand_named(
        $translation,
        @args == 1 ? %{ $args[0] } : @args,
    );
    $self->filter
        and $self->run_filter(\$translation);

    return $translation;
}

BEGIN {
    no warnings qw(redefine); ## no critic (NoWarnings)
    *__   = \&__x;
    *__n  = \&__nx;
    *__p  = \&__px;
    *__np = \&__npx;

    # Dummy methods for string marking.
    my $dummy = sub {
        my (undef, @more) = @_;
        return wantarray ? @more : $more[0];
    };
    *N__    = $dummy;
    *N__x   = $dummy;
    *N__n   = $dummy;
    *N__nx  = $dummy;
    *N__p   = $dummy;
    *N__px  = $dummy;
    *N__np  = $dummy;
    *N__npx = $dummy;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Expand::Gettext - Additional gettext methods, prefixed with __

$Id: Gettext.pm 545 2014-10-30 13:23:00Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Plugin/Expand/Gettext.pm $

=head1 VERSION

1.014

=head1 DESCRIPTION

This module provides an additional getext methods
for static domain and category handling.

=head1 SYNOPSIS

    my $loc = Locale::Text::TextDomain::OO->new(
        plugins => [ qw (
            Expand::Gettext
            ...
        )],
        ...
    );

Optional type formatting or grammar stuff see
L<Locale::Utils::PlaceholderNamed|Locale::Utils::PlaceholderNamed>
for possible methods.

    $loc->expand_gettext->modifier_code($code_ref);

=head1 SUBROUTINES/METHODS

=head2 method expand_gettext

Returns the Locale::Utils::PlaceholderNamed object
to be able to set some options.

    my $expander_object = $self->expand_gettext;

e.g.

    $self->expand_gettext->modifier_code(
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

Use __ and append this with "n", "p" and/or "x" in alphabetic order.

 .------------------------------------------------------------------------.
 | Snippet | Description                                                  |
 |---------+--------------------------------------------------------------|
 | __      | Special marked for extraction.                               |
 | n       | Using plural forms.                                          |
 | p       | Context is the first parameter.                              |
 | x       | Last parameters as hash/hash_ref are for named placeholders. |
 '------------------------------------------------------------------------'

=head3 method __

Translate only

    print $loc->__(
        'Hello World!',
    );

=head3 method __x

Expand named placeholders

    print $loc->__x(
        'Hello {name}!',
        # hash or hash_ref
        name => 'Steffen',
    );

=head3 method __n

Plural

    print $loc->__n(
        'one file read',       # Singular
        'a lot of files read', # Plural
        $file_count,           # number to select the right plural form
    );

=head3 method __nx

Plural and expand named placeholders

    print $loc->__nx(
        '{count:num} file read',
        '{count:num} files read',
        $file_count,
        # hash or hash_ref
        count => $file_count,
    );

=head3 What is the meaning of C<{count:num}> or alternative C<{count :num}>?

That is a attribute.
If there is such an attribute like C<:num>
and the modifier_code is set,
the placeholder value will be modified before replacement.

Think about the attribute names.
Too technical names are able to destroy the translation process
by translation office stuff.

For better automatic translation use the reserved attribute C<:num>
and tag all numeric placeholders.

You are allowed to set multiple attributes like C<{count :num :numf}>
The resulting attribute string is then C<num :numf>.

=head3 method __p

Context

    print $loc->__p(
        'time', # Context
        'to',
    );

    print $loc->__p(
        'destination', # Context
        'to',
    );

=head3 method __px

Context and expand named placeholders

    print $loc->__px(
        'destination',
        'from {town_from} to {town_to}',
        # hash or hash_ref
        town_from => 'Chemnitz',
        town_to   => 'Erlangen',
    );

=head3 method __np

Context and plural

    print $loc->__np(
        'maskulin',
        'Dear friend',
        'Dear friends',
        $friends,
    );

=head3 method __npx

Context, plural and expand named placeholders

    print $loc->__npx(
        'maskulin',
        'Mr. {name} has {count:num} book.',
        'Mr. {name} has {count:num} books.',
        $book_count,
        # hash or hash_ref
        name  => $name,
        count => $book_count,
    );


=head2 Methods to mark the translation for extraction only

How to build the method name?

Use N__ and append this with "n", "p" and/or "x" in alphabetic order.

 .------------------------------------------------------------------------.
 | Snippet | Description                                                  |
 |---------+--------------------------------------------------------------|
 | __      | Special marked for extraction.                               |
 | n       | Using plural forms.                                          |
 | p       | Context is the first parameter.                              |
 | x       | Last parameters as hash/hash_ref are for named placeholders. |
 '------------------------------------------------------------------------'

=head3 methods N__, N__x, N__n, N__nx, N__p, N__px, N__np, N__npx

The extractor looks for C<__('...>
and has no problem with C<< $loc->N__('... >>.

This is the idea of the N-Methods.

    $loc->N__('...');
    $loc->N__x('...', ...);
    ...

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Locale::Utils::PlaceholderNamed|Locale::Utils::PlaceholderNamed>

L<Moo::Role|Moo::Role>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 - 2014,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
