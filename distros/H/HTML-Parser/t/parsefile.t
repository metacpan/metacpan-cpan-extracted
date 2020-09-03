use strict;
use warnings;

use HTML::Parser ();
use IO::File     ();
use Test::More tests => 6;

my $filename = "file$$.htm";
die "$filename is already there" if -e $filename;
{
    open(my $fh, '>', $filename) || die "Can't create $filename: $!";
    print {$fh} "<title>Heisan</title>\n";
    close($fh);
}
{

    package MyParser;
    use strict;
    use warnings;
    require HTML::Parser;
    our @ISA = qw(HTML::Parser);

    sub start {
        my ($self, $tag, $attr) = @_;
        Test::More::is($tag, "title");
    }

    1;
}

MyParser->new->parse_file($filename);
open(my $fh, $filename) || die;
MyParser->new->parse_file($fh);
seek($fh, 0, 0) || die;
MyParser->new->parse_file($fh);
close($fh);

my $io = IO::File->new($filename) || die;
MyParser->new->parse_file($io);
$io->seek(0, 0) || die;
MyParser->new->parse_file(*$io);

my $text = '';
$io->seek(0, 0) || die;
MyParser->new(
    start_h => [sub { shift->eof; }, "self"],
    text_h  => [sub { $text = shift; }, "text"]
)->parse_file(*$io);
ok(!$text);

close($io);    # needed because of bug in perl
undef($io);

unlink($filename) or warn "Can't unlink $filename: $!";
