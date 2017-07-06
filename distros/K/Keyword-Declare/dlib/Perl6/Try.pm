package # hidden from PAUSE indexer
Perl6::Try;
our $VERSION = '0.000001';

use 5.012; use warnings;

use Keyword::Declare;
use Carp;

sub import {
    keytype CatchParam is / \( (?&PerlOWS) (?&PerlVariableScalar) (?&PerlOWS) \) /x;

    keyword CATCH (CatchParam $param = '($_______________________v)', Block $block) :desc(CATCH phaser) {{{
        BEGIN { eval'$CATCH=$CATCH;1' // die q{Can't specify CATCH block outside a try};              }
        BEGIN { die q{Can't specify two CATCH blocks inside a single try} if defined $CATCH;          }
        BEGIN { $CATCH = sub { use experimentals; my <{$param}> = @_; given (<{$param}>) <{$block}> } }
    }}}

    keyword try (Block $block) {{{
        { my $CATCH; eval { <{$block}> 1 } // do{ my $error = $@; eval{ $CATCH->($error) } }; }
    }}}
}

1; # Magic true value required at end of module
