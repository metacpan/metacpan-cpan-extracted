use strict;
use Test::More tests => 115;

# make sure the htmldoc binary is installed
my $version = `htmldoc --version` || 'htmldoc not found';
like($version, '/^1\.\d+/', 'HTMLDoc installed') or BAIL_OUT qq{This module can not work without the 'htmldoc' program installed on this system.};

# try to compile the module
use_ok $_ for qw(
    HTML::HTMLDoc
);

# test constructor
my $htmldoc = new HTML::HTMLDoc();
is(ref($htmldoc), 'HTML::HTMLDoc', 'Create HTMLDoc object');

# check mode of instance
my $config_mode = 'ipc';
if ($^O eq 'freebsd') {
	$config_mode = 'file';
}
is($htmldoc->_config('mode'), $config_mode, 'Set config mode');

# test internal method for checking allowed parameters
is($htmldoc->_test_params('asdf', ['jhgjhg', 'trztr', 'asdf', 'jhkjh']), 1, 'Allowed parameters (1/2)' );

# same with wrong input
is($htmldoc->_test_params('asdf', ['jhgjhg', 'trztr', '1asdf', 'jhkjh']), 0, 'Allowed parameters (2/2)' );

# internal method for storing settings string mode
$htmldoc->_set_doc_config('testkey', 'testvalue');
is($htmldoc->_get_doc_config('testkey'), 'testvalue', 'Retrieving settings - string mode');

# delete this config-entry
$htmldoc->_delete_doc_config('testkey');
is($htmldoc->_get_doc_config('testkey'), undef, 'Deleting settings');

# set an array
$htmldoc->_set_doc_config('testkey', ['one', 'two', 'tree']);
is($htmldoc->_get_doc_config('testkey')->[1], 'two' , 'Setting an array');

# delete our test array
$htmldoc->_delete_doc_config('testkey');
is($htmldoc->_get_doc_config('testkey'), undef, 'Deleting test array');

# set page size a4
$htmldoc->set_page_size('a4');
is($htmldoc->get_page_size(), 'a4', 'Set page size A4');

# set page size letter
$htmldoc->set_page_size('letter');
is($htmldoc->get_page_size(), 'letter', 'Set page size letter');

# set page size 10x10cm
$htmldoc->set_page_size('10x10cm');
is($htmldoc->get_page_size(), '10x10cm', 'Set page size 10x10cm');

# Owner password
$htmldoc->set_owner_password('secure');
is($htmldoc->_get_doc_config('owner-password'), 'secure', 'Set owner password');

# User password
$htmldoc->set_user_password('secure');
is($htmldoc->_get_doc_config('user-password'), 'secure', 'Set user password');

# permissions - all
$htmldoc->set_permissions('all');
is($htmldoc->_get_doc_config('permissions')->[0], 'all', 'Get permissions');

# permissions - none
$htmldoc->set_permissions('none');
is($htmldoc->_get_doc_config('permissions')->[0], 'none', 'Get none permissions');

# clean up permissions
$htmldoc->_delete_doc_config('permissions');

# JPEG-quality
$htmldoc->set_jpeg_compression();
is($htmldoc->_get_doc_config('jpeg'), "75",'Default JPG commpression at 75');

$htmldoc->set_jpeg_compression(0);
is($htmldoc->_get_doc_config('jpeg'), 0, 'Set JPG commpression to 0');

$htmldoc->set_jpeg_compression(100);
is($htmldoc->_get_doc_config('jpeg'), 100, 'Set JPG commpression to 100');

$htmldoc->_delete_doc_config('jpeg');
$htmldoc->best_image_quality();
is($htmldoc->_get_doc_config('jpeg'), 100, 'Set JPG commpression to 100 via best_image_quality()');

$htmldoc->_delete_doc_config('jpeg');
$htmldoc->low_image_quality();
is($htmldoc->_get_doc_config('jpeg'), 25);

# permissions - nos
my $okcounter = 0;
my @noperms = ('no-annotate', 'no-copy', 'no-modify',  'no-print');
foreach my $perm( @noperms ) {
	$htmldoc->set_permissions($perm);
}
my $stored = $htmldoc->_get_doc_config('permissions');
for(my $i=0; $i<@$stored; $i++) {
	$okcounter++ if ($stored->[$i] eq @noperms[$i]);
}
is($okcounter, 4, 'Set NO write / copy permissions');

# clean up permissions
$htmldoc->_delete_doc_config('permissions');

