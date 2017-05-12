#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper::Concise; # For Dumper().

use Marpa::R2;

# ---------------------------------

sub hash { return { $_[1] => $_[3] } }

# ---------------------------------

sub list { shift; return [@_] }

# ---------------------------------

sub pair { return { $_[1] => $_[2] } }

# ---------------------------------

sub second { return [ @_[2 .. $#_ - 1 ] ] }

# ---------------------------------

my($grammar) = << '__GRAMMAR__';

lexeme default = latm => 1

:default	::= action => ::first

:start		::= List
List		::= Hash+					action => list
Hash		::= String '{' Pairs '}'	action => hash
Pairs		::= Pair+					action => list

Pair		::= String Value ';'		action => pair
				| Hash

Value		::= String
				| Bracketed

Bracketed	::= '[' String ']'			action => second

String		~ [-a-zA-Z_0-9]+

:discard	~ whitespace
whitespace	~ [\s] +

__GRAMMAR__

my($parser) = Marpa::R2::Scanless::G -> new({source => \$grammar});
my($input)  = do {local $/; <DATA>};

print Dumper $parser -> parse(\$input, 'main');

__DATA__
bob {
    ed {
        larry {
            rule5 {
                option {
                    disable-server-response-inspection no;
                }
                tag [ some_tag ];
                from [ prod-L3 ];
                to [ corp-L3 ];
                source [ any ];
                destination [ any ];
                source-user [ any ];
                category [ any ];
                application [ any ];
                service [ any ];
                hip-profiles [ any ];
                log-start no;
                log-end yes;
                negate-source no;
                negate-destination no;
                action allow;
                log-setting orion_log;
            }
            rule6 {
                option {
                    disable-server-response-inspection no;
                }
                tag [ some_tag ];
                from [ prod-L3 ];
                to [ corp-L3 ];
                source [ any ];
                destination [ any ];
                source-user [ any ];
                category [ any ];
                application [ any ];
                service [ any ];
                hip-profiles [ any ];
                log-start no;
                log-end yes;
                negate-source no;
                negate-destination no;
                action allow;
                log-setting orion_log;
            }
        }
    }
}
