use strict;
use warnings;
use Test::More;

unless ( do { local $@; eval "use HTML::TreeBuilder 5 -weak; 1" } ) {
    plan skip_all => 'No HTML::TreeBuilder 5 -weak';
}

use_ok('HTML::Gumbo');

my $parser = HTML::Gumbo->new;

{
    my $res = $parser->parse(<<'END', format => 'tree');
<!DOCTYPE html>
<!--This is a comment-->
<h1>hello world!</h1>
END

    my $expected = <<'END';
<document><!DOCTYPE html><!--This is a comment--><html><head></head><body><h1>hello world!</h1>
</body></html></document>
END
    chomp $expected;
    is $res->as_HTML, $expected, 'correct value';
}

{
    my $res = $parser->parse(<<'END', fragment_namespace => 'HTML', format => 'tree');
<div>hello world!</div>
END

    my $expected = <<'END';
<document><div>hello world!</div>
</document>
END
    chomp $expected;
    is $res->as_HTML, $expected, 'correct value';
}

done_testing();
