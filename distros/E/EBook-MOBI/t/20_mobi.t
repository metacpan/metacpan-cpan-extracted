#!/usr/bin/perl

use strict;
use warnings;

#######################
# TESTING starts here #
#######################
use Test::More tests => 26;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);

can_ok($obj, 'new');
can_ok($obj, 'reset');
can_ok($obj, 'debug_on');
can_ok($obj, 'debug_off');
can_ok($obj, 'set_title');
can_ok($obj, 'set_author');
can_ok($obj, 'set_filename');
can_ok($obj, 'set_encoding');
can_ok($obj, 'add_mhtml_content');
can_ok($obj, 'add_content');
can_ok($obj, 'add_pagebreak');
can_ok($obj, 'add_toc_once');
can_ok($obj, 'make');
can_ok($obj, 'print_mhtml');
can_ok($obj, 'save');

################################
# We define some parsing input #
# and also how the result      #
# should look like             #
################################
my %html_in ; # parsing input
my %html_out;  # parsing result

# 1
$html_in{TOC} = <<'HEREDOC';
 <h1>NOT IN TOC</h1>
This should not appear in TOC because of the whitespace at begin of line.
<h1>CHAPTER ONE</h1>
This should appear in the TOC.
<h1>CHAPTER TWO</h1>
This too. Lets make some text to fill some gaps:<br />
<br />
<b>I've a Pain in my Head by Jane Austen</b><br />
<br />
'I've a pain in my head'<br />
Said the suffering Beckford;<br />
To her Doctor so dread.<br />
'Oh! what shall I take for't?'<br />
<br />
Said this Doctor so dread<br />
Whose name it was Newnham.<br />
'For this pain in your head<br />
Ah! What can you do Ma'am?'<br />
<br />
Said Miss Beckford, 'Suppose<br />
If you think there's no risk,<br />
I take a good Dose<br />
Of calomel brisk.'--<br />
<br />
'What a praise worthy Notion.'<br />
Replied Mr. Newnham.<br />
'You shall have such a potion<br />
And so will I too Ma'am.' <br />
<h2>NOT IN TOC 2</h2>
This should not appear in TOC because it's head type 2.
HEREDOC

$html_out{TOC} = <<'HEREDOC';
<html>
<head>
<guide>
<reference type="toc" title="Table of Contents" filepos="00000151"/>
</guide>
</head>
<body>
<b><i>TEST</i></b><mbp:pagebreak />
<h1>Table of Contents</h1><!-- TOC start -->
<p><ul>
<li><a filepos="00000458">CHAPTER ONE</a></li><!-- TOC entry -->
<li><a filepos="00000510">CHAPTER TWO</a></li><!-- TOC entry -->
</ul></p>

<mbp:pagebreak />
 <h1>NOT IN TOC</h1>
This should not appear in TOC because of the whitespace at begin of line.
<h1>CHAPTER ONE</h1>
This should appear in the TOC.
<h1>CHAPTER TWO</h1>
This too. Lets make some text to fill some gaps:<br />
<br />
<b>I've a Pain in my Head by Jane Austen</b><br />
<br />
'I've a pain in my head'<br />
Said the suffering Beckford;<br />
To her Doctor so dread.<br />
'Oh! what shall I take for't?'<br />
<br />
Said this Doctor so dread<br />
Whose name it was Newnham.<br />
'For this pain in your head<br />
Ah! What can you do Ma'am?'<br />
<br />
Said Miss Beckford, 'Suppose<br />
If you think there's no risk,<br />
I take a good Dose<br />
Of calomel brisk.'--<br />
<br />
'What a praise worthy Notion.'<br />
Replied Mr. Newnham.<br />
'You shall have such a potion<br />
And so will I too Ma'am.' <br />
<h2>NOT IN TOC 2</h2>
This should not appear in TOC because it's head type 2.
</body>
</html>
HEREDOC

#################################################
# Now we parse the input and compare the result #
# with what we expected...                      #
#################################################
for my $key (keys %html_in) {
    # we make a new book for each test
    my $obj = $module->new();

    $obj->add_mhtml_content('<b><i>TEST</i></b>');
    $obj->add_pagebreak();
    $obj->add_toc_once();
    $obj->add_pagebreak();
    $obj->add_mhtml_content($html_in{$key});
    $obj->make();

    my $html_res = $obj->print_mhtml('no print to stdout');

    is($html_res, $html_out{$key}, "Book -> $key");
}

###
### Let's do some more testing
###

$obj->reset();

my $POD_in = <<END;
=head0 Zero

=head1 One

Text 1

=head2 Two

Text 2

=head0 Zero 2

=head1 Three

Text 3

=cut
END

my $POD_res_default = <<END;
<html>
<head>
</head>
<body>
<h1>One</h1>
<p>Text 1</p>
<h2>Two</h2>
<p>Text 2</p>
<h1>Three</h1>
<p>Text 3</p>
</body>
</html>
END

