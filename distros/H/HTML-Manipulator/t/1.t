# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use strict;
use Test::More tests => 40;
BEGIN { use_ok('HTML::Manipulator') };

#########################

my ($before, $after, $testname, $data, $one, $two, $link);
my (@list);

# ===================================

$testname = 'replace a simple div without nested tags';

$before = <<HTML;
<html>
<body>
<div id=simple>
XXXXXXX
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=simple>$testname</div>
</body>
</html>
HTML

is ( HTML::Manipulator::replace($before, 
    simple => $testname
), $after, $testname);

# ===================================

$testname = 'remove a simple div without nested tags';


$after = <<HTML;
<html>
<body>

</body>
</html>
HTML

is ( HTML::Manipulator::remove($before, 
   qw[ simple ]
), $after, $testname);


# ===================================

$testname = 'insert_before_begin with a simple div without nested tags';


$after = <<HTML;
<html>
<body>
$testname<div id=simple>
XXXXXXX
</div>
</body>
</html>
HTML

is ( HTML::Manipulator::insert_before_begin($before, 
   simple => $testname
), $after, $testname);

# ===================================

$testname = 'insert_after_end with a simple div without nested tags';


$after = <<HTML;
<html>
<body>
<div id=simple>
XXXXXXX
</div>$testname
</body>
</html>
HTML

is ( HTML::Manipulator::insert_after_end($before, 
   simple => $testname
), $after, $testname);

# ===================================

$testname = 'insert_before_end with a simple div without nested tags';


$after = <<HTML;
<html>
<body>
<div id=simple>
XXXXXXX
$testname</div>
</body>
</html>
HTML

is ( HTML::Manipulator::insert_before_end($before, 
   simple => $testname
), $after, $testname);

# ===================================

$testname = 'insert_after_begin with a simple div without nested tags';


$after = <<HTML;
<html>
<body>
<div id=simple>$testname
XXXXXXX
</div>
</body>
</html>
HTML

is ( HTML::Manipulator::insert_after_begin($before, 
   simple => $testname
), $after, $testname);






# ===================================

$testname = 'replace a div with nested tags (but no divs) and uppercase tags';

$before = <<HTML;
<html>
<body>
<div id=simple>
<a href='link'>link</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=simple>$testname</div>
</body>
</html>
HTML

is ( HTML::Manipulator::replace( uc $before, 
    SIMPLE =>  uc $testname
),  uc $after, $testname);


# ===================================

$testname = 'remove a div with nested tags (but no divs) and uppercase tags';


$after = <<HTML;
<html>
<body>

</body>
</html>
HTML

is ( HTML::Manipulator::remove( uc $before, 
    qw[ SIMPLE ]
),  uc($after), $testname);


# ===================================

$testname = 'replace a link href and text';

$before = <<HTML;
<html>
<body>
<div id=simple>
<a Href='link' id=link>link</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=simple>
<a href='new href' id='link'>$testname</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML
#also checking some case sensitivity issues here
is ( HTML::Manipulator::replace($before, 
    link => { HREF => 'new href', _content => $testname}
), $after, $testname);

# ===================================

$testname = 'replace two divs and a nested link';

$before = <<HTML;
<html>
<body>
<div id=one>
<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>
<div id=two>
<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=one>$testname</div>
<div id=two>$testname$testname</div>
</body>
</html>
HTML

is ( HTML::Manipulator::replace($before, 
    link => { href => 'new href', _content => $testname},
    one => $testname,
    two => $testname.$testname
), $after, $testname);


# ===================================

$testname = 'remove two divs and a nested link';


$after = <<HTML;
<html>
<body>


</body>
</html>
HTML

is ( HTML::Manipulator::remove($before, 
   qw[ link one two ]
), $after, $testname);



# ===================================

$testname = 'insert_before_begin with two divs and a nested link';


$after = <<HTML;
<html>
<body>
$testname one<div id=one>
$testname link<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>
$testname two<div id=two>
<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML

