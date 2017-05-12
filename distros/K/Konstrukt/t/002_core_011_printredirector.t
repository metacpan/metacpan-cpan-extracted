# check core module: print redirector

use strict;
use warnings;

use Test::More tests => 3;

#=== Dependencies
use Konstrukt::Event;
my $handler = Konstrukt::Test::PrintRedirector->new();
$Konstrukt::Event->register("Konstrukt::PrintRedirector::print", $handler, \&Konstrukt::Test::PrintRedirector::print);

#Print Redirector
use Konstrukt::PrintRedirector;

#print
is($Konstrukt::PrintRedirector->activate(), 1, "activate");
print "some stuff";
is($handler->{printed}, "some stuff", "print");
is($Konstrukt::PrintRedirector->deactivate(), 1, "deactivate");

package Konstrukt::Test::PrintRedirector;

sub new { bless {}, $_[0] }

sub print { $_[0]->{printed} .= $_[1] }

1;
