package Gears::Config::Reader;
$Gears::Config::Reader::VERSION = '0.001';
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

