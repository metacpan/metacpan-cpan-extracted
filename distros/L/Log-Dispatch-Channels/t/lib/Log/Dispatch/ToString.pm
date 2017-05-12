#!/usr/bin/perl
use strict;
use warnings;
package Log::Dispatch::ToString;
our $VERSION = '0.01';

use base 'Log::Dispatch::Output';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->_basic_init(@_);
    $self->{_string} = '';
    return $self;
}

sub log_message {
    my $self = shift;
    my %args = @_;
    $self->{_string} .= $args{message};
}

sub get_string {
    my $self = shift;
    return $self->{_string};
}

1;
