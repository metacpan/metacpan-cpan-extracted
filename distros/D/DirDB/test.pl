#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 13 };
use DirDB;
ok(1); # If we made it this far, we're ok.

use strict;

# tie my %dcty, 'DirDB', ".";
ok(tie my %dcty, 'DirDB', './test_dir');

# print  "\nSTORE TEST\n";
$dcty{pid} = $$;

# print "\nFETCH TEST\n";
ok($dcty{pid},$$);
ok(delete($dcty{pid}),$$);
warn "after deleting, still have key <$_>\n" for keys %dcty;
 ok((keys %dcty) == 0);



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
warn "after clearing, still have key <$_>\n" for keys %dcty;
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
eval { $dcty{reftest} = $x };
ok($@);

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


my $Object = bless {a=>1,b=>2,c=>3} => 'Some Package';
$dcty{Object} = $Object;
ok('Some Package',ref($dcty{Object}));

$Object->{d} = 4;
ok($dcty{Object}->{d},4);

%dcty = ();

untie %dcty;

ok(rmdir "./test_dir");




