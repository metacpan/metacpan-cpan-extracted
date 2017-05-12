###########################################
package File::Tail::FAM;
###########################################
use SGI::FAM;
use Log::Log4perl qw(:easy);
use strict;
use warnings;

our $VERSION = "0.02";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        fam => SGI::FAM->new(),
        %options,
    };

    LOGDIE "Mandatory parameter missing: file" unless
        exists $self->{file};

    LOGDIE "File $self->{file} doesn't exist" unless
        -f $self->{file};

    LOGDIE "File $self->{file} isn't readable" unless
        -r $self->{file};

    $self->{fam}->monitor($self->{file}) or 
        LOGDIE "Monitoring $self->{file} failed";

        # Block until we get the 'exist' event to make
        # sure the monitor is in place
    my $e = $self->{fam}->next_event();

    bless $self, $class;

    $self->file_open();
    $self->checkpoint(2);

    return $self;
}

###########################################
sub read_nonblock {
###########################################
    my($self) = @_;

    return $self->read(1);
}

###########################################
sub poll_pending {
# The test suite uses this to avoid race conditions
###########################################
    my($self) = @_;

    while(! $self->{fam}->pending()) {
        select undef, undef, undef, 0.1;
    }
}

###########################################
sub checkpoint {
###########################################
    my($self, $whence) = @_;

    DEBUG "Checkpoint on file $self->{file}";

    if(defined $self->{offset}) {
        my $new_size = -s "$self->{file}";

        if($new_size < $self->{offset}) {
            # File truncated, re-read
            DEBUG "Assuming truncated file";
            $self->file_close();
            $self->file_open(0);
        }
    }

        # Seek to $whence
    seek $self->{fh}, 0, $whence;
    $self->{offset} = tell $self->{fh};

    DEBUG "Offset on $self->{file} is $self->{offset}";
}

###########################################
sub read {
###########################################
    my($self, $nonblock) = @_;

    while(1) {

        if($nonblock) {
            unless($self->{fam}->pending()) {
                DEBUG "No events pending in non-blocking read";
                return undef;
            }
        }

        DEBUG "Blocking for next event";
        my $e = $self->{fam}->next_event();
        DEBUG "Got event: ", $e->type();

        my $data;

        if($e->type() eq "create") {
            $self->checkpoint(0);
            $data = $self->read_more();
            redo unless defined $data;
            return $data;
        } elsif( $e->type() eq "change" ) {
            $data = $self->read_more();
            redo unless defined $data;
            return $data;
        }
    }
}

###########################################
sub read_more {
###########################################
    my($self) = @_;

       # Lift EOF
    seek $self->{fh}, 0, 1;

    local $/;
    $/ = undef;
    
    my $fh = $self->{fh};
    my $data = <$fh>;

    if(defined $data) {
        DEBUG "Found data: '$data'";
    } else {
            # This can happen if we get several change events
            # in a row, no problem
        $self->checkpoint(2);
        return undef;
    }

    $self->{offset} = tell $self->{fh};

    return $data;
}

##################################################
sub file_close {
##################################################
    my($self) = @_;

    DEBUG "Closing file $self->{file}";

    undef $self->{fh};
}

##################################################
sub file_open {
##################################################
    my($self, $whence) = @_;

    $whence = 2 unless defined $whence;

    DEBUG "Opening file $self->{file}";

    my $fh = do { local *FH; *FH; };

    open $fh, "$self->{file}" or
        LOGDIE "Can't open $self->{file} ($!)";

    $self->{fh} = $fh;

        # Seek to EOF
    seek $self->{fh}, 0, $whence;
    $self->{offset} = tell $self->{fh};

    DEBUG "Setting offset to $self->{offset}";
}

1;

__END__

=head1 NAME

File::Tail::FAM - Tail using the File Alteration Monitor (FAM)

=head1 SYNOPSIS

    use File::Tail::FAM;

    my $tail = File::Tail::FAM->new(
        file => "/tmp/abc"
    );

       # Blocking read (without wasting any CPU time)
    while(defined( my $data = $tail->read() )) {
        print "This just got added: [$data]\n";
    }

       # Or, read data in non-blocking mode
    my $data = $tail->read_nonblock();
    if(defined $data) {
        print "This just got added: [$data]\n";
    } else {
        print "Nothing happened\n";
    }

=head1 DESCRIPTION

C<File::Tail::FAM> reports when new data chunks are appended to a 
given file. Similar to the Unix command 

    $ tail -f filename

it watches a file grow continuously and reports whenever a new chunk
of data has been added.

Differently from the traditional approach of periodically polling the file
(used by C<tail -f> and C<File::Tail>), C<File::Tail::FAM> uses the
I<File Alteration Monitor> to get notified by the Linux kernel whenever
new data gets added to the watched file.

This way, C<File::Tail::FAM> will simply block (and therefore won't
use any CPU cycles) until the kernel's notification mechanism wakes
it up when new data has arrived.

C<File::Tail::FAM> uses the Perl module C<SGI::FAM>, which provides an
API to the File Alteration Monitor (FAM) library routines which come
with many Linux distributions (C<man 3 fam>) and are available for
download at

    http://oss.sgi.com/projects/fam/index.html

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
