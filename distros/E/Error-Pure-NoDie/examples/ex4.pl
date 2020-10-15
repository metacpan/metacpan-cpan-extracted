#!/usr/bin/env perl

use strict;
use warnings;

use Dumpvalue;
use Error::Pure::NoDie qw(err);
use Error::Pure::Utils qw(err_get);

# Error in eval.
eval { err '1', '2', '3'; };

# Error structure.
my @err = err_get();

# Dump.
my $dump = Dumpvalue->new;
$dump->dumpValues(\@err);

# In \@err:
# [
#         {
#                 'msg' => [
#                         '1',
#                         '2',
#                         '3',
#                 ],
#                 'stack' => [
#                         {
#                                 'args' => '(1)',
#                                 'class' => 'main',
#                                 'line' => '9',
#                                 'prog' => 'script.pl',
#                                 'sub' => 'err',
#                         },
#                         {
#                                 'args' => '',
#                                 'class' => 'main',
#                                 'line' => '9',
#                                 'prog' => 'script.pl',
#                                 'sub' => 'eval {...}',
#                         },
#                 ],
#         },
# ],