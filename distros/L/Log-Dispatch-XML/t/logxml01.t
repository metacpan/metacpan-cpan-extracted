
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

my @level;
BEGIN {
    @level = qw(
     debug
     info
     notice
     warning
     error
     critical
     alert
     emergency
    );
}

use Test::More tests => 6 + @level + 3;
use strict;
use warnings;

use_ok( 'Log::Dispatch::XML' );
can_ok( 'Log::Dispatch::XML',qw(
 xml
) );

my $dispatcher = Log::Dispatch->new;
isa_ok( $dispatcher,'Log::Dispatch' );

my $channel = Log::Dispatch::XML->new( qw(name default min_level debug) );
isa_ok( $channel,'Log::Dispatch::XML' );

$dispatcher->add( $channel );
is( $dispatcher->output( 'default' ),$channel,'Check if channel activated' );

is( $channel->xml( qq{foo:bar xmlns:foo="http://foo.com"} ),
 qq{<foo:bar xmlns:foo="http://foo.com"></foo:bar>},
 "Check if no messages to start with"
);

my $mustbexml = "<foo>";
foreach my $method (@level) {
    eval { $dispatcher->$method( "This is a '$method' action" ) };
    ok( !$@,qq{Check if dispatcher method '$method' ok} );
    $mustbexml .= "<$method><![CDATA[This is a '$method' action]]></$method>";
}
$mustbexml .= "</foo>";

foreach my $keep (1,0) {
    is( $channel->xml( 'foo',$keep ),$mustbexml,qq{Check if XML correct} );
}

is( $channel->xml,"<messages></messages>","Check if no messages left" );
