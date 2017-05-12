package Jmespath::ValueException;
use Moose;
with 'Throwable';

has 'message' => ( is => 'ro' );

sub to_string { return shift->message; }

no Moose;
1;
