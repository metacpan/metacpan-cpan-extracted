package Locale::TextDomain::OO::Translator; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use Class::Load qw(load_class);
use Locale::TextDomain::OO::Singleton::Lexicon;
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use Moo;
use MooX::StrictConstructor;
use MooX::Types::MooseLike::Base qw(Str);
use namespace::autoclean;

our $VERSION = '1.026';

with qw(
    Locale::TextDomain::OO::Role::Logger
);

my $loaded_plugins;
sub load_plugins {
    my ( $class, @args ) = @_;

    my %arg_of = @args == 1 ? %{ $args[0] } : @args;
    my $plugins = delete $arg_of{plugins};
    if ( $plugins ) {
        ref $plugins eq 'ARRAY'
            or confess 'Attribute plugins expected as ArrayRef';

        my $current_plugins = join ', ', sort @{$plugins};
        if ( defined $loaded_plugins ) {
            length $current_plugins
                and $loaded_plugins ne $current_plugins
                and confess
                    "Too late to load plugins $current_plugins.",
                    " Another method new was called before with plugins $loaded_plugins";
        }
        else {
            for my $plugin ( @{$plugins} ) {
                my $package = ( 0 == index $plugin, q{+} )
                    ? $plugin
                    : "Locale::TextDomain::OO::Plugin::$plugin";
                with $package;
            }
            $loaded_plugins = $current_plugins;
        }
    }
    if ( ! defined $loaded_plugins ) {
        $loaded_plugins = q{};
    }

    return \%arg_of;
}

has language => (
    is      => 'rw',
    isa     => Str,
    default => 'i-default',
);

has category => (
    is      => 'rw',
    isa     => Str,
    default => q{},
);

has domain => (
    is      => 'rw',
    isa     => Str,
    default => q{},
);

has project => (
    is  => 'rw',
    isa => sub {
        my $project = shift;
        defined $project
            or return;
        return Str->($project);
    },
);

has filter => (
    is  => 'rw',
    isa => sub {
        my $arg = shift;
        # Undef
        defined $arg
            or return;
        # CodeRef
        ref $arg eq 'CODE'
            and return;
        confess "$arg is not Undef or CodeRef";
    },
);

sub _calculate_multiplural_index {
    my ($self, $count_ref, $plural_code, $lexicon, $lexicon_key) = @_;

    my $nplurals = $lexicon->{ q{} }->{multiplural_nplurals}
        or confess qq{X-Multiplural-Nplurals not found in lexicon "$lexicon_key"};
    my @counts = @{$count_ref}
        or confess 'Count array is empty';
    my $index = 0;
    while (@counts) {
        $index *= $nplurals;
        my $count = shift @counts;
        $index += $plural_code->($count);
    }

    return $index;
}

# The reason we need that here is "gettext_to_maketext => 1" during load lexicon.
# That escaps all [ ] before it is changing %1 to [_1] or similar.
# And so all none gettext strings are also involved.
my $escape_maketext = sub {
    my $string = shift;

    defined $string
        or return $string;
    $string =~ s{ ( [\[\]] ) }{~$1}xmsg;

    return $string;
};
my $unescape_maketext = sub {
    my $string = shift;

    defined $string
        or return $string;
    $string =~ s{ [~] ( [\[\]] ) }{$1}xmsg;

    return $string;
};

