#!perl -w

# Ensure that there are no FIXMEs in the code

use strict;
use warnings;
use Test::Most;

my @messages;

if(not $ENV{AUTHOR_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
} else {
	is($INC{'Devel/FIXME.pm'}, undef, "Devel::FIXME isn't loaded yet");
	
	use_ok('Devel::FIXME');

	$Devel::FIXME::REPAIR_INC = 1;

	use_ok('Geo::Coder::Free');
	# use_ok('Geo::Coder::Free::Local');

	if($@) {
		plan skip_all => 'Test::Warnings required for finding FIXMEs';
	} else {
		# ok($messages[0] !~ /lib\/Geo\/Coder\/Free/);
		ok(scalar(@messages) == 0);

		done_testing(4);
	}
}

sub Devel::FIXME::rules {
	sub {
		my $self = shift;
		return shout($self) if $self->{file} =~ /lib\/Geo\/Coder\/Free/;
		return Devel::FIXME::DROP();
	}
}

sub shout {
	my $self = shift;
	push @messages, "# FIXME: $self->{text} at $self->{file} line $self->{line}.\n";
}
