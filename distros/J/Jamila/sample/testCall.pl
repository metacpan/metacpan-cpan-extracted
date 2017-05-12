use strict;
package SmpLocal;
sub echo($$)
{
  my($sClass, $sPrm) = @_;
  return "LOCAL: Welcome to Jamila! ( $sPrm )";
}

package main;
use Jamila;
use Data::Dumper;
#(1) Call Remote
my $oJm = Jamila->new(
#  'http://hippo2000.atnifty.com/cgi-bin/jamila/testJamila.pl'
  'http://localhost/cgi-bin/jamila/testJamila.pl');
print $oJm->call('echo', 'Test for Remote') . "\n";
print $oJm->call('_echo', 'Test for Remote') . "\n";

#(2) Call Local
my $oJmL = Jamila->new(bless {}, 'SmpLocal');
print $oJmL->call('echo', 'How is local?') . "\n";

