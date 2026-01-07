package Gears::Config;
$Gears::Config::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Gears::Config::Reader::PerlScript;
use Gears::X::Config;
use Value::Diff;

has param 'readers' => (
	isa => ArrayRef [InstanceOf ['Gears::Config::Reader']],
	default => sub { [Gears::Config::Reader::PerlScript->new] },
);

has field 'config' => (
	isa => HashRef,
	default => sub { {} },
);

my sub _merge ($this_conf, $this_diff)
{
	foreach my $key (sort keys $this_diff->%*) {
		my $value = $this_diff->{$key};
		my $ref = ref $value;
		my $mode;

		if ($key =~ /^([+-=])/) {
			$mode = $1;
			$key = substr $key, 1;
		}

		# equal sign allow replacing mismatching types of refs
		if (!exists $this_conf->{$key} || ($mode // '') eq '=') {
			$this_conf->{$key} = $value;
		}
		elsif (ref $this_conf->{$key} ne $ref) {
			Gears::X::Config->raise("configuration key type mismatch for $key");
		}

		elsif ($ref eq 'HASH') {
			if (!defined $mode || $mode eq '+') {
				__SUB__->($this_conf->{$key}, $value);
			}
			else {
				Gears::X::Config->raise("$mode$key is not supported for this ref type");
			}
		}

		elsif ($ref eq 'ARRAY') {
			if (!defined $mode || $mode eq '+') {
				push $this_conf->{$key}->@*, $value->@*;
			}
			elsif ($mode eq '-' && diff($this_conf->{$key}, $value, \my $rest)) {
				$this_conf->{$key}->@* = $rest->@*;
			}
		}

		else {
			Gears::X::Config->raise("$mode$key is not supported for this ref type")
				if defined $mode;

			$this_conf->{$key} = $value;
		}
	}

}

sub merge ($self, $hash)
{
	my $conf = $self->config;
	if (diff($hash, $conf, \my $diff)) {
		_merge($conf, $diff);
	}
}

sub parse ($self, $source_type, $source)
{
	if ($source_type eq 'file') {
		my $config;
		foreach my $reader ($self->readers->@*) {
			next unless $reader->handles($source);
			$config = $reader->parse($self, $source);
			last;
		}

		Gears::X::Config->raise("no reader to handle file: $source")
			unless defined $config;

		return $config;
	}
	elsif ($source_type eq 'var') {
		return $source;
	}
	else {
		Gears::X::Config->raise("unknown type of config to add: $source_type");
	}
}

sub add ($self, $source_type, $source)
{
	$self->merge($self->parse($source_type, $source));
	return $self;
}

sub get ($self, $path, $default = undef)
{
	my $current = $self->config;

	foreach my $part (split /\./, $path) {
		Gears::X::Config->raise("invalid config path $path at part $part - not a hash")
			unless ref $current eq 'HASH';

		return $default unless exists $current->{$part};
		$current = $current->{$part};
	}

	return $current;
}