# permissions - yes
my $okcounter = 0;
my @noperms = ('annotate', 'copy', 'modify',  'print');
foreach my $perm( @noperms ) {
	$htmldoc->set_permissions($perm);
}
my $stored = $htmldoc->_get_doc_config('permissions');
for(my $i=0; $i<@$stored; $i++) {
	$okcounter++ if ($stored->[$i] eq @noperms[$i]);
}
is($okcounter, 4, 'Set YES write / copy permissions');

# permissions - none again to test if the set are deleted
$htmldoc->set_permissions('none');
is($htmldoc->_get_doc_config('permissions')->[0], 'none', 'Deleted permissions');

# permissions - corresponding flag deleted
$htmldoc->_delete_doc_config('permissions');
$htmldoc->set_permissions('copy');
$htmldoc->set_permissions('no-copy');
my $set = $htmldoc->_get_doc_config('permissions');
my $found = 0;
foreach (@$set) {
	$found = 1 if ($_ eq 'copy');
}
is($found, 0, 'Copy permissions set');

# permissions - corresponding flag deleted
$htmldoc->_delete_doc_config('permissions');
$htmldoc->set_permissions('no-copy');
$htmldoc->set_permissions('copy');
my $set = $htmldoc->_get_doc_config('permissions');
my $found = 0;
foreach (@$set) {
	$found = 1 if ($_ eq 'no-copy');
}
is($found, 0, 'No-Copy permissions set');

# landscape mode
$htmldoc->landscape();
my @keys = $htmldoc->_get_doc_config_keys();
is(array_contains(\@keys, 'landscape'), 1, 'Landscape mode (1/2)' );
is(array_contains(\@keys, 'portrait'), 0, 'Landscape mode (2/2)' );

# portrait mode
$htmldoc->portrait();
my @keys = $htmldoc->_get_doc_config_keys();
is(array_contains(\@keys, 'portrait'), 1, 'Portrait mode (1/2)' );
is(array_contains(\@keys, 'landscape'), 0, 'Portrait mode (1/2)' );

# right margin without measure
my $ret = $htmldoc->set_right_margin(2);
is($ret, 1, 'Right margin set to 2cm (1/2)');
is($htmldoc->_get_doc_config('right'), '2cm', 'Right margin set to 2cm (2/2)' );

# right margin without measure
my $ret = $htmldoc->set_right_margin(2.1);
is($ret, 1, 'Right margin set to 2.1cm (1/2)' );
is($htmldoc->_get_doc_config('right'), '2.1cm', 'Right margin set to 2.1cm (2/2)' );

# right margin mm
my $ret = $htmldoc->set_right_margin(2, 'mm');
is($ret, 1, 'Right margin set to 2mm (2/2)');
is($htmldoc->_get_doc_config('right'), '2mm', 'Right margin set to 2mm (2/2)' );

# right margin in
my $ret = $htmldoc->set_right_margin(2, 'in');
is($ret, 1, 'Right margin set to 2in (1/2)');
is($htmldoc->_get_doc_config('right'), '2in', 'Right margin set to 2in (2/2)');

# right margin to wrong value
my $ret = $htmldoc->set_right_margin(2, 'mc');
is( (!$ret && $htmldoc->error()=~/wrong arguments/ && $htmldoc->error()=~/right-margin/), 1, 'Block a wrong margin on right value' );

# left margin without measure
$htmldoc->set_left_margin(2);
is($htmldoc->_get_doc_config('left'), '2cm', 'Left margin without measure' );

# top margin without measure
$htmldoc->set_top_margin(2);
is($htmldoc->_get_doc_config('top'), '2cm', 'Top margin without measure'  );

# bottom margin without measure
$htmldoc->set_bottom_margin(2);
is($htmldoc->_get_doc_config('bottom'), '2cm', 'Bottom margin without measure'  );

# test colors hex
my $c = $htmldoc->_test_color('#FF00DD');
is($c, '#FF00DD', 'Hex colors (1/4)');
my $c = $htmldoc->_test_color('#FJ00DD');
is($c, undef, 'Hex colors (2/4)');

# test colors hex
my $c = $htmldoc->_test_color(0,0,0);
is($c, '#000000', 'Hex color (3/4)');
my $c = $htmldoc->_test_color(255,255,255);
is($c, '#ffffff', 'Hex color (4/4)');
my $c = $htmldoc->_test_color(256,255,255);
is($c, undef, 'Invalid color');
my $c = $htmldoc->_test_color('red');
is($c, 'red', 'Red color');
my $c = $htmldoc->_test_color('violette');
is($c, undef, 'Invalid color name');

