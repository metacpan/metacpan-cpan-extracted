use strict;
use warnings;

use Test::More 0.98;

use GraphQL::Houtou qw(parse parse_with_options);

subtest 'top-level parse returns legacy AST shape' => sub {
  my $ast = parse('{ viewer { id } }');

  is ref($ast), 'ARRAY', 'document is an arrayref';
  is $ast->[0]{kind}, 'operation', 'legacy parse returns operation node';
  is ref($ast->[0]{selections}), 'ARRAY', 'operation has selections';
  is $ast->[0]{selections}[0]{name}, 'viewer', 'legacy field name is preserved';
};

subtest 'parse rejects parser options and stays minimal' => sub {
  my $error;
  eval { parse('{ viewer { id } }', 1) };
  $error = $@;
  ok !$error, 'extra positional parser flags are ignored by Perl signature truncation';
};

subtest 'parse_with_options exposes only parser-local options' => sub {
  my $ast = parse_with_options('{ viewer { id } }', {
    no_location => 1,
  });

  is ref($ast), 'ARRAY', 'graphql-perl parse returns arrayref document';
  my $compat_error;
  eval { parse_with_options('{ viewer { id } }', { noLocation => 1 }) };
  $compat_error = $@;
  like($compat_error, qr/Unknown parser option 'noLocation'/, 'camelCase parser option is retired');

  my $error;
  eval { parse_with_options('{ viewer { id } }', { dialect => 'graphql-js' }) };
  $error = $@;
  like($error, qr/Unknown parser option/, 'legacy dialect option is no longer exposed');
};

subtest 'block string values follow the spec BlockStringValue algorithm' => sub {
  my $ast = parse(qq<{ f(s: """\n    hello\n      world\n  """) }>);
  is $ast->[0]{selections}[0]{arguments}{s}, "hello\n  world",
    'common indent is stripped and blank first/last lines are removed';

  my $escaped = parse(qq<{ f(s: """quote \\""" here""") }>);
  is $escaped->[0]{selections}[0]{arguments}{s}, 'quote """ here',
    'escaped triple quote is unescaped';

  my $crlf = parse(qq<{ f(s: """\r\n  a\r\n  b\r\n""") }>);
  is $crlf->[0]{selections}[0]{arguments}{s}, "a\nb",
    'CRLF line terminators are treated as single line breaks';
};

subtest 'parse errors die with a GraphQL::Houtou::Error object' => sub {
  eval { parse('{ broken ') };
  my $error = $@;
  isa_ok $error, 'GraphQL::Houtou::Error';
  like "$error", qr/Expected name but got EOF/, 'stringifies to the parse message';
  is $error->locations->[0]{line}, 1, 'error carries a line location';
  ok $error->locations->[0]{column}, 'error carries a column location';
};

done_testing;
