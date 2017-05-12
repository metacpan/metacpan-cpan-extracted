package Device::Modbus::Exception;

use parent 'Device::Modbus';
use Carp;
use overload '""' => \&stringify;

use strict;
use warnings;

my %exc_descr_for = (
    1 => '1 - Function code not supported',
    2 => '2 - Incorrect address or address not supported',
    3 => '3 - Invalid data (either quantity or values)',
    4 => '4 - Execution failed',  
);

sub new {
    my ($class, %args) = @_;

    # Must receive either a function name or a function code
    unless (exists $args{function} or exists $args{code}) {
        croak 'Please specify either a function name or code to instantiate an exception';
    }

    if (exists $args{function} && exists $Device::Modbus::code_for{$args{function}}) {
        $args{code} = $Device::Modbus::code_for{$args{function}} + 0x80;
    }
    elsif (exists $args{code} && exists $Device::Modbus::function_for{$args{code} - 0x80}) {
        $args{function} = $Device::Modbus::function_for{$args{code} - 0x80};
    }
    elsif (exists $args{code}) {
        $args{function} = 'Non-supported function';
    }
    else {
        croak "Function $args{function} is not supported";
    }

    # Must receive an exception code
    croak 'A valid exception code (between 1 and 4) is required'
        unless exists $args{exception_code} && $args{exception_code} > 0 && $args{exception_code} <= 4;

    return bless \%args, $class;
}

sub pdu {
    my $self = shift;
    return pack('CC', $self->{code}, $self->{exception_code});
}

sub stringify {
    my $self = shift;

    my $str   = $Device::Modbus::function_for{$self->{code}-0x80} // 'Unknown';
    my $descr = $exc_descr_for{$self->{exception_code}};

    return "Exception for function <$str>: $descr";
}

1;
