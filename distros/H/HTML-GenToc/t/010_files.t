use Test::More tests => 36;
use HTML::GenToc;
require 't/compare.pl';

# Insert your test code below
#===================================================

$toc = new HTML::GenToc(debug=>0,quiet=>1);

#
# file test1
#
$result = $toc->generate_toc(
	make_anchors=>1,
	make_toc=>0,
	input=>['tfiles/test1.wml'],
	outfile=>'test1_anch.wml',
);
ok($result, 'generated anchors from test1.wml');

# compare the files
$result = compare('test1_anch.wml', 'tfiles/good_test1_anch.wml');
ok($result, 'test1_anch.wml matches tfiles/good_test1_anch.wml exactly');

$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['test1_anch.wml'],
	outfile=>'test1_toc.html',
);
ok($result, 'generated toc from test1_anch.wml');

# compare the files
$result = compare('test1_toc.html', 'tfiles/good_test1_toc.html');
ok($result, 'test1_toc.html matches tfiles/good_test1_toc.html exactly');

# clean up test1
if ($result) {
    unlink('test1_anch.wml');
    unlink('test1_toc.html');
}

#
# file test2
#
if (-f 'test2_anch.html')
{
    unlink('test2_anch.html');
}
if (-f 'test2_anch.html.org')
{
    unlink('test2_anch.html.org');
}
$result = $toc->generate_toc(
	make_anchors=>1,
	make_toc=>0,
	input=>['tfiles/test2.html'],
	outfile=>'test2_anch.html',
);
ok($result, 'generated anchors from test2.html');

# compare the files
$result = compare('test2_anch.html', 'tfiles/good_test2_anch.html');
ok($result, 'test2_anch.html matches tfiles/good_test2_anch.html exactly');

$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	outfile=>'',
	input=>['test2_anch.html'],
	inline=>1,
	overwrite=>1,
);
ok($result, 'generated toc inline test2_anch.html');

# compare the files
$result = compare('test2_anch.html', 'tfiles/good_test2_toc.html');
ok($result, 'test2_anch.html matches tfiles/good_test2_toc.html exactly');

# clean up
if ($result) {
    unlink('test2_anch.html');
    unlink('test2_anch.html.org');
}

#
# file test3
#
$result = $toc->generate_toc(
	make_anchors=>1,
	make_toc=>0,
	bak=>'',
	inline=>0,
	overwrite=>0,
	input=>['tfiles/test3.wml'],
	outfile=>'test3_anch.wml',
	toc_entry=>{
		H1=>1,
		H2=>2,
		H3=>3,
	},
	toc_end=>{
		H1=>'/H1',
		H2=>'/H2',
		H3=>'/H3',
	},
);
ok($result, 'generated anchors (H1,H2,H3) from test3.wml');

# compare the files
$result = compare('test3_anch.wml', 'tfiles/good_test3_anch.wml');
ok($result, 'test3_anch.wml matches tfiles/good_test3_anch.wml exactly');

$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['test3_anch.wml'],
	outfile=>'test3_toc.html',
	toc_entry=>{
		H1=>1,
		H2=>2,
		H3=>3,
	},
	toc_end=>{
		H1=>'/H1',
		H2=>'/H2',
		H3=>'/H3',
	},
);
ok($result, 'generated toc from test3_anch.wml');

# compare the files
$result = compare('test3_toc.html', 'tfiles/good_test3_toc.html');
ok($result, 'test3_toc.html matches tfiles/good_test3_toc.html exactly');

# clean up
if ($result) {
    unlink('test3_anch.wml');
    unlink('test3_toc.html');
}

