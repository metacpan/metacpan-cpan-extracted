package Deflate::Faster;

use strict;
use warnings;
use Carp;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(gzip gunzip gzip_file gunzip_file gzip_to_file);
our @EXPORT_OK = qw(deflate inflate deflate_raw inflate_raw gunzip_to_file);
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Deflate::Faster', $VERSION);

sub CLONE_SKIP { 1 }

sub get_file
{
    my ($file) = @_;
    open my $in, "<:raw", $file or croak "Error opening '$file': $!";
    my $size = -s $in;
    my $content;
    if (defined $size && $size > 0) {
        my $read = sysread ($in, $content, $size);
        if (! defined $read || $read != $size || ! eof ($in)) {
            seek $in, 0, 0;
            local $/;
            $content = <$in>;
        }
    }
    else {
        local $/;
        $content = <$in>;
    }
    close $in or croak "Error closing '$file': $!";
    return $content;
}

sub gzip_options
{
    my ($plain, %options) = @_;
    my $df = __PACKAGE__->new();
    my $file_name = $options{file_name};
    my $mod_time  = $options{mod_time};
    my $level     = $options{level};

    if (defined $file_name && length($file_name)) {
        $df->file_name($file_name);
    }
    if (defined $mod_time && $mod_time > 0) {
        $df->mod_time($mod_time);
    }
    if (defined $level) {
        $df->level($level);
    }
    if (defined $options{copy_perl_flags}) {
        $df->copy_perl_flags($options{copy_perl_flags});
    }
    return $df->zip($plain);
}

sub gzip_file
{
    my ($file, %options) = @_;
    my $plain = get_file($file);
    $options{file_name} = $file unless exists $options{file_name};
    $options{mod_time} = (stat($file))[9] unless exists $options{mod_time};
    return gzip_options($plain, %options);
}

sub gunzip_file
{
    my ($file, %options) = @_;
    my $zipped = get_file($file);
    my $plain;
    if (keys %options) {
        my $df = __PACKAGE__->new();
        if (defined $options{max_size}) {
            $df->max_size($options{max_size});
        }
        if (defined $options{copy_perl_flags}) {
            $df->copy_perl_flags($options{copy_perl_flags});
        }
        $plain = $df->unzip($zipped);

        my $file_name_ref = $options{file_name};
        if (defined $file_name_ref) {
            if (ref $file_name_ref ne 'SCALAR') {
                warn "Cannot write file name to non-scalar reference";
            }
            else {
                $$file_name_ref = $df->file_name();
            }
        }

        my $mod_time_ref = $options{mod_time};
        if (defined $mod_time_ref) {
            if (ref $mod_time_ref ne 'SCALAR') {
                warn "Cannot write modification time to non-scalar reference";
            }
            else {
                $$mod_time_ref = $df->mod_time();
            }
        }
    }
    else {
        $plain = gunzip($zipped);
    }
    return $plain;
}

sub gzip_to_file
{
    my ($plain, $file, %options) = @_;
    my $zipped = keys %options ? gzip_options($plain, %options) : gzip($plain);
    _write_file($file, $zipped);
}

sub gunzip_to_file
{
    my ($zipped, $file, %options) = @_;
    my $plain;
    if (keys %options) {
        my $df = __PACKAGE__->new();
        if (defined $options{max_size}) {
            $df->max_size($options{max_size});
        }
        $plain = $df->unzip($zipped);
    }
    else {
        $plain = gunzip($zipped);
    }
    _write_file($file, $plain);
}

sub _write_file
{
    my ($file, $data) = @_;
    open my $out, ">:raw", $file or croak "Error opening '$file': $!";
    if (defined $data && length($data) > 0) {
        my $len = length($data);
        my $written = 0;
        while ($written < $len) {
            my $bytes = syswrite($out, $data, $len - $written, $written);
            if (! defined $bytes) {
                croak "Error writing to '$file': $!";
            }
            if ($bytes == 0) {
                croak "Error writing to '$file': syswrite returned 0";
            }
            $written += $bytes;
        }
    }
    close $out or croak "Error closing '$file': $!";
}

1;
