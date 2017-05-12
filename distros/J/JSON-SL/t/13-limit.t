#copied over from JSON::XS and ported to JSON::SL
use Test::More;
use JSON::SL qw(decode_json);
use Data::Dumper;

my $def = 512;
my $sl;

ok (!eval { decode_json (("[" x ($def + 1)) . ("]" x ($def + 1))) });
ok (ref decode_json (("[" x $def) . ("]" x $def)));
ok (ref decode_json (("{\"\":" x ($def - 1)) . "[]" . ("}" x ($def - 1))));
ok (!eval { decode_json (("{\"\":" x $def) . "[]" . ("}" x $def)) });

{
   $sl = JSON::SL->new(32);
   ok (ref $sl->feed(("[" x 32) . ("]" x 32)));

}

{
   $sl = JSON::SL->new(32);
   $sl->max_size(8);
   ok (
      eval { ref $sl->feed("[      ]") }
   );
   $sl->reset();
   eval {
      $sl->feed("[       ]");
   };
   ok ($@ =~ /max_size/);
}

done_testing();