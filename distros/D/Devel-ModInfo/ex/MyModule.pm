#This module is purely for testing ModInfo's
# installation and capabilities
#It doesn't do anything useful itself

package MyModule;

use XML::DOM;
use CGI;
use IO::Handle;

@ISA = qw/ Exporter Autoloader NiceModule /;

sub new {
	#This is my object oriented constructor!
	my($class) = @_;
	return bless {} => $class;
}

sub method1 {
	my($self) = @_;
	return 1;
}

sub method2($$) {
	my($self, $message) = @_;
	print "$message!\n";
	return 2;
}