is ( HTML::Manipulator::insert_before_begin($before, 
   link => "$testname link",  one => "$testname one",  
   two => "$testname two" 
), $after, $testname);

# ===================================

$testname = 'insert_after_end with two divs and a nested link';


$after = <<HTML;
<html>
<body>
<div id=one>
<a href='link' id=link>link</a>$testname link<b>text<i>yyy</b>
</div>$testname one
<div id=two>
<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>$testname two
</body>
</html>
HTML

is ( HTML::Manipulator::insert_after_end($before, 
   link => "$testname link",  one => "$testname one",  
   two => "$testname two" 
), $after, $testname);

# ===================================

$testname = 'insert_before_end with two divs and a nested link';


$after = <<HTML;
<html>
<body>
<div id=one>
<a href='link' id=link>link$testname link</a><b>text<i>yyy</b>
$testname one</div>
<div id=two>
<a href='link' id=link>link</a><b>text<i>yyy</b>
$testname two</div>
</body>
</html>
HTML

is ( HTML::Manipulator::insert_before_end($before, 
   link => "$testname link",  one => "$testname one",  
   two => "$testname two" 
), $after, $testname);

# ===================================

$testname = 'insert_after_begin with two divs and a nested link';


$after = <<HTML;
<html>
<body>
<div id=one>$testname one
<a href='link' id=link>$testname linklink</a><b>text<i>yyy</b>
</div>
<div id=two>$testname two
<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML

is ( HTML::Manipulator::insert_after_begin($before, 
   link => "$testname link",  one => "$testname one",  
   two => "$testname two" 
), $after, $testname);



# ===================================

$testname = 'replace a div with a nested div';

$before = <<HTML;
<html>
<body>
<div id=one>
<!-- a comment -->
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

is ( HTML::Manipulator::replace($before, 
    link => { href => 'new href', _content => $testname},
    one => $testname,
    two => $testname.$testname
), $after, $testname);


# ===================================


is ( HTML::Manipulator::extract_content($after, 'one')   
    , $testname
    , 'extract a div content');


# ===================================

$testname = 'extract a link with attributes';

$data = HTML::Manipulator::extract($before, 'link');

ok ( (ref $data 
       and ($data->{href} eq 'link')
       and ( $data->{_content} eq 'link')) 
    , $testname);

# ===================================

$testname = 'extract all element IDs';

$data = HTML::Manipulator::extract_all_ids($before);


ok ( (ref $data 
       and (delete $data->{link} eq 'a')
        and (delete $data->{one} eq 'div')
         and (delete $data->{two} eq 'div')
          and not keys %$data
       ) 
    , $testname);

# ===================================

$testname = 'extract the content of all IDs';

$data = HTML::Manipulator::extract_all_content($before);

$two = "\n<a href='link' id=link>link</a><b>text<i>yyy</b>\n";
$one= "\n<!-- a comment -->\n<div id=two>$two</div>\nblah blah blah\n";

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

$testname = 'extract contents from HTML without IDs';

$data = HTML::Manipulator::extract_all('not really HTML');

is (keys %$data, 0, $testname);
    
# ===================================

$testname = 'extract the content of all IDs from a file';

open IN, 't/1.html' or die "could not open t/1.html: $!";
$data = HTML::Manipulator::extract_all_content(*IN);
close IN;

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

$testname = 'handle quotation marks in attributes';

$before = <<HTML;
<a href='link' id=link>link</a><b>text<i>yyy</b>
HTML

$after = <<HTML;
<a href="new 'href" id='link'>$testname</a><b>text<i>yyy</b>
HTML

is ( HTML::Manipulator::replace($before, 
    link => { href => "new 'href", _content => $testname}
), $after, $testname);

# ===================================

$testname = 'extract the document title';

$before = <<HTML;
<title>$testname</title>
HTML


is ( HTML::Manipulator::extract_title($before), $testname, $testname);

# ===================================

$testname = 'replace the document title';

$after = <<HTML;
<title>$testname</title>
HTML

