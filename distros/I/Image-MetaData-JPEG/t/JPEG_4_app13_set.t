use Test::More tests => 54;
BEGIN { require 't/test_setup.pl'; }

my $tphoto = 't/test_photo.jpg';
my $tdata  = 't/test_photo.desc';
my $shop   = 'PHOTOSHOP';
my ($image, $seg1, $seg2, $hash, $hash2, $hashtot, $ref, $segs, $recver, $num);

my $ht = { ObjectName           => [ "prova" ],
	   ByLine               => [ "ciao" ],
	   Keywords             => [ "donald", "duck" ],
	   ActionAdvised        => [ "02" ],
	   SupplementalCategory => ["arte", "scienza", "sport"] };
my $hn = { 55 => [ "19890207" ], 65 => [ 2 ],
	   80 => [ "d3", "d4" ], 15 => [ "b" ] };
my $ver = "\000\002";
my $nkey = 'singola';
my $iptc_tag = 0x0404;

my $phn = { 0x041c => ['xxx'],
	    0x041d => 'yyy',
	    0x041e => ['zzz', undef],
	    0x0421 => 'aaa',
	    0x0bb7 => ['bbb', 'Clipping path name'] };
my $pht = { 'GridGuidesInfo'    => 'ddd',
	    'ThumbnailResource' => ['eee'],
	    'ICCUntagged'       => ['fff', undef ],
	    'URL' => ['ggg', 'This is the universal resource locator'] };

#=======================================
diag "Testing APP13 IPTC set routines";
#=======================================

BEGIN { use_ok ($::pkgname) or exit; }

#########################
$image = newimage($tphoto);
eval { $image->set_app13_data(undef, undef, undef) };
is( $@, '', "No error with undefined arguments in set" );

#########################
eval { $image->set_app13_data({}, 'ADD', 'IpTccc') };
isnt( $@, '', "... but \$what cannot be wrong" );

#########################
$seg1 = $image->retrieve_app13_segment(0, 'IPTC');
$seg1->set_app13_data({'ObjectName' => 'newname'}, 'ADD', 'IPTC');
$seg1->set_app13_data({'ObjectName' => 'newname2'}, 'ADD', 'IPTC');
$hash = $seg1->get_app13_data('TEXTUAL', 'IPTC');
$ref = $$hash{'ObjectName'};
is( scalar @$ref, 1, "Non-repeatable IPTC constraint is enforced" );

#########################
is( $$ref[0], 'newname2', "Correct precedence for nonrepeatables" );

#########################
$hashtot = $seg1->get_app13_data('TEXTUAL', 'IPTC');
push @{$$hashtot{$_}}, @{$$ht{$_}} for keys %$ht;
$$hashtot{'ObjectName'} = $$ht{'ObjectName'}; # fix non-repeatable
$seg1->set_app13_data($ht, 'ADD', 'IPTC');
$hash = $seg1->get_app13_data('TEXTUAL', 'IPTC');
is_deeply( $hash, $hashtot, "Adding records textually" );

#########################
$seg1->set_app13_data({'Keywords' => $nkey}, 'UPDATE', 'IPTC');
$hash = $seg1->get_app13_data('TEXTUAL', 'IPTC');
is_deeply( $$hash{'Keywords'}, [ $nkey ], "UPDATE addresses user tags ..." );

#########################
is_deeply( $$hash{'SupplementalCategory'}, $$hashtot{'SupplementalCategory'},
	   "... without touching the others" );

#########################
$seg1->set_app13_data($ht, 'REPLACE', 'IPTC');
$hash = $seg1->get_app13_data('TEXTUAL', 'IPTC');
$recver = delete $$hash{'RecordVersion'};
is_deeply( $hash, $ht, "Replacing instead of adding" );

#########################
is( $$recver[0], $ver, "Record version is OK" );

