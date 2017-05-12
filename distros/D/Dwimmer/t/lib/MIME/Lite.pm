package MIME::Lite;
use strict;
use warnings;

use Data::Dumper qw(Dumper);

sub new  {
	my ($class, %args)  = @_;
	return bless \%args, $class;
}

sub send {
	my $self = shift;
	# save to a file?
	if ($ENV{DWIMMER_MAIL}) {
		open my $out, '>', $ENV{DWIMMER_MAIL} or die $!;
		print $out Dumper $self;
	}
}

1;
