package Spike;

use strict;
use warnings;

our $VERSION = '0.01';

sub pick {
    my ($a, $b) = @_;
    if ($a && $b) {
        return 'both';
    }
    elsif ($a || $b) {
        return 'one';
    }
    return 'none';
}

sub tag {
    my ($name) = @_;
    return "<b>$name</b>";
}

sub unused {
    return 'never' if $_[0];
    return 'still never';
}

1;

__END__

=head1 NAME

Spike - the Perl half of the report fixture

=head1 DESCRIPTION

A few branches and conditions for the report to draw.

=cut
