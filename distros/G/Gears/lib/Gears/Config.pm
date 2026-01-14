package Gears::Config;
$Gears::Config::VERSION = '0.101';
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

__END__

=head1 NAME

Gears::Config - Configuration management system

=head1 SYNOPSIS

	use Gears::Config;

	my $config = Gears::Config->new(
		readers => [Gears::Config::Reader::PerlScript->new],
	);

	# Add configuration from a file
	$config->add(file => 'config.pl');

	# Add configuration from a hash
	$config->add(var => { database => { host => 'localhost' } });

	# Get configuration values
	my $host = $config->get('database.host');
	my $port = $config->get('database.port', 3306);

=head1 DESCRIPTION

Gears::Config manages application configuration through a flexible merging
system. It supports loading configuration from multiple sources using pluggable
readers and provides a sophisticated merging mechanism with special operators
for controlling how configuration is combined.

Configuration is stored as nested hash structures and can be accessed using
dot-separated paths. Multiple configuration sources can be merged together,
with later sources modifying earlier ones according to merge rules.

=head2 Merge operators

Configuration keys can be prefixed with special operators to control merge
behavior:

=over

=item * C<key> - Smart merges values

Finds the what values are missing from the configuration and merges them.

=item * C<+key> - Add to existing value

For hashes, works the same as smart merging. For arrays, appends elements to
the existing array regardless of them being present in the array.

=item * C<-key> - Remove from existing value (arrays only)

Removes matching elements from the array using deep comparison.

=item * C<=key> - Replace existing value

Forces replacement even if the types don't match. Without this operator, trying
to merge mismatched types raises an exception.

=back

Examples:

	# Original config
	{ users => ['alice', 'bob'] }

	# Smart merge
	{ users => ['bob', 'charlie'] }
	# Result: { users => ['alice', 'bob', 'charlie'] }

	# Merge with +users (or just users)
	{ '+users' => ['bob', 'charlie'] }
	# Result: { users => ['alice', 'bob', 'bob', 'charlie'] }

	# Merge with -users
	{ '-users' => ['bob'] }
	# Result: { users => ['alice'] }

	# Merge with =users
	{ '=users' => { admin => 'alice' } }
	# Result: { users => { admin => 'alice' } }

=head1 INTERFACE

=head2 Attributes

=head3 readers

An array reference of L<Gears::Config::Reader> instances used to parse
configuration files. By default, includes L<Gears::Config::Reader::PerlScript>.

I<Available in constructor>

=head3 config

The internal hash reference containing the merged configuration data.

I<Not available in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

=head3 add

	$config = $config->add($source_type, $source)

Adds and merges configuration from a source. The C<$source_type> can be:

=over

=item * C<file> - Load from a file using an appropriate reader

=item * C<var> - Use the provided hash reference directly

=back

Returns the configuration object for method chaining.

Example:

	$config->add(file => 'app.pl')
		->add(var => { debug => true });

=head3 parse

	$hash_ref = $config->parse($source_type, $source)

Parses a configuration source and returns the resulting hash reference without
merging it into the current configuration. Uses the same C<$source_type> values
as L</add>.

Raises C<Gears::X::Config> if no reader can handle the file or if the source
type is unknown.

=head3 merge

	$config->merge($hash_ref)

Merges the provided hash reference into the current configuration. This is the
core merging logic used by L</add>. The merge behavior can be controlled using
special key prefixes (see L</Merge operators>).

=head3 get

	$value = $config->get($path, $default = undef)

Retrieves a configuration value using a dot-separated path. If the path doesn't
exist, returns C<$default>.

Examples:

	$config->get('database.host')
	$config->get('cache.ttl', 3600)

Raises C<Gears::X::Config> if the path traverses through a non-hash value.

