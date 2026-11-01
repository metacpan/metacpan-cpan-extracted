BEGIN { $| = 1; print "1..18\n"; }

use JSON::SIMD;

our $test;
sub ok($;$) {
   print $_[0] ? "" : "not ", "ok ", ++$test, "\n";
}

my $o1 = bless { a => 3 }, "XX";
my $o2 = bless \(my $dummy = 1), "YY";

sub XX::TO_JSON {
   {__,""}
}

my $js = JSON::SIMD->new;

eval { $js->encode ($o1) }; ok ($@ =~ /allow_blessed/);
eval { $js->encode ($o2) }; ok ($@ =~ /allow_blessed/);
$js->allow_blessed;
ok ($js->encode ($o1) eq "null");
ok ($js->encode ($o2) eq "null");
$js->convert_blessed;
ok ($js->encode ($o1) eq '{"__":""}');
ok ($js->encode ($o2) eq "null");

# filter_json_object, filter_json_single_key_object not supported for simdjson

$js->filter_json_object (sub { 5 });
ok($js->get_use_simdjson == 0);
$js->use_simdjson(1);

ok ("ARRAY" eq ref $js->decode ("[]"));
ok (5 eq join ":", @{ $js->decode ('[{}]') });
ok($js->get_use_simdjson == 1);

$js->filter_json_object ();
$js->use_simdjson(1);
ok($js->get_use_simdjson == 1);


$js->filter_json_single_key_object (a => sub { shift });
ok($js->get_use_simdjson == 0);
$js->use_simdjson(1);
$js->decode ("[]");
ok($js->get_use_simdjson == 1);

$js->filter_json_single_key_object ("a");
$js->use_simdjson(1);
ok($js->get_use_simdjson == 1);


my $json = JSON::SIMD->new->allow_tags->max_depth(32);
ok( !eval { $json->decode('(' x 1000) } );     # "catch deeply nested allow_tags->max_depth"
ok( $@ =~ qr/maximum nesting level/);           # "caught allow_tags->max_depth"
ok( !eval { $json->decode('("a")' x 1000) } ); # "catch large linear allow_tags->max_depth"
ok( $@ =~ qr/maximum nesting level/);          # "caught allow_tags->max_depth"
