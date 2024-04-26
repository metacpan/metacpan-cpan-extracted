package Test::LivesOK;

use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/lives_ok/;

use Test::Builder;
my $builder = Test::Builder->new;

sub lives_ok(&@) {
	my ($sub, $desc) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $success = eval {
		$sub->();
		1;
	};
	$builder->ok($success, $desc) or $builder->note("Exception thrown: $@");
	return $success;
}
