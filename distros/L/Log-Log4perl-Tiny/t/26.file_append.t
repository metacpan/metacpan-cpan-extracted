# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 2;    # last test to print
use Log::Log4perl::Tiny qw( :easy get_logger );

use lib 't';
use TestLLT qw( set_logger log_is );

(my $target = __FILE__) =~ s/\.t$/.log/mxs;

{
   # write some gibberish into target file
   open my $fh, '>', $target or die "open($target): $!";
   print {$fh} "some\ngibberish\n";
   close $fh;
}
ok((-e $target), "file $target initialized");

Log::Log4perl->easy_init({
   format => '%m%n',
   level  => $INFO,
   file_append => $target,
});
my $logger = get_logger();
set_logger($logger);

INFO 'whatever';

{
   # close file
   my $fh = $logger->fh();
   $logger->fh(sub {});
   close $fh;
}

my $text = do {
   open my $fh, '<', $target or die "open($target): $!";
   local $/;
   <$fh>;
};

is($text, "some\ngibberish\nwhatever\n", 'file contents are correct');

unlink($target);
