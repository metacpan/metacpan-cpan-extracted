#===============================================================================
#
#  DESCRIPTION:  Module to make a mockery of LWP::UserAgent  'use' this module in a BEGIN block.
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@hellosix.com
#      CREATED:  01/20/2012 09:52:30 AM
#===============================================================================

use 5.008;
use strict;
use warnings;

use Test::More;
use Test::MockObject;       # to mock an object

# This module  should be called in a BEGIN block to prevent loading of the real module

my %mock_methods = (
    get => sub {
      # print STDERR "Sleeping three seconds to simulate net latency...";
        sleep 2;    # simulate some network latency
      # print STDERR "\nOK, done now\n";
        # some TDList.txt pulled directly from the AGA:
        return qq(
WONG, JOSHUA TIEN           21009 Full     0.0  1/18/2015 none CA             
Aal, Zachary                 15648 Full   -20.0   7/2/2008 LIGC NY             
Aarhus, Bob                   9616 Full   -21.9   1/1/2008 NOVA VA             
Aaron, William C.             7206 Full     0.0 12/28/1994 none CA             
Abarbanel, Jacob             17213 Youth    0.0   8/9/2009 none --             
Abate, Ethan                 20211 Youth    0.0 10/10/2013 none KY             
Abaub, Mehdi                 10459 Full     0.0  3/22/2002 HOGC CO             
Abbas, Ashraf                19806 Youth  -21.5   4/1/2013 none VA             
Abbey, David                  2601 Full     0.0  8/28/1994 none TX             
Abbey, Ralph                 17957 Full   -12.7  3/30/2013 none NC             
Abdul-Rahman, Hasan          19725 Full     0.0  2/14/2013 BAYA CA             
Abdulazziz, Ramy             16331 Full     0.0  7/20/2008 none NY             
Abdurehman, Nabill           16386 Youth  -15.2   3/1/2010 PRIN NJ             
Abe, Kiyoko                  20678 Non    -24.1  6/30/2013 none --             
Abe, Shozo                    2443 Full     0.0  3/28/1986 SMON NJ             
Abe, Terutake                 8628 Full   -16.7  5/31/1998 CCSG MD             
Abe, Tomomi                  13858 Non     -5.1   9/9/2005 none --             
Abe, Y.                       2043 Full     0.0 12/28/1983 none GA             
Abe, Yokito                  16769 Full     3.0  8/14/2008 none --             
        );
    },
);

# fool the target code into using our mocked object instead of the real thing
my $mocked_obj = Test::MockObject->new;

# prevent Perl from loading the mocked class
$mocked_obj->fake_module(
    'LWP::UserAgent',
);
# define mocked functions in mocked_obj
map { $mocked_obj->mock($_ => $mock_methods{$_}) } (keys %mock_methods);

$mocked_obj->fake_new('LWP::UserAgent'); # need if we call isa() on the mocked object
$mocked_obj->set_isa('LWP::UserAgent'); # need if we call isa() on the mocked object

1;
