package JSON::SchemaValidator::Pointer;

use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(pointer);

use URI::Escape qw(uri_unescape);

sub pointer {
    my ($json, $pointer) = @_;

    return unless $pointer =~ m/^#/;

    $pointer = uri_unescape($pointer);

    $pointer =~ s{^#/?}{};

    my $top = $json;
    foreach my $part (split m{/}, $pointer) {
        $part =~ s{\~1}{\/}g;
        $part =~ s{\~0}{\~}g;

        if (ref $top eq 'HASH') {
            $top = $top->{$part};
        }
        elsif (ref $top eq 'ARRAY') {
            $top = $top->[$part];
        }
    }

    return $top;
}

1;
