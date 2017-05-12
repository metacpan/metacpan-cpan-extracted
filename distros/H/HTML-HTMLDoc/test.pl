# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 121 };
use strict;
use lib 'lib';
use HTML::HTMLDoc;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

{
	# test 2 - constructor
	my $htmldoc = new HTML::HTMLDoc();
	ok(ref($htmldoc), qr/HTML::HTMLDoc/);

	# test 3 - check mode of instance
	ok($htmldoc->_config('mode'), 'ipc');

	# test 4 - test internal method for checking allowed
	#			parameters
	ok($htmldoc->_test_params('asdf', ['jhgjhg', 'trztr', 'asdf', 'jhkjh']), 1 );

	# test 5 - same with wrong input
	ok($htmldoc->_test_params('asdf', ['jhgjhg', 'trztr', '1asdf', 'jhkjh']), 0 );

	# test 6 - internal method for storing settings
	#		    string mode
	$htmldoc->_set_doc_config('testkey', 'testvalue');
	ok($htmldoc->_get_doc_config('testkey'), 'testvalue');

	# test 7 - delete this config-entry
	$htmldoc->_delete_doc_config('testkey');
	ok($htmldoc->_get_doc_config('testkey'), undef);

	# test 8 - set an array
	$htmldoc->_set_doc_config('testkey', ['one', 'two', 'tree']);
	ok($htmldoc->_get_doc_config('testkey')->[1], 'two' );

	# test 9 - delete it again
	$htmldoc->_delete_doc_config('testkey');
	ok($htmldoc->_get_doc_config('testkey'), undef);

	# test 10 - set page size a4
	$htmldoc->set_page_size('a4');
	ok($htmldoc->get_page_size(), 'a4');

	# test 11 - set page size letter
	$htmldoc->set_page_size('letter');
	ok($htmldoc->get_page_size(), 'letter');

	# test 12 - set page size 10x10cm
	$htmldoc->set_page_size('10x10cm');
	ok($htmldoc->get_page_size(), '10x10cm');

	# test 13 - Owner password
	$htmldoc->set_owner_password('secure');
	ok($htmldoc->_get_doc_config('owner-password'), 'secure');

	# test 14 - User password
	$htmldoc->set_user_password('secure');
	ok($htmldoc->_get_doc_config('user-password'), 'secure');

	# test 15 - permissions - all
	$htmldoc->set_permissions('all');
	ok($htmldoc->_get_doc_config('permissions')->[0], 'all');

	# test 16 - permissions - none
	$htmldoc->set_permissions('none');
	ok($htmldoc->_get_doc_config('permissions')->[0], 'none');

	# clean up permissions
	$htmldoc->_delete_doc_config('permissions');

	# test  - JPEG-quality
	$htmldoc->set_jpeg_compression();
	ok($htmldoc->_get_doc_config('jpeg'), "75");
	$htmldoc->set_jpeg_compression(0);
	ok($htmldoc->_get_doc_config('jpeg'), 0);
	$htmldoc->set_jpeg_compression(100);
	ok($htmldoc->_get_doc_config('jpeg'), 100);
	
	$htmldoc->_delete_doc_config('jpeg');
	$htmldoc->best_image_quality();
	ok($htmldoc->_get_doc_config('jpeg'), 100);
	
	$htmldoc->_delete_doc_config('jpeg');
	$htmldoc->low_image_quality();
	ok($htmldoc->_get_doc_config('jpeg'), 25);

	# test 17 - permissions - nos
	my $okcounter = 0;
	my @noperms = ('no-annotate', 'no-copy', 'no-modify',  'no-print');
	foreach my $perm( @noperms ) {
			$htmldoc->set_permissions($perm);
	}

	my $stored = $htmldoc->_get_doc_config('permissions');
	for(my $i=0; $i<@$stored; $i++) {
			$okcounter++ if ($stored->[$i] eq @noperms[$i]);
	}

	ok($okcounter, 4);

	# clean up permissions
	$htmldoc->_delete_doc_config('permissions');

	# test 18 - permissions - yes
	my $okcounter = 0;
	my @noperms = ('annotate', 'copy', 'modify',  'print');
	foreach my $perm( @noperms ) {
			$htmldoc->set_permissions($perm);
	}

	my $stored = $htmldoc->_get_doc_config('permissions');
	for(my $i=0; $i<@$stored; $i++) {
			$okcounter++ if ($stored->[$i] eq @noperms[$i]);
	}

	ok($okcounter, 4);


	# test 19 - permissions - none again to test if the set are deleted
	$htmldoc->set_permissions('none');
	ok($htmldoc->_get_doc_config('permissions')->[0], 'none');

	# test 20 - permissions - corresponding flag deleted
	$htmldoc->_delete_doc_config('permissions');
	$htmldoc->set_permissions('copy');
	$htmldoc->set_permissions('no-copy');
	my $set = $htmldoc->_get_doc_config('permissions');
	my $found = 0;
	foreach (@$set) {
		$found = 1 if ($_ eq 'copy');
	}
	ok($found, 0);

	# test 21 - permissions - corresponding flag deleted
	$htmldoc->_delete_doc_config('permissions');
	$htmldoc->set_permissions('no-copy');
	$htmldoc->set_permissions('copy');
	my $set = $htmldoc->_get_doc_config('permissions');
	my $found = 0;
	foreach (@$set) {
		$found = 1 if ($_ eq 'no-copy');
	}
	ok($found, 0);


	# test 22,23 - landscape
	$htmldoc->landscape();
	my @keys = $htmldoc->_get_doc_config_keys();
	ok(array_contains(\@keys, 'landscape'), 1 );
	ok(array_contains(\@keys, 'portrait'), 0 );

	# test 24,25 - landscape
	$htmldoc->portrait();
	my @keys = $htmldoc->_get_doc_config_keys();
	ok(array_contains(\@keys, 'portrait'), 1 );
	ok(array_contains(\@keys, 'landscape'), 0 );


	# test 26, 27 - right margin without messure
	my $ret = $htmldoc->set_right_margin(2);
	ok($ret, 1);
	ok($htmldoc->_get_doc_config('right'), '2cm' );
	
	# test 26, 27 - right margin without messure
	my $ret = $htmldoc->set_right_margin(2.1);
	ok($ret, 1);
	ok($htmldoc->_get_doc_config('right'), '2.1cm' );

	# test 28,29 - right margin mm
	my $ret = $htmldoc->set_right_margin(2, 'mm');
	ok($ret, 1);
	ok($htmldoc->_get_doc_config('right'), '2mm' );

	# test 30,31 - right margin in
	my $ret = $htmldoc->set_right_margin(2, 'in');
	ok($ret, 1);
	ok($htmldoc->_get_doc_config('right'), '2in' );

	# test 32 - right margin to wrong value
	my $ret = $htmldoc->set_right_margin(2, 'mc');
	ok( (!$ret && $htmldoc->error()=~/wrong arguments/ && $htmldoc->error()=~/right-margin/), 1 );


	# test 33 - left margin without messure
	$htmldoc->set_left_margin(2);
	ok($htmldoc->_get_doc_config('left'), '2cm' );

	# test 34 - top margin without messure
	$htmldoc->set_top_margin(2);
	ok($htmldoc->_get_doc_config('top'), '2cm' );

	# test 35 - bottom margin without messure
	$htmldoc->set_bottom_margin(2);
	ok($htmldoc->_get_doc_config('bottom'), '2cm' );

	# test 36 - set_bodycolor
	$htmldoc->set_bottom_margin(2);
	ok($htmldoc->_get_doc_config('bottom'), '2cm' );

	# test 37, 38 - test colors hex
	my $c = $htmldoc->_test_color('#FF00DD');
	ok($c, '#FF00DD');
	my $c = $htmldoc->_test_color('#FJ00DD');
	ok($c, undef);

	# test 39,40,41,42,43 - test colors hex
	my $c = $htmldoc->_test_color(0,0,0);
	ok($c, '#000000');
	my $c = $htmldoc->_test_color(255,255,255);
	ok($c, '#ffffff');
	my $c = $htmldoc->_test_color(256,255,255);
	ok($c, undef);

	my $c = $htmldoc->_test_color('red');
	ok($c, 'red');

	my $c = $htmldoc->_test_color('violette');
	ok($c, undef);


	# 44-47 setting bodycolor
	ok($htmldoc->set_bodycolor('red'), 1);
	ok($htmldoc->set_bodycolor('#010101'), 1);
	ok($htmldoc->set_bodycolor('#0101011'), 0);
	ok($htmldoc->set_bodycolor(0,0,0), 1);

	# 48-52 - setting font
	ok($htmldoc->set_bodyfont('Arial'), 1);
	ok($htmldoc->_get_doc_config('bodyfont'), 'Arial');
	ok($htmldoc->set_bodyfont('arial'), 1);
	ok($htmldoc->set_bodyfont('sans-serif'), 1);
	ok($htmldoc->set_bodyfont('arialx'), 0);

	# 52 - browser-width
	$htmldoc->set_browserwidth(100);
	ok($htmldoc->_get_doc_config('browserwidth'), 100);
	ok($htmldoc->set_browserwidth("sad"), 0);

	# 54-56 - embed fonts
	$htmldoc->embed_fonts();
	my @keys = $htmldoc->_get_doc_config_keys();
	ok(array_contains(\@keys, 'embedfonts'), 1);

	$htmldoc->no_embed_fonts();
	my @keys = $htmldoc->_get_doc_config_keys();
	ok(array_contains(\@keys, 'embedfonts'), 0);

	# 58,59 - default header and footer
	ok($htmldoc->_get_doc_config('header'), '.t.' );
	ok($htmldoc->_get_doc_config('footer'), '.1.' );

	#  60, 61 - set special footer
	ok($htmldoc->set_footer('/', 'a', 'A'), 1);
	ok($htmldoc->_get_doc_config('footer'), '/aA' );

	# 62 - set wrong footer
	ok($htmldoc->set_footer('7', '&', 'x'), 0);

	#  64, 65 - set special header
	ok($htmldoc->set_header('/', 'a', 'A'), 1);
	ok($htmldoc->_get_doc_config('header'), '/aA' );

	# 62 - set wrong header
	ok($htmldoc->set_header('7', '&', 'x'), 0);

	# 63 - default outputformat
	ok($htmldoc->_get_doc_config('format'), 'pdf');

	# 66, 67 - special output-format
	ok($htmldoc->set_output_format('html'), 1);
	ok($htmldoc->_get_doc_config('format'), 'html');
	$htmldoc->set_output_format('pdf');

	# 68, 69 wrong output format
	ok($htmldoc->set_output_format('asdasd'), 0);
	ok($htmldoc->_get_doc_config('format'), 'pdf');

	# 70, 71 set html
	my $content = '<html>test</html>';
	ok($htmldoc->set_html_content($content), 1);
	ok($htmldoc->get_html_content(), $content);

	# 70, 71 set html as ref
	my $content = '<html>test</html>';
	ok($htmldoc->set_html_content(\$content), 1);
	ok($htmldoc->get_html_content(), $content);

	# turn links on
	ok($htmldoc->links(), 1);
	ok($htmldoc->_get_doc_config('links'), '');
	ok($htmldoc->_get_doc_config('no-links'), undef);

	# turn links off
	ok($htmldoc->no_links(), 1);
	ok($htmldoc->_get_doc_config('no-links'), '');
	ok($htmldoc->_get_doc_config('links'), undef);

	# set path for documents
	ok($htmldoc->path('/tmp'), 1);
	ok($htmldoc->_get_doc_config('path'), '/tmp');

	# set fontsize
	ok($htmldoc->set_fontsize(2), 1);
	ok($htmldoc->_get_doc_config('fontsize'), 2);
	ok($htmldoc->set_fontsize(2.5), 1);
	ok($htmldoc->_get_doc_config('fontsize'), 2.5);
	ok($htmldoc->set_fontsize("x"), 0);
    
	
	# set a logoimage
	$htmldoc = new HTML::HTMLDoc();
	my $setimage = $htmldoc->set_logoimage('./testdata/missingimage.gif');
	ok($setimage, 0);
	ok($htmldoc->error(), "Logoimage ./testdata/missingimage.gif could not be found");
                                                                     
	my $logoimg = './testdata/testimage.gif';
	my $setimage = $htmldoc->set_logoimage($logoimg);
	ok($setimage, 1);

	ok($htmldoc->get_logoimage(), $logoimg);

}

