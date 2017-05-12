package Locale::TextDomain::OO::Singleton::Lexicon; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use Moo;
use MooX::StrictConstructor;
use namespace::autoclean;

our $VERSION = '1.026';

with qw(
    MooX::Singleton
);

has data => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
        my $self = shift;
        return {
            # empty lexicon of developer English
            'i-default::' => {
                q{} => {
                    nplurals    => 2,
                    plural      => 'n != 1',
                    plural_code => sub { return shift != 1 },
                },
            },
        };
    },
);

sub move_lexicon {
    my ( $self, $from, $to ) = @_;

    defined $from
        or confess 'Undef is not a lexicon name to move from';
    exists $self->data->{$from}
        or confess qq{Missing lexicon "$from" to move from};
    defined $to
        or confess 'Undef is not a lexicon name to move to';
    ( my $data_to, $self->data->{$to} ) = delete @{ $self->data }{ $to, $from };

    return $data_to;
}

sub delete_lexicon {
    my ( $self, $name ) = @_;

    defined $name
        or confess 'Undef is not a lexicon name to delete';

    return delete $self->data->{$name};
}

sub merge_lexicon {
    my ( $self, $from1, $from2, $to ) = @_;
    defined $from1
        or confess 'Undef is not a lexicon name to merge from';
    defined $from2
        or confess 'Undef is not a lexicon name to merge from';
    exists $self->data->{$from1}
        or confess qq{Missing lexicon "$from1" to merge from};
    exists $self->data->{$from2}
        or confess qq{Missing lexicon "$from2" to merge from};
    defined $to
        or confess 'Undef is not a lexicon name to merge to';

    $self->data->{$to} = {
        %{ $self->data->{$from1} },
        %{ $self->data->{$from2} },
    };

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Singleton::Lexicon - Provides singleton lexicon access

$Id: Lexicon.pm 617 2015-08-22 05:39:27Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Singleton/Lexicon.pm $

=head1 VERSION

1.026

=head1 DESCRIPTION

This module provides the singleton lexicon access
for L<Locale::TextDomain:OO|Locale::TextDomain:OO>.

=head1 SYNOPSIS

    use Locale::TextDomain::OO::Singleton::Lexicon;

    $lexicon_data = Locale::TextDomain::OO::Singleton::Lexicon->instance->data;

=head1 SUBROUTINES/METHODS

=head2 method new

exists but makes no sense

=head2 method instance

see SYNOPSIS

exists but makes no sense

=head2 method data

Get back the lexicon hash reference
to fill the lexicon or to read from lexicon.

    $lexicon_data = Locale::TextDomain::OO::Singleton::Lexicon->instance->data;

=head2 method merge_lexicon

Merge ist mostly used to join data of a language
to create data for a region with some region different data.

    $instance->merge_lexicon('de::', 'de-at::', 'de-at::');

=head2 method move_lexicon

Move is typical used to move the "i-default::" lexicon
into your domain and category.
With that lexicon without messages you are able to translate
because the header with plural forms is set.
With no lexicon you would get a missing "plural forms"-error during translation.

    $deleted_lexicon = $instance->move_lexicon(
        'i-default::',
        'i-default:LC_MESSAGES:domain',
    );

=head2 method delete_lexicon

Delete a lexicon from data.

    $deleted_lexicon = $instance->delete_lexicon('de::');

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<namespace::autoclean|namespace::autoclean>

L<MooX::Singleton|MooX::Singleton>

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
