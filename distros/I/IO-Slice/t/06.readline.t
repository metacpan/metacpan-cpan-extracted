use strict;
use Test::More;
use Test::Exception;
use IO::Slice;
use Fcntl qw< :seek >;
use File::Basename qw< dirname >;
my $dirname = dirname(__FILE__);
my $spec    = {
   filename => "$dirname/testfile.multiline",
   offset   => 0,
   length   => 115,
};

my @full;
{
   open my $fh, '<:raw', $spec->{filename}
     or die "open('$spec->{filename}'): $!";
   @full = readline $fh;
}

my $sfh = IO::Slice->new($spec);

my @twolines;
lives_ok {
   @twolines = map { scalar readline $sfh } 1 .. 2;
}
'readline() lives';
is $twolines[0], $full[0], 'first line is OK';
is $twolines[1], $full[1], 'second line is OK';

# rewind
seek $sfh, 0, SEEK_SET;
my @got_paragraphs;
lives_ok {
   local $/ = '';
   @got_paragraphs = readline $sfh;
}
'readline() for paragraphs lives';
my @expected_paragraphs = map { "$_\n" } split /\n\n+/, join '', @full;
is scalar(@got_paragraphs), scalar(@expected_paragraphs),
  'number of paragraphs';
is $got_paragraphs[$_], $expected_paragraphs[$_], "paragraph $_ is OK"
  for 0 .. $#got_paragraphs;

# rewind
seek $sfh, 0, SEEK_SET;
my $got_full;
lives_ok {
   local $/;
   $got_full = <$sfh>;
} 'readline() using operator, for slurping';
is $got_full, join('', @full), 'slurp is successful';

done_testing();
