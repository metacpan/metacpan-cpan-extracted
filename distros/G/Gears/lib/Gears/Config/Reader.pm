package Gears::Config::Reader;
$Gears::Config::Reader::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Path::Tiny qw(path);

sub _get_contents ($self, $filename)
{
	return path($filename)->slurp({binmode => ':encoding(UTF-8)'});
}

sub handles ($self, $filename)
{
	foreach my $ex ($self->handled_extensions) {
		return true if $filename =~ m/\.\Q$ex\E$/;
	}

	return false;
}

# plain array, strings inside must not contain a dot
sub handled_extensions ($self)
{
	...;
}

sub parse ($self, $filename)
{
	...;
}

__END__

=head1 NAME

Gears::Config::Reader - Base class for configuration readers

=head1 SYNOPSIS

	package My::Config::Reader::JSON;

	use v5.40;
	use Mooish::Base -standard;
	use JSON::MaybeXS;

	extends 'Gears::Config::Reader';

	sub handled_extensions ($self)
	{
		return qw(json);
	}

	sub parse ($self, $config, $filename)
	{
		return decode_json($self->_get_contents($filename));
	}

=head1 DESCRIPTION

Gears::Config::Reader is an abstract base class for configuration file readers.
Readers are responsible for determining if they can handle a particular file
(based on extension) and parsing that file into a hash reference.

Subclasses must implement C<handled_extensions> and C<parse> methods to provide
format-specific functionality.

=head1 EXTENDING

To create a new configuration reader:

=over

=item 1. Extend Gears::Config::Reader

=item 2. Implement C<handled_extensions> to return supported file extensions

=item 3. Implement C<parse> to read and parse the file

=back

Refer to L</SYNOPSIS> for an example. New reader must be included in the
L<Gears::Config/readers> array to be used during config loading.

=head1 INTERFACE

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor.

=head3 handles

	$bool = $reader->handles($filename)

Returns true if this reader can handle the given filename, based on its
extension. The default implementation checks if the file extension matches any
of the extensions returned by L</handled_extensions>.

=head3 handled_extensions

	@extensions = $reader->handled_extensions()

I<Must be implemented by subclasses>

Returns a list of file extensions (without dots) that this reader can handle.
Extensions must not contain dots.

Example:

	sub handled_extensions ($self)
	{
		return qw(yaml yml);
	}

=head3 parse

	$hash_ref = $reader->parse($config, $filename)

I<Must be implemented by subclasses>

Parses the configuration file and returns a hash reference. The C<$config>
parameter is the L<Gears::Config> instance, which can be used for nested
configuration loading if needed. Helper method C<_get_contents> may be used to
get the file content of a configuration file.

Example:

	sub parse ($self, $config, $filename)
	{
		return decode_yaml($self->_get_contents($filename));
	}

