package Debug::Phases;

use version; $VERSION = qv('0.0.2');

use warnings;
use strict;
use Carp;
use Time::HiRes qw(time);

my $start;

BEGIN {
    $start = time();
    print {*STDERR} "Compiling..."
}

INIT {
    my $delta = sprintf '%.2f', time()-$start;
    print {*STDERR} "$delta second";
    print {*STDERR} 's' if $delta != 1;
    print {*STDERR} "\nRunning...\n"
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Debug::Phases - Announce BEGIN and INIT phases to help locate problems


=head1 VERSION

This document describes Debug::Phases version 0.0.2


=head1 SYNOPSIS

    use Debug::Phases;

    # Your code here


    or:

    > perl -MDebug::Phases your_script
  
  
=head1 DESCRIPTION

This tiny module does nothing but announce the start of the BEGIN and INIT
phases, recording how long the compilation (BEGIN phase) took. It's handy for
tracking down whether particular problems are compile-time or run-time, and
also for evaluating the time-cost for using other modules.


=head1 INTERFACE 

None. It simply prints its information to STDERR.


=head1 DIAGNOSTICS

=over

=item Compiling...

Your script is currently in its BEGIN phase

=item Compiling...%s seconds. Running...

Your script just finished its compile phase (in the indicated time) and
is now executing.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Debug::Phases requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires the Time::HiRes module.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-debug-phases@rt.cpan.org>, or through the web interface at
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
