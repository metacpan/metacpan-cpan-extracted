package Measure::Everything::Adapter::InfluxDB::File;

# ABSTRACT: Write stats formatted as InfluxDB lines into a file
our $VERSION = '1.003'; # VERSION

use strict;
use warnings;

use Config;
use Fcntl qw/:flock/;

use base qw(Measure::Everything::Adapter::Base);
use InfluxDB::LineProtocol qw(data2line);

my $HAS_FLOCK = $Config{d_flock} || $Config{d_fcntl_can_lock} || $Config{d_lockf};

sub init {
    my $self = shift;
    my $file = $self->{file};
    open( $self->{fh}, ">>", $file )
      or die "cannot open '$file' for append: $!";
    $self->{fh}->autoflush(1);
}

sub write {
    my $self = shift;
    my $line = data2line(@_);

    flock($self->{fh}, LOCK_EX) if $HAS_FLOCK;
    $self->{fh}->print($line."\n");
    flock($self->{fh}, LOCK_UN) if $HAS_FLOCK;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter::InfluxDB::File - Write stats formatted as InfluxDB lines into a file

=head1 VERSION

version 1.003

=head1 SYNOPSIS

    Measure::Everything::Adapter->set( 'InfluxDB::File', file => '/path/to/file.stat' );

=head1 DESCRIPTION

Write stats using
L<InfluxDB::LineProtocol|https://metacpan.org/pod/InfluxDB::LineProtocol>
into a file.

The file is opened for append with autoflush on. If flock
is available, the handle will be locked when writing. (Docs and code
copied as-is from Log::Any::Adapter::File)

It is your job to somehow process the file to get the lines into
L<InfluxDB|https://influxdb.com/>. We will release a set of modules
that help doing that in the near future.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
