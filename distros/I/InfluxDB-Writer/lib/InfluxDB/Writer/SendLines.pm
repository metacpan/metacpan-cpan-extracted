package InfluxDB::Writer::SendLines;

# ABSTRACT: Send lines from a file to InfluxDB
our $VERSION = '1.003'; # VERSION

use strict;
use warnings;
use feature 'say';


use Moose;
use Carp qw(croak);
use Log::Any qw($log);
use File::Spec::Functions;
use Hijk ();

has 'file'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'influx_host' => ( is => 'ro', isa => 'Str', required => 1 );
has 'influx_port' =>
    ( is => 'ro', isa => 'Int', default => 8086, required => 1 );
has 'influx_db'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'buffer_size'     => ( is => 'ro', isa => 'Int', default  => 1000 );

with qw(InfluxDB::Writer::AuthHeaderRole);

$| = 1;

my @buffer;

sub run {
    my $self = shift;

    $log->infof( "Starting %s with file %s", __PACKAGE__, $self->file );

    my $f     = $self->file;
    my $lines = `wc -l $f`;
    chomp($lines);
    $lines =~ s/ .*//;
    my $total = $lines;
    my $start = scalar time;

    open( my $in, "<", $self->file ) || die $!;

    my $cnt       = 0;
    my $print_cnt = $self->buffer_size * 50;
    while ( my $line = <$in> ) {
        my $elements = push( @buffer, $line );
        if ( $elements >= $self->buffer_size ) {
            $self->send;
        }
        $cnt++;
        if ( $cnt % $print_cnt == 0 ) {
            my $now   = scalar time;
            my $diff  = $now - $start || 1;
            my $speed = $cnt / $diff;
            my $estimate =
                $speed > 0 ? ( $total - $cnt ) / $speed : 'Infinity';
            printf( "  % 6i/%i (%.2f/s) time left: %i sec\n",
                $cnt, $total, $speed, $estimate );
        }
    }
    $self->send;
}

sub send {
    my $self       = shift;
    my $second_try = shift;
    my $new_buffer = shift;

    my $to_send = $second_try ? $new_buffer : \@buffer;

    my %args;
    if ( $self->_with_auth ) {
        $args{head} = [ "Authorization" => $self->_auth_header ];
    }

    $log->debugf( "Sending %i lines to influx", scalar @$to_send );
    my $res = Hijk::request(
        {   method       => "POST",
            host         => $self->influx_host,
            port         => $self->influx_port,
            path         => "/write",
            query_string => "db=" . $self->influx_db,
            body         => join( '', @$to_send ),
            %args,
        }
    );

    if ( $res->{status} != 204 ) {
        if (!$second_try
            && (
                (   exists $res->{error}
                    && $res->{error} & Hijk::Error::TIMEOUT
                )
                || ( $res->{status} == 500 && $res->{body} =~ /timeout/ )
            )
            ) {
            # wait a bit and try again with smaller packages
            my @half = splice( @$to_send, 0, int( scalar @$to_send / 2 ) );
            print ':';
            $self->send( 1, \@half );
            $self->send( 1, $to_send );
        }
        else {
            $log->errorf(
                "Could not send %i lines to influx: %s",
                scalar @$to_send,
                $res->{body}
            );
            open( my $fh, ">>", $self->file . '.err' ) || die $!;
            print $fh join( '', @$to_send );
            close $fh;
            print 'X';
        }
    }
    else { # success
        print $second_try ? ',' : '.';
    }

    @$to_send = () unless $second_try;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

InfluxDB::Writer::SendLines - Send lines from a file to InfluxDB

=head1 VERSION

version 1.003

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
