package Luftwaffe::Context;

use warnings;
use strict;

sub new { bless $_[1] || {}, $_[0] }

sub create_from_env {
	my ($class, $runner, $env) = @_;

	$class->new({
		params => $env->{PAYLOAD},
		path => $env->{ROUTE},
		method => $env->{METHOD}
	});
}

sub params { shift->{params} || {} }

sub path { shift->{path} }

sub method { shift->{method} }

1;
__END__