{
	# make clean copy to test the outputs
	my $htmldoc = new HTML::HTMLDoc();

	my $t = $htmldoc->_build_parameters();
	my $ok = 1;
	my @cont = ('--header .t.', '--format pdf',  '--charset iso-8859-1', '--quiet', '--portrait', '--size a4', '--footer .1.');
	foreach(@cont) {
		if ( $t !~ /$_/ ) {
			$ok=0;
			last;
		}
	}
	ok($ok, 1);

	# Test the generation of pdf, ps and html in all possible versions
	$htmldoc->set_html_content('test');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,10), qr/^\Q%PDF-1.3\E/ );

	my $htmldoc = new HTML::HTMLDoc();
	$htmldoc->set_output_format('pdf11');
	$htmldoc->set_html_content('test');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,10), qr/^\Q%PDF-1.1\E/ );

	my $htmldoc = new HTML::HTMLDoc();
	$htmldoc->set_output_format('pdf12');
	$htmldoc->set_html_content('test');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,10), qr/^\Q%PDF-1.2\E/ );

	my $htmldoc = new HTML::HTMLDoc();
	$htmldoc->set_output_format('pdf13');
	$htmldoc->set_html_content('test');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,10), qr/^\Q%PDF-1.3\E/ );

	my $htmldoc = new HTML::HTMLDoc();
	$htmldoc->set_output_format('pdf14');
	$htmldoc->set_html_content('test');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,10), qr/^\Q%PDF-1.4\E/ );


	my $htmldoc = new HTML::HTMLDoc();
	$htmldoc->set_output_format('ps');
	$htmldoc->set_html_content('test');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,20), qr/^\Q%!PS-Adobe-3.0\E/ );

	my $htmldoc = new HTML::HTMLDoc();
	$htmldoc->set_output_format('ps1');
	$htmldoc->set_html_content('test');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,20), qr/^\Q%!PS-Adobe-3.0\E/ );

	my $htmldoc = new HTML::HTMLDoc();
	$htmldoc->set_output_format('ps2');
	$htmldoc->set_html_content('test');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,20), qr/^\Q%!PS-Adobe-3.0\E/ );

	my $htmldoc = new HTML::HTMLDoc();
	$htmldoc->set_output_format('ps3');
	$htmldoc->set_html_content('test');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,20), qr/^\Q%!PS-Adobe-3.0\E/ );

	my $htmldoc = new HTML::HTMLDoc();
	$htmldoc->set_output_format('html');
	$htmldoc->set_html_content('<html><body>lkjlkjlkj</body></html>');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,100), qr|\Q<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"\E| );
	ok($pdf->to_string(), qr|\Qlkjlkjlkj\E| );



	# test the generation of pdf in Apache-File-Mode
	my $htmldoc = new HTML::HTMLDoc('mode'=>'file', 'tmpdir'=>'/tmp/hshshshd/sdasd/');
	$htmldoc->set_html_content('<html><body>lkjlkjlkj</body></html>');
	my $pdf = $htmldoc->generate_pdf();
	ok(ref($pdf), 'HTML::HTMLDoc::PDF');
	ok(substr($pdf->to_string(),0,10), qr/^\Q%PDF-1.3\E/ );
}

# look up for a key in an array
sub array_contains {
	my $array = shift;
	my $key = shift;

	my $contains = 0;
	foreach(@$array) {
		$contains = 1 if ($_ eq $key);
	}
	return $contains;
}
