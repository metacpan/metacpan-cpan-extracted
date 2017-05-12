package InfluxDB::Writer::FileTailer;
use strict;
use warnings;
use feature 'say';

our $VERSION = '1.000';

# ABSTRACT: Tail files and send lines to InfluxDB

use Moose;
use IO::Async::File;
use IO::Async::FileStream;
use IO::Async::Loop;
use Hijk ();
use Carp qw(croak);
use InfluxDB::LineProtocol qw(line2data data2line);
use Log::Any qw($log);
use File::Spec::Functions;
use Cwd 'abs_path';

with qw(InfluxDB::Writer::AuthHeaderRole);

has 'dir'         => ( is => 'ro', isa => 'Str', required => 1 );
has 'influx_host' => ( is => 'ro', isa => 'Str', required => 1 );
has 'influx_port' =>
    ( is => 'ro', isa => 'Int', default => 8086, required => 1 );
has 'influx_db' => ( is => 'ro', isa => 'Str', required => 1 );

has 'flush_size' =>
    ( is => 'ro', isa => 'Int', required => 1, default => 1000 );
has 'flush_interval' =>
    ( is => 'ro', isa => 'Int', required => 1, default => 30 );
has 'tags' => ( is => 'ro', isa => 'HashRef', predicate => 'has_tags' );
has '_files' => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has '_loop' => ( is => 'ro', isa => 'IO::Async::Loop', lazy_build => 1 );
has 'buffer' => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] }, traits => ['Array'],
    handles => {
        buffer_push => 'push',
        buffer_all => 'elements',
        buffer_size => 'count',
        buffer_splice => 'splice',
        buffer_is_empty => 'is_empty',
    },

);

sub _build__loop {
    return IO::Async::Loop->new;
}

sub run {
    my $self = shift;

    unless ( -d $self->dir ) {
        croak "Not a directory: " . $self->dir;
    }

    $log->infof( "Starting %s in directory %s", __PACKAGE__, $self->dir );

    $self->watch_dir;

    my $dir = IO::Async::File->new(
        filename         => $self->dir,
        on_mtime_changed => sub {
            $self->watch_dir;
        },
    );

    $self->_loop->add($dir);

    my $timer = IO::Async::Timer::Periodic->new(    # could be Countdown
        interval => $self->flush_interval,
        on_tick  => sub {
            $self->send;
        },
    );
    $timer->start;
    $self->_loop->add($timer);

    $self->_loop->run;
}


sub cleanup_hook {}
sub archive_hook {}

sub watch_dir {
    my ($self) = @_;

    $log->infof( "Checking for new files to watch in %s", $self->dir );
    opendir( my $dh, $self->dir );
    while ( my $f = readdir($dh) ) {
        next unless $f =~ /\.stats$/;
        if ( my $watcher =
            $self->setup_file_watcher( catfile( $self->dir, $f ) ) ) {
            $self->_loop->add($watcher);
        }
    }
    closedir($dh);
}

sub is_running {
    my ($self, $pid, $file) = @_;

    my $running = kill('ZERO', $pid);
    return unless $running;

    # This might only work on linux with $proc access
    my $fd_dir = catdir("/", "proc", $pid, "fd");
    if (-d $fd_dir ) {
        my $abs_file = File::Spec->rel2abs( $file );

        my $found = 0;
        opendir(my $dh, $fd_dir);
        while ( my $f = readdir($dh) ) {
            $f = catfile($fd_dir, $f);

            if ( -f $f && -l $f ) {

                my $filename = Cwd::abs_path( $f );
                if ($abs_file eq $filename) { #need to close dir
                    $found = 1;
                    last;
                }
            }
        }
        closedir($dh);
    
        return $found;
    }

    return $running;

}

sub setup_file_watcher {
    my ( $self, $file ) = @_;

    $file =~ /(\d+)\.stats$/;
    my $pid = int($1);

    my $is_running = $self->is_running( $pid, $file );

    if (!$is_running) {

        if ( my $w = $self->_files->{$file} ) {
            $self->_loop->remove($w);
            undef $w;
            delete $self->_files->{$file};
            $log->infof( "Removed watcher for %s because pid %i is not more",
                $file, $pid );

            $self->archive_hook($file);

        }
        else {
            $log->debugf(
                "Skipping file %s because pid %i seems to be not running.",
                $file, $pid );

            $self->cleanup_hook($file);
        }
        return;
    }

    if ( $self->_files->{$file} ) {
        $log->debugf( "Already watching file %s", $file );
        return;
    }

    if ( open( my $fh, "<", $file ) ) {
        my $filestream = IO::Async::FileStream->new(
            read_handle => $fh,
            on_initial  => sub {
                my ($stream) = @_;
                $stream->seek_to_last("\n");    # TODO remember last position?
            },

            on_read => sub {
                my ( $stream, $buffref ) = @_;

                while ( $$buffref =~ s/^(.*\n)// ) {
                    my $line = $1;
                    if ( $self->has_tags ) {
                        $line = $self->add_tags_to_line($line);
                    }
                    $self->buffer_push($line);
                }

                if ( $self->buffer_size > $self->flush_size ) {
                    $self->send;
                }

                return 0;
            },
        );
        $log->infof( "Tailing file %s", $file );
        $self->_files->{$file} = $filestream;
        return $filestream;
    }
    else {
        $log->errorf( "Could not open file %s: %s", $file, $! );
        return;
    }
}

sub send {
    my ($self) = @_;

    my $current_size = $self->buffer_size;
    return unless $current_size;

    my @to_send = $self->buffer_splice(0, $current_size);

    my %args;
    if ( $self->_with_auth ) {
        $args{head} = [ "Authorization" => $self->_auth_header ];
    }
    $log->debugf( "Sending %i lines to influx", scalar @to_send);
    my $res = Hijk::request(
        {   method       => "POST",
            host         => $self->influx_host,
            port         => $self->influx_port,
            path         => "/write",
            query_string => "db=" . $self->influx_db,
            body         => join( "\n", @to_send ),
            %args,
        }
    );
    if (my $current_error = $res->{error}) {

        my @errs = (qw/
            CONNECT_TIMEOUT
            READ_TIMEOUT
            TIMEOUT
            CANNOT_RESOLVE
            REQUEST_SELECT_ERROR
            REQUEST_WRITE_ERROR
            REQUEST_ERROR
            RESPONSE_READ_ERROR
            RESPONSE_BAD_READ_VALUE
            RESPONSE_ERROR
            /);

        my @matches;
        foreach my $err (@errs) {
            my $const = eval "Hijk::Error::" . $err;
            if ( $current_error & $const ) {
                push(@matches, $err);
            }
        }

        $log->errorf("Hijk Request Error(s) cannot send %s", join(", ", @matches));

        return;
    
    }
    if ( $res->{status} != 204 ) {
        $log->errorf(
            "Could not send %i lines to influx: %s",
            scalar @to_send,
            $res->{body}
        );

        return;
    }

    return scalar(@to_send);
}

sub add_tags_to_line {
    my ( $self, $line ) = @_;

    my ( $measurement, $values, $tags, $timestamp ) = line2data($line);
    my $combined_tags;
    if ($tags) {
        $combined_tags = { %$tags, %{ $self->tags } };
    }
    else {
        $combined_tags = $tags;
    }
    return data2line( $measurement, $values, $combined_tags, $timestamp );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

InfluxDB::Writer::FileTailer - Tail files and send lines to InfluxDB

=head1 VERSION

version 1.002

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
