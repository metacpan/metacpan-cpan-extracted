package Test::Markdent;

use strict;
use warnings;

use Data::Dumper;
use Test2::V0;
use Tree::Simple::Visitor::ToNestedArray;

BEGIN {
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval {
        require HTML::Differences;
        HTML::Differences->import('html_text_diff');
    };
    eval { require WebService::Validator::HTML::W3C; };
    ## use critic
}

use Markdent::Handler::HTMLStream::Document;
use Markdent::Handler::HTMLStream::Fragment;
use Markdent::Handler::MinimalTree;
use Markdent::Parser;

use Exporter qw( import );

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = qw(
    tree_from_handler
    parse_ok
    html_fragment_ok
    html_document_ok
    test_all_html
);
## use critic

sub parse_ok {
    my $parser_p    = ref $_[0] ? shift : {};
    my $markdown    = shift;
    my $expect_tree = shift;
    my $desc        = shift;

    my $handler_class = delete $parser_p->{handler_class}
        || 'Markdent::Handler::MinimalTree';
    my $handler = $handler_class->new();

    my $parser = Markdent::Parser->new( %{$parser_p}, handler => $handler );

    $parser->parse( markdown => $markdown );

    my $results = tree_from_handler($handler);

    diag( Dumper($results) )
        if $ENV{MARKDENT_TEST_VERBOSE};

    is( $results, $expect_tree, $desc );
}

sub tree_from_handler {
    my $handler = shift;

    my $visitor = Tree::Simple::Visitor::ToNestedArray->new();
    $handler->tree()->accept($visitor);

    # The top level of this data structure is always a one element array ref
    # containing the document contents.
    return $visitor->getResults()->[0];
}

sub html_fragment_ok {
    my $dialects        = ref $_[0] ? shift : {};
    my $markdown        = shift;
    my $expect_html     = shift;
    my $desc            = shift;
    my $skip_validation = shift;

    return unless _can_test_html();

    return subtest(
        $desc,
        sub {
            my $got_html = _html_for(
                'Fragment',
                $dialects,
                $markdown,
            );

            _html_validates_ok( $got_html, 'is fragment' )
                unless $skip_validation;

            s/\n+$/\n/ for $got_html, $expect_html;

            my $diff = html_text_diff( $got_html, $expect_html );
            ok( !$diff, $desc )
                or diag($diff);
        }
    );
}

sub html_document_ok {
    my $dialects    = ref $_[0] ? shift : {};
    my $markdown    = shift;
    my $expect_html = shift;
    my $desc        = shift;

    return unless _can_test_html();

    return subtest(
        $desc,
        sub {
            my $got_html = _html_for(
                'Document',
                $dialects,
                $markdown, {
                    title    => $desc,
                    charset  => 'UTF-8',
                    language => 'en',
                },
            );

            my $real_expect_html = <<"EOF";
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>$desc</title>
</head>
<body>
$expect_html
</body>
</html>
EOF

            _html_validates_ok($got_html);

            my $diff = html_text_diff( $got_html, $real_expect_html );
            ok( !$diff, $desc )
                or diag($diff);
        }
    );
}

sub _html_for {
    my $class     = shift;
    my $dialects  = shift || {};
    my $markdown  = shift;
    my $handler_p = shift || {};

    my $got_html = q{};

    ## no critic (InputOutput::RequireBriefOpen)
    open my $fh, '>', \$got_html
        or die $!;

    my $full_class = 'Markdent::Handler::HTMLStream::' . $class;
    my $streamer   = $full_class->new(
        %{$handler_p},
        output => $fh,
    );
    my $parser = Markdent::Parser->new(
        %{$dialects},
        handler => $streamer,
    );
    $parser->parse( markdown => $markdown );

    close $fh
        or die $!;

    return $got_html;
}

sub _html_validates_ok {
    my $got_html    = shift;
    my $is_fragment = shift;

SKIP: {
        skip(
            'The WebService::Validator::HTML::W3C module is completely broken.'
                . ' See https://rt.cpan.org/Ticket/Display.html?id=122930 for some details.',
            1
        );
    }
    return;

    #     unless ( $ENV{RELEASE_TESTING} ) {
    #     SKIP: {
    #             skip
    #                 'HTML validation tests with W3C service are only done for release testing',
    #                 1;
    #         }
    #         return;
    #     }

    #     unless ( WebService::Validator::HTML::W3C->can('new') ) {
    #     SKIP: {
    #             skip
    #                 'HTML validation tests require WebService::Validator::HTML::W3C',
    #                 1;
    #         }
    #         return;
    #     }

    #     if ($is_fragment) {
    #         $got_html = <<"EOF";
    # <!DOCTYPE html>
    # <html lang="en">
    # <head>
    # <meta charset="UTF-8">
    # <title>Test</title>
    # </head>
    # <body>
    # $got_html
    # </body>
    # </html>
    # EOF
    #     }

    #     my $v = WebService::Validator::HTML::W3C->new(
    #         detailed => 1,
    #     );

    #     $v->validate_markup($got_html);

    #     is( $v->num_errors(), 0, 'no errors from W3C validator' )
    #         and return;

    #     diag($got_html);
    #     diag(
    #         sprintf(
    #             "line %s\tcol %s\terror: %s",
    #             $_->line(), $_->col(), $_->msg()
    #         )
    #     ) for @{ $v->errors() || [] };

    #     return;
}

