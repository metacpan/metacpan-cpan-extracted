use lib qw(t);
use Carp;
use Hash::AutoHash::Record qw(autohash_tied autohash_keys);
use Test::More;
use Test::Deep;
use recordUtil;

#################################################################################
# test force
#################################################################################

sub test_force {
  my($label,$start,$correct_start)=@_;
  my $record=new Hash::AutoHash::Record %$start;
  # force each field to value of each field
  while (my($force_key,$force_value)=each %$start) {
    my $correct_force={};
    my $correct_value=$record->$force_key;
    my @keys=autohash_keys($record);
    for my $key (@keys) {
      autohash_tied($record)->force($key,$force_value);
      autohash_tied($record)->force("new_$key",$force_value);
      $correct_force->{$key}=$correct_value;
      $correct_force->{"new_$key"}=$correct_value;
    }
    cmp_record("$label after force all to $force_key",$record,$correct_force);
    # clear should restore original state
    %$record=();
    cmp_record("$label after force all to $force_key. clear restores initial values",
	       $record,$correct_start);
  }
}
test_force('usual empty values.',
	   {single=>'',multi=>[],avp_single=>{},avp_multi=>\{},
	    nested=>new Hash::AutoHash::Record},
           {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested});
test_force('usual non-empty values.',
	   {single=>'value1',multi=>['value2'],avp_single=>{key3=>'value3'},
	    avp_multi=>{key4=>['value4']},
	    nested=>new Hash::AutoHash::Record key5=>'value5'},
	   {single=>'value1',multi=>['value2'],avp_single=>new_SV(key3=>'value3'),
	    avp_multi=>new_MV(key4=>['value4']),
	    nested=>new_Nested(key5=>'value5')});
test_force('unusual non-empty values.',
	   {hash_normal=>{key=>\'value1'},
	    hash_workaround=>bless({key=>'value1'}),
	    refhash=>\bless({key=>'value1'})},
	   {hash_normal=>{key=>\'value1'},
	    hash_workaround=>bless({key=>'value1'}),
	    refhash=>\bless({key=>'value1'})});
  
test_force('usual empty + unusual nonempty values.',
	   {single=>'',multi=>[],avp_single=>{},avp_multi=>\{},
	    nested=>new Hash::AutoHash::Record,
	    hash_normal=>{key=>\'value1'},
	    hash_workaround=>bless({key=>'value1'}),
	   refhash=>\bless({key=>'value1'})},
           {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    hash_normal=>{key=>\'value1'},
	    hash_workaround=>bless({key=>'value1'}),
	    refhash=>\bless({key=>'value1'})});

done_testing();
