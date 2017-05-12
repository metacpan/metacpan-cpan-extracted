
# $Id: Default.pm,v 1.3 2000/09/13 21:57:07 nwiger Exp $
####################################################################
#
# Copyright (c) 2000, Nathan Wiger <nate@sun.com>
#
# IO::Default - Replace select() and default filehandle with $DEFOUT
#               Also add $DEFIN and $DEFERR variables
#
####################################################################

require 5.005;
package IO::Default;

use strict;
no strict 'refs';
use vars qw(@EXPORT @ISA $VERSION $DEFOUT $DEFERR $DEFIN);
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($DEFOUT $DEFERR $DEFIN);

use Carp;

# This works via tie(), "plain and simple", but with a couple special
# subclasses since each variable is tied differently. On assignment,
# basically we just do some select or open calls to twiddle what
# we're working with. The $DEFIN handle is more complicated because
# it tries to override what is done with <> and <ARGV>.

tie $DEFOUT, 'IO::Default::DEFOUT';
tie $DEFERR, 'IO::Default::DEFERR';
tie $DEFIN, 'IO::Default::DEFIN';

# Stolen from CGI.pm - thanks Lincoln!
# Man, will I be glad when these become scalars in Perl 6...

sub _to_filehandle {
    my $thingy = shift;
    return undef unless $thingy;
    return $thingy if UNIVERSAL::isa($thingy,'GLOB');
    return $thingy if UNIVERSAL::isa($thingy,'FileHandle');
    if (!ref($thingy)) {
        my $caller = 1;
        while (my $package = caller($caller++)) {
            my($tmp) = $thingy =~ /[\':]/ ? $thingy : "$package\:\:$thingy"; 
            return $tmp if defined(fileno($tmp));
        }
    }
    return undef;
}


# For $DEFOUT, we just call select() on STORE/FETCH

package IO::Default::DEFOUT;
use Carp;

sub TIESCALAR {
    my $c = shift;
    bless { DEFOUT => (select) }, $c;
}

sub STORE {
    my $c = shift;
    my $h = IO::Default::_to_filehandle(shift);
    return $h if ($c->{DEFOUT} and $h eq $c->{DEFOUT});     # duplicate, skip
    select $h or carp "Assignment to \$DEFOUT failed: $!";
    return $c->{DEFOUT} = $h;
}

sub FETCH {
    my $c = shift;
    return $c->{DEFOUT} = select;
}


# For $DEFERR, we just reopen STDERR

package IO::Default::DEFERR;
use Carp;

sub TIESCALAR {
    my $c = shift;
    bless { DEFERR => "STDERR" }, $c;
}

sub STORE {
    my $c = shift;
    my $h = IO::Default::_to_filehandle(shift);
    return $h if $h eq $c->{DEFERR};     # duplicate, skip
    if ( ref $h ) {
       *STDERR = *$h;       # use typeglob aliases
    } else {
       open(STDERR, ">&$h") or carp "Assignment to \$DEFERR failed: $!";
    }
    $c->{DEFERR} = $h;
}

sub FETCH {
    shift->{DEFERR};
}


# For $DEFIN, we just copy whatever's been passed in

package IO::Default::DEFIN;
use Carp;

sub TIESCALAR {
    my $c = shift;
    bless { DEFIN => undef }, $c;
}

sub STORE {
    my $c = shift;
    my $h = IO::Default::_to_filehandle(shift);
    return $h if ($c->{DEFERR} and $h eq $c->{DEFERR});     # duplicate, skip

    # This may seem mean, but the whole purpose of this module
    # is to change the meaning of <> to not iterate over
    # command-line files. As such, we need to blow away any
    # @ARGV that's hanging around still because of ARGV's
    # inherent special-ness.
    undef @ARGV;

    if ( ref $h ) {
       *ARGV = *$h;          # use typeglob aliases
    } else {
       open(ARGV, "<&$h") or carp "Assignment to \$DEFIN failed: $!";
    }
    $c->{DEFIN} = $h;
}

sub FETCH {
    my $c = shift;
    my $h = IO::Default::_to_filehandle(shift);
    return $h if $h eq $c->{DEFIN};     # duplicate, skip

    # If we haven't set $DEFIN yet, but we're trying to
    # read from it explicitly, then basically do what STORE
    # does and reopen ARGV "correctly".
    $c->STORE($h);
}


1;

__END__

=head1 NAME

IO::Default - replace select() with $DEFOUT, $DEFERR, $DEFIN

=head1 SYNOPSIS

   use IO::Default;

   open LOG, ">/var/log/my.log";
   $DEFOUT = LOG;               # instead of select(LOG);

   open $DEFERR, ">/var/log/my.err";
   warn "Badness!";             # sends to $DEFERR

   $DEFIN = \*STDIN;            # barewords or globs work
   @data = <>;                  # reads from $DEFIN now

   use FileHandle;              # provide OO file methods

   $DEFOUT = \*MYFILE;          # need to use globs if want OO
   $DEFOUT->autoflush(1);       # set $| on whatever $DEFOUT is
   $DEFERR->autoflush(1);       # ditto

   $DEFIN->untaint;             # untaint default input stream

=head1 DESCRIPTION

Currently, Perl provides a somewhat clumsy way of manipulating
the default filehandle, and no easy way of manipulating default
error and input handles. This module serves the dual purpose of
providing a means around this, as well as serving as a prototype
for a proposed Perl 6 feature.

This module replaces the use of select() and the default filehandle
with three variables, $DEFOUT, $DEFERR, and $DEFIN, that are the
default output, input, and error filehandles. By default, they
point to STDOUT, STDERR, and nothing, respectively. The reason
$DEFIN doesn't do anything until you assign to it is because assigning
to it wipes out @ARGV. See the BUGS below.

To change what the default filehandle is for output, simply assign
a filehandle or filehandle glob to $DEFOUT:

   open LOG, ">/var/log/my.log" or die;
   $DEFOUT = LOG;                       # bare filehandles ok
   print "Here's some data";            # goes to LOG

The same can be easily done with $DEFERR for default errors:

   open ERR, ">/var/log/my.err" or die;
   $DEFERR = \*ERR unless $have_a_tty;  # glob refs ok too
   warn "Danger, Will Robinson!";       # goes to ERR

Finally, this module changes the semantics of <> if you assign
to $DEFIN. Normally, the <> ARGV filehandle will iterate through
command line arguments. This is still the default. However, if
you explicitly assign a filehandle to $DEFIN, then this changes
the semantics and input is instead read from the handle:

   open MOTD, "</etc/motd" or die;
   $DEFIN = MOTD;
   print while (<>);                    # just reads /etc/motd

Why do this? Well, passing filehandles in and out of functions is
a pain in Perl 5, requiring you to use globs. If you simply want
to change the default input for a sub function somewhere, have
it read from <>:

   sub get_data {
       my @data = <>;
       # do more stuff
       return @data;
   } 

Then from the top level do something like this:

   # Figure out our input stream
   $DEFIN = get_handle || \*STDIN;
   @data = get_data;

And now you don't have to pass filehandles in and out of functions
anymore just for dealing with default input and output. Note that
here <> and <$DEFIN> are synonymous.

=head1 BUGS

This module should NOT be used in production code because it is
considered unstable and subject to change.

Unfortunately, getting $DEFIN to work in Perl 5 is hairy, since
ARGV is so special. As such, assigning to $DEFIN will wipe out
whatever you have in @ARGV at the time. It also can't set $ARGV,
since the file that was opened is unknown.

Luckily, if you never assign or access $DEFIN, then <> retains
its magic powers, so if you don't like this simply don't use $DEFIN.

This module really just does some trickery to reopen the STD
filehandles and point them to different places. As such, mixing
print calls to $DEFERR and STDERR will send the output to the
same place (contrary to the Perl 6 proposal).

=head1 REFERENCES

For complete details on the Perl 6 proposal, please visit
http://dev.perl.org/rfc/129.html. Comments are welcome.

=head1 AUTHOR

Copyright (c) 2000, Nathan Wiger <nate@sun.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

