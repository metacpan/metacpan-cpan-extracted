use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

unless ( do { local $@; eval "use HTML::TreeBuilder 5 -weak; 1" } ) {
    plan skip_all => 'No HTML::TreeBuilder 5 -weak';
}

use_ok('HTML::Gumbo');

# Test for memory leak in tree mode (rt.cpan.org #128667).
# Before the fix, parse_to_tree_cb leaked the root document SV on
# every parse call, keeping the entire tree alive after undef.

my $parser = HTML::Gumbo->new;

{
    my $tree = $parser->parse(<<'END', format => 'tree');
<!DOCTYPE html>
<h1>hello world</h1>
<p>some text</p>
END

    my $weak = $tree;
    weaken($weak);
    undef $tree;

    is $weak, undef, 'tree freed after undef in document mode';
}

{
    my $tree = $parser->parse(<<'END', fragment_namespace => 'HTML', format => 'tree');
<div><p>hello</p><p>world</p></div>
END

    my $weak = $tree;
    weaken($weak);
    undef $tree;

    is $weak, undef, 'tree freed after undef in fragment mode';
}

done_testing();