# setting bodycolor
is($htmldoc->set_bodycolor('red'), 1, 'Body color (1/4)');
is($htmldoc->set_bodycolor('#010101'), 1, 'Body color (2/4)');
is($htmldoc->set_bodycolor('#0101011'), 0, 'Body color (3/4)');
is($htmldoc->set_bodycolor(0,0,0), 1, 'Body color (4/4)');

# browser-width
$htmldoc->set_browserwidth(100);
is($htmldoc->_get_doc_config('browserwidth'), 100, 'Browser width (1/2)');
is($htmldoc->set_browserwidth("sad"), 0, 'Browser width (2/2)');

# default header and footer
is($htmldoc->_get_doc_config('header'), '.t.', 'Default header' );
is($htmldoc->_get_doc_config('footer'), '.1.', 'Default footer');

# set special footer
is($htmldoc->set_footer('/', 'a', 'A'), 1, 'Set special footer');
is($htmldoc->_get_doc_config('footer'), '/aA', 'Verify special footer' );

# set wrong footer
is($htmldoc->set_footer('7', '&', 'x'), 0, 'Wrong footer');

# set special header
is($htmldoc->set_header('/', 'a', 'A'), 1, 'Set special header');
is($htmldoc->_get_doc_config('header'), '/aA', 'Verify special header' );

# set wrong header
is($htmldoc->set_header('7', '&', 'x'), 0, 'Wrong header');

#  default outputformat
is($htmldoc->_get_doc_config('format'), 'pdf', 'Default output');

# special output-format
is($htmldoc->set_output_format('html'), 1, 'Set special (HTML) output');
is($htmldoc->_get_doc_config('format'), 'html', 'Get special (HTML) output');
$htmldoc->set_output_format('pdf');

# wrong output format
is($htmldoc->set_output_format('asdasd'), 0, 'Wrong output format');
is($htmldoc->_get_doc_config('format'), 'pdf', 'Fallback to output format');

# set html
my $content = '<html>test</html>';
is($htmldoc->set_html_content($content), 1, 'Set HTML');
is($htmldoc->get_html_content(), $content, 'Verify HTML');

# set html as ref
my $content = '<html>test</html>';
is($htmldoc->set_html_content(\$content), 1, 'Set HTML as ref');
is($htmldoc->get_html_content(), $content, 'Verify HTML set from ref');

# turn links on
is($htmldoc->links(), 1, 'Turn on links (1/3)');
is($htmldoc->_get_doc_config('links'), '', 'Turn on links (2/3)');
is($htmldoc->_get_doc_config('no-links'), undef, 'Turn on links (3/3)');

# turn links off
is($htmldoc->no_links(), 1, 'Turn off links (1/3)');
is($htmldoc->_get_doc_config('no-links'), '', 'Turn off links (2/3)');
is($htmldoc->_get_doc_config('links'), undef, 'Turn off links (3/3)');

# set path for documents
is($htmldoc->path('/tmp'), 1, 'Set path for documents (1/2)');
is($htmldoc->_get_doc_config('path'), '/tmp', 'Set path for documents (2/2)');

# set fontsize
is($htmldoc->set_fontsize(2), 1, 'Set font size (1/5)');
is($htmldoc->_get_doc_config('fontsize'), 2, 'Set font size (2/5)');
is($htmldoc->set_fontsize(2.5), 1, 'Set font size (3/5)');
is($htmldoc->_get_doc_config('fontsize'), 2.5, 'Set font size (4/5)');
is($htmldoc->set_fontsize("x"), 0, 'Set font size (5/5)');

# set a logoimage
$htmldoc = new HTML::HTMLDoc();
my $setimage = $htmldoc->set_logoimage('./testdata/missingimage.gif');
is($setimage, 0, 'Set a missing logo image (1/2)');
is($htmldoc->error(), "Logoimage ./testdata/missingimage.gif could not be found", 'Set a missing logo image (2/2)');

my $logoimg = './testdata/testimage.gif';
my $setimage = $htmldoc->set_logoimage($logoimg);
is($setimage, 1, 'Set a correct logo image (1/2)');
is($htmldoc->get_logoimage(), $logoimg, 'Set a correct logo image (2/2)');

# set a letterhead image
$htmldoc = new HTML::HTMLDoc();
my $letterheadimg = './testdata/testimage.gif';
my $setimage = $htmldoc->set_letterhead($letterheadimg);
is($setimage, 1, 'Set a letterhead image (1/2)');
is($htmldoc->get_letterhead(), $letterheadimg, 'Set a letterhead image (2/2)');

