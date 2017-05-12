package t::lib::Object;
use strict;
use warnings;

sub new { bless {}, shift };
sub param {
    my ($self, $key, $value) = @_;
    return keys %$self if !defined $key && !defined $value;
    $self->{$key} = $value if defined $value;
    $self->{$key || ''};
}

!!1;
