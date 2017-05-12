#!/perl/bin/perl
use strict;
package TestJamila;
sub echo($$)
{
  my($sClass, $sPrm) = @_;
  return "Welcome to Jamila! ( $sPrm )";
}
sub getServerTime($)
{
  my($sClass) = @_;
  return 'Now ... ' . scalar(localtime());
}
sub arraySample($)
{
  my($sClass) = @_;
  return ['KAWAI', 'Takanori', 'Marie'];
}
sub hashSample($)
{
  my($sClass) = @_;
  return {'last' => 'KAWAI', 'first' => 'Takanori', 
          'wife' => 'Marie'};
}

package main;
use Jamila;
Jamila->proc('TestJamila');
