package Log::Saftpresse::CountersOutput::JSON;

use strict;
use warnings;

# ABSTRACT: plugin to dump counters in JSON format
our $VERSION = '1.6'; # VERSION

use base 'Log::Saftpresse::CountersOutput';

use JSON;

sub output {
	my ( $self, $counters ) = @_;
	my $json = JSON->new;
	$json->pretty(1);
	my %data = map {
		$_ => $counters->{$_}->counters,
	} keys %$counters;
	print $json->encode( \%data );	
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::CountersOutput::JSON - plugin to dump counters in JSON format

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
