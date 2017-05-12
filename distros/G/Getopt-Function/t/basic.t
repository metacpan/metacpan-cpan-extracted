#!/usr/bin/perl -w

BEGIN {print "1..4\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}


use Getopt::Function;
 $loaded = 1;
 ok(1);

$::opthandler = new Getopt::Function 
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
  ],  {};

$::opthandler->std_opts;

sub usage() {
  print <<EOF;
extract-changed [options] page-url...

EOF
  $::opthandler->list_opts;
}

sub version() {
  print <<'EOF';
extract-changed version 
$Id: basic.t,v 1.3 2000/12/23 17:39:32 mikedlr Exp $
EOF
}

#think of something kids

ok(2);

#check that makevalue works with wierd values

$::option="this";
$::value="something's up with this string";
Getopt::Function::makevalue();
print "not" unless $::value = $::this;

ok(3);

$::option="this";
$::value='something#$%$%&&%"s here is quite bade #$%$$#%#@$% .&';
Getopt::Function::makevalue();
print "not" unless $::value = $::this;

ok(4);

#FIXME setup and test actual options.. 
#both boolean and value
#particularly
# options with - in them 