#########################
$hash = $seg1->get_app13_data('NUMERIC', 'IPTC');
$seg1->set_app13_data($hn, 'ADD', 'IPTC');
$hashtot = $hash;
push @{$$hashtot{$_}}, @{$$hn{$_}} for keys %$hn;
$hash = $seg1->get_app13_data('NUMERIC', 'IPTC');
is_deeply( $hash, $hashtot, "Adding records numerically" );

#########################
$seg1->set_app13_data($hn, 'REPLACE', 'IPTC');
$hash = $seg1->get_app13_data('NUMERIC', 'IPTC');
$recver = delete $$hash{0};
is_deeply( $hash, $hn, "Replacing records numerically" );

#########################
is( $$recver[0], $ver, "Record version added automatically" );

#########################
$hash = $image->get_app13_data('NUMERIC', 'IPTC');
$recver = delete $$hash{0};
is_deeply( $hash, $hn, "High level get IPTC data (numeric)" );

#########################
$hashtot = $seg1->get_app13_data('TEXTUAL', 'IPTC');
push @{$$hashtot{$_}}, @{$$ht{$_}} for keys %$ht;
$image->set_app13_data($ht, 'ADD', 'IPTC');
$hash = $image->get_app13_data('TEXTUAL', 'IPTC');
is_deeply( $hash, $hashtot, "High level set/get (textual)" );

#########################
$image->remove_app13_info(-1, 'IPTC');
$image->set_app13_data($ht, 'ADD', 'IPTC');
$hash = $image->get_app13_data('TEXTUAL', 'IPTC');
$recver = delete $$hash{'RecordVersion'};
is_deeply( $hash, {%$ht}, "Forcing an IPTC segment (high level)" );

#########################
$image->remove_app13_info(-1, 'IPTC');
$image->set_app13_data($hn, 'REPLACE', 'IPTC');
$hash = $image->get_app13_data('NUMERIC', 'IPTC');
$recver = delete $$hash{0};
is_deeply( $hash, {%$hn}, "Same, but with replace and numerically" );

#########################
$recver = [ "\123\156" ];
$image->set_app13_data({'RecordVersion' => $recver}, 'ADD', 'IPTC');
$hash = $image->get_app13_data('TEXTUAL', 'IPTC');
is_deeply( $$hash{'RecordVersion'}, $recver, "Record version can be changed" );

#########################
$seg1->set_app13_data($ht, 'REPLACE', 'IPTC');
$hashtot = $seg1->get_app13_data('NUMERIC', 'IPTC');
$seg1->set_app13_data($hn, 'ADD', 'IPTC');
push @{$$hashtot{$_}}, @{$$hn{$_}} for keys %$hn;
$ref = \ (my $buffer = "");
$image->save($ref);
$image = newimage($ref, 'APP13', 'FASTREADONLY');
isnt( $image, undef, "File written and re-read");

#########################
$hash = $image->get_app13_data('NUMERIC', 'IPTC');
isnt( $hash, undef, "There is an APP13 segment" );

#########################
is_deeply( $hash, $hashtot, "Re-read data is ok" );

#########################
$hashtot = undef;
$$hashtot{$_} = [ @{$$ht{$_}} ] for keys %$ht;
$$hashtot{$_} = [ @{$$hn{$_}} ] for keys %$hn;
$image->set_app13_data($hashtot, 'REPLACE', 'IPTC');
$hash = $image->get_app13_data('NUMERIC', 'IPTC');
$image->set_app13_data($ht, 'REPLACE', 'IPTC');
$hashtot = $image->get_app13_data('NUMERIC', 'IPTC');
for (keys %$hn) { if (! exists $$hashtot{$_}) { $$hashtot{$_} = $$hn{$_} }
		  # remember that numeric keys are merged first!
		  else { unshift @{$$hashtot{$_}}, @{$$hn{$_}} }; }
is_deeply( $hash, $hashtot, "Set with mixed type tags" );

#########################
$seg1 = $image->retrieve_app13_segment(0, 'IPTC');
$seg1->{name} = 'trick';
$image->provide_app13_segment('IPTC');
$seg1->{name} = 'APP13';
is( $image->retrieve_app13_segment(-1, 'IPTC'), 2, "Two APP13 segments now" );

