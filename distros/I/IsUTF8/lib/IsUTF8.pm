package IsUTF8;

# $Id: IsUTF8.pm 2011 2006-06-21 08:23:10Z heiko $
# $URL: https://svn.schlittermann.de/pub/perl-unicode-detect/trunk/lib/IsUTF8.pm $
# © 2006 <hs@schlittermann.de>
#

=head1 NAME 

IsUTF8 - detects if UTF8 characters are present

=cut

use strict;
use warnings;

our $VERSION = '0.2';

use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/&isUTF8/;

=head1 SYNOPSIS

    use IsUTF8;
    $result = IsUTF8::isUTF8;
    $result = IsUTF8::isUTF8($line);

    use IsUTF8 qw(isUTF8);
    $result = isUTF8;
    $result = isUTF8($line);

    use IsUTF8 qw(isUTF8 debug);
    $result = isUTF8;
    $result = isUTF8($line);

    if (not defined $result) {
	print "Contains some characters with 8th bit set!";
    }
    if ($result == 0) {
	print "Plain ASCII (0..127)";
    }
    if ($result) {
	print "Contains UTF8";
    }

=cut

my $debug = 0;

sub import(@) {
    $debug = grep /^debug$/, @_;
    @_ = grep !/^debug$/, @_;
    goto &Exporter::import;
}

sub isUTF8(;$) {
    my $data = @_ ? $_[0] : $_;

	$data =~ s/\s*$// if $debug;
	print STDERR "test: $data\n" if $debug > 2;

	if ($data =~ /(
	      [\xc0-\xdf][\x80-\xbf]
	    | [\xe0-\xef][\x80-\xbf]{2}
	    | [\xf0-\xf7][\x80-\xbf]{3}	) /x
	) {
	    if ($debug) {
		print STDERR "$data\n" 
		    . " " x index($data, $1)
		    . "^\n";
	    }

	    return 1;

	}

	if ($data =~ /([\x80-\xff])/) {
	    if ($debug) {
		print STDERR "$data\n",
		    . " " x index($data, $1)
		    . "^\n";
	    }

	    return undef;
	}

	return 0;
}

=head1 DESCRIPTION

This tests the given line and returns true if there is at least one
UTF8 character sequence.  (Actually the tests returns after the first
sequence found.)  C<undef> is returned if there is some other character 
with the 8th bit set. C<0> is returned if there are only characters 
from C<0x00> to C<0x7f>.

=head1 BACKGROUND

UTF8-Encoding looks like this:

    1111.0x:   1111.0000-1111.0111 0xF0 - 0xF7, followed by 3 bytes
    1110.xx:   1110.0000-1110.1111 0xE0 - 0xEF, followed by 2 bytes
    110x.xx:   1100.0000-1101.1111 0xC0 - 0xDF, followed by 1 byte
    10xx.xx:   1000.0000-1011.1111 0x80 - 0xBF  (following byte as above)

=head1 SEE ALSO

L<Encode::Guess> and L<Encode::Detect>

=head1 BUGS

First release.  Please do not rely on a stable API yet.  If you're interested
in stabilizing, please tell me.

Probably.  Not tested a lot!

=head1 AUTHOR

Heiko Schlittermann <hs@schlittermann.de>

=cut


1;