#
# file test4
#
$result = $toc->generate_toc(
	make_anchors=>1,
	make_toc=>0,
	input=>['tfiles/test4.html'],
	bak=>'',
	inline=>0,
	overwrite=>0,
	outfile=>'test4_anch.html',
	toc_entry=>{ 'H2'=>1,
		'H3'=>2,
		},
	toc_end=>{ 'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
ok($result, 'generated anchors (H1,H3) from test4.html');

# compare the files
$result = compare('test4_anch.html', 'tfiles/good_test4_anch.html');
ok($result, 'test4_anch.html matches tfiles/good_test4_anch.html exactly');

$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['test4_anch.html'],
	outfile=>'test4_toc.html',
	toc_entry=>{ 'H2'=>1,
		'H3'=>2,
		},
	toc_end=>{ 'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
ok($result, 'generated toc from test4_anch.html');

# compare the files
$result = compare('test4_toc.html', 'tfiles/good_test4_toc.html');
ok($result, 'test4_toc.html matches tfiles/good_test4_toc.html exactly');

# clean up
if ($result) {
    unlink('test4_anch.html');
    unlink('test4_toc.html');
}

#
# file test4 using entrysep
#
$result = $toc->generate_toc(
	make_anchors=>1,
	make_toc=>0,
	input=>['tfiles/test4.html'],
	bak=>'',
	inline=>0,
	overwrite=>0,
	outfile=>'test4a_anch.html',
	toc_entry=>{ 'H2'=>1,
		'H3'=>-2,
		},
	toc_end=>{ 'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
ok($result, 'generated anchors (entrysep) from test4.html');

# compare the files
$result = compare('test4a_anch.html', 'tfiles/good_test4a_anch.html');
ok($result, 'test4a_anch.html matches tfiles/good_test4a_anch.html exactly');

$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['test4a_anch.html'],
	outfile=>'test4a_toc.html',
	toc_entry=>{ 'H2'=>1,
		'H3'=>-2,
		},
	toc_end=>{ 'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
ok($result, 'generated toc from test4a_anch.html');

# compare the files
$result = compare('test4a_toc.html', 'tfiles/good_test4a_toc.html');
ok($result, 'test4a_toc.html matches tfiles/good_test4a_toc.html exactly');

# clean up
if ($result) {
    unlink('test4a_anch.html');
    unlink('test4a_toc.html');
}

#
# file test4 using ol
#
$result = $toc->generate_toc(
	make_anchors=>1,
	make_toc=>0,
	input=>['tfiles/test4.html'],
	bak=>'',
	inline=>0,
	overwrite=>0,
	outfile=>'test4b_anch.html',
	toc_entry=>{ 'H2'=>1,
		'H3'=>2,
		},
	toc_end=>{ 'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
# (don't check the above because it's exactly the same as test4)

$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['test4b_anch.html'],
	outfile=>'test4b_toc.html',
	ol=>1,
	toc_entry=>{ 'H2'=>1,
		'H3'=>2,
		},
	toc_end=>{ 'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
ok($result, 'generated toc (ol) from test4b_anch.html');

# compare the files
$result = compare('test4b_toc.html', 'tfiles/good_test4b_toc.html');
ok($result, 'test4b_toc.html matches tfiles/good_test4b_toc.html exactly');

# clean up
if ($result) {
    unlink('test4b_anch.html');
    unlink('test4b_toc.html');
}

#
# file test5 (this file already has anchors)
# (testing H3 -> H2 sequence)
#
$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['tfiles/test5.php'],
	ol=>0,
	inline=>0,
	overwrite=>0,
	bak=>'',
	outfile=>'test5_toc.html',
	toc_entry=>{ 'H2'=>1,
		'H3'=>2,
		},
	toc_end=>{ 'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
ok($result, 'generated toc from test5.php');

# compare the files
$result = compare('test5_toc.html', 'tfiles/good_test5_toc.html');
ok($result, 'test5_toc.html (H3 -> H2) matches tfiles/good_test5_toc.html exactly');

# clean up
if ($result) {
    unlink('test5_toc.html');
}

#
# file test5 (this file already has anchors)
# (testing H3 -> H2 sequence with OL)
#
$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['tfiles/test5.php'],
	ol=>1,
	inline=>0,
	overwrite=>0,
	bak=>'',
	outfile=>'test5b_toc.html',
	toc_entry=>{ 'H2'=>1,
		'H3'=>2,
		},
	toc_end=>{ 'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
ok($result, 'generated toc with OL from test5.php');

# compare the files
$result = compare('test5b_toc.html', 'tfiles/good_test5b_toc.html');
ok($result, 'test5b_toc.html (H3 -> H2 + OL) matches tfiles/good_test5b_toc.html exactly');

# clean up
if ($result) {
    unlink('test5b_toc.html');
}

#
# file test6 (this file already has anchors)
# (testing 2-level OL)
#
$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['tfiles/test6.html'],
	ol=>1,
	ol_num_levels=>2,
	inline=>0,
	overwrite=>0,
	bak=>'',
	outfile=>'test6_toc.html',
	toc_entry=>{
		'H1'=>1,
		'H2'=>2,
		'H3'=>3,
		},
	toc_end=>{
		'H1'=>'/H1',
		'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
ok($result, 'generated toc with OL(2) from test6.html');

# compare the files
$result = compare('test6_toc.html', 'tfiles/good_test6_toc.html');
ok($result, 'test6_toc.html (L2 OL) matches tfiles/good_test6_toc.html exactly');

# clean up
if ($result) {
    unlink('test6_toc.html');
}

#
# file test6 (this file already has anchors)
# (testing all-level OL)
#
$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['tfiles/test6.html'],
	ol=>1,
	ol_num_levels=>0,
	bak=>'',
	outfile=>'test6a_toc.html',
	toc_entry=>{
		'H1'=>1,
		'H2'=>2,
		'H3'=>3,
		},
	toc_end=>{
		'H1'=>'/H1',
		'H2'=>'/H2',
		'H3'=>'/H3',
		}
	);
ok($result, 'generated toc with OL(0) from test6.html');

# compare the files
$result = compare('test6a_toc.html', 'tfiles/good_test6a_toc.html');
ok($result, 'test6a_toc.html (OL) matches tfiles/good_test6a_toc.html exactly');

# clean up
if ($result) {
    unlink('test6a_toc.html');
}

#
# RESET file test2a
#
undef $toc;
$toc = new HTML::GenToc(debug=>0,quiet=>1);

if (-f 'test2a_anch.html')
{
    unlink('test2a_anch.html');
}
if (-f 'test2a_anch.html.org')
{
    unlink('test2a_anch.html.org');
}
$result = $toc->generate_toc(
	make_anchors=>1,
	make_toc=>0,
	use_id=>1,
	input=>['tfiles/test2.html'],
	outfile=>'test2a_anch.html',
);
ok($result, 'generated anchors (ID) from test2.html');

# compare the files
$result = compare('test2a_anch.html', 'tfiles/good_test2a_anch.html');
ok($result, 'test2a_anch.html matches tfiles/good_test2a_anch.html exactly');

$result = $toc->generate_toc(
	make_anchors=>0,
	make_toc=>1,
	input=>['test2a_anch.html'],
	inline=>1,
	overwrite=>1,
);
ok($result, 'generated toc inline test2a_anch.html');

# compare the files
$result = compare('test2a_anch.html', 'tfiles/good_test2a_toc.html');
ok($result, 'test2a_anch.html matches tfiles/good_test2a_toc.html exactly');

# clean up
if ($result) {
    unlink('test2a_anch.html');
    unlink('test2a_anch.html.org');
}

#
# file test7 (this file already has some anchors)
# testing generation of anchors
#
$result = $toc->generate_toc(
	make_anchors=>1,
	use_id=>1,
	make_toc=>0,
	input=>['tfiles/test7.html'],
	overwrite=>0,
	bak=>'',
	outfile=>'test7a.html',
	toc_entry=>{ 'H1'=>1,
		'H2'=>2,
		},
	toc_end=>{ 'H1'=>'/H1',
		'H2'=>'/H2',
		}
	);
ok($result, 'generated anchors from test7.html');

# compare the files
$result = compare('test7a.html', 'tfiles/good_test7a.html');
ok($result, 'test7a.html matches tfiles/good_test7a.html exactly');

# clean up
if ($result) {
    unlink('test7a.html');
}


# vim: ft=perl
