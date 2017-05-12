use strict;
use Test::More;
use Test::Exception;
use IO::Slice;
use File::Basename qw< dirname >;
my $dirname = dirname(__FILE__);
my @specs = map { $_->{filename} = "$dirname/$_->{filename}"; $_ }
   @{ do "$dirname/testfile.specs" };

for my $spec (@specs) {
   my $sfh = IO::Slice->new($spec);

   my @expected = split //, $spec->{contents};
   for my $e (@expected) {
      my $got = getc $sfh;
      if (defined $got) {
         my $eprint = ($e eq "\n") ? '\n' : $e;
         is $got, $e, "got right character $eprint";
      }
      else {
         fail 'character is defined';
      }
   }

   my $newc = getc $sfh;
   ok ! defined($newc), 'next getc is undefined';
   ok eof($sfh), 'file is at its end';
}

done_testing();
