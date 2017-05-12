package EntityModel::Test::Storage;
{
  $EntityModel::Test::Storage::VERSION = '0.102';
}
use EntityModel::Class {
	_isa	=> [qw(Exporter)],
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Test::Storage - tests for L<EntityModel::Storage> and subclasses

=head1 VERSION

version 0.102

=head1 SYNOPSIS

 use EntityModel::Test::Storage;
 storage_ok('EntityModel::Storage::Perl', '::Perl subclass works');

=head1 DESCRIPTION

Provides functions for testing L<EntityModel::Storage> subclasses.

=cut

use Test::Builder;
use Module::Load;
use CPS qw(kseq);
use EntityModel;

use constant STORAGE_METHODS => qw(
	new
	register
	apply_model
	apply_model_and_schema
	read
	create
	store
	remove
	find
	adjacent
	prev
	next
	outer
	first
	last
);

=head1 EXPORTS

Since this is a test class, functions are exported automatically
to match behaviour of other test modules such as L<Test::More>.
To disable this, pass an empty list on the C<use> line or
use C<require> instead:

 use EntityModel::Test::Storage ();
 EntityModel::Test::Storage::storage_ok(...);

=cut

our @EXPORT = qw(
	storage_ok
	storage_methods_ok
);

=head1 FUNCTIONS

=cut

=head2 storage_ok

Runs all available tests (including attempting to load the module) and returns the usual
L<Test::Builder> ok/fail response.

=cut

sub storage_ok {
	my $class = shift;
	my $opt = shift || [];
	my $msg = shift || "$class is a valid, working EntityModel::Storage (sub)class";

# First we need to be able to load our module
	try {
		Module::Load::load($class);
	} catch {
		return _report_fail($msg, $_);
	};

	$class->isa('EntityModel::Storage') or return _report_fail($msg, 'is not an EntityModel::Storage (sub)class');
	_methods_ok($class, $msg) or return;

# Abstract base class won't work very well for 'real' model handling, so skip that

	unless($class eq 'EntityModel::Storage') {
		_simple_model($class, $opt, $msg) or return;
	}

	return _report_pass($msg);
}

=head2 storage_methods_ok

Check whether the expected methods are present. Requires the class to be loaded first.

=cut

sub storage_methods_ok {
	my $class = shift;
	my $opt = shift || [];
	my $msg = shift || "$class has all the required methods";
	return 0 unless _methods_ok($class, $msg);
	return _report_pass($msg);
}

=head2 _methods_ok

Internal helper function to report whether the expected methods are present for the subclass.

=cut

sub _methods_ok {
	my $class = shift;
	my $msg = shift;

	my %failed;
	foreach my $method (STORAGE_METHODS) {
		try {
			$class->can($method);
		} catch {
			$failed{$method} = $_;
		} or $failed{$method} ||= 'not available';
	}
	if(keys %failed) {
		return _report_fail($msg, join "\n", map { "Could not $class->$_ because: " . $failed{$_} } sort keys %failed);
	}
	return 1;
}

=head2 _simple_model

=cut

sub _simple_model {
	my $class = shift;
	my $opt = shift;
	my $msg = shift;

# Bring in a simple model - if this fails then it's not the storage class' fault so die() rather than marking as failure
	my $model = EntityModel->new->load_from(
		Perl	=> {
			"name" => "mymodel",
			"entity" => [ {
				"name" => "thing",
				"primary" => "id",
				"field" => [
					{ "name" => "id", "type" => "int" },
					{ "name" => "name", "type" => "varchar" }
				]
			}, {
				"name" => "other",
				"primary" => "id",
				"field" => [
					{ "name" => "id", "type" => "int" },
					{ "name" => "extra", "type" => "varchar" }
				]
			} ]
		}
	) or die "Model creation failed";

# Now we try to apply the storage model
	$model->add_storage($class => $opt) or die "Failed to add storage";

# Sanity check that we end up with single storage item of the expected class
	my @storage = $model->storage->list;
	return _report_fail($msg, "expected 1 storage item, found " . scalar(@storage)) unless @storage == 1;
	return _report_fail($msg, "unexpected class found, wanted $class but had " . join(',', map ref, @storage)) if grep { ref($_) ne $class } @storage;

# Now the model has been applied, we'll try to do some simple tests directly against storage:
# first we'll create an entry
	my ($storage) = @storage;
	my ($thing) = grep { $_->name eq 'thing' } $model->entity->list;
	die "no thing" unless $thing;

# Support failure passthrough in our continuations
	my $failed = 0;
	my $fail = sub {
		my ($err, $next) = @_;
		# Bail out immediately if we're already in failure state.
		$next->() if $failed && $next;

		# This would be a most lamentable state of affairs
		die "Failed already and no continuation, help!" if $failed;

		$failed = 1;
		_report_fail($msg, $err);
		$next->() if $next;
	};

# Take advantage of CPS to avoid excessive indentation
	my ($id, $data);
	kseq(sub {
	# First we create a simple entity instance
		my $next = pop;
		$storage->create(
			entity	=> $thing,
			data	=> {
				name	=> 'Test name',
			},
			on_complete => sub {
				$id = shift;
				$next->();
			},
			on_fail => sub {
				$fail->("Something failed", $next);
			}
		) or $fail->("->create returned false", $next);
	}, sub {
	# Next we check, then read it back
		my $next = pop;
		$next->() if $failed;
		$fail->("no ID assigned", $next) unless defined $id;

		$storage->read(
			entity	=> $thing,
			id	=> $id,
			on_complete	=> sub {
				$data = shift;
				$next->();
			},
			on_fail => sub {
				$fail->("Something failed", $next);
			}
		) or $fail->("->read returned false", $next);
	}, sub {
	# Verify that we read back what we wrote originally
		my %read = %$data;
		$fail->("wrong keys returned: " . join ',', keys %read) unless [sort keys %read] ~~ [qw(id name)];
		$fail->("wrong data for name -  returned: " . $read{name}) unless $read{name} eq 'Test name';
	});
	return 0 if $failed;
	return 1;
}

=head2 _report_status

Internal helper function to report pass/fail via L<Test::Builder>.

=cut

sub _report_status {
	my $ok = shift;
	my $msg = shift;
	my $diag = shift;

	my $test = Test::Builder->new;
	$test->ok($ok, $msg);
	$test->diag($diag) if defined $diag;
	return $ok;
}

sub _report_pass { _report_status(1, @_) }

sub _report_fail { _report_status(0, @_) }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2012. Licensed under the same terms as Perl itself.
