use warnings;
use strict;

use Test::More;
use lib './tlib', '../tlib';

BEGIN {
    use Keyword::Simple;
    if ($Keyword::Simple::VERSION >= 0.04 && $] < 5.018) {
        plan skip_all => "Keyword::Declare not compatible with Keyword::Simple v$Keyword::Simple::VERSION under Perl $]";
    }
}

use Keyword::Export::Test;

#test1;
#test 2;
test3 3;
#test4 { note 'test3' }

done_testing();

