#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Devel::ebug;
use Devel::ebug::Wire;

# Both JSON modules are optional, so load them by filename: a bareword
# require would make them test prereqs.
my @classes = grep { (my $pm = "$_.pm") =~ s{::}{/}g; eval { require $pm; 1 } }
              @Devel::ebug::Wire::JSON_CLASSES;

plan skip_all => 'JSON::PP or Cpanel::JSON::XS is needed for the json serializer'
  unless @classes;

plan tests => 12 + @classes;

# --- format detection -------------------------------------------------

is(Devel::ebug::Wire::detect('{"command":"ping"}'), 'json', 'a brace means json');
is(Devel::ebug::Wire::detect('2d2d2d0a'), 'yaml', 'hex means yaml');
is(Devel::ebug::Wire::detect(undef), 'yaml', 'nothing to go on means yaml');

# --- round trips ------------------------------------------------------

for my $format (qw( yaml json )) {
  my $data = { command => 'break_point', line => 12, ok => 'yes' };
  my $back = Devel::ebug::Wire::decode($format,
               Devel::ebug::Wire::encode($format, $data));
  is_deeply($back, $data, "$format round trips a plain structure");
}

# --- each json module ---------------------------------------------

foreach my $class (@classes) {
  subtest $class => sub {
    plan tests => 13;
    local $Devel::ebug::Wire::JSON;
    local @Devel::ebug::Wire::JSON_CLASSES = ($class);
    is(ref Devel::ebug::Wire::_json(), $class, "encoding with $class");

    my $line = Devel::ebug::Wire::encode('json', { command => 'step', note => "a\nb" });
    unlike($line, qr/\n/, 'an encoded json line never contains a newline');
    is_deeply($class->new->utf8->decode($line),
              { command => 'step', note => "a\nb" },
              'the line is plain json, readable without Devel::ebug');

    # Blessed references have to survive, because stack_trace sends
    # Devel::StackTrace::Frame objects that the frontend calls methods on.
    {
      my $obj  = bless { subroutine => 'main::foo', args => [ 1, 2 ] }, 'Some::Frame';
      my $back = Devel::ebug::Wire::decode('json',
                   Devel::ebug::Wire::encode('json', { frames => [$obj] }));
      is(ref $back->{frames}[0], 'Some::Frame', 'json keeps the class of a blessed reference');
      is($back->{frames}[0]{subroutine}, 'main::foo', 'and its contents');
      is_deeply($back->{frames}[0]{args}, [ 1, 2 ], 'and nested contents');
    }

    {
      my $scalar = 'hello';
      my $back   = Devel::ebug::Wire::decode('json',
                     Devel::ebug::Wire::encode('json', { ref => \$scalar }));
      is(ref $back->{ref}, 'SCALAR', 'json keeps a scalar reference');
      is(${ $back->{ref} }, 'hello', 'with the right value');
    }

    # Values sampled out of the debugged program can be anything at all; a
    # readable placeholder beats refusing to serialize the response.
    {
      my $back = Devel::ebug::Wire::decode('json',
                   Devel::ebug::Wire::encode('json', { code => sub { 1 } }));
      like($back->{code}, qr/^CODE/, 'a code reference becomes its name');
    }

    {
      my $cycle = { name => 'loop' };
      $cycle->{self} = $cycle;
      my $back = Devel::ebug::Wire::decode('json',
                   Devel::ebug::Wire::encode('json', $cycle));
      is($back->{name}, 'loop', 'a cycle still encodes the rest of the structure');
      ok(!ref $back->{self}, 'and the loop is broken rather than followed');
    }

    is(Devel::ebug::Wire::decode('json', '{"t":true,"f":false}')->{t}, 1,
       'true decodes to a plain 1');
    is(Devel::ebug::Wire::decode('json', '{"t":true,"f":false}')->{f}, 0,
       'false decodes to a plain 0');
  };
}

# --- a real session over json ----------------------------------------

my $ebug = Devel::ebug->new;
$ebug->serializer('json');
$ebug->program('corpus/calc.pl');
$ebug->load;

$ebug->break_point(9);
$ebug->run;
is($ebug->line, 9, 'stopped at the break point');
is($ebug->filename, 'corpus/calc.pl', 'in the right file');
like($ebug->codeline, qr/\S/, 'and the source line came back');

my $pad = $ebug->pad;
is(ref $pad, 'HASH', 'the pad came back');

is($ebug->eval('2 + 2'), 4, 'eval works over json');

$ebug->break_point_subroutine('main::add');
$ebug->run;
my @stack = $ebug->stack_trace;
ok(@stack, 'a stack trace came back');
ok($stack[0]->can('subroutine'), 'its frames are objects, not plain hashes');
