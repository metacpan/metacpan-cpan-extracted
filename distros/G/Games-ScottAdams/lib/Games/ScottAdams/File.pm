# $Id: File.pm,v 1.3 2006/11/03 20:59:19 mike Exp $

# File.pm - a cleverer IO::File-alike that does pushback

package Games::ScottAdams::File;
use strict;

# This module simply implements a slightly cleverer IO::File-alike
# that remembers the filename, maintains a notion of the current line
# number (useful for diagnostics) and can maintain an arbitrary number
# of pushback lines.  It clearly has wider applicability outside of
# the Scott Adams module and should probably not be a
# Games::ScottAdams class.

use IO::File;


sub new {
    my $class = shift();
    my($filename) = @_;

    my $f = new IO::File("<$filename")
	or return undef;

    return bless {
	f => $f,
	filename => $filename,
	linenumber => 0,
	pushback => [],
	buf => "",		# for getint() and getstring() only
    }, $class;
}


sub getline {
    my $this = shift();
    my($trim) = @_;

    my $line = pop @{ $this->{pushback} };
    if (!defined $line) {
      AGAIN:
	$this->{linenumber}++;
	$line = $this->{f}->getline();
	return undef if !defined $line;
    }

    if ($trim) {
	$line =~ s/#.*//;
	$line =~ s/\s+$//;
	goto AGAIN if $line =~ /^$/;
    }

    return $line;
}


sub ungetline {
    my $this = shift();
    my($line) = @_;

    push @{ $this->{pushback} }, $line;
}


# Calls to getint() and getstring() may be freely intermixed, but
# won't play nice if mixed with getline() and ungetline() calls.

sub getint {
    my $this = shift();
    $this->_refresh();
    die "getint($this) on non-int buffer '" . $this->{buf} . "'"
	if $this->{buf} !~ /^\d/;

    $this->{buf} =~ s/(\d+)//;
    return $1;
}

sub getstring {
    my $this = shift();
    $this->_refresh();

    $this->{buf} =~ s/^[""]//
	or die "getstring($this) on non-string buffer '" . $this->{buf} . "'";

    my $string = "";
    while ($this->{buf} !~ /[""]/) {
	$string .= $this->{buf};
	$this->{buf} = $this->getline();
    }

    $this->{buf} =~ s/^(.*?)[""]//
	or die "can't happen";

    $string .= $1;
    $string =~ s/[``"]/"/g;
    return $string;
}

# PRIVATE to getint() and getstring()
sub _refresh {
    my $this = shift();
    while ($this->{buf} =~ /^\s*$/) {
	$this->{buf} = $this->getline();
    }
    $this->{buf} =~ s/^\s*//;
}


sub warn {
    my $this = shift();

    print STDERR $this->{filename}, ':', $this->{linenumber}, ': ',
	'WARNING: ', @_, "\n";
}


sub fatal {
    my $this = shift();

    my $filename = $this->{filename} || '[unknown]';
    my $linenumber = $this->{linenumber} || '[unknown]';
    print STDERR $filename, ':', $linenumber, ': ERROR: ', @_, "\n";
    exit 1;
}


sub close {
    my $this = shift();

    $this->{f}->close();
}


1;
