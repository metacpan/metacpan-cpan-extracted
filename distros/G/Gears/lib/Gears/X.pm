package Gears::X;
$Gears::X::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

use overload
	q{""} => sub ($self, @) { $self->as_string },
	q{0+} => sub ($self, @) { $self->as_number },
	fallback => 1;

our $PRINT_TRACE = $ENV{GEARS_PRINT_TRACE};

has param 'message' => (
	isa => Str,
	writer => -hidden,
);

has field 'trace' => (
	isa => ArrayRef,
	builder => 1,
);

my @ignored = qw(Gears Type::Coercion);
my $packages_to_skip;
_rebuild_skip();

sub _rebuild_skip
{
	my $sub_re = join '|', map { quotemeta } @ignored;
	$packages_to_skip = qr/^($sub_re)::/;
}

sub add_ignored_namespace($self, $module)
{
	push @ignored, $module;
	_rebuild_skip;
}

sub _base_class ($self)
{
	return __PACKAGE__;
}

sub _trace_config ($self)
{
	return state $conf = {
		max_level => 20,
		skip_package => \$packages_to_skip,
		skip_file => qr/\(eval \d+\)/,
	};
}

sub _build_trace ($self)
{
	my @trace;
	my $trace_conf = $self->_trace_config;

	for my $call_level (0 .. $trace_conf->{max_level}) {
		my ($package, $file, $line) = CORE::caller $call_level;
		last unless defined $package;
		next if $package =~ $trace_conf->{skip_package}->$*;
		next if $file =~ $trace_conf->{skip_file};
		next if @trace > 0 && $trace[-1][0] eq $file && $trace[-1][1] == $line;

		push @trace, [$file, $line];
	}

	return \@trace;
}

sub caller ($self)
{
	return $self->trace->[0];
}

sub raise ($self, $error = undef)
{
	if (defined $error) {
		$self = $self->new(message => $error);
	}

	die $self;
}

sub _build_message ($self)
{
	return $self->message;
}

sub as_string ($self, $trace = $PRINT_TRACE)
{
	my $raised = $self->_build_message;

	if ($trace) {
		$raised .= "\nStack trace:\n";
		foreach my $trace ($self->trace->@*) {
			$raised .= "  $trace->[0], line $trace->[1]\n";
		}
	}
	elsif (defined(my $caller = $self->caller)) {
		$raised .= " (raised at $caller->[0], line $caller->[1])";
	}

	my $class = ref $self;
	my $base = $self->_base_class;
	if ($class eq $base) {
		$class = '';
	}
	else {
		$class =~ s/^${base}::(.+)$/[$1] /;
	}

	return "An error occured: $class$raised";
}

sub as_number ($self)
{
	return refaddr $self;
}

__END__

=head1 NAME

Gears::X - Base exception class

=head1 SYNOPSIS

	use Gears::X;

	# Raise an exception directly
	Gears::X->raise("Something went wrong");

	# Create and raise later
	my $error = Gears::X->new(message => "Invalid input");
	$error->raise;

	# Catch and inspect
	try {
		Gears::X->raise("Error occurred");
	}
	catch ($e) {
		say $e->message;                  # Error occurred
		say $e;                           # An error occured: Error occurred (raised at ...)
		my ($file, $line) = $e->caller->@*;
	}

	# Enable stack traces
	try {
		Gears::X->raise("With trace");
	}
	catch ($e) {
		local $Gears::X::PRINT_TRACE = true;
		say $e;
	}

	# Create exception subclasses
	package My::X::Database {
		use Mooish::Base;
		extends 'Gears::X';
	}

=head1 DESCRIPTION

Gears::X is the base exception class for the Gears framework. It provides stack
trace capture, string overloading, and a simple interface for creating and
raising exceptions. Exceptions can be stringified for display and include
information about where they were raised.

The exception class captures a stack trace when created, filtering out internal
framework packages to show only relevant application code. Stack traces can be
optionally printed by setting the L</$PRINT_TRACE> package variable or setting
C<GEARS_PRINT_TRACE> environmental variable before the package is loaded.

=head1 INTERFACE

=head2 Package variables

=head3 $PRINT_TRACE

	local $Gears::X::PRINT_TRACE = true;

When set to true, exceptions will include full stack traces in their string
representation. By default the value of an environmental variable
C<GEARS_PRINT_TRACE> is used. If this is false, only the immediate caller
location is shown.

This can be enabled temporarily for debugging.

	{
		local $Gears::X::PRINT_TRACE = true;
		# Exceptions here will show full traces
	}

=head2 Attributes

=head3 message

The error message string. This is the primary description of what went wrong.

I<Required in constructor>

=head3 trace

An array reference containing the stack trace. Each element is an array
reference of C<[$file, $line]>. The trace is automatically generated when the
exception is created.

I<Not available in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

=head3 raise

	$exception->raise($message = undef)
	$class->raise($message)

Raises an exception. Can be called as either an instance method or a
class method. When called as a class method with a message, creates a new
exception instance and raises it immediately.

=head3 caller

	$array_ref = $exception->caller()

Returns the first element of the trace (C<[$file, $line]>), representing where
the exception was raised outside of the internal packages. Returns C<undef> if
no trace is available.

=head3 as_string

	$string = $exception->as_string($include_trace = $PRINT_TRACE)

Returns a formatted string representation of the exception. If C<$include_trace>
is true, includes the full stack trace. Otherwise, includes only the file and
line where the exception was raised.

This method is called automatically when the exception is stringified.

If the exception is a subclass, the class name is included:

	An error occured: [HTTP] 404 - Not Found (raised at ...)

=head3 as_number

	$number = $exception->as_number()

Returns the reference address of the exception object. This allows exceptions
to be used in numeric contexts for comparison or identification.

=head3 add_ignored_namespace

	$class->add_ignored_namespace($module)

Adds a module namespace to the list of packages that should be filtered from
stack traces. This is useful when creating framework extensions that should not
appear in application-level traces.

Stack traces automatically filter out packages matching certain patterns to
show only relevant application code. By default, filtered packages include:

=over

=item * C<Gears::*> - Framework-framework internals

=item * C<Type::Coercion::*> - Type coercion internals

=back

