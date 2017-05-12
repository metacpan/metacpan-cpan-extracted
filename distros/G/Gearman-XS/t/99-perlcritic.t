# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
  my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
  my $msg = 'Test::Perl::Critic required to criticise code';
  plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
