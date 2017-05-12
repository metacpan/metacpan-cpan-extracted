
package Log::Parallel::Metadata;

use strict;
use warnings;
use YAML::Syck;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(compress_metadata);

sub compress_metadata
{
	my (@meta) = @_;

	my %headers;
	my %sort_types;
	my %sort_by;

	for my $m (@meta) {
		my $hyaml = Dump($m->{header});
		if ($headers{$hyaml}) {
			$m->{header} = $headers{$hyaml};
		} else {
			$headers{$hyaml} = $m->{header};
			my $sbyaml = Dump($m->{header}{sort_by});
			if ($sort_by{$sbyaml}) {
				$m->{header}{sort_by} = $sort_by{$sbyaml};
			} else {
				$sort_by{$sbyaml} = $m->{header}{sort_by};
			}
			my $styaml = Dump($m->{header}{sort_types});
			if ($sort_by{$styaml}) {
				$m->{header}{sort_types} = $sort_by{$styaml};
			} else {
				$sort_by{$styaml} = $m->{header}{sort_types};
			}
		}
		my $mstyaml = Dump($m->{sort_types});
		if ($sort_by{$mstyaml}) {
			$m->{sort_types} = $sort_by{$mstyaml};
		} else {
			$sort_by{$mstyaml} = $m->{sort_types};
		}
	}
	return @meta;
}

1;


__END__

=head1 DESCRIPTION

This is a support module for Log::Parallel

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

