package MyDummyAutotranslator; ## no critic (TidyCode)

use strict;
use warnings;
use Moo;

our $VERSION = 0;

sub translate_text {
    my ( $self, $msgid ) = @_;

    return { 'not in po file' => 'nicht im po File' }->{$msgid};
}

__PACKAGE__->meta->make_immutable;

1;