is ( HTML::Manipulator::replace_title($before, $testname),
	$after, $testname);
	
# ===================================

$testname = 'extract some element IDs using regular expressions';

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


$data = HTML::Manipulator::extract_all_ids($before, qr/LINK/i, qr/no match/, 'one');


ok ( (ref $data 
       and (delete $data->{link} eq 'a')
        and (delete $data->{one} eq 'div')
          and not keys %$data
       ) 
    , $testname);


# ===================================
$testname = 'extract some elements matched by regular expressions';

$data = HTML::Manipulator::extract_all_content($before, qr/o../, qr/LINK/i);

$two = "\n<a href='link' id=link>link</a><b>text<i>yyy</b>\n";
$one= "\n<div id=two>$two</div>\nblah blah blah\n";

ok ( (ref $data 
       and (delete $data->{link} eq 'link')
       and (delete $data->{one} eq $one)
    and not keys %$data
       ) 
    , $testname);
    
# ===================================
$testname = 'extract a section marked by comments';

$two = 'This region is editable';
$one = "<b id=check>$two</b>";
$before = <<HTML;
<p id=test>
<!-- #BeginEditable "content" -->$one<!-- #EndEditable -->
</p>
<!-- another comment -->
HTML

$data = HTML::Manipulator::extract_content($before, '<!-- #BeginEditable "content" -->');
is ($data, $one, $testname);

# ===================================
$testname = 'extract a section marked by comments with nesting';


$data = HTML::Manipulator::extract_all_content($before, '<!--#BEGINEDITABLE"content"-->','test', 'check');