#########################
$seg1 = $image->retrieve_app13_segment(0, 'IPTC');
$seg2 = $image->retrieve_app13_segment(1, 'IPTC');
$seg1->set_app13_data($ht, 'REPLACE', 'IPTC');
$seg2->set_app13_data($hn, 'REPLACE', 'IPTC');
$hash  = $image->get_app13_data(undef, 'IPTC'); # use undef $type
$hash2 = $seg1->get_app13_data(undef, 'IPTC');
is_deeply( $hash, $hash2, "Run get_IPTC_data with two segments (get 1st)" );

#########################
$image->remove_app13_info(0, 'IPTC');
is( $image->retrieve_app13_segment(-1,'IPTC'), 1, "First segment eliminated" );

#########################
$hash  = $image->get_app13_data(undef, 'IPTC');
$hash2 = $seg2->get_app13_data(undef, 'IPTC');
is_deeply( $hash, $hash2, "get_IPTC_data now retrieves the second segment" );

#########################
$$ht{'An invalid tag'} = [ 'ciao', 34 ];
$$ht{'Zibaldone'} = [ 'ariciao' ];
$hash = $image->set_app13_data($ht, 'ADD', 'IPTC');
is( scalar keys %$hash, 2, "Two invalid textual entries rejected" );

#########################
$$hn{99} = [ 'pippero' ];
$$hn{-1} = [ 'paperopoli' ];
$hash = $image->set_app13_data($hn, 'ADD', 'IPTC');
is( scalar keys %$hash, 2, "Two invalid numeric entries rejected" );

#########################
$hash = $image->set_app13_data({'RecordVersion'=>["ab","cd"]},'UPDATE','IPTC');
is( scalar keys %$hash, 1, "Updating illegally fails" );

#########################
$hash  = $image->get_app13_data('TEXTUAL', 'IPTC');
$hash2 = $image->set_app13_data({'RecordVersion' => 'ab'}, 'UPDATE', 'IPTC');
is( scalar keys %$hash2, 0, "Updating record version work ..." );

#########################
$hash2 = $image->get_app13_data('TEXTUAL', 'IPTC');
$$hash{'RecordVersion'} = [ 'ab' ];
is_deeply( $hash, $hash2, "... without touching the other tags" );

#########################
$hash = $image->set_app13_data({'City' => undef}, 'ADD', 'IPTC');
is( scalar keys %$hash, 1, "A value array with one undef is invalid" );

#########################
$hash = $image->set_app13_data({'City' => [undef, undef, undef]},'ADD','IPTC');
is( scalar keys %$hash, 1, "... also with multiple undefs" );

#########################
$hash = $image->set_app13_data({'City' => []},'ADD', 'IPTC');
is( scalar keys %$hash, 1, "... also with no elements" );

#########################
$image = newimage($tphoto); # reset
ok( $image, "From now on we are testing [$shop]" );

#########################
$hash = $image->set_app13_data({$iptc_tag => "xx"}, 'ADD', $shop);
is( scalar keys %$hash, 1, "You cannot add the IPTC/NAA tag" );

#########################
$hash  = $image->get_app13_data('NUMERIC', $shop);
$hash2 = $image->set_app13_data($phn, 'UPDATE', $shop);
is( scalar keys %$hash2, 0, "All numeric tags updated" );

for (keys %$hash2) { printf "K: '0x%04x'\n", $_; }

#########################
$$hash{$_} = ref $$phn{$_} ? $$phn{$_} : [$$phn{$_}] for keys %$phn;
$$hash{$_}[1] = exists $$hash{$_}[1] ? $$hash{$_}[1] : undef for keys %$hash;
$hash2 = $image->get_app13_data('NUMERIC', $shop);
is_deeply( $hash, $hash2, "... resource block correctly updated" );

#########################
$hash  = $image->get_app13_data('TEXTUAL', $shop);
$hash2 = $image->set_app13_data($pht, 'UPDATE', $shop);
is( scalar keys %$hash2, 0, "All textual tags updated" );