my $POD_res_head0_mode = <<END;
<html>
<head>
</head>
<body>
<h1>Zero</h1>
<h2>One</h2>
<p>Text 1</p>
<h3>Two</h3>
<p>Text 2</p>
<h1>Zero 2</h1>
<h2>Three</h2>
<p>Text 3</p>
</body>
</html>
END

my $POD_res_pagemode = <<END;
<html>
<head>
</head>
<body>
<h1>One</h1>
<p>Text 1</p>
<h2>Two</h2>
<p>Text 2</p>
<mbp:pagebreak />
<h1>Three</h1>
<p>Text 3</p>
</body>
</html>
END

my $POD_res_head0_and_pagemode = <<END;
<html>
<head>
</head>
<body>
<h1>Zero</h1>
<h2>One</h2>
<p>Text 1</p>
<h3>Two</h3>
<p>Text 2</p>
<mbp:pagebreak />
<h1>Zero 2</h1>
<h2>Three</h2>
<p>Text 3</p>
</body>
</html>
END

my $POD_res_toc_and_head0_and_pagemode = <<END;
<html>
<head>
<guide>
<reference type="toc" title="Table of Contents" filepos="00000115"/>
</guide>
</head>
<body>
<h1>Table of Contents</h1><!-- TOC start -->
<p><ul>
<li><a filepos="00000297">Zero</a></li><!-- TOC entry -->
<li><a filepos="00000383">Zero 2</a></li><!-- TOC entry -->
</ul></p>

<h1>Zero</h1>
<h2>One</h2>
<p>Text 1</p>
<h3>Two</h3>
<p>Text 2</p>
<mbp:pagebreak />
<h1>Zero 2</h1>
<h2>Three</h2>
<p>Text 3</p>
</body>
</html>
END

my $POD_res_namedtoc = <<END;
<html>
<head>
<guide>
<reference type="toc" title="Inhaltsverzeichnis" filepos="00000116"/>
</guide>
</head>
<body>
<h1>Inhaltsverzeichnis</h1><!-- TOC start -->
<p><ul>
<li><a filepos="00000297">One</a></li><!-- TOC entry -->
<li><a filepos="00000351">Three</a></li><!-- TOC entry -->
</ul></p>

<h1>One</h1>
<p>Text 1</p>
<h2>Two</h2>
<p>Text 2</p>
<h1>Three</h1>
<p>Text 3</p>
</body>
</html>
END

my $POD_res_namedtoc_and_head0_and_pagemode = <<END;
<html>
<head>
<guide>
<reference type="toc" title="TOC_NAME" filepos="00000106"/>
</guide>
</head>
<body>
<h1>TOC_NAME</h1><!-- TOC start -->
<p><ul>
<li><a filepos="00000279">Zero</a></li><!-- TOC entry -->
<li><a filepos="00000365">Zero 2</a></li><!-- TOC entry -->
</ul></p>

<h1>Zero</h1>
<h2>One</h2>
<p>Text 1</p>
<h3>Two</h3>
<p>Text 2</p>
<mbp:pagebreak />
<h1>Zero 2</h1>
<h2>Three</h2>
<p>Text 3</p>
</body>
</html>
END

$obj->add_content(data => $POD_in);
$obj->make();
my $res = $obj->print_mhtml(1);
is($res, $POD_res_default, "Book -> default");

$obj->reset();
$obj->add_content(data => $POD_in, driver => 'EBook::MOBI::Driver::POD');
$obj->make();
$res = $obj->print_mhtml(1);
is($res, $POD_res_default, "Book -> driver_select");

$obj->reset();
$obj->add_content(data => $POD_in, driver_options => {head0_mode => 1});
$obj->make();
$res = $obj->print_mhtml(1);
is($res, $POD_res_head0_mode, "Book -> head0_mode");

$obj->reset();
$obj->add_content(data => $POD_in, driver_options => {pagemode => 1});
$obj->make();
$res = $obj->print_mhtml(1);
is($res, $POD_res_pagemode, "Book -> pagemode");

$obj->reset();
$obj->add_content(data => $POD_in, driver_options => {pagemode => 1, head0_mode => 1});
$obj->make();
$res = $obj->print_mhtml(1);
is($res, $POD_res_head0_and_pagemode, "Book -> head0+pagemode");

$obj->reset();
$obj->add_toc_once();
$obj->add_content(data => $POD_in, driver_options => {pagemode => 1, head0_mode => 1});
$obj->make();
$res = $obj->print_mhtml(1);
is($res, $POD_res_toc_and_head0_and_pagemode, "Book -> toc+head0+pagemode");

$obj->reset();
$obj->add_toc_once('Inhaltsverzeichnis');
$obj->add_content(data => $POD_in);
$obj->make();
$res = $obj->print_mhtml(1);
is($res, $POD_res_namedtoc, "Book -> namedtoc");

$obj->reset();
$obj->add_toc_once('TOC_NAME');
$obj->add_content(data => $POD_in, driver_options => {pagemode => 1, head0_mode => 1});
$obj->make();
$res = $obj->print_mhtml(1);
is($res, $POD_res_namedtoc_and_head0_and_pagemode, "Book -> namedtoc+head0+pagemode");

########
# done #
########
1;

