#!perl

# COPYRIGHT AND LICENCE
#
# Copyright (C) 2014 Joshua ben Jore.
#
# This program is distributed WITHOUT ANY WARRANTY, including but not
# limited to the implied warranties of merchantability or fitness for
# a particular purpose.
#
# The program is free software.  You may distribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (either version 2 or any later version)
# and the Perl Artistic License as published by O’Reilly Media, Inc.
# Please open the files named gpl-2.0.txt and Artistic for a copy of
# these licenses.


use strict;
use warnings;
use Test::More;
use lib 't';
use Test::Enbugger 'run_with_tmp';

=head1 NAME

11load.t - Tests that the module can be loaded and breakpoints
triggered

=over

=cut


my @options = (
    [ $^X, '-Mblib',       't/30break.pl',                                                       ],
    [ $^X, '-Mblib',       't/30break.pl',                                          '--noimport' ],
    [ $^X, '-Mblib',       't/30break.pl',                        '--load_perl5db',              ],
    [ $^X, '-Mblib',       't/30break.pl',                        '--load_perl5db', '--noimport' ],
    [ $^X, '-Mblib',       't/30break.pl', '--import', 'perl5db',                                ],
    [ $^X, '-Mblib',       't/30break.pl', '--import', 'perl5db', '--load_perl5db',              ],
    [ $^X, '-Mblib', '-d', 't/30break.pl',                                                       ],
    [ $^X, '-Mblib', '-d', 't/30break.pl',                                          '--noimport' ],
    [ $^X, '-Mblib', '-d', 't/30break.pl',                        '--load_perl5db',              ],
    [ $^X, '-Mblib', '-d', 't/30break.pl',                        '--load_perl5db', '--noimport' ],
    [ $^X, '-Mblib', '-d', 't/30break.pl', '--import', 'perl5db',                                ],
    [ $^X, '-Mblib', '-d', 't/30break.pl', '--import', 'perl5db', '--load_perl5db',              ],

    [ $^X, '-Mblib',       't/31break.pl',                                                       ],
    [ $^X, '-Mblib',       't/31break.pl',                                          '--noimport' ],
    [ $^X, '-Mblib',       't/31break.pl',                        '--load_perl5db',              ],
    [ $^X, '-Mblib',       't/31break.pl',                        '--load_perl5db', '--noimport' ],
    [ $^X, '-Mblib',       't/31break.pl', '--import', 'perl5db',                                ],
    [ $^X, '-Mblib',       't/31break.pl', '--import', 'perl5db', '--load_perl5db',              ],
    [ $^X, '-Mblib', '-d', 't/31break.pl',                                                       ],
    [ $^X, '-Mblib', '-d', 't/31break.pl',                                          '--noimport' ],
    [ $^X, '-Mblib', '-d', 't/31break.pl',                        '--load_perl5db',              ],
    [ $^X, '-Mblib', '-d', 't/31break.pl',                        '--load_perl5db', '--noimport' ],
    [ $^X, '-Mblib', '-d', 't/31break.pl', '--import', 'perl5db',                                ],
    [ $^X, '-Mblib', '-d', 't/31break.pl', '--import', 'perl5db', '--load_perl5db',              ],
);
plan( tests => 0+@options );

for my $args ( @options ) {
    my $test_output = run_with_tmp( @$args );
    like( $test_output, qr/^(?# )?\$Caught = 3\.$/m, "@$args");
}

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
