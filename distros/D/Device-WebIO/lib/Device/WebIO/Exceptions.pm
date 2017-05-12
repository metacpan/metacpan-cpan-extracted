package Device::WebIO::Exceptions;
$Device::WebIO::Exceptions::VERSION = '0.010';
use v5.12;
use base 'Exception::Tiny';

package Device::WebIO::PinDoesNotExistException;
$Device::WebIO::PinDoesNotExistException::VERSION = '0.010';
use base 'Device::WebIO::Exceptions';


package Device::WebIO::FunctionNotSupportedException;
$Device::WebIO::FunctionNotSupportedException::VERSION = '0.010';
use base 'Device::WebIO::Exceptions';


1;
__END__

