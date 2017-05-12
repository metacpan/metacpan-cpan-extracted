use strict;
use warnings;
use Encode;
use File::Temp qw(tempdir);
use MIME::Visitor;
use MIME::Parser;

use Test::More tests => 1;

my $parser = MIME::Parser->new;
$parser->output_under(tempdir(CLEANUP => 1));

{
  my $entity = $parser->parse_open('eg/no-text.msg');

  my $orig_line = $entity->body->[0];

  MIME::Visitor->rewrite_parts($entity, sub{ warn $_ });

  my $new_line = $entity->body->[0];

  chomp($orig_line, $new_line);

  is($new_line, $orig_line, "we didn't rewrite");
}
