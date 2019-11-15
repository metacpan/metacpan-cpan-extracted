package Localizer::Lexicon;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Class::Accessor::Lite 0.05 (
    rw => [qw(dictionary)],
);

sub new {
    my $class = shift;
    my $dictionary = { @_==1 ? %{$_[0]} : @_ };
    bless { dictionary => $dictionary }, $class;
}

sub msgids { keys %{shift->dictionary} }

sub msgstr {
    my ( $self, $msgid ) = @_;
    ( exists $self->dictionary->{$msgid} && $self->dictionary->{$msgid} ) || undef;
}

1;

=encoding utf-8

=head1 NAME

Localizer::Lexicon - Default lexicon class

=head1 SYNOPSIS

    use Localizer::Resource;
    use Localizer::Style::Gettext;
    use Localizer::Lexicon

    my $es = Localizer::Resource->new(
        dictionary => Localizer::Lexicon->new( 'Hi, %1.' => 'Hola %1.' ),
        format     => Localizer::Style::Gettext->new(),
    );

    say $es->maketext("Hi, %1.", "John"); # => Hola, John.

=head1 DESCRIPTION

L<Localizer::Lexicon> is just the default lexicon that is built internally when you provide a hashref as your dictionary.

You can implement your own class to replace this one as your L<Localizer> dictionary, for instance, to get your translations from a database or API. Just pass your object which implements msgids() and msgstr() like this one as your dictionary.

=head1 METHODS

=over 4

=item * Localizer::Lexicon->new(%args | \%args)

Constructor. It will initialize the lexicon from a list or hashref

e.g.

    my $de = Localizer::Lexicon->new(
        'Hello, World!' => 'Hello, Welt!'
    );

=over 8

=item dictionary: Hash Reference

Dictionary data to localize.

=back

=item * $localizer->msgids();

Returns a list of msgeid's which are the keys of the dictionary.

=item * $localizer->msgstr($msgid);

Return the message to translate given $msgid (dictionary data with key). If you give nonexistent key to this method, it returns undef.

=back

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
