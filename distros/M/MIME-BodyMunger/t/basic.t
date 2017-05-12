use strict;
use warnings;
use Encode;
use File::Temp qw(tempdir);
use MIME::Visitor;
use MIME::Parser;

use Test::More tests => 18;

my $parser = MIME::Parser->new;
$parser->output_under(tempdir(CLEANUP => 1));

my $reverser = sub {
  my ($line_ref) = @_;
  chomp;
  $_ = reverse . "\n";
};

{
  my $entity = $parser->parse_open('eg/boring.msg');

  my $orig_line = $entity->body->[0];

  MIME::Visitor->rewrite_all_lines($entity, $reverser);

  my $new_line = $entity->body->[0];

  chomp($orig_line, $new_line);

  # The significance of the second test is that while new IS the old one
  # reversed, but it's not bytewise.  We'll have to re-decode them to get the
  # comparison right. -- rjbs, 2008-05-09
  isnt($new_line, $orig_line,          "the first line has been rewritten");
  isnt($new_line, reverse($orig_line), "...and it isn't bytewise reversed");

  my $decoded_orig = decode('utf-8', $orig_line);
  my $decoded_new  = decode('utf-8', $new_line);

  is($decoded_new, reverse($decoded_orig), "...but it is character reversed");
}

{
  my $entity = $parser->parse_open('eg/macroman.msg');

  my $orig_line = $entity->body->[0];

  MIME::Visitor->rewrite_all_lines($entity, $reverser);

  my $new_line = $entity->body->[0];

  chomp($orig_line, $new_line);

  isnt($new_line, $orig_line,          "the first line has been rewritten");

  # Of course, /this/ one is bytewise reversed, because MacRoman is one-byte
  # chars.
  #isnt($new_line, reverse($orig_line), "...and it isn't bytewise reversed");

  my $decoded_orig = decode('MacRoman', $orig_line);
  my $decoded_new  = decode('MacRoman', $new_line);

  is(
    ord(substr($orig_line, 62, 1)),
    0xD8,
    "got the right y-dots char for MacRoman",
  );

  is($decoded_new, reverse($decoded_orig), "...and it is character reversed");
}

{
  my $entity = $parser->parse_open('eg/multi.msg');

  my @orig_lines = map { $_->body->[0] } $entity->parts;

  MIME::Visitor->rewrite_all_lines($entity, $reverser);

  my @new_lines = map { $_->body->[0] } $entity->parts;

  chomp(@orig_lines, @new_lines);

  isnt($new_lines[0], reverse($orig_lines[0]), "utf8 part not bytewise rev");
  is  ($new_lines[1], reverse($orig_lines[1]), "ascii part is bytewise rev");

  my $decoded_orig = decode('utf-8', $orig_lines[0]);
  my $decoded_new  = decode('utf-8', $new_lines[0]);

  is($decoded_new, reverse($decoded_orig), "...but it is character reversed");
}

{
  my $entity = $parser->parse_open('eg/base64.msg');

  my @orig_lines = $entity->bodyhandle->as_lines;
  
  MIME::Visitor->rewrite_all_lines(
    $entity,
    sub { chomp; $_ = reverse . "\n"; },
  );

  my @new_lines = $entity->bodyhandle->as_lines;

  chomp(@orig_lines, @new_lines);

  for( 0..@orig_lines -1 ) {
    is( $new_lines[ $_ ], reverse( $orig_lines[ $_ ] ), 'reversed' );
  }
}

{
  my $entity = $parser->parse_open('eg/nested.msg');
  
  MIME::Visitor->rewrite_all_lines(
    $entity,
    sub { chomp; $_ = reverse . "\n"; },
  );

  # why can't these end with $?  works under 5.10, but not 5.8
  like($entity->as_string, qr/^\.amanap lanac a nalp a nam A/m, 'nested pt 2');
  like($entity->as_string, qr/^\?\.\.i saw a was I/m, 'nested pt 1');
}
