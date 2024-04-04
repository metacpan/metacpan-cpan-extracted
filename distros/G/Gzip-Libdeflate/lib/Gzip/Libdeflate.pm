package Gzip::Libdeflate;
use warnings;
use strict;
our $VERSION = '0.08';
require XSLoader;
XSLoader::load ('Gzip::Libdeflate', $VERSION);

use File::Slurper qw!read_binary write_binary!;
use Carp;

sub get_from
{
    my (%options) = @_;
    my $from;
    if ($options{in}) {
	$from = read_binary ($options{in});
    }
    elsif ($options{from}) {
	$from = $options{from};
    }
    if (! $from) {
	carp "Specify one of from => scalar or in => file";
    }
    return $from;
}

sub make_out
{
    my ($out, %options) = @_;
    my $outfile = $options{out};
    if ($outfile) {
	write_binary ($outfile, $out);
    }
    return $out;
}

sub compress_file
{
    my ($o, %options) = @_;
    my $from = get_from (%options);
    if (! $from) {
	return undef;
    }
    my $out = $o->compress ($from);
    return make_out ($out, %options);
}

sub decompress_file
{
    my ($o, %options) = @_;
    my $from = get_from (%options);
    if (! $from) {
	return undef;
    }
    my $type = $o->get_type ();
    if ($type ne 'gzip') {
	if (! $options{size}) {
	    warn "A non-zero numerical size is required to decompress deflate/zlib inputs";
	    return undef;
	}
    }
    my $size = $options{size};
    if (! $size) {
	$size = 0;
    }
    my $out = $o->decompress ($from, $size);
    return make_out ($out, %options);
}

1;
