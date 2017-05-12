# $Id: resolve.t,v 1.2 2008-04-30 11:44:50 mike Exp $

use strict;
use warnings;
use Test::More tests => 1;

# We need to use the actual "resolve" script.  We use it to resolve
# one of the OpenURLs in the regression suite, and check that the
# result is as expected.  The regression suite runs the tests with
# the baseURL set to http://example.com/resolve and with XML output
# turned on, so we need to do the same.

$ENV{KRuser} ||= "kr_read";
$ENV{KRpw} ||= "kr_read_3636";
$ENV{KRxsltdir} ||= "etc/xslt";

my $test = "t/regression/zetoc-suuwassea";
my $query = read_file("$test.in");
$query =~ s/\n+$//s;
$query =~ s/.*\n//s;
@ARGV = ($query . "&opt_baseURL=http://example.com/resolve&opt_xml=1");

# Redirect STDOUT into temporary file, the revert it
my $tmpfile = "/tmp/krtest.$$";
open my $oldout, ">&STDOUT" or die "can't dup STDOUT: $!";
open STDOUT, ">$tmpfile" or die "can't redirect STDOUT: $!";
do "web/htdocs/mod_perl/resolve";
open STDOUT, ">&", $oldout or die "can't dup oldout: $!";

my $expected = read_file("$test.out");
my $got = read_file($tmpfile);
is($got, $expected);

# Naughty additional output will be pragmatically useful
system("diff $test.out $tmpfile") if $expected ne $got;
unlink($tmpfile);

sub read_file {
    my($name) = @_;
    use IO::File;

    my $fh = new IO::File("<$name")
	or die "can't read file '$name': $!";
    my $res = join("", <$fh>);
    $fh->close();
    return $res;
}