# make clean copy to test the outputs
my $htmldoc = new HTML::HTMLDoc();

# default parameters
my $t = $htmldoc->_build_parameters();
my $ok = 1;
my @cont = ('--header .t.', '--format pdf',  '--charset iso-8859-1', '--quiet', '--portrait', '--size universal', '--footer .1.');
foreach(@cont) {
	if ( $t !~ /$_/ ) {
		$ok=0;
		last;
	}
}
is($ok, 1, 'Check default parameters');

#  the generation of pdf, ps and html in all possible versions

# test pdf 1.x
$htmldoc->set_html_content('test');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'PDF format (1/2)');
like(substr($pdf->to_string(),0,10), '/%PDF-1.\d/', 'PDF format (2/2)' );

# test pdf 1.1
my $htmldoc = new HTML::HTMLDoc();
$htmldoc->set_output_format('pdf11');
$htmldoc->set_html_content('test');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'PDF 1.1 format (1/2)');
like(substr($pdf->to_string(),0,10), '/%PDF-1.1/', 'PDF 1.1 format (2/2)' );

# test pdf 1.2
my $htmldoc = new HTML::HTMLDoc();
$htmldoc->set_output_format('pdf12');
$htmldoc->set_html_content('test');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'PDF 1.2 format (1/2)');
like(substr($pdf->to_string(),0,10), '/%PDF-1.2/', 'PDF 1.2 format (2/2)' );

# test pdf 1.3
my $htmldoc = new HTML::HTMLDoc();
$htmldoc->set_output_format('pdf13');
$htmldoc->set_html_content('test');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'PDF 1.3 format (1/2)');
like(substr($pdf->to_string(),0,10), '/%PDF-1.3/', 'PDF 1.3 format (2/2)' );

# test pdf 1.4
my $htmldoc = new HTML::HTMLDoc();
$htmldoc->set_output_format('pdf14');
$htmldoc->set_html_content('test');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'PDF 1.4 format (1/2)');
like(substr($pdf->to_string(),0,10), '/%PDF-1.4/', 'PDF 1.4 format (2/2)' );

# test PS
my $htmldoc = new HTML::HTMLDoc();
$htmldoc->set_output_format('ps');
$htmldoc->set_html_content('test');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'PS format (1/2)');
like(substr($pdf->to_string(),0,20), qr/^\Q%!PS-Adobe-3.0\E/, 'PS format (2/2)' );

# test PS1
my $htmldoc = new HTML::HTMLDoc();
$htmldoc->set_output_format('ps1');
$htmldoc->set_html_content('test');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'PS1 format (1/2)');
like(substr($pdf->to_string(),0,20), qr/^\Q%!PS-Adobe-3.0\E/, 'PS1 format (2/2)' );

# test PS2
my $htmldoc = new HTML::HTMLDoc();
$htmldoc->set_output_format('ps2');
$htmldoc->set_html_content('test');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'PS2 format (1/2)');
like(substr($pdf->to_string(),0,20), qr/^\Q%!PS-Adobe-3.0\E/, 'PS2 format (2/2)' );

# test PS3
my $htmldoc = new HTML::HTMLDoc();
$htmldoc->set_output_format('ps3');
$htmldoc->set_html_content('test');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'PS3 format (1/2)');
like(substr($pdf->to_string(),0,20), qr/^\Q%!PS-Adobe-3.0\E/, 'PS3 format (2/2)' );

# test HTML
my $htmldoc = new HTML::HTMLDoc();
$htmldoc->set_output_format('html');
$htmldoc->set_html_content('<html><body>lkjlkjlkj</body></html>');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'HTML format (1/2)');
like(substr($pdf->to_string(),0,15), qr/<!DOCTYPE html/i, 'HTML format (2/2)' );

# test generation of pdf in Apache-File-Mode
my $htmldoc = new HTML::HTMLDoc('mode'=>'file', 'tmpdir'=>'/tmp/hshshshd/sdasd/');
$htmldoc->set_html_content('<html><body>lkjlkjlkj</body></html>');
my $pdf = $htmldoc->generate_pdf();
is(ref($pdf), 'HTML::HTMLDoc::PDF', 'Apache format (1/2)');
like(substr($pdf->to_string(),0,10), '/%PDF-1.\d/', 'Apache format (2/2)' );

# that's it and that's that
done_testing;

# routine to look up for a key in an array
sub array_contains {
	my ($array,$key) = @_;

	my $contains = 0;
	foreach(@$array) {
		$contains = 1 if ($_ eq $key);
	}
	return $contains;
}




