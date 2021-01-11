package InfluxDB::Writer::RememberingFileTailer;

# ABSTRACT: RememberingFileTailer
our $VERSION = '1.003'; # VERSION

use Moose;
use feature 'say';

use IO::Async::File;
use IO::Async::FileStream;
use IO::Async::Loop;
use Hijk ();
use Carp qw(croak);
use InfluxDB::LineProtocol qw(line2data data2line);
use Log::Any qw($log);
use File::Spec::Functions;
use File::Spec qw(splitpath);

extends 'InfluxDB::Writer::FileTailer';

has 'done_dir' => ( is => 'rw', isa => "Str" );

before 'run' => sub {
    my $self = shift;

    my $done_dir = catdir( $self->dir, 'done' );
    if ( -d $done_dir ) {
        $self->done_dir($done_dir);
    }
    else {
        croak "Missing 'done' directory, please create: " . $done_dir;
    }

};

sub archive_file {
    my $self = shift;
    my $file = shift;

    my $done_dir = $self->done_dir;
    my ( $vol, $dirs, $basename ) = File::Spec->splitpath($file);

    my $destination = catfile( $done_dir, $basename );
    my $count = 0;
    while ( -f $destination ) {
        $count++;
        my $new_destination = catfile( $done_dir, $basename ) . '_' . $count;
        $log->infof( "Renaming destination %s to %s",
            $destination, $new_destination );
        $destination = $new_destination;
    }

    if ( -s $file == 0 ) {

        if ( unlink($file) ) {
            $log->infof( "Unlinked zero size stats file %s", $file );
            return 1;
        }
        else {
            $log->warnf( "Could not unlink zero size stats file %s (%s)",
                $file, $! );
            return 0;
        }

        return 0;
    }

    if ( rename( $file, $destination ) ) {
        $log->infof( "Archived file %s to %s", $basename, $done_dir );
        return 1;
    }
    else {
        $log->errorf( "Failed to archive %s to %s", $basename, $done_dir );
        croak "Failed to archive $file";
        return 0;
    }

}


sub slurp_and_send {
    my $self = shift;
    my $file = shift;

    if ( open( my $fh, "<", $file ) ) {
        $log->infof( "Slurping %s", $file );

        while ( my $line = <$fh> ) {
            chomp($line);
            if ( $self->has_tags ) {
                $line = $self->add_tags_to_line($line);
            }
            if ($line !~ /\s\d+$/) {
                # Line does not end in timestamp
                $log->warnf("Skipping probably broken line %s", $line);
                next;
            
            }
            $self->buffer_push($line);

            if ( $self->buffer_size > $self->flush_size ) {
                if ( !$self->send ) {
                    $log->warnf( "Unable to send buffer (%i lines)",
                        $self->buffer_size );
                    return;
                }
            }
        }

        if ( $self->buffer_size ) {
            $log->infof( "Clear buffer (size %i) for file %s",
                $self->buffer_size, $file );
            if ( !$self->send ) {
                $log->warnf( "Unable to send clear buffer (%i lines)",
                    $self->buffer_size );
                return;
            }
        }

        $log->infof( "Finished slurping %s", $file );

        return 1;
    }

    return;

}

override 'archive_hook' => sub {
    shift->archive_file(@_);
    super();
};

override 'cleanup_hook' => sub {
    my ( $self, $file ) = @_;

    if ( $self->slurp_and_send($file) ) {
        $self->archive_file($file);
    }
    return super();

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

InfluxDB::Writer::RememberingFileTailer - RememberingFileTailer

=head1 VERSION

version 1.003

=head2 slurp_and_send

IO::Async read operations are blocking so it does not make sense to wrice
complicated async code here. We want to read the files that are left over and
send them to influx asap, then move them to the archive folder (aka. out of the
way)

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
