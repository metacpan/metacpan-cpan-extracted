package Locale::Maketext::AutoTranslate;

use strict;
use warnings;

use utf8;
use encoding 'utf8';
use Moose;
use REST::Google::Translate;
use Locale::Maketext::Extract;
use HTML::Entities;
use Locale::Maketext::Lexicon {
    _allow_empty => 1,
};

our $VERSION = '0.1';

has 'from' => (is => 'rw');
has 'to'   => (is => 'rw');

sub translate {
    my $self = shift;
    my $source_file = shift or die "Please specify source file";
    my $target_file = shift or die "Please specify target file";

    die "Please specify target language" if !$self->to;

    $self->from('en') if !$self->from;

    my $ext = Locale::Maketext::Extract->new;
    $ext->read_po($source_file);

    REST::Google::Translate->http_referer('http://example.com');

    for my $i ($ext->msgids()) {
        my $res = REST::Google::Translate->new(q => $i,
                                               langpair => $self->from() . '|' . $self->to());

        print STDERR "[$i] => " if $ENV{AUTOTRANSLATE_DEBUG};

        if ($res->responseStatus == 200) {
            my $translated = $res->responseData->translatedText;
            $ext->set_msgstr($i, $translated);
        }
        else {
            $ext->set_msgstr($i, undef);
        }

        print STDERR "[" . $ext->msgstr($i) . "]\n" if $ENV{AUTOTRANSLATE_DEBUG};
    }
    $ext->write_po($target_file);
}

1;

=pod

=head1 NAME

Locale::Maketext::AutoTranslate - Translate L10N messages automatically

=head1 SYNOPSIS

    use Locale::Maketext::AutoTranslate;

    my $t = Locale::Maketext::AutoTranslate->new();

    $t->from('en');
    $t->to('zh_tw');

    $t->translate('en.po' => 'zh_tw.po'); # writes the translations
                                          # into zh_tw.po.

=head1 DESCRIPTION

This module can help human translators to translate l10n messages with
less effort. It sends messages to Google Translate service and get
rough translations. No translation memories need to be set up locally,
and translation process would simply become just correcting,
correcting, and correcting.

Setting environment variable B<AUTOTRANSLATE_DEBUG> can trace the
translation process.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yung-chung Lin (henearkrxern@gmail.com)

=cut
