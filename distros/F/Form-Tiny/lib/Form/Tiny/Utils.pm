package Form::Tiny::Utils;

use v5.10;
use warnings;
use Exporter qw(import);

our $VERSION = '1.13';
our @EXPORT = qw(
	try
);

sub try
{
	my ($sub) = @_;

	local $@;
	my $ret = not eval {
		$sub->();
		return 1;
	};

	if ($@ && $ret) {
		$ret = $@;
	}

	return $ret;
}

1;
