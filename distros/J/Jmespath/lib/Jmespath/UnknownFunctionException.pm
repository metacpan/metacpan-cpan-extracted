package Jmespath::UnknownFunctionException;
use Moose;
extends 'Jmespath::JMESPathException';
with 'Throwable';

no Moose;
1;