sub _can_test_html {
    return 1 if HTML::Differences->can('html_text_diff');

SKIP: {
        skip 'This test requires HTML::Differences', 1;
    }

    return 0;
}

sub test_all_html {
    my $type = shift;

    my $sub = __PACKAGE__->can( 'html_' . $type . '_ok' );

    {
        my $markdown = <<'EOF';
This is a paragraph
EOF

        my $expect_html = <<'EOF';
<p>
  This is a paragraph
</p>
EOF

        $sub->( $markdown, $expect_html, 'single paragraph' );
    }

    {
        my $markdown = <<'EOF';
Here is a [link](http://example.com) and *em* and **strong**.

* Now a list
* List 2
    * indented

Need a para to separate lists.

1. #1
2. #2
EOF

        my $expect_html = <<'EOF';
<p>
  Here is a <a href="http://example.com">link</a>
  and <em>em</em> and <strong>strong</strong>.
</p>

<ul>
  <li>Now a list</li>
  <li>List 2
    <ul>
      <li>indented</li>
    </ul>
  </li>
</ul>

<p>
  Need a para to separate lists.
</p>

<ol>
  <li>#1</li>
  <li>#2</li>
</ol>
EOF

        $sub->( $markdown, $expect_html, 'links, em, strong, and lists' );
    }

    {
        my $markdown = <<'EOF';
A Theory-style table

  [Table caption]
| Header 1 and 2     || Nothing  |
+--------------------++----------+
| Header 1 | Header 2 | Header 3 |
+----------+----------+----------+
| B1       | B2       | B3       |
|    right |  center  |          |

| l1       | x        | x        |
: l2       :          :          :
: l3       :          :          :
| end                          |||
EOF

        my $expect_html = <<'EOF';
<p>
  A Theory-style table
</p>

<table>
  <caption>Table caption</caption>
  <thead>
    <tr>
      <th style="text-align: left" colspan="2">Header 1 and 2</th>
      <th style="text-align: left">Nothing</th>
    </tr>
    <tr>
      <th style="text-align: left">Header 1</th>
      <th style="text-align: left">Header 2</th>
      <th style="text-align: left">Header 3</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align: left">B1</td>
      <td style="text-align: left">B2</td>
      <td style="text-align: left">B3</td>
    </tr>
    <tr>
      <td style="text-align: right">right</td>
      <td style="text-align: center">center</td>
      <td style="text-align: left"></td>
    </tr>
  </tbody>
  <tbody>
    <tr>
      <td style="text-align: left">
        <p>
          l1
l2
l3
        </p>
      </td>
      <td style="text-align: left">x</td>
      <td style="text-align: left">x</td>
    </tr>
    <tr>
      <td style="text-align: left" colspan="3">end</td>
    </tr>
  </tbody>
</table>
EOF

        $sub->(
            { dialects => 'Theory' },
            $markdown,
            $expect_html,
            'Complex Theory-style table'
        );
    }

    {
        my $markdown = <<'EOF';
| **foo** | **bar** | **baz** |
| 1       | 2       | 3       |
EOF

        my $expect_html = <<'EOF';
<table>
  <tbody>
    <tr>
      <td style="text-align: left"><strong>foo</strong></td>
      <td style="text-align: left"><strong>bar</strong></td>
      <td style="text-align: left"><strong>baz</strong></td>
    </tr>
    <tr>
      <td style="text-align: left">1</td>
      <td style="text-align: left">2</td>
      <td style="text-align: left">3</td>
    </tr>
  </tbody>
</table>
EOF

        $sub->(
            { dialects => 'Theory' },
            $markdown,
            $expect_html,
            'Simple Theory-style table with no header rows'
        );
    }

    {
        my $markdown = <<'EOF';
This is a p.

```
my $foo = 'bar';
```

More p.
EOF

        my $expect_html = <<'EOF';
<p>
  This is a p.
</p>

<pre><code>my $foo = 'bar';</code></pre>

<p>
  More p.
</p>
EOF

        $sub->(
            { dialects => 'GitHub' },
            $markdown,
            $expect_html,
            'GitHub dialect with fenced code block (no language)'
        );
    }

    {
        my $markdown = <<'EOF';
This is a p.

```Perl
my $foo = 'bar';
```

More p.
EOF

        my $expect_html = <<'EOF';
<p>
  This is a p.
</p>

<pre><code class="language-Perl">my $foo = 'bar';</code></pre>

<p>
  More p.
</p>
EOF

        $sub->(
            { dialects => 'GitHub' },
            $markdown,
            $expect_html,
            'GitHub dialect with fenced code block (language = Perl)'
        );
    }
}

1;

# ABSTRACT: High level test functions for Markdent

__END__

=pod

=head1 DESCRIPTION

There are no user-facing parts in here.

=cut
