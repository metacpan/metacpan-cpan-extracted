#!/bin/bash

perl -pe '/^=head1 DESCRIPTION/ and print <STDIN>' lib/HTTP/LoadGen.pod >README.pod <<EOF
=head1 INSTALLATION

 perl Makefile.PL
 make
 make test
 make install

=head1 DEPENDENCIES

=over 4

=item * perl 5.8.8

=item * IPC::ScoreBoard

=item * Coro

=item * AnyEvent

=item * Async::Interrupt

=item * Net::SSLeay

=back

EOF

perldoc -tU README.pod >README
rm README.pod
