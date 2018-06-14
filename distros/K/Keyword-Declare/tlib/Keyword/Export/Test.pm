package
# Hide this from the CPAN indexer...
Keyword::Export::Test;

use warnings;

use Keyword::Declare;

sub import {
#    keyword test1           {{{ ok 1, "test1"                  }}}
#    keyword test  (Int $n)  {{{ ok «$n == 2», "test"           }}}
    keyword test3 (Int* @n) {{{ ok «@n && $n[0] == 3», "test3" }}}
#    keyword test4 (Block)   {{{ ok 1, "test4";                 }}}
}


1; # Magic true value required at end of module
__END__
