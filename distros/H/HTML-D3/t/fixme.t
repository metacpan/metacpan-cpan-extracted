#!perl -w

# Ensure that there are no FIXMEs in the code

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;

my @messages;

is($INC{'Devel/FIXME.pm'}, undef, "Devel::FIXME isn't loaded yet");

eval 'use Devel::FIXME';
if($@) {
	# AUTHOR_TESTING=1 perl -MTest::Without::Module=Devel::FIXME -w -Iblib/lib t/fixme.t
	diag('Devel::FIXME needed to test for FIXMEs');
	done_testing(1);
} else {
	# $Devel::FIXME::REPAIR_INC = 1;

	use_ok('HTML::D3');

	# ok($messages[0] !~ /lib\/HTML\/D3.pm/);
	cmp_ok(scalar(@messages), '==', 0, 'No FIXMEs found');

	done_testing(3);
}

sub Devel::FIXME::rules {
	sub {
		my $self = shift;
		return shout($self) if $self->{file} =~ /lib\/HTML\/D3/;
		return Devel::FIXME::DROP();
	}
}

sub shout {
	my $self = shift;
	push @messages, "# FIXME: $self->{text} at $self->{file} line $self->{line}.\n";
}
