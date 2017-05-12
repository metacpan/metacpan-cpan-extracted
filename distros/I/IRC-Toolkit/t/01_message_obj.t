use Test::More;
use strict; use warnings FATAL => 'all';

use_ok( 'IRC::Message::Object', 'ircmsg' );
use_ok( 'POE::Filter::IRCv3' );

my $filter = POE::Filter::IRCv3->new(colonify => 0);

my $raw_line = ":server.org 001 user :Welcome to IRC";
my $arr = $filter->get([$raw_line]);
my $hash = shift @$arr;

my $obj = new_ok( 'IRC::Message::Object' => [
    %$hash
  ],
);

cmp_ok( $obj->prefix, 'eq', 'server.org', 'prefix  ok' );
cmp_ok( $obj->command, 'eq', '001', 'command  ok' );
cmp_ok( $obj->params->[0], 'eq', 'user', 'param 0  ok' );
cmp_ok( $obj->params->[1], 'eq', 'Welcome to IRC', 'param 1  ok' );

is_deeply $obj->TO_JSON,
  +{
    prefix  => 'server.org',
    command => '001',
    params  => [ 'user', 'Welcome to IRC' ],
  },
  'TO_JSON ok';

my $short = ircmsg(%$hash);
isa_ok($short, 'IRC::Message::Object', 'ircmsg() produced obj' );
cmp_ok( $short->command, 'eq', '001', 'ircmsg()->command()  ok' );

my $tag_line = q{@intent=ACTION;znc.in/extension=value;foobar}
             . q{ PRIVMSG #somewhere :Some string};
my $parsed = $filter->get([$tag_line])->[0];
my $tagged = IRC::Message::Object->new(%$parsed);

cmp_ok( length($tagged->raw_line), '==', length($tag_line), 
  'raw_line length ok' 
);

ok( $tagged->has_tags, 'has_tags  ok' );
is_deeply( $tagged->tags,
  +{
    foobar => undef,
    intent => 'ACTION',
    'znc.in/extension' => 'value',
  },
  'tags  ok'
);
cmp_ok( $tagged->get_tag('intent'), 'eq', 'ACTION', 'get_tag  ok' );
ok( $tagged->has_tag('foobar'), 'has_tag  ok' );

ok(
  $tagged->tags_as_string =~ qr/intent=ACTION(?:[;\s]|$)/ &&
  $tagged->tags_as_string =~ qr/znc\.in\/extension=value(?:[;\s]|$)/ &&
  $tagged->tags_as_string =~ qr/foobar(?:[;\s]|$)/,
  'tags_as_string'
) or diag "Got string ".$tagged->tags_as_string;

ok(
  (grep {; $_ eq 'foobar' } @{ $tagged->tags_as_array }) &&
  (grep {; $_ eq 'znc.in/extension=value' } @{ $tagged->tags_as_array }) &&
  (grep {; $_ eq 'intent=ACTION' } @{ $tagged->tags_as_array }),
  'tags_as_array  ok'
) or diag explain $tagged->tags_as_array;

my $from_raw = new_ok( 'IRC::Message::Object' => [
    raw_line => $tag_line,
  ],
);
# Breaking encapsulation needs to work for optimized bits like
# POEx::IRC::Backend ->
cmp_ok $from_raw->{command}, 'eq', 'PRIVMSG',
  'backing HASH filled command from raw ok';
is_deeply [ $from_raw->{params}->all ], [ '#somewhere', 'Some string' ],
  'backing HASH filled params from raw ok';

cmp_ok( $from_raw->command, 'eq', 'PRIVMSG', 'obj from raw_line ok: command' );
is_deeply [ $from_raw->params->all ], [ '#somewhere', 'Some string' ],
  'obj from raw_line ok: params';

my $clonedish = IRC::Message::Object->new(
  colonify => 1,
  command => $from_raw->command,
  params  => [ @{ $from_raw->params } ],
  prefix  => $from_raw->prefix,
);
my $line_from_clonedish = $clonedish->raw_line;

cmp_ok $line_from_clonedish, 'eq', 'PRIVMSG #somewhere :Some string',
  'raw_line from cloned ok';

my $long_without_tags = q{PRIVMSG #somewhere :}.'X'x700;
my $long_with_tags = $tag_line .'X'x700;

my $orig_without_tags = ircmsg(raw_line => $long_without_tags);
my $trunc_without_tags = $orig_without_tags->truncate;
isa_ok( $trunc_without_tags, 'IRC::Message::Object', 
  'truncate() returned obj'
);
cmp_ok( length $trunc_without_tags->raw_line, '==', 510,
  'truncate() raw_line length ok'
);
cmp_ok( $trunc_without_tags->command, 'eq', 'PRIVMSG',
  'truncate() command ok'
);
cmp_ok( $trunc_without_tags->params->[0], 'eq', '#somewhere',
  'truncate() param 0 ok'
);
cmp_ok( $trunc_without_tags->params->[1], '=~', qr/^X+$/,
  'truncate() param 1 ok'
);

my $orig_with_tags  = ircmsg(raw_line => $long_with_tags);
my $trunc = $orig_with_tags->truncate;
ok( $trunc->has_tag('foobar'), 'has_tag after truncate ok' );

ok(
  (grep {; $_ eq 'foobar' } @{ $trunc->tags_as_array }) &&
  (grep {; $_ eq 'znc.in/extension=value' } @{ $trunc->tags_as_array }) &&
  (grep {; $_ eq 'intent=ACTION' } @{ $trunc->tags_as_array }),
  'tags_as_array after truncate ok'
) or diag explain $trunc->tags_as_array;


done_testing;
