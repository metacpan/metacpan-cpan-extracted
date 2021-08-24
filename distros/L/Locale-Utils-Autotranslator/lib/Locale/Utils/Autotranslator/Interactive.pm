package Locale::Utils::Autotranslator::Interactive; ## no critic (TidyCode)

use strict;
use warnings;
use Encode qw(decode_utf8);
use Moo;
use namespace::autoclean;

our $VERSION = '1.011';

extends qw(
    Locale::Utils::Autotranslator
);

sub translate_text {
    my ( $self, $msgid ) = @_;

    $self->comment('translated by: interactive');
    () = printf
        "\n"
        . "\n"
        . "========== %s -> %s ==========\n"
        . "%s\n"
        . "========== paste now, press Enter and <CTRL> D (or line __END__ anywhere) ==========\n",
        $self->developer_language,
        $self->language,
        $msgid;
    my $msgstr = q{};
    LOOP: {
        local $_ = <STDIN>;
        defined
            or last LOOP;
        m{\A __END__ }xms
            and die $_;
        $msgstr .= $_;
        redo LOOP;
    }
    chomp $msgstr;

    return decode_utf8($msgstr);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::Utils::Autotranslator::Interactive - Interface for manual translation with copy/paste

=head1 VERSION

1.011

=head1 SYNOPSIS

    use Locale::Utils::Autotranslator::Interactive;

    my $obj = Locale::Utils::Autotranslator::Interactive->new(
        language                => 'de',
        # all following parameters are optional
        developer_language      => 'en', # en is the default
        before_translation_code => sub {
            my ( $self, $msgid ) = @_;
            ...
            return 1; # true: translate, false: skip translation
        },
        after_translation_code  => sub {
            my ( $self, $msgid, $msgstr ) = @_;
            ...
            return 1; # true: translate, false: skip translation
        },
    );
    $identical_obj = $obj->translate(
        'mydir/de.pot',
        'mydir/de.po',
    );
    my $translation_count = $obj->translation_count;

=head1 DESCRIPTION

Interface for translation by terminal input

Type __END__ to stop the translation.
Otherwise the file is stored back after all translations for that file are done.

=head1 SUBROUTINES/METHODS

=head2 method new

see SYNOPSIS

=head2 method translate_text

    $translated = $object->translate_text($untranslated);

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run the *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Encode|Encode>

L<Moo|Moo>

L<namespace::autoclean|namespace::autoclean>

L<Locale::Utils::Autotranslator|Locale::Utils::Autotranslator>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Gettext>

L<Locale::TextDomain::OO|Locale::TextDomain::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2021,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
