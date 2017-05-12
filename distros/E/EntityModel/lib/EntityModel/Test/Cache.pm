package EntityModel::Test::Cache;
{
  $EntityModel::Test::Cache::VERSION = '0.102';
}
use EntityModel::Class {
	_isa	=> [qw(Exporter)],
};

=head1 NAME

EntityModel::Test::Cache - tests for L<EntityModel::Cache> and subclasses

=head1 VERSION

version 0.102

=head1 SYNOPSIS

 use EntityModel::Test::Cache;
 cache_ok('EntityModel::Cache::Perl', '::Perl subclass works');

=head1 DESCRIPTION

Provides functions for testing L<EntityModel::Cache> subclasses.

=cut

use Test::Builder;
use Module::Load;

use constant CACHE_METHODS => qw(
	new
	get
	set
);

=head1 EXPORTS

Since this is a test class, functions are exported automatically
to match behaviour of other test modules such as L<Test::More>.
To disable this, pass an empty list on the C<use> line or
use C<require> instead:

 use EntityModel::Test::Cache ();
 EntityModel::Test::Cache::cache_ok(...);

=cut

our @EXPORT = qw(
	cache_ok
	cache_methods_ok
);

=head1 FUNCTIONS

=cut

=head2 cache_ok

Runs all available tests (including attempting to load the module) and returns the usual
L<Test::Builder> ok/fail response.

=cut

sub cache_ok {
	my $class = shift;
	my $msg = shift || "$class is a valid, working EntityModel::Cache (sub)class";
	my $ok = 0;


# First we need to be able to load our module
	try {
		Module::Load::load($class);
	} catch {
		return _report_status($ok, $msg, $_);
	};

	_methods_ok($class, $msg) or return;

	$ok = 1;
	return _report_status($ok, $msg);
}

sub cache_methods_ok {
	my $class = shift;
	my $msg = shift || "$class has all the required methods";
	return 0 unless _methods_ok($class, $msg);
	return _report_status(1, $msg);
}

sub _methods_ok {
	my $class = shift;
	my $msg = shift;

	my %failed;
	foreach my $method (CACHE_METHODS) {
		try {
			$class->can($method);
		} catch {
			$failed{$method} = $_;
		} or $failed{$method} ||= 'not available';
	}
	if(keys %failed) {
		_report_status(0, $msg, join "\n", map { "Could not ->$_ because: " . $failed{$_} } sort keys %failed);
		return 0;
	}
	return 1;
}

sub _report_status {
	my $ok = shift;
	my $msg = shift;
	my $diag = shift;

	my $test = Test::Builder->new;
	$test->ok($ok, $msg);
	$test->diag($diag) if defined $diag;
	return $ok;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
