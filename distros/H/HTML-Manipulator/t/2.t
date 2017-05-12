#########################

use strict;
use Test::More tests => 14;
BEGIN { use_ok('HTML::Manipulator::Document') };

#########################

my ($before, $after, $testname, $data, $obj, $one, $two);


# ===================================

$testname = 'method "replace"';

$before = <<HTML;
<html>
<body>
<div id=one>
<div id=two>
<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>
blah blah blah
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=one>$testname</div>
</body>
</html>
HTML


$obj = HTML::Manipulator::Document->from_string($before);

is ( $obj->replace(
	one => $testname
), $after, $testname);

# ===================================

$obj = HTML::Manipulator::Document->from_string($before);
$obj->replace(
	one => $testname
);

is ($obj->as_string(), $after, 'method "as_string"');

# ===================================

$obj = HTML::Manipulator::Document->from_string($after);

is ( $obj->extract_content('one')   
    , $testname
    , 'method "extract_content"');


# ===================================

$testname = 'method "extract"';

$obj = HTML::Manipulator::Document->from_string($before);

$data = $obj->extract( 'link');

ok ( (ref $data 
       and ($data->{href} eq 'link')
       and ( $data->{_content} eq 'link')) 
    , $testname);

# ===================================

$testname = 'method "extract_all_ids"';

$obj = HTML::Manipulator::Document->from_string($before);

$data = $obj->extract_all_ids();


ok ( (ref $data 
       and (delete $data->{link} eq 'a')
        and (delete $data->{one} eq 'div')
         and (delete $data->{two} eq 'div')
          and not keys %$data
       ) 
    , $testname);

# ===================================

$testname = 'method "extract_all_content"';

$obj = HTML::Manipulator::Document->from_string($before);

$data = $obj->extract_all_content();

$two = "\n<a href='link' id=link>link</a><b>text<i>yyy</b>\n";
$one= "\n<div id=two>$two</div>\nblah blah blah\n";

#is( delete ($data->{link}) , 'link', $testname);
#is( delete ($data->{two}) , $two, $testname);
#is( delete ($data->{one}) , $one, $testname);

ok ( (ref $data 
       and (delete $data->{link} eq 'link')
       and (delete $data->{one} eq $one)
       and (delete $data->{two} eq $two)
    and not keys %$data
       ) 
    , $testname);
    
# ===================================

$testname = 'method "from_file" with file handle';

open IN, 't/1.html' or die "could not open t/1.html: $!";
$obj = HTML::Manipulator::Document->from_file(*IN);
close IN;


$data = $obj->extract_all_content();


$two = "\n<a href='link' id=link>link</a><b>text<i>yyy</b>\n";
$one= "\n<div id=two>$two</div>\nblah blah blah\n";

ok ( (ref $data 
       and (delete $data->{link} eq 'link')
       and (delete $data->{one} eq $one)
       and (delete $data->{two} eq $two)
    and not keys %$data
       ) 
    , $testname);
    
# ===================================

$testname = 'method "from_file" with file name';

$obj = HTML::Manipulator::Document->from_file('t/1.html');

$data = $obj->extract_all_content();

$two = "\n<a href='link' id=link>link</a><b>text<i>yyy</b>\n";
$one= "\n<div id=two>$two</div>\nblah blah blah\n";

ok ( (ref $data 
       and (delete $data->{link} eq 'link')
       and (delete $data->{one} eq $one)
       and (delete $data->{two} eq $two)
    and not keys %$data
       ) 
    , $testname);
    
    
# ===================================

$testname = 'method "extract_title"';

$before = <<HTML;
<title>$testname</title>
HTML

$obj = HTML::Manipulator::Document->from_string($before);

is ( $obj->extract_title(), $testname, $testname);

# ===================================

$testname = 'method "replace_title"';

$after = <<HTML;
<title>$testname</title>
HTML

$obj = HTML::Manipulator::Document->from_string($before);

is ( $obj->replace_title($testname), $after, $testname);

# ==========================

$testname = 'method save_as';

$before = <<HTML;
<title>$testname</title>
HTML

use File::Spec;
$one = File::Spec->catfile(File::Spec->tmpdir, 'htmlmanipulator', 't2_saveas.html');
$obj = HTML::Manipulator::Document->from_string($before);
$obj->save_as($one);
ok ( -e $one, $testname);
unlink $one;
rmdir File::Spec->catfile(File::Spec->tmpdir, 'htmlmanipulator');

# ===================================
$testname = 'method extract_all_comments';

$two = 'This region is editable';
$one = "<b id=check>$two</b>";
$before = <<HTML;
<p id=test>
<!-- #BeginEditable "content" -->$one<!-- #EndEditable -->
</p>
<!-- another comment -->
HTML

$obj = HTML::Manipulator::Document->from_string($before);
is (scalar $obj->extract_all_comments(), 3, $testname);


# ===================================
$testname = 'insert adjacent';

$before = <<HTML;
<p id=test>
<!-- #BeginEditable "content" -->$one<!-- #EndEditable -->
</p>
<!-- another comment -->
HTML

$after = <<HTML;
BEFORE_BEGIN<p id=test>AFTER_BEGIN
BEFORE_BEGIN<!-- #BeginEditable "content" -->AFTER_BEGIN${one}BEFORE_END<!-- #EndEditable -->AFTER_END
BEFORE_END</p>AFTER_END
<!-- another comment -->
HTML

$obj = HTML::Manipulator::Document->from_string($before);
$obj->insert_before_begin( test=>'BEFORE_BEGIN', 
	'<!-- #BeginEditable "content"-->' => 'BEFORE_BEGIN');
$obj->insert_after_begin( test=>'AFTER_BEGIN', 
	'<!-- #BeginEditable "content"-->' => 'AFTER_BEGIN');
$obj->insert_before_end( test=>'BEFORE_END', 
	'<!-- #BeginEditable "content"-->' => 'BEFORE_END');
is ( $obj->insert_after_end( test=>'AFTER_END', 
	'<!-- #BeginEditable "content"-->' => 'AFTER_END') ,
	$after, $testname);

