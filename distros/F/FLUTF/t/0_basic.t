use Test::More tests => 5;
BEGIN {use_ok( 'Games::Freelancer::UTF' ); }
eval {
	require Test::NoWarnings;
	Test::NoWarnings->import();
	1;
} or do {
	SKIP: {
		skip "Test::NoWarnings is not installed", 1;
		fail "This shouldn't really happen at all";
	};
};
use Games::Freelancer::UTF;

$tree = {
	  '\\' => {
		    'VMeshLibrary' => {
					'jc_defender.lod0.vms' => {
								    'VMeshData' => 'Some Vmeshdata' #Removed by me because you can't see anything useful here and its large.
								  }
				      },
		    'Cmpnd' => {
				 'Root' => {
					     'File name' => 'jc_defender.3db ',
					     'Index' => '        ',
					     'Object name' => 'Root '
					   }
			       },
		    'jc_defender.3db' => {
					   'Hardpoints' => {
							     'Fixed' => {
									  'HpEngine01' => {
											    'Orientation' => '  �?              �?              �?', #These are just packed vectors, can be easily decoded using unpack("f*",this)
											    'Position' => '    IK���A' #also a vector: unpack("f*",this)
											  },
 
									},
							     'Revolute' => {
									     'HpWeapon01' => {
											       'Axis' => '      �?    ', #also a vector: unpack("f*",this)
											       'Max' => '�
�>    ', #an angle in radians: unpack("f*",this)
											       'Min' => '�
��    ',
											       'Orientation' => 'Z|���1�   ���1>Z|�           �  �?', #also a vector: unpack("f*",this)
											       'Position' => '�L�?���>�+��' #also a vector: unpack("f*",this)
											     },
									     'HpWeapon02' => {
											       'Axis' => '      �?    ',
											       'Max' => '�
�>    ',
											       'Min' => '�
��    ',
											       'Orientation' => 'Z|���1>    ��1�Z|�              �?', 
											       'Position' => 'r����>�+��'
											     }
									   }
							   },
					   'MultiLevel' => {
							     'Level0' => {
									   'VMeshPart' => {
											    'VMeshRef' => '<   ��  x  n   ���@ĝ�����?d���-�A�7� `�:m$����,A'
											  }
									 }
							   }
					 }
		  }
	};
my $data;
eval {
	$data=UTFwrite($tree);
};
ok(!$@,"Writing errors");
undef $@;
my $tree2;
eval {
	$tree2=UTFread($data);
};
ok(!$@,"Reading errors");
undef $@;
is_deeply($tree,$tree2,"Differences between original and reread trees");
