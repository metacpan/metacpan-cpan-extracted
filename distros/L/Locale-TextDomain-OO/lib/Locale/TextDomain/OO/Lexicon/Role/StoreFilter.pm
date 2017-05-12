package Locale::TextDomain::OO::Lexicon::Role::StoreFilter; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use Clone qw(clone);
use Locale::TextDomain::OO::Singleton::Lexicon;
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(HashRef);
use namespace::autoclean;

our $VERSION = '1.017';

for my $name ( qw( language category domain project ) ) {
    has "filter_$name" => (
        is  => 'rw',
        isa => sub {
            my $value = shift;
            defined $value
                or return;
            my $ref = ref $value;
            $ref eq 'Regexp'
                and return;
            $ref eq 'CODE'
                and return;
            $ref
                and confess 'Undef, Str, RegexpRef or CodeRef expected';
        },
    );
}

sub clear_filter {
    my $self = shift;

    $self->filter_language(undef);
    $self->filter_category(undef);
    $self->filter_domain(undef);
    $self->filter_project(undef);

    return $self;
};

has data => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    default => sub { {} },
);

my $is_expected_lexicon_key = sub {
    my ( $self, $lexicon_key ) = @_;

    my $key_ref = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys
        ->instance
        ->split_lexicon_key($lexicon_key);
    NAME:
    for my $name ( qw( language category domain project ) ) {
        defined $key_ref->{$name}
            or $key_ref->{$name} = q{};
        my $method = "filter_$name";
        my $filter = $self->$method;
        if ( defined $filter ) {
            local $_ = $key_ref->{$name};
            my $ref = ref $filter;
            $ref eq 'Regexp'
                ? $_ =~ $filter
                : $ref eq 'CODE'
                ? $filter->($method)
                : $_ eq $filter
                or return;
        }
    }

    return 1;
};

my $prepare_lexicon = sub {
    my ( $self, $lexicon_ref ) = @_;

    $lexicon_ref = clone($lexicon_ref);

    # not able to serialize code references
    delete $lexicon_ref->{ q{} }->{plural_code};

    my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;
    MESSAGE_KEY:
    for my $message_key ( keys %{$lexicon_ref} ) {
        length $message_key
            or next MESSAGE_KEY;
        my $new_message_key = $key_util->join_message_key(
            $key_util->split_message_key($message_key),
            'JSON',
        );
        $lexicon_ref->{$new_message_key} = delete $lexicon_ref->{$message_key};
    }

    return $lexicon_ref;
};

sub copy {
    my $self = shift;

    my $data = Locale::TextDomain::OO::Singleton::Lexicon->instance->data;
    for my $lexicon_key ( keys %{$data} ) {
        $self->$is_expected_lexicon_key($lexicon_key)
            and $self->data->{$lexicon_key}
                = $self->$prepare_lexicon( $data->{$lexicon_key} );
    }

    return $self;
}

sub remove {
    my $self = shift;

    my $data = $self->data;
    for my $lexicon_key ( keys %{$data} ) {
        $self->$is_expected_lexicon_key($lexicon_key)
            and delete $data->{$lexicon_key};
    }

    return $self;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Lexicon::Role::StoreFilter - Filters the lexicon data before stored

$Id: StoreFilter.pm 573 2015-02-07 20:59:51Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Lexicon/Role/StoreFilter.pm $

=head1 VERSION

1.017

=head1 DESCRIPTION

This module filters the lexicon data before stored.

The idea is: Not all parts of lexicon are used by other programming languages.

Implements attributes
"filter_language", "filter_category", "filter_domain" and "filter_project".
There it is possible to store
undef for ignore filter,
a string to check equal,
a regex reference to match
or a code reference to do some more complicate things.

That filter removes also the key "plural_code" from header.
That is an already prepared Perl code reference
to calculate what plural form should used.
The other language has to create the code again from key header key "plural".
That contains that pseudo code from po/mo file
without C<;> and/or C<\n> at the end.

=head1 SYNOPSIS

    with qw(
        Locale::TextDomain::OO::Lexicon::Role::StoreFilter
    );

Usage of that optional filter

    use Locale::TextDomain::OO::Lexicon::Store...;

    my $obj = Locale::TextDomain::OO::Lexicon::Store...->new(
        ...
        # all parameters optional
        filter_language => undef,
        filter_category => 'cat1',
        filter_domain   => qr{ \A dom }xms,
        filter_project  => sub {
            my $filter_name = shift;   # $filter_name eq 'filter_project'
            return $_ eq 'my project'; # $_ contains the value
        },
    );
    $obj->copy;
    $obj->clear_filter;
    $obj->filter_language('en');
    $obj->remove;
    $obj->to_...;

=head1 SUBROUTINES/METHODS

=head2 method filter_language, filter_category, filter_domain, filter_project

Set a filter as undef, string, regex or code reference.

=head2 method clear_filter

Set filter_language, filter_category, filter_domain, filter_project
to undef.

    $obj->clear_filter;

=head2 method copy

Copies lexicon entries with matching filter
from singleton lexicon to data (new lexicon).

    $obj->copy;

=head2 method remove

Removes lexicon entries with matching filter
from data (new lexicon).

    $obj->remove;

=head2 method data

Get back that filtered lexicon data.

    $data = $obj->data;

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Clone|Clone>

L<Locale::TextDomain::OO::Singleton::Lexicon|Locale::TextDomain::OO::Singleton::Lexicon>

L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>

L<Moo::Role|Moo::Role>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

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

Copyright (c) 2013 - 2015,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
