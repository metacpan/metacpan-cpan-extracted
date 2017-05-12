BEGIN { $| = 1; print "1..24\n"; }

use Digest::FNV::XS;

sub tst {
   my ($name, $data, $hash) = @_;

   my $func = defined &{"Digest::FNV::XS::$name"}
      ? \&{"Digest::FNV::XS::$name"}
      : sub { $hash };

   my $hex = unpack "H*", $data;
   my $h = $func->($data);

   print $h == $hash ? "" : "not ", "ok ", ++$count, " # plain $name($hex) == $h ($hash)\n";

   my $h;
   $h = $func->($_, $h)
      for split //, $data;

   print $h == $hash ? "" : "not ", "ok ", ++$count, " # split $name($hex) == $h ($hash)\n";
}

tst fnv0_32  => "\x00", 0;
tst fnv0_64  => "\x00\x00", 0;
tst fnv0_32  => "chongo <Landon Curt Noll> /\\../\\", 2166136261;
tst fnv0_64  => "chongo <Landon Curt Noll> /\\../\\", 14695981039346656037;
tst fnv1_32  => "\x01\x47\x6c\x10\xf3", 0;
tst fnv1a_32 => "\xcc\x24\x31\xc4", 0;
tst fnv1_64  => "\x92\x06\x77\x4c\xe0\x2f\x89\x2a\xd2", 0;
tst fnv1a_64 => "\xd5\x6b\xb9\x53\x42\x87\x08\x36", 0;
tst fnv1_32  => "03SB[", 0;
tst fnv1_64  => "!v)EYwYVk&", 0;
tst fnv1a_32 => "3pjNqM", 0;
tst fnv1a_64 => "77kepQFQ8Kl", 0;

