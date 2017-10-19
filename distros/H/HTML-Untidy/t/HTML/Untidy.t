use Test2::Bundle::Extended '!meta', '!prop', '!note';
use HTML::Untidy ':common';

subtest 'text' => sub{
  do {
    local @HTML::Untidy::BODY;
    is text('foo'), U, 'returns undef';
    is text('bar', 'baz', 'bat'), U, 'returns undef';
    is \@HTML::Untidy::BODY, ['foo', 'bar', 'baz', 'bat'], 'fragments pushed onto @BODY';
  };

  do {
    local @HTML::Untidy::BODY;
    is text(qw(< > &)), U, 'returns undef';
    is \@HTML::Untidy::BODY, [qw(&lt; &gt; &amp;)], 'fragments properly escaped';
  };
};

subtest 'raw' => sub{
  do {
    local @HTML::Untidy::BODY;
    is raw('foo'), U, 'returns undef';
    is raw('bar', 'baz', 'bat'), U, 'returns undef';
    is \@HTML::Untidy::BODY, ['foo', 'bar', 'baz', 'bat'], 'fragments pushed onto @BODY';
  };

  do {
    local @HTML::Untidy::BODY;
    is raw(qw(< > &)), U, 'returns undef';
    is \@HTML::Untidy::BODY, [qw(< > &)], 'fragments are not escaped';
  };
};

subtest 'note' => sub{
  do {
    local @HTML::Untidy::BODY;
    is note('foo'), U, 'returns undef';
    is note('bar', 'baz', 'bat'), U, 'returns undef';
    is \@HTML::Untidy::BODY, ['<!-- foo -->', '<!-- bar -->', '<!-- baz -->', '<!-- bat -->'], 'fragments pushed onto @BODY';
  };

  do {
    local @HTML::Untidy::BODY;
    is note(qw(< > &)), U, 'returns undef';
    is \@HTML::Untidy::BODY, ['<!-- &lt; -->', '<!-- &gt; -->', '<!-- &amp; -->'], 'fragments properly escaped';
  };
};

subtest 'class' => sub{
  do {
    local @HTML::Untidy::CLASS;
    is class('foo bar'), U, 'returns undef';
    is class('baz', 'bat'), U, 'returns undef';
    is \@HTML::Untidy::CLASS, [qw(foo bar baz bat)], 'classes added to %CLASS';
  };

  do {
    local @HTML::Untidy::CLASS;
    is class(qw(< > &)), U, 'returns undef';
    is \@HTML::Untidy::CLASS, [qw(&lt; &gt; &amp;)], 'classes properly escaped';
  };
};

subtest 'prop' => sub{
  do {
    local @HTML::Untidy::PROP;
    is prop('foo'), U, 'returns undef';
    is prop('bar', 'baz', 'bat'), U, 'returns undef';
    is \@HTML::Untidy::PROP, ['foo', 'bar', 'baz', 'bat'], 'fragments pushed onto @PROP';
  };

  do {
    local @HTML::Untidy::PROP;
    is prop(qw(< > &)), U, 'returns undef';
    is \@HTML::Untidy::PROP, ['&lt;', '&gt;', '&amp;'], 'fragments properly escaped';
  };
};

subtest 'element' => sub{
  is p{}, '<p></p>', 'empty tag';
  is p{ p{} }, "<p>\n<p></p>\n</p>", 'empty nest';
  is div {p {text 'para 1'}; p {text 'para 2'}}, "<div>\n<p>\npara 1\n</p>\n<p>\npara 2\n</p>\n</div>", 'multiple children';

  do {
    local $HTML::Untidy::INDENT = 2;

    my $html = html {
      head {
        title { text 'test page' };
      };

      body {
        h1 { text 'hello world' };

        div {
          class 'testclass';
          attr  id => 'testdiv';
          prop  'fnord';
          note  'nobody can see this';

          p { text 'foo' };

          p {
            text 'bar';
            text 'baz bat';
          };
        };

        div {
          attr id => 'footer';
        };
      };
    };

    my $expected = q{<html>
  <head>
    <title>
      test page
    </title>
  </head>
  <body>
    <h1>
      hello world
    </h1>
    <div class="testclass" id="testdiv" fnord>
      <!-- nobody can see this -->
      <p>
        foo
      </p>
      <p>
        bar
        baz bat
      </p>
    </div>
    <div id="footer"></div>
  </body>
</html>};

    is $html, $expected, 'integration';
  };
};

done_testing;