#########################
$$hash{$_} = ref $$pht{$_} ? $$pht{$_} : [$$pht{$_}] for keys %$pht;
$$hash{$_}[1] = exists $$hash{$_}[1] ? $$hash{$_}[1] : undef for keys %$hash;
$hash2 = $image->get_app13_data('TEXTUAL', $shop);
is_deeply( $hash, $hash2, "... resource block correctly updated" );

#########################
$image->set_app13_data($pht, 'ADD', $shop);
$hash2 = $image->get_app13_data('TEXTUAL', $shop);
is_deeply( $hash, $hash2, "ADD behaves like UPDATE" );

#########################
$num = scalar grep { $_ != 2 } map { scalar @{$_} } values %$hash2;
is( $num, 0, "All value arrays have exactly 2 values" );

#########################
$hash2 = $image->set_app13_data($phn, 'REPLACE', $shop);
is( scalar keys %$hash2, 0, "All numeric tags replaced" );

#########################
$hash2 = $image->get_app13_data('NUMERIC', $shop);
%$hash = ();
$$hash{$_} = ref $$phn{$_} ? $$phn{$_} : [$$phn{$_}] for keys %$phn;
$$hash{$_}[1] = exists $$hash{$_}[1] ? $$hash{$_}[1] : undef for keys %$hash;
is_deeply( $hash2, $hash, "REPLACE works as expected (NUMERIC)" );

#########################
$hash2 = $image->set_app13_data($pht, 'REPLACE', $shop);
is( scalar keys %$hash2, 0, "All textual tags replaced" );

#########################
$hash2 = $image->get_app13_data('TEXTUAL', $shop);
%$hash = ();
$$hash{$_} = ref $$pht{$_} ? $$pht{$_} : [$$pht{$_}] for keys %$pht;
$$hash{$_}[1] = exists $$hash{$_}[1] ? $$hash{$_}[1] : undef for keys %$hash;
is_deeply( $hash2, $hash, "... also with TEXTUAL tags" );

#########################
$num = scalar grep { $_ != 2 } map { scalar @{$_} } values %$hash2;
is( $num, 0, "All value arrays have exactly 2 values" );

#########################
$hash = $image->set_app13_data({'Invalid' => ['xxx', 'desc' ],
			        'PhotoshopSecret' => 'wow' }, 'ADD', $shop);
is( scalar keys %$hash, 2, "Invalid textual tags are rejected" );

#########################
$hash = $image->set_app13_data({0x0001 => ['xxx', 'desc' ],
			        0x1111 => 'wow' }, 'ADD', $shop);
is( scalar keys %$hash, 2, "Invalid numeric tags are rejected" );

#########################
$hash = $image->set_app13_data({0x0888 => "\012\333\231\000f"}, 'ADD', $shop);
is( scalar keys %$hash, 0, "Valid tags with strange data accepted" );

#########################
$hash = $image->set_app13_data({'URL' => ['x', 'd', 'third' ]}, 'ADD', $shop);
is( scalar keys %$hash, 1, "Value arrays cannot have > 2 element" );

#########################
$hash = $image->set_app13_data({'URL' => []}, 'ADD', $shop);
is( scalar keys %$hash, 1, ".... nor less than one" );

#########################
$hash = $image->set_app13_data({'URL' => undef}, 'ADD', $shop);
is( scalar keys %$hash, 1, ".... nor an undefined one" );

#########################
$seg1 = $image->provide_app13_segment('PHOTOSHOP');
$hash2 = {GlobalAngle    => pack('N', 0x1e),
	  GlobalAltitude => pack('N', 0x1e),
	  CopyrightFlag  => "\001",
	  IDsBaseValue   => [ pack('N', 1), 'Layer ID Generator Base' ] };
$hash = $seg1->set_app13_data($hash2, 'ADD', 'PHOTOSHOP');
is( scalar keys %$hash, 0, "This is the exemple in the .pod" );

### Local Variables: ***
### mode:perl ***
### End: ***
