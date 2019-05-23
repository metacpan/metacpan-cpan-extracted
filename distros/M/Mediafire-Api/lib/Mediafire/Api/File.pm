package Mediafire::Api::File;

use 5.008001;
use utf8;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my ($class, %opt) = @_;
    my $self = {};

    for my $field (qw/key size name hash/) {
        $self->{$field} = $opt{"-$field"};
    }

    bless $self, $class;
    return $self;
}


########### ACCESSORS #######################

sub key {
    if (defined($_[1])) {
        $_[0]->{key} = $_[1];
    }
    return $_[0]->{key};
}

sub size {
    if (defined($_[1])) {
        $_[0]->{size} = $_[1];
    }
    return $_[0]->{size};
}

sub name {
    if (defined($_[1])) {
        $_[0]->{name} = $_[1];
    }
    return $_[0]->{name};
}

sub hash {
    if (defined($_[1])) {
        $_[0]->{hash} = $_[1];
    }
    return $_[0]->{hash};
}


1;
