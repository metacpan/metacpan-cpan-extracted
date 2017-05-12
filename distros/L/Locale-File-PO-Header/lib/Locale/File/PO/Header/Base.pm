package Locale::File::PO::Header::Base; ## no critic (TidyCode)

use Moose;

use namespace::autoclean;
use syntax qw(method);

our $VERSION = '0.001';

method default {
    return;
}

method trigger_helper ($arg_ref) {
    my ($new, $current, $default) = map {
        defined $_ ? $_ : q{};
    } @{$arg_ref}{ qw(new current default) };
    if ( ! length $new ) {
        $new = $default;
    }
    if (
        ( defined $arg_ref->{new} xor defined $arg_ref->{current} )
        || $new ne $current
    ) {
        my $writer = $arg_ref->{writer};
        $self->$writer($new);
    }

    return;
}

method header_keys {
    return $self->name;
}

method format_line ($line, %args) {
    for my $key ( keys %args ) {
        $line =~ s{
            [{]
            \Q$key\E
            [}]
        } {
            defined $args{$key}
            ? $args{$key}
            : q{}
        }xmsge;
    }

    return $line;
}

__PACKAGE__->meta->make_immutable;

# $Id: Utils.pm 602 2011-11-13 13:49:23Z steffenw $

1;
