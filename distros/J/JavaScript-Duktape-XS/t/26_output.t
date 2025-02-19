use warnings;
use strict;
use JavaScript::Duktape::XS;
use Text::Trim qw(trim);
use Test::More tests => 100;

#Test to ensure output generated in one instance is from that instance
my $options = {
  gather_stats     => 1,
  save_messages    => 1,
};

my @instance;
for (1..100) {
  push @instance,JavaScript::Duktape::XS->new($options);   
}

my $count = 1;
foreach (@instance) {
  $_->eval('console.log("'.$count.'")');  
  $count++;
}

$count = 1;
foreach (@instance) {
  my $msgs = $_->get_msgs();
  my $out = join ('',map +( trim $_ ), @{ $msgs->{stdout} });
  ok($out eq $count, 'stdout');
  $count++;
}



