package Jmespath::EmptyExpressionException;
use Moose;
with 'Throwable';
extends 'Jmespath::JMESPathException';

no Moose;
1;
