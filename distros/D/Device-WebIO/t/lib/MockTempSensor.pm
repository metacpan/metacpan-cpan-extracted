package MockTempSensor;
use v5.12;
use Moo;
use namespace::clean;

has 'celsius' => (
    is     => 'rw',
    writer => 'set_celsius',
    reader => 'temp_celsius',
);

with 'Device::WebIO::Device::TempSensor';


sub temp_kelvins
{
    my ($self) = @_;
    return $self->_convert_c_to_k( $self->temp_celsius );
}

sub temp_fahrenheit
{
    my ($self) = @_;
    return $self->_convert_c_to_f( $self->temp_celsius );
}


sub pin_desc
{
    # Placeholder
}

sub all_desc
{
    # Placeholder
}


1;
__END__

