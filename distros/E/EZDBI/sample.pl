#!/usr/bin/perl

use EZDBI;

Connect 'mysql:test' => 'username', 'password';

Insert 'Into NAMES Values', 'Harry', 'Potter';

if( (Select q{Count(*) From NAMES Where first = 'Harry'})[0] ) {
  print "Potter is IN THE HOUSE.\n";
}

for (Select 'last from names') {
  next if $seen{$_}++;
  my @first = Select 'first From NAMES Where last = ?', $_;
  print "$_: @first\n";
}

Delete q{From NAMES Where last='Potter'};

if( (Select q{Count(*) From NAMES Where first = 'Harry'})[0] ) {
  die "Can't get rid of that damn Harry Potter!";
}

