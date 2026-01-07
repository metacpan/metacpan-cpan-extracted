package Gears::X;
$Gears::X::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use overload
	q{""} => sub ($self, @) { $self->as_string },
	q{0+} => sub ($self, @) { $self->as_number },
	fallback => 1;

our $PRINT_TRACE = false;

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

