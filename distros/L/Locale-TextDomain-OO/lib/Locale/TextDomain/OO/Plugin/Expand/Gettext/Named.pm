package Locale::TextDomain::OO::Plugin::Expand::Gettext::Named; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(cluck confess);
use Hash::Util qw(lock_keys);
use Locale::Utils::PlaceholderNamed;
use Moo::Role;
use Try::Tiny;
use namespace::autoclean;

our $VERSION = '1.016';

requires qw(
    translate
    filter
    run_filter
    category
    domain
);

has _shadow_domains_named => (
    is      => 'rw',
    default => sub { [] },
);

has _shadow_categories_named => (
    is      => 'rw',
    default => sub { [] },
);

has expand_gettext_named => (
    is      => 'rw',
    default => sub {
        return Locale::Utils::PlaceholderNamed->new;
    },
);

my $begin_d = sub {
    my ($self, $domain) = @_;

    defined $domain
        or confess 'Domain is not defined';
    push
        @{ $self->_shadow_domains_named },
        $self->domain;
    $self->domain($domain);

    return $self;
};

my $begin_c = sub {
    my ($self, $category) = @_;

    defined $category
        or confess 'Category is not defined';
    push
        @{ $self->_shadow_categories_named },
        $self->category;
    $self->category($category);

    return $self;
};

my $end_d = sub {
    my $self = shift;

    if ( ! @{ $self->_shadow_domains_named } ) {
        cluck 'Tried to get the domain from stack but no domain is not stored';
        return $self;
    }
    $self->domain( pop @{ $self->_shadow_domains_named } );

    return $self;
};

my $end_c = sub {
    my $self = shift;

    if ( ! @{ $self->_shadow_categories_named } ) {
        cluck 'Tried to get the category from stack but no category is stored',
        return $self;
    }
    $self->category( pop @{ $self->_shadow_categories_named } );

    return $self;
};

sub locn {
    my ($self, @args) = @_;

    my $arg_ref = ref $args[0] eq 'HASH' ? $args[0] : { @args };
    try {
        lock_keys( %{$arg_ref}, qw( category domain context text plural replace ) );
        exists $arg_ref->{plural}
            or return;
        lock_keys( %{ $arg_ref->{plural} }, qw( singular plural count ) );
    }
    catch {
        confess $_;
    };

    $arg_ref->{domain}
        and $self->$begin_d( $arg_ref->{domain} );
    $arg_ref->{category}
        and $self->$begin_c( $arg_ref->{category} );
    my $translation
        = exists $arg_ref->{text}
        ? $self->translate(
            @{$arg_ref}{ qw( context text ) },
        )
        : exists $arg_ref->{plural}
        ? $self->translate(
            $arg_ref->{context},
            @{ $arg_ref->{plural} }{ qw( singular plural count ) },
            1,
        )
        : q{};
    $arg_ref->{replace}
        and $translation = $self->expand_gettext_named->expand_named(
            $translation,
            $arg_ref->{replace},
        );
    $self->filter
        and $self->run_filter(\$translation);
    if ( exists $arg_ref->{text} || exists $arg_ref->{plural} ) {
        $arg_ref->{domain}
            and $self->$end_d;
        $arg_ref->{category}
            and $self->$end_c;
    }

    return $translation;
}

sub Nlocn { ## no critic (Capitalization)
    my (undef, @args) = @_;

    my $arg_ref = ref $args[0] eq 'HASH' ? $args[0] : { @args };

    return wantarray ? @args : $args[0];
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Expand::Gettext::Named - Additional gettext methods locn, Nlocn

$Id: Named.pm 545 2014-10-30 13:23:00Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Plugin/Expand/Gettext/Named.pm $

=head1 VERSION

1.016

=head1 DESCRIPTION

This module provides hash or hash reference based methods.

=head1 SYNOPSIS

    my $loc = Locale::Text::TextDomain::OO->new(
        plugins => [ qw (
            Expand::Gettext::Named
            ...
        )],
        ...
    );

Optional type formatting or grammar stuff see
L<Locale::Utils::PlaceholderNamed|Locale::Utils::PlaceholderNamed>
for possible methods.

    $loc->expand_gettext_named->modifier_code($code_ref);

=head1 SUBROUTINES/METHODS

=head2 method expand_gettext_named

Returns the Locale::Utils::PlaceholderNamed object
to be able to set some options.

    my $expander_object = $self->expand_gettext_named;

e.g.

    $self->expand_gettext_name->modifier_code(
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

=head2 method locn

The method accepts hash or hash reference parameters.

=head3 Translate only

    print $loc->locn(
        text => 'Hello World!',
    );

    print $loc->locn(
        {
            text => 'Hello World!',
        },
    );

=head3 Expand named placeholders

    print $loc->locn(
        text    => 'Hello {name}!',
        replace => { name => 'Steffen' },
    );

=head3 Plural

    print $loc->locn(
        plural => {
            singular => 'one file read',
            plural   => 'a lot of files read',
            count    => $file_count, # number to select the right plural form
        },
    );

=head3 Plural and expand named placeholders

    print $loc->locn(
        plural => {
            singular => '{count:num} file read',
            plural   => '{count:num} files read',
            count    => $file_count,
        },
        replace => {
            count => $file_count,
        },
    );

=head3 What is the meaning of C<{count:numf}> or alternative C<{count :numf}>?

That is a attribute.
If there is such an attribute like C<:numf>
and the modifier_code is set,
the placeholder value will be modified before replacement.

Think about the attribute names.
Too technical names are able to destroy the translation process
by translation office stuff.

For better automatic translation use the reserved attribute C<:num>
and tag all numeric placeholders.

You are allowed to set multiple attributes like C<{count :num :numf}>
The resulting attribute string is then C<num :numf>.

=head3 Context

    print $loc->locn(
        context => 'time',
        text    => 'to',
    );

    print $loc->locn(
        context => 'destination',
        text    => 'to',
    );

=head3 Context and expand named placeholders

    print $loc->locn(
        context => 'destination',
        text    => 'from {town_from} to {town_to}',
        replace => {
            town_from => 'Chemnitz',
            town_to   => 'Erlangen',
        },
    );

=head3 Context and plural

    print $loc->locn(
        context => 'maskulin',
        plural  => {
            singular => 'Dear friend',
            plural   => 'Dear friends',
            count    => $friends,
        },
    );

=head3 Context, plural and expand named placeholders

    print $loc->locn(
        context => 'maskulin',
        plural  => {
            singular => 'Mr. {name} has {count:num} book.',
            plural   => 'Mr. {name} has {count:num} books.',
            count    => $book_count,
        },
        replace => {
            name  => $name,
            count => $book_count,
        },
    );

=head2 method Nlocn to mark the translation for extraction only

The method name is N prefixed so it results in Nlocn.

The extractor looks for C<locn(...>
and has no problem with C<< $loc->Nlocn(... >>.

This is the idea of the N-Methods.

    my %hash     = $loc->Nlocn( ... );
    my $hash_ref = $loc->Nlocn( { ... } );

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Hash::Util|Hash::Util>

L<Locale::Utils::PlaceholderNamed|Locale::Utils::PlaceholderNamed>

L<Moo::Role|Moo::Role>

L<Try::Tiny|Try::Tiny>

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
