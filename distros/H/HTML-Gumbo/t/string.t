use strict;
use warnings;
use utf8;
use Test::More;

use_ok('HTML::Gumbo');

my $parser = HTML::Gumbo->new;
{
    my $input = <<'END';
<!DOCTYPE html>
<!--This is a comment-->
<h1>hello world!</h1>
<div class="test">
  <p>first para
  <p>second
</div>
<div>
  <img />
  <img alt="&copy;">
  <img></img>
</div>
<some>
END
    my $expected = <<'END';
<!DOCTYPE html>
<!--This is a comment--><html><head></head><body><h1>hello world!</h1>
<div class="test">
  <p>first para
  </p><p>second
</p></div>
<div>
  <img>
  <img alt="©">
  <img>
</div>
<some>
</some></body></html>
END
    my $res = $parser->parse($input);
    is $res, $expected, 'very basic test';
}

{
    my $input = <<'END';
<div class="&quot;&bull;&amp;bull;&">&lt;p&gt;</div>
END
    my $expected = <<'END';
<html><head></head><body><div class="&quot;•&amp;bull;&amp;">&lt;p&gt;</div>
</body></html>
END
    my $res = $parser->parse($input);
    is $res, $expected, 'very basic test';
}

{
    my $input = <<'END';
<pre>foo</pre>
<pre>
foo</pre>
<pre>

foo</pre>
END
    my $expected = <<'END';
<html><head></head><body><pre>
foo</pre>
<pre>
foo</pre>
<pre>

foo</pre>
</body></html>
END
    my $res = $parser->parse($input);
    is $res, $expected, 'very basic test';
}

{
    my $input = <<'END';
<div></div>
END
    my $expected = <<'END';
<div></div>

END
    my $res = $parser->parse($input, fragment_namespace => 'HTML');
    is $res, $expected, 'very basic fragment parsing test';
}


{
    my $input = <<'END';
<div>&gt;&lt;&amp;t&gt;&lt;</div>
END
    my $expected = <<'END';
<div>&gt;&lt;&amp;t&gt;&lt;</div>

END
    my $res = $parser->parse($input, fragment_namespace => 'HTML');
    is $res, $expected, "make sure we don't turn text into html";
}


done_testing();
