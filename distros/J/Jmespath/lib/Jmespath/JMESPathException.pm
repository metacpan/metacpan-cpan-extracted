package Jmespath::JMESPathException;
use Moose;
extends 'Jmespath::ValueException';
with 'Throwable';

no Moose;
1;
