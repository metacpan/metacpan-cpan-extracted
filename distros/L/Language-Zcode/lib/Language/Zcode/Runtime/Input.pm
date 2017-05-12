package Language::Zcode::Runtime::Input;

use strict;
use warnings;

=head1 NAME

Language::Zcode::Runtime::Input - handle (some) input to Z-machine

=DESCRIPTION

This package handles (some) input to the Z-machine.

It does need to call some print routines, but basically it handles
input streams.

=cut

# 10.2
use constant INPUT_KEYBOARD => 0;
use constant INPUT_FILE => 1;

sub setup {
    input_stream(INPUT_KEYBOARD);
}

my $current_input_stream;
my $input_filehandle; # for reading commands from file

# select input stream
sub input_stream {
    my ($stream, $filename) = @_;
    # $filename is an extension (only used internally)
    $current_input_stream = $stream;

    if ($stream == INPUT_FILE) {
	my $ok = 0;
	my $fn = $filename || Language::Zcode::Runtime::IO::filename_prompt("-ext" => "cmd");
	# filename provided if playing back from command line
	if ($fn) {
	    if ($input_filehandle = new IO::File($fn)) {
		$ok = 1;
		# if name provided, don't print this message
		Language::Zcode::Runtime::IO::write_text("Playing back commands from $fn...") 
		    unless defined $filename;
	    } else {
		Language::Zcode::Runtime::IO::write_text("Can't open \"$fn\" for playback: $!");
	    }
	    Language::Zcode::Runtime::IO::newline();
	}
	$current_input_stream = INPUT_KEYBOARD unless $ok;
    } elsif ($stream eq INPUT_KEYBOARD) {
	close $input_filehandle if $input_filehandle;
    } else {
	# XXX this sub doesn't exist
	Language::Zcode::Runtime::IO::fatal_error("Unknown stream $stream");
    }
}

# Return chomped line from a file
# Return undef and stop reading from the file if eof
# Also return undef if we're not supposed to be reading from a file right now
sub get_line_from_file {
    my $s; # = "";
    if ($current_input_stream == INPUT_FILE) {
	$s = <$input_filehandle>;
	if (defined($s)) {
	    # got a command; display it
	    # Chomp to avoid OS differences in \n
	    chomp $s;
	} else {
	    # end of file
	    input_stream(INPUT_KEYBOARD);
	    # ADK returning "" instead of undef makes eof
	    # indistinguishable from an empty line that doesn't end the file
	    #$s = "";
	}
    }
    return $s;
}

# End of program cleanup
sub cleanup {
    close $input_filehandle if $input_filehandle;
    # Don't need to do anything to screen input stream
}

1;
