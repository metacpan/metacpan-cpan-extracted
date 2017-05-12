#!/usr/bin/perl
#
# $Id: 05_basic.t 142 2004-11-30 19:42:11Z james $
#

use strict;
use warnings;

BEGIN {
    use Test::More;
    use Test::Exception;
    our $tests = 24;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

# pull in the package
use_ok 'Lingua::Alphabet::Phonetic';
use_ok 'Lingua::Alphabet::Phonetic::Password';

# create an object
my $p;
lives_ok { $p = Lingua::Alphabet::Phonetic->new('Password') }
    'instantiate an object';
isa_ok $p, 'Lingua::Alphabet::Phonetic::Password';

# check some basic passwords (generated from 
# http://www.winguides.com/security/password.php)
my %tests = (
    'qOusiENi' => [ qw|quebec OSCAR uniform sierra india ECHO NOVEMBER india| ],
    '9L1=ouzl' => [ qw|Nine LIMA One Equals oscar uniform zulu lima| ],
    'vI4yl$fl' => [ qw|victor INDIA Four yankee lima Dollars foxtrot lima| ],
    'g=aphl0C' => [ qw|golf Equals alpha papa hotel lima Zero CHARLIE| ],
    '2=oakiAq' => [ qw|Two Equals oscar alpha kilo india ALPHA quebec| ],
    'Th6E$iEq' => [ qw|TANGO hotel Six ECHO Dollars india ECHO quebec| ],
    'k#0joasl' => [ qw|kilo Hash Zero juliet oscar alpha sierra lima| ],
    'gl-5iu*I' => [ qw|golf lima Dash Five india uniform Asterisk INDIA| ],
    '#12phoud' => [ qw|Hash One Two papa hotel oscar uniform delta| ],
    'SWo&1ouq' => [ qw|SIERRA WHISKEY oscar Ampersand One oscar uniform quebec| ],
    'cro$@Ieh' => [ qw|charlie romeo oscar Dollars At INDIA echo hotel| ],
    'qouG*=br' => [ qw|quebec oscar uniform GOLF Asterisk Equals bravo romeo| ],
    'cr=7joej' => [ qw|charlie romeo Equals Seven juliet oscar echo juliet| ],
    'Jo3hi7p!' => [ qw|JULIET oscar Three hotel india Seven papa Exclamation| ],
    '2ro!*oa0' => [ qw|Two romeo oscar Exclamation Asterisk oscar alpha Zero| ],
    '4Ro1-#ax' => [ qw|Four ROMEO oscar One Dash Hash alpha xray| ],
    '_o9Jlabr' => [ qw|Underscore oscar Nine JULIET lima alpha bravo romeo| ],
    'b_iUdia0' => [ qw|bravo Underscore india UNIFORM delta india alpha Zero| ],
    '?*Achies' => [ qw|Question Asterisk ALPHA charlie hotel india echo sierra| ],
    'sw$A$w9U' => [ qw|sierra whiskey Dollars ALPHA Dollars whiskey Nine UNIFORM| ],    
);
for my $pw( keys %tests ) {
    my @ret = $p->enunciate( $pw );
    is_deeply \@ret, $tests{$pw}, "enunciate password $pw";
}

#
# EOF
