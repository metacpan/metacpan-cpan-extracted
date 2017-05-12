#!/usr/bin/perl
# vim: set ft=perl ts=4 sw=4:

(@ARGV) || exec "$0",
    "--with-apache_src=/usr/local/src/apache_1.3.20/src", 
    "--with-defaultdomain=sevenroot.org",
    "--with-mysql-user=nobody",
    "--with-mysql-passwd=l33t_n_s3kr3t",
    "--with-mysql-host=dbhost",
    "--enable-option=masquerading",
    "--enable-option=mbox-limits",
    "--disable-option=aliases",
    "--verbose";

use strict;
use blib;
use Getopt::AutoConf;

use Test;
BEGIN { plan tests => 7 }

my ($VERBOSE, $ap_src, %mysql, $defaultdomain);
my @options = ('aliases', 'forwarding');
GetOptions(
  "verbose"       => \$VERBOSE,
  "apache_src"    => \$ap_src,
  "mysql-user"    => \$mysql{'user'},
  "mysql-passwd"  => \$mysql{'passwd'},
  "mysql-host"    => \$mysql{'host'},
  "option"        => \@options,
  "defaultdomain" => \$defaultdomain,
);

ok($VERBOSE, undef);
ok($ap_src, "/usr/local/src/apache_1.3.20/src");
ok($mysql{'user'}, "nobody");
ok($mysql{'passwd'}, "l33t_n_s3kr3t");
ok($mysql{'host'}, "dbhost");
ok($defaultdomain, "sevenroot.org");
ok(@options, 3);

