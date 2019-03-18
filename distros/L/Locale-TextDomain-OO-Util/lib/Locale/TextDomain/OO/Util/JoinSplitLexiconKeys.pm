package Locale::TextDomain::OO::Util::JoinSplitLexiconKeys; ## no critic (TidyCode)

use strict;
use warnings;
use Locale::TextDomain::OO::Util::Constants;
use namespace::autoclean;

our $VERSION = '4.001';

sub instance {
    return __PACKAGE__;
}

sub join_lexicon_key {
    my ( undef, $arg_ref ) = @_;

    my $const = Locale::TextDomain::OO::Util::Constants->instance;

    return join $const->lexicon_key_separator,
        (
            ( defined $arg_ref->{language} && length $arg_ref->{language} )
            ? $arg_ref->{language}
            : 'i-default'
        ),
        ( defined $arg_ref->{category} ? $arg_ref->{category} : q{} ),
        ( defined $arg_ref->{domain}   ? $arg_ref->{domain}   : q{} ),
        ( defined $arg_ref->{project}  ? $arg_ref->{project}  : ()  );
}

sub split_lexicon_key {
    my ( undef, $lexicon_key ) = @_;

    defined $lexicon_key
        or return {};
    my $const = Locale::TextDomain::OO::Util::Constants->instance;
    my ( $language, $category, $domain, $project )
        = split $const->lexicon_key_separator, $lexicon_key, 4; ## no critic (Magic Numbers)

    return {(
        language => $language,
        category => $category,
        domain   => $domain,
        ( defined $project ? ( project  => $project ) : () ),
    )};
}

my $length_or_empty_list = sub {
    my $item = shift;

    defined $item or return;
    length $item or return;

    return $item;
};

sub join_message_key {
    my ( undef, $arg_ref, $format ) = @_;

    my $const = Locale::TextDomain::OO::Util::Constants->instance;

    return join $const->msg_key_separator($format),
        (
            join $const->plural_separator($format),
                $length_or_empty_list->( $arg_ref->{msgid} ),
                $length_or_empty_list->( $arg_ref->{msgid_plural} ),
        ),
        $length_or_empty_list->( $arg_ref->{msgctxt} );
}

sub split_message_key {
    my ( undef, $message_key, $format ) = @_;

    defined $message_key
        or return {};
    my $const = Locale::TextDomain::OO::Util::Constants->instance;
    my ( $text, $context )
        = split $const->msg_key_separator($format), $message_key;
    defined $text
        or $text = q{};
    my ( $singular, $plural )
        = split $const->plural_separator($format), $text;
    defined $singular
        or $singular = q{};
    my $list_if_defined = sub { return defined shift() ? @_ : () };

    return {(
        msgid => $singular,
        $list_if_defined->( $context,  msgctxt      => $context ),
        $list_if_defined->( $plural,   msgid_plural => $plural ),
    )};
}

sub join_message {
    my ( $self, $message_key, $message_value_ref, $format ) = @_;

    defined $message_key
        or $message_key = q{};
    ref $message_value_ref eq 'HASH'
        or $message_value_ref = {};

    return {(
        %{$message_value_ref},
        %{ $self->split_message_key($message_key, $format) },
    )};
}

sub split_message {
    my ( $self, $message, $format ) = @_;

    ref $message eq 'HASH'
        or $message = {};

    my $message_key = $self->join_message_key(
        {(
            map {
                $_ => delete $message->{$_};
            }
            qw( msgctxt msgid msgid_plural )
        )},
        $format,
    );

    return $message_key, $message;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Util::JoinSplitLexiconKeys
- Handle lexicon and message key

=head1 VERSION

4.001

$Id: JoinSplitLexiconKeys.pm 715 2018-06-04 15:08:31Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/Locale-TextDomain-OO-Util/trunk/lib/Locale/TextDomain/OO/Util/JoinSplitLexiconKeys.pm $

=head1 SYNOPSIS

    use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;

    my $keys_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;

=head1 DESCRIPTION

Module to handle the lexicon and message key.

=head1 SUBROUTINES/METHODS

=head2 method instance

see SYNOPSIS

=head2 method join_lexicon_key

    $lexicon_key = $keys_util->join_lexicon_key({
        category => 'LC_MESSAGES', # default q{}
        domain   => 'TextDomain',  # default q{}
        language => 'de-de',       # default 'i-default' = developer English
        # mostly not needed
        project  => 'myProject',   # default not exists
    });

=head2 method split_lexicon_key

This method is the reverse implementation of method join_lexicon_key.

    $hash_ref = $keys_util->split_lexicon_key($lexicon_key);

=head2 method join_message_key

    $message_key = $keys_util->join_message_key({
        msgctxt      => 'my context',
        msgid        => 'simple text or singular',
        msgid_plural => 'plural',
    });

JSON format

    $message_key = $keys_util->join_message_key(
        {
            msgctxt      => 'my context',
            msgid        => 'simple text or singular',
            msgid_plural => 'plural',
        },
        'JSON',
    );

=head2 method split_message_key

This method is the reverse implementation of method join_message_key.

    $hash_ref = $keys_util->split_message_key($message_key);

JSON format

    $hash_ref = $keys_util->split_message_key($message_key, 'JSON');

=head2 method join_message

This method puts all data into the message_ref

    $message_ref = $keys_util->join_message(
        $message_key,       # joined msgctxt, msgid, msgid_plural
        $message_value_ref, # all other as hash reference
    );

JSON format

    $message_ref = $keys_util->join_message(
        $message_key,       # joined msgctxt, msgid, msgid_plural
        $message_value_ref, # all other as hash reference
        'JSON',
    );

=head2 method split_message

This method splits the message reference into a message key and the rest

    ( $message_key, $message_value_ref )
        = $keys_util->split_message($message_ref);

JSON format

    ( $message_key, $message_value_ref )
        = $keys_util->split_message($message_ref, 'JSON');

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Locale::TextDomain::OO::Util::Constants|Locale::TextDomain::OO::Util::Constants>

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

Copyright (c) 2014 - 2018,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
