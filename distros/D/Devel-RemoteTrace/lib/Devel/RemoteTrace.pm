package Devel::RemoteTrace;

use warnings;
use strict;

our $VERSION = '0.3';


=head1 NAME

Devel::RemoteTrace - Attachable call trace of perl scripts
(a.k.a) L<perldebguts> by example

=head1 SYNOPSIS

  $ perl -d:RemoteTrace your-script

or 
 
  use Devel::RemoteTrace;

=head1 DESCRIPTION

The purpose of this module is twofold. First of all it solves a real problem
taht seems hard with the standard debugger: Trace the execution of a long
running process when it stops serving requests.

The secondary purpose is to be an easy understandable example for writing your
own debuggers. A kind of perldebgutstut (but what a horrible name that would
have been).

=head1 USAGE

Devel::RemoteTrace uses UDP to send trace messages to the address defined by
the environent variables C<DEBUG_ADDR> and C<DEBUG_HOST>. If neither of these
are defined the default is to send to localhost:9999.

Tracing is enabled and disabled by sending the traced process an SIGUSR2. If
Devel::RemoteTrace is loaded with the single argument ':trace' tracing is
enabled from the beginning otherwise it is disabled from the beginning.

=cut

sub import {
    $DB::trace = 1 if grep { $_ eq ':trace' } @_;
}

package DB;

=head1 perldebguts by examples

=head2 Variables used or maintained by the interpreter

=cut

our ($single, $trace, $signal);
our $sub;
our @args;

=over 4

=item $DB::single, $DB::trace, $DB::signal

If either of these are true the interpreter enters single step-mode where
DB::DB() is called right before execution of each statement. 

(Only $DB::trace are really used by Devel::RemoteTrace)

=item $main::{"_<$filename"}

For each compiled file (C<$filename>) the interpreter maintains a scalar
containing the filename. This doesn't seem usefull at first, but DB::postponed
is called with a glob pointing at this.

=item @main::{"_<$filename"}

For each compiled file (C<$filename>) the interpreter maintains an array that
holds the lines of the file.

Values in this array are magical in numeric context: they compare equal to zero
only if the line is not breakable.

=item %DB::sub

The keys of this hash is the fully quallyfied name of each subroutine known to
the debugger. The values is of the form 'filename:startline-endline'.

=item $DB::sub

In DB::sub() this scalar holds the fully quallyfied name of the subroutine to
be called.

=item @DB::args

When called from the DB namespace, C<caller()> places the argument for the
invoked subroutine here. 

=back

=cut


use Socket;
my ($socket, $sin);
my $depth;

BEGIN {
    # Force use of debuging:
    $INC{'perl5db.pl'} = 1;
    $^P = 0x33f;

    # Initialize socket:
    my $port  = $ENV{DEBUG_PORT} || 9999;
    my $host  = $ENV{DEBUG_ADDR} || 'localhost';
    my $proto = getprotobyname('udp');

    $sin      = sockaddr_in($port, INADDR_LOOPBACK);
    socket( $socket, PF_INET, SOCK_DGRAM, $proto);

    # Initialize pretty printing:
    $depth = '';
}

sub dblog {
    local $!;
    send($socket, $_[0], 0, $sin);
}

$SIG{USR2} = sub { $trace = !$trace; };

=head2 Subroutine hooks

=over 4

=item DB::DB

This subroutine is called before exeution of each statement if either of
$DB::single, $DB::trace, or $DB::signal is true. All debuggers are required to
have this subroutine, but it might be empty.
 
Use C<caller(0)> to get where in you code you are.

=cut

sub DB {
    return unless $trace;

    my %Caller;
    @Caller{ qw( package filename line subroutine) } = caller(0);

    no strict 'refs';
    dblog( "[$$]$depth $Caller{filename}:$Caller{line}: " .  ${$main::{"_<$Caller{filename}"}}[$Caller{line}] );
}

=item DB::sub

This subroutine is called B<instead> of each normal subroutine call. The
subroutine name is placed in $DB::sub and the debugger is responsibel for make
the actual subroutine call in the right context. This is done either directly
at the return statement:

    return &{ $sub };

or by examinating wantarray():

    my ($ret, @ret);
    # Call the function in the correct context:

    if (wantarray) {
        @ret = &{ $sub };
    } elsif (defined wantarray) {
        $ret = &{ $sub };
    } else {
        &{ $sub };
    }

    # inspect the return value or something 

    # and return the correct context
    return (wantarray) ? @ret : defined(wantarray) ? $ret : undef;

Use C<caller()> to inspct where in the code you are called from. As a special
case C<caller(-1)> returns the stack frame you are about to call.

=cut

sub sub {
    unless ($trace) {
        no strict 'refs';
        return &{ $sub };
    }

    my %dbCalled;
    my %realCalled;

    # A call frame contains where the call happened and the name of the called
    # subroutine. To log the complete description we need the subroutine name from the
    # callers frame and the filename and line numer form the callees
    # frame.
    @dbCalled{   qw(package filename line subroutine) } = caller(-1);
    @realCalled{ qw(package filename line subroutine) } = caller( 0);

    $realCalled{subroutine} ||= "<main>";

    dblog( "[$$]$depth $sub called in $realCalled{subroutine} "
         . "at $dbCalled{filename}:$dbCalled{line}\n" );


    $depth .= "  ";
    
    my ($ret, @ret);
    {
        # Call the function in the correct context:

        no strict 'refs';
        if (wantarray) {
            @ret = &{ $sub };
        } elsif (defined wantarray) {
            $ret = &{ $sub };
        } else {
            &{ $sub };
        }
    }

    substr($depth,0,2,'');

    # and return the correct context
    return (wantarray) ? @ret : defined(wantarray) ? $ret : undef;
}

=item DB::postponed

postponed is called when perl is finished compiling either a subroutine or a
complete file. For subroutine this call is only made if the subroutine name
exists as a key in %DB::postponed though.

For subroutines the argument to postponed() is simply the subroutine name.

For complete files the argument to postponed is the glob C<*{"_<$filename"}>
referring to both the scalar containing the filename and the array containing
the complete file.

=cut

sub postponed {
    return unless $trace;

    my $arg = shift;
    if (ref \$arg eq 'GLOB') {
        dblog( "[$$] Loaded file ${ *$arg{SCALAR} }\n" );
    } else {
        dblog( "[$$] Compiled function $arg\n" );
    }
}


1;

__END__

=back

=head1 BUGS, FEATURES, AND OTHER ISSUES

Using this on untrusted networks might leak security related information

Due to the nature of UDP there is no guarantee that the receiver gets all
function calls. This could be "fixed" by adding a sequence number.

=head1 AUTHOR

Peter Makholm, C<< <peter at makholm.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Makholm, all rights reserved.

This software is released under the MIT license cited below.

=head1 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject
to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