ok ( (ref $data 
       and (delete $data->{test} eq qq{\n<!-- #BeginEditable "content" -->$one<!-- #EndEditable -->\n})
        and (delete $data->{check} eq $two)
       and (delete $data->{'<!--#BEGINEDITABLE"content"-->'} eq $one)
    and not keys %$data
       ) 
    , $testname);

    
# ===================================
$testname = 'extract all comments';

@list= HTML::Manipulator::extract_all_comments($before);

ok (
	(($list[0] eq '<!-- #BeginEditable "content" -->')
	and ($list[1] eq '<!-- #EndEditable -->')
	and ($list[2] eq '<!-- another comment -->')
	and @list == 3),
	$testname);
	
# ===================================
$testname = 'extract all comments (with filter)';

@list = HTML::Manipulator::extract_all_comments($before, '#BEGINEDITABLE "CONTENT"', qr/Another/i);

ok ((($list[0] eq '<!-- #BeginEditable "content" -->')
	and ($list[1] eq '<!-- another comment -->')
	and @list == 2),
	$testname);
	

# ===================================
$testname = 'replace a section marked by comments';

$after = $before;
$after =~ s/$one/$testname/;
$data = HTML::Manipulator::replace($before, '<!-- #BeginEditable "content" -->' => $testname);
is ($data, $after, $testname);

# ===================================
$testname = 'remove a section marked by comments';

$after = <<HTML;
<p id=test>

</p>
<!-- another comment -->
HTML
$data = HTML::Manipulator::remove($before, '<!-- #BeginEditable "content" -->');
is ($data, $after, $testname);

# ===================================
$testname = 'insert_before_begin with a section marked by comments and a nested div';

$before = <<HTML;
<p id=test>
<!-- #BeginEditable "content" --><p>blah</p>
<div id='nested'><i>$testname</i></div><!-- #EndEditable -->
</p>
<!-- another comment -->
<div id='three'>hey</div>
HTML


$after = <<HTML;
<p id=test>
ONE<!-- #BeginEditable "content" --><p>blah</p>
TWO<div id='nested'><i>$testname</i></div><!-- #EndEditable -->
</p>
<!-- another comment -->
THREE<div id='three'>hey</div>
HTML
$data = HTML::Manipulator::insert_before_begin(
	$before, '<!-- #BeginEditable "content" -->' => 'ONE', 
		nested => 'TWO', three => 'THREE');
	
is ($data, $after, $testname);

# ===================================
$testname = 'insert_after_end with a section marked by comments and a nested div';

$before = <<HTML;
<p id=test>
<!-- #BeginEditable "content" --><p>blah</p>
<div id='nested'><i>$testname</i></div><!-- #EndEditable -->
</p>
<!-- another comment -->
<div id='three'>hey</div>
HTML


$after = <<HTML;
<p id=test>
<!-- #BeginEditable "content" --><p>blah</p>
<div id='nested'><i>$testname</i></div>TWO<!-- #EndEditable -->ONE
</p>
<!-- another comment -->
<div id='three'>hey</div>THREE
HTML
$data = HTML::Manipulator::insert_after_end(
	$before, '<!-- #BeginEditable "content" -->' => 'ONE', 
		nested => 'TWO', three => 'THREE');
	
is ($data, $after, $testname);

# ===================================
$testname = 'insert_before_end with a section marked by comments and a nested div';

$before = <<HTML;
<p id=test>
<!-- #BeginEditable "content" --><p>blah</p>
<div id='nested'><i>$testname</i></div><!-- #EndEditable -->
</p>
<!-- another comment -->
<div id='three'>hey</div>
HTML


$after = <<HTML;
<p id=test>
<!-- #BeginEditable "content" --><p>blah</p>
<div id='nested'><i>$testname</i>TWO</div>ONE<!-- #EndEditable -->
</p>
<!-- another comment -->
<div id='three'>heyTHREE</div>
HTML
$data = HTML::Manipulator::insert_before_end(
	$before, '<!-- #BeginEditable "content" -->' => 'ONE', 
		nested => 'TWO', three => 'THREE');
	
is ($data, $after, $testname);

# ===================================
$testname = 'insert_before_end with a section marked by comments';

$before = <<HTML;
<p id=test>
<!-- #BeginEditable "content" -->$one<!-- #EndEditable -->
</p>
<!-- another comment -->
HTML

$after = <<HTML;
<p id=test>
<!-- #BeginEditable "content" -->${one}BEFORE_END<!-- #EndEditable -->
BEFORE_END</p>
<!-- another comment -->
HTML

$data = HTML::Manipulator::insert_before_end($before, 
    test=>'BEFORE_END', 
	'<!-- #BeginEditable "CONtent"    -->' => 'BEFORE_END'
);
	
is ($data, $after, $testname);


# ===================================
$testname = 'insert_after_begin with a section marked by comments and a nested div';

$before = <<HTML;
<p id=test>
<!-- #BeginEditable "content" --><p>blah</p>
<div id='nested'><i>$testname</i></div><!-- #EndEditable -->
</p>
<!-- another comment -->
<div id='three'>hey</div>
HTML


$after = <<HTML;
<p id=test>
<!-- #BeginEditable "content" -->ONE<p>blah</p>
<div id='nested'>TWO<i>$testname</i></div><!-- #EndEditable -->
</p>
<!-- another comment -->
<div id='three'>THREEhey</div>
HTML
$data = HTML::Manipulator::insert_after_begin(
	$before, '<!-- #BeginEditable "content" -->' => 'ONE', 
		nested => 'TWO', three => 'THREE');
	
is ($data, $after, $testname);

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

$before = HTML::Manipulator::insert_before_begin($before, test=>'BEFORE_BEGIN', 
	'<!-- #BeginEditable "content"  -->' => 'BEFORE_BEGIN');

$before = HTML::Manipulator::insert_after_begin($before, test=>'AFTER_BEGIN', 
	'<!-- #BeginEditable "content"-->' => 'AFTER_BEGIN');

$before = HTML::Manipulator::insert_before_end($before, 
    test=>'BEFORE_END', 
	'<!-- #BeginEditable "CONtent"    -->' => 'BEFORE_END'
);


is ( HTML::Manipulator::insert_after_end($before, test=>'AFTER_END', 
	'<!-- #  Begineditable "content"-->' => 'AFTER_END') ,
	$after, $testname);



