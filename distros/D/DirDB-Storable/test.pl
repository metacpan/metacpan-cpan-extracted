#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 12 };
use DirDB::Storable;
ok(1); # If we made it this far, we're ok.

use strict;

# tie my %dcty, 'DirDB', ".";
ok(tie my %dcty, 'DirDB::Storable', './test_dir');

# print  "\nSTORE TEST\n";
$dcty{pid} = $$;

# print "\nFETCH TEST\n";
ok($dcty{pid},$$);
ok(delete($dcty{pid}),$$);



# print "\nEACH TEST\n";
# while (my ($k,$v) = each %dcty ) {
  # print "got key <$k>\n";
  # print qq( $k -> $v\n );
# }

# print "\nKEYS TEST\n";
# for my $f ( keys %dcty ) {
  # print "got key <$f>\n";
  # print qq( $f -> $dcty{ $f }\n );
# }

# print "\nKeys now @{[keys %dcty]}\n";
# print "\nCLEARING\n";
%dcty = ();

# print "Keys now @{[keys %dcty]}\n";

 ok((keys %dcty) == 0);
# print "\nDelete slice test\n";
@dcty{1..5} = qw{fee fi fo fum five};
# print "fi fo? ",delete( @dcty{2,3}),"\n";
ok("fi fo","@{[delete( @dcty{2,3})]}");
# ok(5);

# print "fee fum five? ", (grep {defined $_} @dcty{1..5}),"\n";
ok( "fee fum five", "@{[grep {defined $_} @dcty{1..5}]}");
# ok(6);

# my $$x = "reference test\n";
# does not work with early perl-fives (thanks, cpantesters!)
my $x = \"reference test\n";
# print $$x;
# eval { $dcty{reftest} = $x };
# ok($@);
# now handled by Storable
$dcty{reftest} = $x;
ok (${$dcty{reftest}}, "reference test\n");

my %x;
$x{something}='else';
$dcty{X} = \%x;	# should tie %x to dcty/X
$x{fruit} = 'banana';
ok('banana',$dcty{X}->{fruit});


# print "complex delete test\n";
my $href = delete $dcty{X};
# print "href is $href\n";
# print "has keys @{[keys %$href]}\n";
# print "has values @{[values %$href]}\n";
ok('banana',$href->{fruit});

# storable test

$dcty{arrayref} = [10..30];
my $cloned_aref = $dcty{arrayref};
my $cloned_aref2 = delete $dcty{arrayref};

ok($cloned_aref -> [10] , 20);
ok($cloned_aref2 -> [10] , 20);



