######################################################################
# Testcase:     Returning values from perl callbacks
# Revision:     $Revision: 1.2 $
# Last Checkin: $Date: 2006/06/13 13:42:58 $
# By:           $Author: thomas_busch $
#
# Author:       Mike Schilli m@perlmeister.com, 2004
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);

use JavaScript::SpiderMonkey;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

my $buffer = "";

my $js = JavaScript::SpiderMonkey->new();
$js->init();

    # Example by Chris Blaise:
    # Let new function document.getElementById('id') (defined in Perl space)
    # return an object into JS.

my $doc = $js->object_by_path('document' );
$js->property_by_path('fooobj.style' );
$js->function_set( 'getElementById', sub {
    if(exists $JavaScript::SpiderMonkey::GLOBAL->{objects}->{'fooobj'}) {
        return $JavaScript::SpiderMonkey::GLOBAL->{objects}->{'fooobj'};
    }
}, $doc);
$js->function_set("write", sub { 
    $buffer .= join('', map { "[$_]" } @_) }, $doc);

my $code = q{
    document.getElementById('bleh').style = 'something';
    document.write(fooobj.style);
};

my $rc = $js->eval($code);

# Check return code
ok($rc, "Function returning object");
is($buffer, "[something]", "Attribute assigned correctly");
