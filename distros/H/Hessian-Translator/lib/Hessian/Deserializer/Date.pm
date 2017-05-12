package  Hessian::Deserializer::Date;

use Moose::Role;

#
use YAML;
use DateTime;
use DateTime::Format::Epoch;
use Math::BigInt try => 'GMP';
use integer;
use feature "switch";

sub read_date_handle_chunk {    #{{{
    my ( $self, $first_bit, ) = @_;
    my $input_handle = $self->input_handle();
    my ( $formatter, $date, $data );
    my $epoch = DateTime->new(
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC'
    );
    my $datetime;
    given ($first_bit) {
        when (/[\x4a\x64]/) {
            $formatter = DateTime::Format::Epoch->new(
                unit  => 'milliseconds',
                type  => 'bigint',
                epoch => $epoch
            );
            $data     = $self->read_long_handle_chunk('L');
            $datetime = $formatter->parse_datetime($data);
        }
        when ( /\x4b/ ) {

            my $raw_octets = $self->read_from_inputhandle(4);
            my @chars      = unpack 'C*', $raw_octets;
            my $shift_val  = 0;
            $data = Math::BigInt->new(0);

            foreach my $byte ( reverse @chars ) {
                my $shift_byte = Math::BigInt->new($byte);
                $shift_byte->blsft($shift_val);
                $data->badd($shift_byte);
                $shift_val += 8;
            }
            $data->bmul(60);

            $datetime = DateTime->from_epoch(
                epoch => ( $data->bstr() )

            );
        }
    }
    $datetime->set_time_zone('UTC');
    return $datetime;
}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::Date - Methods for deserializing hessian dates.

=head1 VERSION

=head1 SYNOPSIS

These methods are only made to be used within the Hessian framework.

=head1 DESCRIPTION

This module reads the input file handle to deserialize Hessian dates.

=head1 INTERFACE

=head2 read_date_handle_chunk

Reads a date from the input handle;


