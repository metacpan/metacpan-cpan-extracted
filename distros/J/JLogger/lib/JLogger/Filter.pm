package JLogger::Filter;

use strict;
use warnings;

sub new {
    my $class = shift @_;
    bless {@_}, $class;
}

1;
__END__

=head1 NAME

JLogger::Filter - filter captured data

=head1 SYNOPSIS

    use base 'JLogger::Filter';

    sub filter {
        my ($self, $message) = @_;

        ...

        return 0;
    }

=head1 DESCRIPTION

This is a base class for data filters.

=head1 METHODS

Subclasses should implement method C<filter>:

=head2 C<filter>

    sub filter {
        my ($self, $message) = @_;

        return 1 if $message->{from} eq 'secret@jabber.com';

        return 0;
    }

Filters the data. Returns true if message has been filter and false otherwise.

=cut
