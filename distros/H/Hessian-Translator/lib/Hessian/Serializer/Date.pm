package  Hessian::Serializer::Date;

use Moose::Role;

requires qw/write_integer write_long/;

use DateTime;
#use DateTime::Format::Strptime;
use DateTime::Format::Epoch;

sub write_date  {    #{{{
    my ($self, $datetime) = @_;
    my $formatter = DateTime::Format::Epoch->new(
        unit  => 'milliseconds',
        type  => 'bigint',
        epoch => DateTime->new(
            year      => 1970,
            month     => 1,
            day       => 1,
            time_zone => 'UTC'
        )
    );
    my $epoch_time   = $formatter->format_datetime($datetime);
    my $time = $self->write_long($epoch_time);
    if ($self->version() == 1) {
        $time =~ s/L/d/;
    }
    else {
        $time =~ s/^L/\x4a/;
        $time =~ s/^I/\x4b/;

    }
    return $time;
}


"one, but we're not the same";

__END__


=head1 NAME

Hessian::Serializer::Date - Role for serializing dates into Hessian.

=head1 SYNOPSIS

These methods are only made to be used within the Hessian framework.

=head1 DESCRIPTION

This module provides a single function for serializing dates into Hessian.

=head1 INTERFACE

=head2 write_date

Serialize an integer representing a particular date in epoch time into
Hessian.
