package # hidden from PAUSE indexer
Perl6::Try;
our $VERSION = '0.000001';

use 5.014; use warnings;

use Keyword::Declare;
use Carp;

sub import {
    keyword try (Block $block) {{{
        { my $CATCH; eval { <{$block->reline}> 1 } // do{ my $error = $@; $CATCH->($error) }; }
    }}}

    keyword CATCH (List $param = '($'.('_'x50).'v)', Block $block) {{{
        BEGIN { eval'$CATCH=$CATCH;1' // die q{Can't specify CATCH block outside a try};              }
        BEGIN { die q{Can't specify two CATCH blocks inside a single try} if defined $CATCH;          }
        BEGIN { $CATCH = sub { use experimentals; my <{$param}> = @_; given (<{$param}>) <{$block->reline}> } }
    }}}
}

1; # Magic true value required at end of module
