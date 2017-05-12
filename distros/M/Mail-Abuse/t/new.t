
# $Id: new.t,v 1.2 2003/06/18 20:03:20 lem Exp $

use Test::More;

package MyFilter;
use base 'Mail::Abuse::Filter';
package main;

package MyReader;
use base 'Mail::Abuse::Reader';
package main;

package MyProcessor;
use base 'Mail::Abuse::Processor';
package main;

package MyIncident;
use base 'Mail::Abuse::Incident';
package main;

my @classes	= qw/ 
	Mail::Abuse::Filter 
	Mail::Abuse::Reader 
	Mail::Abuse::Incident
	Mail::Abuse::Processor
	/;

my @over	= qw/
	MyFilter 
	MyReader 
	MyIncident
	MyProcessor
	/;

plan tests => (5 * @classes + 4 *@over);

for my $c (@classes)
{
    my $o = undef;
    use_ok($c);
    ok($o = new $c, "new <class>");
    isa_ok($o, $c, "new <class>");
    ok($o = $c->new, "<class>->new");
    isa_ok($o, $c, "<class>->new");
}

for my $c (@over)
{
    my $o = undef;
    ok($o = new $c, "new <class>");
    isa_ok($o, $c, "new <class>");
    ok($o = $c->new, "<class>->new");
    isa_ok($o, $c, "<class>->new");
}


