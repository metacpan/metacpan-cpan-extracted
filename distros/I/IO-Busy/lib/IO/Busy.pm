package IO::Busy;

use version; $VERSION = qv('0.0.3');

use warnings;
use strict;
use Carp;

use Perl6::Export::Attrs;

sub _input_pending_on {
    my ($fh) = @_;
    my $read_bits = "";
    vec($read_bits, fileno($fh), 1) = 1;
    select $read_bits, undef, undef, 0.1;
    return $read_bits;
}

my @warning = (
    "That input was ignored. Please don't press any keys yet.\n",
    "That input was ignored. Please wait a little longer.\n",
    "That input was also ignored. You might as well just wait, you know.\n",
   # "Look, there's no point typing yet. Your input isn't going anywhere.\n",
    #"Are you learning impaired? DON'T. TYPE. YET.\n",
    #"Okay, fine. Type whatever you like. Whatever makes you happy.\n",
    #"La la la la. I can't hear you.\n",
    "",
);

sub busy (&) :Export(:MANDATORY) {
    my ($block_ref) = @_;
    my $count = 0;

    my ($read, $write);
    pipe $read, $write;
    my $child = fork;
    if (!$child) {
        close $read;
        $write->autoflush(1);
        while (1) {
            if (_input_pending_on(\*STDIN)) {
                my $res = <STDIN>;
                print {$write} $res;
                print {*STDERR} "\n";
                print {*STDERR} $warning[$count++] || $warning[-1];
                print {*STDERR} "\n";
            }
        }
        exit;
    }
    close $write;
    local *ARGV;
    open *ARGV, '<', \"";
    $block_ref->();
    kill 9, $child;
    wait;
    local $/;
    return $read;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

IO::Busy - Intercept terminal input while something else is happening


=head1 VERSION

This document describes IO::Busy version 0.0.3


=head1 SYNOPSIS

    use IO::Busy;

    my $fh = busy {
        non_interactive_stuff();
    };

  
=head1 DESCRIPTION

This module exports a single subroutine, named C<busy>. That subroutine takes
a single argument, which must be a block of code. C<busy> forks off a separate
process that intercepts and stores any input, then executes the block (in the
original process). 

If the user types anything during the execution of the block, that input
does not appear on the STDIN of the original process. Instead the busy
block informs the user that their input is not being received, and
stores the input in a separate filehandle. That filehandle is then
returned by the C<busy> call, at the end of the block's execution, at which
time STDIN is reconnected to the process.


=head1 INTERFACE 

=head2 $FH = busy {...}

The C<busy> subroutine expects a code block as its only argument. It executes
the block, intercepting any input during that execution. It returns a
filehandle opened for reading, from which the intercepted input can be re-read
if desired.


=head1 DIAGNOSTICS

=over

=item That input was ignored. %s

You typed something whilst the C<busy> block was executing. The C<busy> did
its job and ignored the input, warning you of the fact.

=back

=head1 CONFIGURATION AND ENVIRONMENT

IO::Busy requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires the Perl6::Export::Attrs module.


=head1 INCOMPATIBILITIES

Will not work on systems that cannot C<fork> correctly.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-io-busy@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
