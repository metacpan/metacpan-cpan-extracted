package Locale::File::PO::Header::Base; ## no critic (TidyCode)

use Moose;
use namespace::autoclean;

our $VERSION = '0.004';

sub default { ## no critic (BuiltinHomonyms)
    return;
}

sub trigger_helper {
    my ($self, $arg_ref) = @_;

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

sub header_keys {
    my $self = shift;

    return $self->name;
}

sub format_line {
    my ($self, $line, %args) = @_;

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
