###########################################################################
#
#   Formatting.pm
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use strict;
require Exporter;

########################################################################
package Log::Agent::Formatting;

use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT_OK = qw(format_args tag_format_args);

require Log::Agent::Message;

#
# adjust_fmt
#
# We process syslog's %m macro as being the current error message ($!) in
# the first argument only. Doing it at this level means it will be supported
# independently from the driver they'll choose. It's also done BEFORE any
# log-related system call, thus ensuring that $! retains its original value.
#
if ($] >= 5.005) {
    eval q{     # if VERSION >= 5.005
        # 5.005 and later version grok /(?<!)/
        sub adjust_fmt {
            my $fmt = shift;
            $fmt =~ s/((?<!%)(?:%%)*)%m/$Log::Agent::OS_Error/g;
            return $fmt;
        }
    }
} else {
    eval q{     # else /* VERSION < 5.005 */
        # pre-5.005 does not grok /(?<!)/
        sub adjust_fmt {
            my $fmt = shift;
            $fmt =~ s/%%/\01/g;
            $fmt =~ s/%m/$Log::Agent::OS_Error/g;
            $fmt =~ s/\01/%%/g;
            return $fmt;
        }
    }
}       # endif /* VERSION >= 5.005 */

#
# whine
#
# This is a local hack of carp
#
sub whine {
    my $msg = shift;
    unless (chomp $msg) {
        my($package, $filename, $line) = caller 2;
        $msg .= " at $filename line $line.";
    }
    warn "$msg\n";
}

#
# tag_format_args
#
# Arguments:
#
#   $caller     caller information, done firstly
#   $priority   priority information, done secondly
#   $tags       list of user-defined tags, done lastly
#   $ary        arguments for sprintf()
#
# Returns a Log::Agent::Message object, which, when stringified, prints
# the string itself.
#
sub tag_format_args {
    my ($caller, $priority, $tags, $ary) = @_;
    my $msg = adjust_fmt(shift @$ary);

    # This bit of tomfoolery is intended to make debugging of
    # programs a bit easier by prechecking input to sprintf()
    # for errors.  I usually prefer lazy error checking, but
    # this seems to be an appropriate exception.
    if (my @arglist = $msg =~ /\%[^\%]*[csduoxefgXEGbpniDUOF]|\%\%/g) {
        BEGIN { no warnings }
        my $argcnt = grep !/\%\%/, @arglist;
        if (grep {! defined} @$ary[0..($argcnt - 1)]) {
            whine("Use of uninitialized value in sprintf");
        }
        $msg = sprintf $msg, @$ary;
    }

    my $str = Log::Agent::Message->make($msg);
    $caller->insert($str) if defined $caller;
    $priority->insert($str) if defined $priority;
    if (defined $tags) {
        foreach my $tag (@$tags) {
            $tag->insert($str);
        }
    }
    return $str;
}

1;
