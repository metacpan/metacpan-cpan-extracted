use 5.010001;
use strict;
use warnings;

package Dist::Inkt::Role::Test::Whitespace;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.024';

use Moose::Role;
use Types::Standard "Bool";
use File::chdir;

with qw(Dist::Inkt::Role::Test);

has skip_whitespace_test => (is => "ro", isa => Bool, default => 0);

after BUILD => sub {
	my $self = shift;
	
	$self->setup_prebuild_test(sub {
		return if $self->skip_whitespace_test;
		local $CWD = $self->rootdir;
		my @dirs = grep -d, qw( lib bin t xt );
		
		$self->log("Testing with Test::EOL");
		die("Bad whitespace")
			if system("perl -MTest::EOL -E'all_perl_files_ok(qw/ @dirs /)'");
		
		$self->log("Testing with Test::Tabs");
		die("Bad whitespace")
			if system("perl -MTest::Tabs -E'all_perl_files_ok(qw/ @dirs /)'");
	});
};

1;
