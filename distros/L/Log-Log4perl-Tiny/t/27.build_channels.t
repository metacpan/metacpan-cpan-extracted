# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 8;    # last test to print
use Log::Log4perl::Tiny qw( :easy get_logger build_channels );

use lib 't';
use TestLLT qw( set_logger log_is );

(my $target_create = __FILE__) =~ s/\.t$/.log_create/mxs;
(my $target_append = __FILE__) =~ s/\.t$/.log_append/mxs;

for my $target ($target_create, $target_append) {

   # write some gibberish into target file
   open my $fh, '>', $target or die "open($target): $!";
   print {$fh} "some\ngibberish\n";
   close $fh;
} ## end for my $target ($target_create...)
ok((-e $target_create), "file $target_create initialized");
ok((-e $target_append), "file $target_append initialized");

my $target_string = '';
open my $target_string_fh, '>', \$target_string
  or die "open(): $!";

my @lines;
my $target_sub = sub { push @lines, $_[0] };

Log::Log4perl->easy_init(
   {
      format   => '%m%n',
      level    => $INFO,
      channels => [
         fh          => $target_string_fh,
         sub         => $target_sub,
         file_create => $target_create,
         file_append => $target_append,
      ],
   }
);
my $logger = get_logger();
set_logger($logger);

isa_ok $logger->fh(), 'ARRAY';

INFO 'whatever';

# Get rid of previous logger, so that files are closed etc.
$logger->fh(sub { });
close $target_string_fh;

# file_create
{
   my $text = do {
      open my $fh, '<', $target_create or die "open($target_create): $!";
      local $/;
      <$fh>;
   };

   is($text, "whatever\n", '(create) file contents are correct');
}

# file_append
{
   my $text = do {
      open my $fh, '<', $target_append or die "open($target_append): $!";
      local $/;
      <$fh>;
   };

   is($text, "some\ngibberish\nwhatever\n",
      '(append) file contents are correct');
}

# reference to sub
is scalar(@lines), 1, 'number of generated lines';
is($lines[0], "whatever\n", 'accumulation array contents are correct');

# filehandle
is($target_string, "whatever\n", 'filehandle contents are correct');

unlink $_ for ($target_create, $target_append);
