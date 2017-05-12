package t::lib::DispatcherException;
use Moose;
with 'Throwable';

has 'response' => ( is => 'ro', required => 1 );

1;
