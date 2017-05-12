# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
use lib 't/lib','./blib/lib';
#use Test::More;
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

use Devel::Diagram(qw(1.00));
BEGIN { select STDERR; $| = 1; select STDOUT; $| = 1; }
END {
    }

    print "OK";

__END__

