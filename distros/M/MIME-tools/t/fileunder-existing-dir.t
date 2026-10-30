use strict;
use warnings;
use Test::More tests => 3;

use MIME::Parser;
use File::Temp qw(tempdir);

my $msg = "Content-Type: text/plain\n"
        . "Content-Disposition: attachment; filename=a.txt\n\nhello\n";

# Pre-create the directories the next parse would use
my $base = tempdir(CLEANUP => 1);
my @planted = map { "$base/msg-$_-$$-0" } time .. time + 120;
mkdir $_ for @planted;

my $parser = MIME::Parser->new();
$parser->output_under($base);
my $ent = eval { $parser->parse_data($msg) };
ok(!$ent, 'Parse refuses an existing generated directory');
is((grep { -e "$_/a.txt" } @planted), 0, 'Nothing written into it');

$parser->output_under(tempdir(CLEANUP => 1));
ok($parser->parse_data($msg), 'Parse into a fresh base works');
