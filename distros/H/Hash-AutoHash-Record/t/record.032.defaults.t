use lib qw(t);
use Carp;
use Hash::AutoHash::Record qw(autohash_tied);
use Test::More;
use Test::Deep;
use recordUtil;

#################################################################################
# test defaults
#################################################################################

sub test_defaults {
  my($label,$start,$correct_start,$defaults,$correct_defaults)=@_;
  my $record=new Hash::AutoHash::Record %$start;
#  cmp_record("$label initial value",$record,$initial_value);
  autohash_tied($record)->defaults($defaults);
  cmp_record("$label after setting defaults",$record,$correct_start);
  my $actual=autohash_tied($record)->defaults;
  cmp_deeply($actual,$correct_defaults,"$label get defaults scalar context");
  my %actual=autohash_tied($record)->defaults;
  cmp_deeply(\%actual,$correct_defaults,"$label get defaults array context");
  
  # clear should set to new defaults
  %$record=();
  cmp_record("$label after clear set to new defaults",$record,$correct_defaults);

}
test_defaults('initial empty. defaults empty.',{},{},{},{});
test_defaults('initial all usual empty values. defaults empty.',
	      {single=>'',multi=>[],avp_single=>{},avp_multi=>\{},
	       nested=>new Hash::AutoHash::Record},
              {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested},
              {},
              {});
test_defaults('initial empty. defaults all usual empty values.',
	      {},
	      {},
	      {single=>'',multi=>[],avp_single=>{},avp_multi=>\{},
	       nested=>new Hash::AutoHash::Record},
              {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested});
test_defaults('initial all usual non-empty values. defaults empty.',
	      {single=>'value1',multi=>['value2'],avp_single=>{key3=>'value3'},
               avp_multi=>{key4=>['value4']},
	       nested=>new Hash::AutoHash::Record key5=>'value5'},
	      {single=>'value1',multi=>['value2'],avp_single=>new_SV(key3=>'value3'),
               avp_multi=>new_MV(key4=>['value4']),
	       nested=>new_Nested(key5=>'value5')},
              {},
              {});
test_defaults('initial empty. defaults all usual non-empty values.',
	      {},
	      {},
	      {single=>'value1',multi=>['value2'],avp_single=>{key3=>'value3'},
               avp_multi=>{key4=>['value4']},
	       nested=>new Hash::AutoHash::Record key5=>'value5'},
	      {single=>'value1',multi=>['value2'],avp_single=>new_SV(key3=>'value3'),
               avp_multi=>new_MV(key4=>['value4']),
	       nested=>new_Nested(key5=>'value5')});
test_defaults('initial & defaults all usual non-empty values.',
	      {single=>'value1',multi=>['value2'],avp_single=>{key3=>'value3'},
               avp_multi=>{key4=>['value4']},
	       nested=>new Hash::AutoHash::Record key5=>'value5'},
	      {single=>'value1',multi=>['value2'],avp_single=>new_SV(key3=>'value3'),
               avp_multi=>new_MV(key4=>['value4']),
	       nested=>new_Nested(key5=>'value5')},
	      {single=>'new_value1',multi=>['new_value2'],avp_single=>{key3=>'new_value3'},
               avp_multi=>{key4=>['new_value4']},
	       nested=>new Hash::AutoHash::Record key5=>'new_value5'},
	      {single=>'new_value1',multi=>['new_value2'],avp_single=>new_SV(key3=>'new_value3'),
               avp_multi=>new_MV(key4=>['new_value4']),
	       nested=>new_Nested(key5=>'new_value5')});

done_testing();