sub translate { ## no critic (ExcessComplexity ManyArgs)
    my ($self, $msgctxt, $msgid, $msgid_plural, $count, $is_n, $plural_callback) = @_;

    my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;
    my $lexicon_key = $key_util->join_lexicon_key({(
        map {
            $_ => $self->$_;
        }
        qw( language category domain project )
    )});
    my $lexicon = Locale::TextDomain::OO::Singleton::Lexicon->instance->data;
    $lexicon = exists $lexicon->{$lexicon_key}
        ? $lexicon->{$lexicon_key}
        : ();
    my $ext_lexicon = do {
        my $lexicon_class = $lexicon->{ q{} }->{lexicon_class};
        $lexicon_class ? load_class($lexicon_class)->instance : ();
    };

    my $msg_key = $key_util->join_message_key({
        msgctxt      => $msgctxt,
        msgid        => $msgid,
        msgid_plural => $msgid_plural,
    });
    my $maketext_msg_key = sub {
        return $key_util->join_message_key({
            msgctxt      => $escape_maketext->($msgctxt),
            msgid        => $escape_maketext->($msgid),
            msgid_plural => $escape_maketext->($msgid_plural),
        });
    };
    my $msg_ref
        = exists $lexicon->{$msg_key}
        ? $lexicon->{$msg_key}
        : exists $lexicon->{ $maketext_msg_key->() }
        ? {
            msgstr => $unescape_maketext->(
                $lexicon->{ $maketext_msg_key->() }->{msgstr},
            ),
        }
        : $ext_lexicon
        ? $ext_lexicon->fetch_from_lexicon($lexicon_key, $msg_key)
          || {
            msgstr => $unescape_maketext->(
                $ext_lexicon->fetch_from_lexicon( $lexicon_key, $maketext_msg_key->() ),
            ),
        }
        : ();
    if ( $plural_callback ) {
        $plural_callback->(
            $lexicon->{ q{} }->{plural_code}
            || confess qq{Plural-Forms not found in lexicon "$lexicon_key"},
        );
    }
    elsif ( $is_n ) {
        my $plural_code = $lexicon->{ q{} }->{plural_code}
            or confess qq{Plural-Forms not found in lexicon "$lexicon_key"};
        my $multiplural_index
            = ref $count eq 'ARRAY'
            ? $self->_calculate_multiplural_index($count, $plural_code, $lexicon, $lexicon_key)
            : $plural_code->($count);
        my $msgstr_plural = $msg_ref->{msgstr_plural}->[$multiplural_index];
        if ( ! defined $msgstr_plural ) { # fallback
            $msgstr_plural = $plural_code->($count)
                ? $msgid_plural
                : $msgid;
            my $text = $lexicon
                ? qq{Using lexicon "$lexicon_key".}
                : qq{Lexicon "$lexicon_key" not found.};
            $self->language ne 'i-default'
                and $self->logger
                and $self->logger->(
                    (
                        sprintf
                            '%s msgstr_plural not found for msgctxt=%s, msgid=%s, msgid_plural=%s.',
                            $text,
                            ( defined $msgctxt      ? qq{"$msgctxt"}      : 'undef' ),
                            ( defined $msgid        ? qq{"$msgid"}        : 'undef' ),
                            ( defined $msgid_plural ? qq{"$msgid_plural"} : 'undef' ),
                    ),
                    {
                        object => $self,
                        type   => 'warn',
                        event  => 'translation,fallback',
                    },
                );
        }
        return $msgstr_plural;
    }
    my $msgstr = exists $msg_ref->{msgstr}
        ? $msg_ref->{msgstr}
        : ();
    if ( ! defined $msgstr ) { # fallback
        $msgstr = $msgid;
        my $text = $lexicon
            ? qq{Using lexicon "$lexicon_key".}
            : qq{Lexicon "$lexicon_key" not found.};
        $self->language ne 'i-default'
            and $self->logger
            and $self->logger->(
                (
                    sprintf
                        '%s msgstr not found for msgctxt=%s, msgid=%s.',
                        $text,
                        ( defined $msgctxt ? qq{"$msgctxt"} : 'undef' ),
                        ( defined $msgid   ? qq{"$msgid"}   : 'undef' ),
                ),
                {
                    object => $self,
                    type  => 'warn',
                    event => 'translation,fallback',
                },
            );
    }

    return $msgstr;
}

sub run_filter {
    my ( $self, $translation_ref ) = @_;

    $self->filter
        or return $self;
    $self->filter->($self, $translation_ref);

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Translator - Translator class

$Id: Translator.pm 637 2017-02-23 16:21:35Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Translator.pm $

=head1 VERSION

1.026

=head1 DESCRIPTION

This is the translator class. Extend that class with plugins (Roles).

=head1 SYNOPSIS

    require Locale::TextDomain::OO::Translator;
    Locale::TextDomain::OO::Translator->new(
        Locale::TextDomain::OO::Translator->load_plugins,
    );

=head1 SUBROUTINES/METHODS

=head2 method new

see SYNOPSIS

=head2 class method load_plugins

Called before new to load the plugins.

    $hash_ref = Locale::TextDomain::OO::Translator->load_plugins;

=head2 method translate

Called from Plugins only.

    $translation = $self->translate(... lots of parameters ...);

=head2 method run_filter

Called from plugins only.

    $self->run_filter(\$translation);

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Read the file README there.
Then run the *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<Carp|Carp>

L<Class::Load|Class::Load>

L<Locale::TextDomain::OO::Singleton::Lexicon|Locale::TextDomain::OO::Singleton::Lexicon>

L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
