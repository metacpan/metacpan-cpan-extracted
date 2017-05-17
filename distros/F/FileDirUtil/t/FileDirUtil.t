#-*-CPerl-*-
use 5.010;
use strict;
use warnings;
use FindBin qw($Bin);
use Data::Dumper;
use constant TEST_COUNT => 2;

use lib "$Bin/../lib", "$Bin/../blib/lib", "$Bin/../blib/arch";

BEGIN {
    # include Test.pm from 't' dir in case itis not installed
    eval { require Test::More; };
    if ($@) {
      use lib 't';
    }
    use Test::More tests => TEST_COUNT;
    print Dumper($Bin);
    use_ok( 'FileDirUtil' ) || print "Bail out! Cannot load FileDirUtil\n";
}

diag ( "Testing FileDirUtil $FileDirUtil::VERSION, Perl $], $^X");

my @arg1 = (ifile => '/user/moo/foo.bar',odir => ['Users','blub']);

my $fdu1 = new_ok("FDU" => \@arg1);
#diag (Dumper($fdu1));





