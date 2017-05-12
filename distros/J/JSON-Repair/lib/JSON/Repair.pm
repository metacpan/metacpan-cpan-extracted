package JSON::Repair;
use parent Exporter;
our @EXPORT_OK = qw/repair_json/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
use warnings;
use strict;
use utf8;
use Carp;

# This Perl version is required because of hashes as errors from
# JSON::Parse.

use 5.014;
use JSON::Parse '0.49';
use C::Tokenize '$comment_re';
our $VERSION = '0.06';

sub repair_json
{
    my ($broken, %options) = @_;
    my $jp = JSON::Parse->new ();
    # Request a hash response from $jp when there is an error.
    $jp->diagnostics_hash (1);
    my $verbose = $options{verbose};
    my $output = $broken;
    while (1) {
	# Try various repairs.  This continues until the JSON is
	# valid, or none of the repairs have worked. After a
	# successful repair, "next;" should be used. Falling through
	# to the end of the while loop which started above causes an
	# exit with an error message.
	eval {
	    $jp->check ($output);
	};
	if (! $@) {
	    last;
	}
	my $error = $@->{error};
	#	    print STDERR "$error\n";
	# The type of thing where the error occurred
	my $type = $@->{'bad type'};
	if ($error eq 'Unexpected character') {
	    my $bad_byte = $@->{'bad byte contents'};
	    # $bad_byte is a number, so for convenient string
	    # comparison, turn it into a string.
	    my $bad_char = chr ($bad_byte);
	    my $valid_bytes = $@->{'valid bytes'};
	    # The position of the bad byte.
	    my $bad_pos = $@->{'bad byte position'};
	    if ($verbose) {
		print "Unexpected character '$bad_char' at byte $bad_pos.\n";
	    }
	    # Everything leading up to the bad byte.
	    my $previous = substr ($output, 0, $bad_pos - 1);
	    # Everything after the bad byte.
	    my $remaining = substr ($output, $bad_pos);
	    if ($bad_char eq "'" && $valid_bytes->[ord ('"')]) {
		my $string;
		# Substitute a ' in the remaining stuff, if there is
		# one, up to a comma or colon or an end-of marker.
		if ($remaining =~ s/^([^,:\]\}]*)'(\s*[,:\]\}])/$1"$2/) {
		    my $string = $1;
		    if ($string =~ /"/) {
			my $quotedstring = $string;
			$quotedstring =~ s/"/\\"/g;
			$remaining =~ s/^\Q$string/$quotedstring/;
		    }
		}
		$output = $previous . '"' . $remaining;
		if ($verbose) {
		    print "Changing single to double quote.\n";
		}
		next;
	    }
	    # An unexpected } or ] usually means there was a comma
	    # after an array or object entry, followed by the end
	    # of the object.
	    elsif ($bad_char eq '}' || $bad_char eq ']') {
		# Look for a comma at the end of it.
		if ($previous =~ /,\s*$/) {
		    $previous =~ s/,(\s*)$/$1/;
		    $output = $previous . $bad_char . $remaining;
		    if ($verbose) {
			print "Removing a trailing comma.\n";
		    }
		    next;
		}
		elsif ($bad_char eq '}' && $previous =~ /:\s*$/) {
		    # In the unlikely event that there was a colon
		    # before the end of the object, add a "null"
		    # to it.
		    $output = $previous . "null" . $remaining;
		    next;
		}
		else {
		    warn "Unexpected } or ] in $type\n";
		}
	    }
	    if (($type eq 'object' || $type eq 'array' ||
		 $type eq 'initial state')) {
		# Handle comments in these states.
		if ($bad_char eq '/') {
		    if ($verbose) {
			print "C-style comments in object or array?\n";
		    }
		    $remaining = $bad_char . $remaining;
		    if ($remaining =~ s/^($comment_re)//) {
			if ($verbose) {
			    print "Deleting comment '$1'.\n";
			}
			$output = $previous . $remaining;
			next;
		    }
		}
		if ($bad_char eq '#') {
		    if ($verbose) {
			print "Hash comments in object or array?\n";
		    }
		    if ($remaining =~ s/^(.*)\n//) {
			if ($verbose) {
			    print "Deleting comment '$1'.\n";
			}
			$output = $previous . $remaining;
			next;
		    }
		}
		if ($type eq 'initial state' && $previous !~ /^\s+$/) {
		    if ($verbose) {
			print "Trailing garbage '$bad_char$remaining'?\n";
		    }
		    $output = $previous;
		    next;
		}
	    }
	    if (($type eq 'object' || $type eq 'array') &&
		$valid_bytes->[ord (',')]) {
		if ($verbose) {
		    print "Missing comma in object or array?\n";
		}
		# Put any space at the end of $previous before the
		# comma, for aesthetic reasons only.
		my $join = ',';
		if ($previous =~ s/(\s+)$//) {
		    $join .= $1;
		}
		$join .= $bad_char;
		$output = $previous . $join . $remaining;
		next;
	    }
	    if ($type eq 'object' && $valid_bytes->[ord ('"')]) {
		if ($verbose) {
		    print "Unquoted key or value in object?\n";
		}
		if ($remaining =~ s/(^[^\}\]:,\n\r"]*)(\s*):/$1"$2:/) {
		    if ($verbose) {
			print "Adding quotes to key '$bad_char$1'\n";
		    }
		    $output = $previous . '"' . $bad_char . $remaining;
		    next;
		}
		if ($previous =~ /:\s*$/) {
		    $remaining = $bad_char . $remaining;
		    if ($remaining =~ s/^(.*)\n/"$1"\n/) {
			if ($verbose) {
			    print "Adding quotes to unquoted value '$1'.\n";
			    $output = $previous . $remaining;
			    next;
			}
		    }
		}
	    }
	    if ($type eq 'string') {
		if ($bad_byte < 0x20) {
		    $bad_char = json_escape ($bad_char);
		    if ($verbose) {
			print "Changing $bad_byte into $bad_char.\n";
		    }
		    $output = $previous . $bad_char . $remaining;
		    next;
		}
	    }
	    # Add a zero to a fraction
	    if ($bad_char eq '.' && $remaining =~ /^[0-9]+/) {
		$output = $previous . "0." . $remaining;
		next;
	    }
	    # Delete a leading zero on a number.
	    if ($type eq 'number') {
		if ($previous =~ /0$/ && $remaining =~ /^[0-9]+/) {
		    if ($verbose) {
			print "Leading zero in number?\n";
		    }
		    $previous =~ s/0$//;
		    $remaining =~ s/^0+//;
		    $output = $previous . $bad_char . $remaining;
#		    print "$output\n";
		    next;
		}
		if ($bad_char =~ /[eE]/ && $previous =~ /\.$/) {
		    if ($verbose) {
			print "Missing zero between . and e?\n";
		    }
		    $output = $previous . "0" . $bad_char . $remaining;
		    next;
		}
	    }
#	    print "$output\n";
	    warn "Could not handle unexpected character '$bad_char' in $type\n";
	    if ($verbose) {
		print_valid_bytes ($valid_bytes);
	    }
	}
	elsif ($error eq 'Unexpected end of input') {
	    #		for my $k (keys %{$@}) {
	    #		    print "$k -> $@->{$k}\n";
	    #		}
	    #		print "Unexpected end of input.\n";
	    if ($type eq 'string') {
		$output .= '"';
		if ($verbose) {
		    print "String ended unexpectedly: adding a quote.\n";
		}
		next;
	    }
	    elsif ($type eq 'object') {
		$output .= '}';
		if ($verbose) {
		    print "Object ended unexpectedly: adding a }.\n";
		}
		next;
	    }
	    elsif ($type eq 'array') {
		$output .= ']';
		if ($verbose) {
		    print "Array ended unexpectedly: adding a ].\n";
		}
		next;
	    }
	    else {
		# Cannot really get an unexpected end of a number
		# since it has no end marker, nor of the initial
		# state. That leaves the case of literals, which might
		# come to an unexpected end like 'tru' or something.
		warn "Unhandled unexpected end of input in $type";
	    }
	}
	elsif ($error eq 'Empty input') {
	    $output = '""';
	    if ($verbose) {
		print "Changing empty input to empty string \"\".\n";
	    }
	    next;
	}
	if ($verbose) {
	    print "$output\n";
	}
	carp "Repair failed: unhandled error $error";
	last;
    }
    return $output;
}

sub print_valid_bytes
{
    my ($valid_bytes) = @_;
    for my $i (0..127) {
	my $ok = $valid_bytes->[$i];
	if ($ok) {
	    print "OK: '",chr ($i),"'\n";
	}
    }
}

# Filched from JSON::Create::PP

sub json_escape
{
    my ($input) = @_;
    $input =~ s/("|\\)/\\$1/g;
    $input =~ s/\x08/\\b/g;
    $input =~ s/\f/\\f/g;
    $input =~ s/\n/\\n/g;
    $input =~ s/\r/\\r/g;
    $input =~ s/\t/\\t/g;
    $input =~ s/([\x00-\x1f])/sprintf ("\\u%04x", ord ($1))/ge;
    return $input;
}

1;
