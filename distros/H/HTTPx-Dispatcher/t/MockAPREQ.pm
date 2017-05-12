package t::MockAPREQ; # mock object for Apache::Request
use strict;
use warnings;

sub new { my $class = shift; bless {@_}, $class; }
sub uri    { $_[0]->{uri} }
sub method { $_[0]->{method} }

1;
