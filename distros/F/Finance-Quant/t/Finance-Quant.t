#use Test::More tests => 23;
# or
#use Test::More skip_all => $reason;
# or
use threads;
use Test::More tests => 3;
use Data::Dumper;

use strict;
use warnings;

BEGIN { use_ok( 'Finance::Quant' ); }
require_ok( 'Finance::Quant' );

my($got,$expected,$test_name)=(0,0,'Finance::Quant->new("AAPL")');


my $self = Finance::Quant->new("AAPL");


$self->Home();


my @symbols = keys %{$self->{result}};
         

# Various ways to say "ok"

$got = $#symbols;

print Dumper[keys %{$self->{result}},$got , $expected, $test_name];


ok($got > $expected, $test_name);

done_testing();

__DATA__
#system('for i in `ls /tmp/Finance-Quant/2012-Jan-27-Fri/ibes-strong-buy/ | replace ".jpg" ""`; do perl ~/myperl/charter.pm $i; done');



   
done_testing();


#fail($test_name);

#BAIL_OUT();
#


# UNIMPLEMENTED!!!
my @status = Test::More::status;

__DATA__
# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use Cache::Memcached;
use Storable;
use XML::Simple;

use Test::More tests => 1;
BEGIN { use_ok( 'Finance::Quant::Base' ); }
require_ok( 'Finance::Quant::Base' );


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Data::Dumper;
use Finance::Quant::Base;
use Finance::Quant::Base::Quotes;
use Finance::Quant::Base::Charter;

    my $home = undef;
    $SIG{CHLD} = 'IGNORE';

    # my $a;

    $ARGV[0] = "AAPL" unless($ARGV[0]);



    $home = Finance::Quant::Base->new($ARGV[0]);
    $home->Home($home->{config});

    foreach(@{$home->{'result'}->{symbols}}){
        print $_;
    }
    
    print Dumper $home;
1;
