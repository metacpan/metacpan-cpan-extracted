package JCONF::Writer::Error;

use strict;
use overload '""' => \&to_string;

our $VERSION = '0.03';

sub new {
	my ($class, $msg) = @_;
	bless \$msg, $class;
}

sub throw {
	die $_[0];
}

sub to_string {
	my $self = shift;
	return $$self."\n";
}

1;
