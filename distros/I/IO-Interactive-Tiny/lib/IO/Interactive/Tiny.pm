package IO::Interactive::Tiny;

# use strict;
# use warnings;

$IO::Interactive::Tiny::VERSION = '0.2';

sub is_interactive {
    my ($out_handle) = (@_, select);    # Default to default output handle

    # Not interactive if output is not to terminal...
    return 0 if not -t $out_handle;

    # If *ARGV is opened, we're interactive if...
    if ( tied(*ARGV) or defined(fileno(ARGV)) ) { # IO::Interactive::Tiny: this is the only relavent part of Scalar::Util::openhandle() for 'openhandle *ARGV'
        # ...it's currently opened to the magic '-' file
        return -t *STDIN if defined $ARGV && $ARGV eq '-';

        # ...it's at end-of-file and the next file is the magic '-' file
        return @ARGV>0 && $ARGV[0] eq '-' && -t *STDIN if eof *ARGV;

        # ...it's directly attached to the terminal 
        return -t *ARGV;
    }

    # If *ARGV isn't opened, it will be interactive if *STDIN is attached 
    # to a terminal.
    else {
        return -t *STDIN;
    }
}

1;
