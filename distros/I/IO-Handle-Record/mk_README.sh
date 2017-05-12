#!/bin/bash

perl -pe '/^=head1 DESCRIPTION/ and print <STDIN>' lib/IO/Handle/Record.pm >README.pod <<EOF
=head1 INSTALLATION

 perl Makefile.PL
 make
 make test
 make install

=head1 DEPENDENCIES

=over 4

=item B<*> perl 5.8.0

=item B<*> Storable 2.05

=item B<*> Class::Member 1.3

=back

EOF

perldoc -tU README.pod >README
rm README.pod
