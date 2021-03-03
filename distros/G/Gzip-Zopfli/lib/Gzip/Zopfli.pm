package Gzip::Zopfli;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/zopfli_compress zopfli_compress_file/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.01';
require XSLoader;
XSLoader::load ('Gzip::Zopfli', $VERSION);

use File::Slurper qw!read_binary write_binary!;

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

sub zopfli_compress_file
{
    my ($o, %options) = @_;
    my $from = get_from (%options);
    if (! $from) {
	return undef;
    }
    my $out = ZopfliCompress ($from, no_warn => 1, %options);
    return make_out ($out, %options);
}

1;
