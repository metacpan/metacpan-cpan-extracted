package Gzip::Faster;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw/gzip gunzip gzip_file gunzip_file gzip_to_file/;
our @EXPORT_OK = qw/deflate inflate deflate_raw inflate_raw/;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);
use Carp;
our $VERSION = '0.21';
require XSLoader;
XSLoader::load ('Gzip::Faster', $VERSION);

sub get_file
{
    my ($file) = @_;
    open my $in, "<:raw", $file or croak "Error opening '$file': $!";
    local $/;
    my $zipped = <$in>;
    close $in or croak "Error closing '$file': $!";
    return $zipped;
}

sub gzip_options
{
    my ($plain, %options) = @_;
    my $gf = __PACKAGE__->new ();
    my $file_name = $options{file_name};
    my $mod_time = $options{mod_time};
    if ($file_name) {
	$gf->file_name ($file_name);
    }
    if ($mod_time) {
	$gf->mod_time ($mod_time);
    }
    return $gf->zip ($plain);
}

sub gzip_file
{
    my ($file, %options) = @_;
    my $plain = get_file ($file);
    if (keys %options) {
	return gzip_options ($plain, %options);
    }
    else {
	my $mod_time = (stat ($file))[9];
	return gzip_options ($plain, file_name => $file, mod_time => $mod_time);
    }
}

sub gunzip_file
{
    my ($file, %options) = @_;
    my $zipped = get_file ($file);
    my $plain;
    if (keys %options) {
	my $gf = __PACKAGE__->new ();
	$plain = $gf->unzip ($zipped);
	my $file_name_ref = $options{file_name};
	if (defined ($file_name_ref) && ref $file_name_ref ne 'SCALAR') {
	    warn "Cannot write file name to non-scalar reference";
	}
	else {
	    $$file_name_ref = $gf->file_name ();
	}
	my $mod_time_ref = $options{mod_time};
	if (defined ($mod_time_ref) && ref $mod_time_ref ne 'SCALAR') {
	    warn "Cannot write modification time to non-scalar reference";
	}
	else {
	    $$mod_time_ref = $gf->mod_time ();
	}
    }
    else {
	$plain = gunzip ($zipped);
    }
    return $plain;
}

sub gzip_to_file
{
    my ($plain, $file, %options) = @_;
    my $zipped;
    if (keys %options) {
	$zipped = gzip_options ($plain, %options);
    }
    else {
	$zipped = gzip ($plain);
    }
    open my $in, ">:raw", $file or croak "Error opening '$file': $!";
    print $in $zipped;
    close $in or croak "Error closing '$file': $!";
}

1;
