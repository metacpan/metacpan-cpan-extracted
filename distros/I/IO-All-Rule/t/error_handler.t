use 5.006;
use strict;
use warnings;
use autodie;
use Test::More 0.92;
use Path::Class;
use File::Temp;
use Test::Deep qw/cmp_deeply/;

use lib 't/lib';
use PCNTest;

use IO::All::Rule;

#--------------------------------------------------------------------------#

my @tree = qw(
  aaaa.txt
  bbbb.txt
);

my $td = make_tree(@tree);

{
  my $rule = IO::All::Rule->new->and( sub { die "Evil here" } );
  eval { $rule->all($td) };
  like( $@, qr/^\Q$td\E: Evil here/, "default error handler dies" );
}

{
  my @msg;
  my $handler = sub { push @msg, [@_]; };
  my $rule = IO::All::Rule->new->and( sub { die "Evil here" } );
  eval { $rule->all($td, { error_handler => $handler } ) };
  is( $@, '', "error handler catches fatalitis" );
  is( scalar @msg, 3, "saw correct number of errors" );
  my ($file, $text) = @{$msg[0]};
  is( "$file", "$td", "object has file path of error");
  like( $text, qr/^Evil here/, "handler gets message" );
}

done_testing;
#
# This file is part of IO-All-Rule
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
