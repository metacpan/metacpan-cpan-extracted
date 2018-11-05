use lib 't/lib';
use JTTest;
use JSON::Transform qw(parse_transform);

my @OPS = (
  [
    'array to hashes',
    '"" <@ { "/$K/id":$V#`id` }',
    [{id=>'a', k=>'va'}, {id=>'b', k=>'vb'}],
    { a => {k=>'va'}, b => {k=>'vb'} },
  ],
  [
    'hashes to array',
    '"" <% [ $V@`id`:$K ]',
    { a => {k=>'va'}, b => {k=>'vb'} },
    [{id=>'a', k=>'va'}, {id=>'b', k=>'vb'}],
  ],
  [
    'array identity non-implicit',
    '"" <- "" <@ [ $V ]',
    [ 1, 'a', 4 ],
    [ 1, 'a', 4 ],
  ],
  [
    'array identity',
    '"" <@ [ $V ]',
    [ 1, 'a', 4 ],
    [ 1, 'a', 4 ],
  ],
  [
    'hash identity',
    '"" <% { $K:$V }',
    { a => {k=>'va'}, b => {k=>'vb'} },
    { a => {k=>'va'}, b => {k=>'vb'} },
  ],
  [
    'hash move',
    '"/b" << "/a"',
    { a => {k=>'va'}, b => {k=>'vb'} },
    { b => {k=>'va'} },
  ],
  [
    'hash move to new',
    '"/c" << "/a"',
    { a => {k=>'va'}, b => {k=>'vb'} },
    { c => {k=>'va'}, b => {k=>'vb'} },
  ],
  [
    'hash copy',
    '"/c" <- "/a"',
    { a => {k=>'va'}, b => {k=>'vb'} },
    { a => {k=>'va'}, b => {k=>'vb'}, c => {k=>'va'} },
  ],
  [
    'hash keys',
    '"" <% [ $K ]',
    { a => {k=>'va'}, b => {k=>'vb'} },
    [ qw(a b) ],
  ],
  [
    'array copy with hash transform',
    '"/c" <- "/a" <@ [ $V@`order`:$K ]',
    { a => [ {k=>'va'}, {k=>'vb'} ] },
    { a => [ {k=>'va'}, {k=>'vb'} ], c => [ {k=>'va', order=>0}, {k=>'vb', order=>1}] },
  ],
  [
    'array count',
    '"" <@ $C',
    [ qw(1 a 4 yo) ],
    4
  ],
  [
    'hash count',
    '"" <% $C',
    { a => 1, b => 2 },
    2
  ],
  [
    'variable bind then replace',
    q{
      $defs <- "/a"
      "" <- $defs
    },
    { a => {k=>'va'}, b => {k=>'vb'} },
    {k=>'va'},
  ],
  [
    'comments',
    q{
      -- This is a comment
      "" <% $C
    },
    { a => 1, b => 2 },
    2
  ],
  [
    'literal empty array',
    q{
      $a <- "/a"
      $b <- "/b"
      "" <- .[]
      "/0" <- $b
      "/1" <- $a
      -- second use of .[] ensures not mutating a global!
      "/2" <- .[]
    },
    { a => {k=>'va'}, b => {k=>'vb'} },
    [ {k=>'vb'}, {k=>'va'}, [] ],
  ],
  [
    'other string tokens',
    '"" <- `hi\u0021\n`',
    { a => 1, b => 2 },
    "hi!\n",
  ],
  [
    'apply JSON pointer to expression',
    '"" <- "/a"<"/b"',
    { a => { b => 2 } },
    2,
  ],
  [
    'array literal',
    '"" <- .[ `hi`, `there` ]',
    { a => { b => 2 } },
    [ 'hi', 'there' ],
  ],
  [
    'hash literal',
    '"" <- .{ `hi`: `there` }',
    { a => { b => 2 } },
    { 'hi' => 'there' },
  ],
  [
    'complex transform',
    '"" <- "/Time Series (Daily)" <% [ .{ `date`: $K, `close`: $V<"/4. close" } ]',
    {
      "Meta Data" => {},
      "Time Series (Daily)" => {
        "2018-10-26" => { "1. open" => "", "4. close" => "106.9600" },
        "2018-10-25" => { "1. open" => "", "4. close" => "108.3000" },
      }
    },
    [
      { 'close' => '108.3000', 'date' => '2018-10-25' },
      { 'close' => '106.9600', 'date' => '2018-10-26' },
    ],
  ],
);

for (@OPS) {
  my ($desc, $transform, $in, $expect) = @$_;
  my $got = parse_transform($transform)->($in);
  is_deeply $got, $expect, $desc or diag explain $got;
}

done_testing;
