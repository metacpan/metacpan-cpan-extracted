#!/usr/bin/perl
use strict;
use warnings;

my $host;
BEGIN {
	eval { require ApacheLog::Compressor } or die "ApacheLog::Compressor is required";
	$host = eval { require Sys::Hostname; Sys::Hostname::hostname } // 'localhost';
}

use Encode qw(decode_utf8 is_utf8);

my $in = shift @ARGV;
die "No input file provided" unless defined $in && length $in;

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

# Processor for incoming data
my $alc_in = ApacheLog::Compressor->new(
	on_write	=> sub {
		my ($self, $pkt) = @_;
		print { $out_fh } $pkt;
	},
	filter => sub {
		my ($self, $data) = @_;
		# Ignore entries with no URL or timestamp
		return 0 unless defined $data->{url} && length $data->{url};
		return 0 unless $data->{timestamp};

		# Skip irrelevant entries (some loadbalancers use this as a 'ping')
		return 0 if $ApacheLog::Compressor::HTTP_METHOD_LIST[$data->{method}] eq 'OPTIONS' && $data->{url} eq '*';
		return 1;
	}
);

# Input file - normally use whichever one's just been closed + rotated
open my $in_fh, '<', $in or die "Failed to open input file $in - $!";
binmode $in_fh, ':encoding(utf8)';

# Initial packet to identify which server this came from
$alc_in->send_packet('server',
	hostname => hostname(),
);

# Read and compress all the lines in the files
while(my $line = <$in_fh>) {
        $alc->compress($line);
}
close $in_fh or die $!;
close $out_fh or die $!;

# Dump the stats in case anyone finds them useful
$alc->stats;


# Provide a callback to send data through to the file
my $alc = ApacheLog::Compressor->new(
	on_log_line	=> sub {
		my ($self, $data) = @_;
		# Use the helper method to expand back to plain text representation
		print { $out_fh } $self->data_to_text($data) . "\n";
	},
);

# Input file - normally use whichever one's just been closed + rotated
open my $in_fh, '<', $in or die "Failed to open input file $in - $!";
binmode $in_fh;

# Read and expand all the lines in the files
my $buffer = '';
while(read($in_fh, my $data, 1024) >= 0) {
	$buffer .= $data;
        $alc->expand(\$buffer);
}
close $in_fh or die $!;
close $out_fh or die $!;

# Dump the stats in case anyone finds them useful
$alc->stats;

#!/usr/bin/env perl
use strict;
use warnings;

use constant MAPPED_KEYS => qw(vhost ip user url refer useragent);
use constant UNMAPPED_KEYS => qw(result duration size method ver);

sub setup {
	my $self = shift;
}

sub on_log_line {
	my $self = shift;
	my $line_data = shift;
	$repo->gather(
		map $_ . ':' . $line_data->{$_}, MAPPED_KEYS,
	)->apply(sub {
		# This will now have mappings from key to ID
		my %data = @_;
		# and for the remainder we use the original values
		@data{+UNMAPPED_KEYS} = @{ $line_data }{+UNMAPPED_KEYS};
		$self->writelog(\%data);
	});
}

sub writelog {
	my $self = shift;
}

1;

__END__

=pod

package Mixin::Data::Source;



=cut

