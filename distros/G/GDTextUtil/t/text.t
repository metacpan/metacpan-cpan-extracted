# $Id: text.t,v 1.17 2003/02/21 00:10:28 mgjv Exp $

use lib ".", "..";
BEGIN { require "t/lib.pl" }

use Test::More tests => 20;

use GD;
BEGIN { use_ok "GD::Text" }

# Test the default setup
$t = GD::Text->new();
ok ($t->is_builtin, "default font is builtin");

# Check some size parameters
$t->set_text("Some text");
($w, $h, $cu, $cd) = $t->get(qw(width height char_up char_down));
ok ($w==54 && $h==13 && $cu==13 && $cd==0, "default size params")
    or diag("w=$w, h=$h, cu=$cu, cd=$cd");

# Change the text
$t->set_text("Some other text");
$w = $t->get('width');
ok ($w==90 && $h==13 && $cu==13 && $cd==0, "default size params 2")
    or diag("w=$w, h=$h, cu=$cu, cd=$cd");

# Test loading of other builtin font
$t->set_font(gdGiantFont);
ok ($t->is_builtin, "gdGiantFont builtin");

# Test the width method
$w = $t->width("Foobar Banana");
is ($w, 117, "width method");

# And make sure it did not change the text in the object
$text = $t->get('text');
is ($text, "Some other text", "text did not change");

# Now check the Giant Font parameters
($w, $h, $cu, $cd) = $t->get(qw(width height char_up char_down));
ok ($w==135 && $h==15 && $cu==15 && $cd==0, "Giant font size")
    or diag("w=$w, h=$h, cu=$cu, cd=$cd");

# Check that constructor with argument works
$t = GD::Text->new(text => 'FooBar Banana', font => gdGiantFont);
($w) = $t->get(qw(width)) if defined $t;
is ($w, 117, "constructor with args")
    or diag("t=$t");

# Check multiple fonts in one go, number 1
$rc = $t->set_font(['foo', gdGiantFont, 'bar', gdTinyFont]);
ok ($rc, "multiple fonts");

SKIP:
{
    skip "No TTF support", 6 unless ($t->can_do_ttf);

    unless (ok (-d "t", "correct directory"))
    {
	diag("Running in incorrect directory: No 't' subdirectory.");
	skip "Test script ran from incorrect directory", 5;
    }

    # Test loading of TTF
    $rc = $t->set_font('Dustismo_Sans.ttf', 18);
    ok ($rc && $t->is_ttf, "ttf set_font")
	or diag("Your GD module incorrectly claims valid TTF support");

    # Check multiple fonts in one go, number 2
    $rc = $t->set_font(['Dustismo_Sans', gdGiantFont, 'bar'], 24);

    like ($t->get('font'),   qr/Dustismo_Sans.ttf$/, "ttf multiple fonts")
	or diag("Font is '".$t->get('font')."'");
    is   ($t->get('ptsize'), 24,                     "ttf multiple fonts");

    skip "Some TTF tests disabled: Freetype inconsistent", 2;

    # Check some size parameters
    @p = $t->get(qw(width height char_up char_down space));
    is ("@p", "210 29 23 6 11", "ttf size param");

    # Check that constructor with argument works
    $t = GD::Text->new(text => 'FooBar', font =>'Dustismo_Sans');
    @p = $t->get(qw(width height char_up char_down space)) if defined $t;
    ok (defined $t && "@p" eq "38 12 10 2 5", "ttf constructor arg")
        or diag("p = @p");
}

# Font Path tests
#
# Only do this if we have TTF font support, and if we're on a unix-like
# OS. Will adapt this once I have support for other OS's for the font
# path.
SKIP :
{
    skip "no tff/nonunix", 4 unless ($t->can_do_ttf && 
				     $^O &&
				     $^O !~ /^MS(DOS|Win)/i && 
				     $^O !~ /VMS/i && 
				     $^O !~ /^MacOS/i && 
				     $^O !~ /os2/i && 
				     $^O !~ /^AmigaOS/i);

    # Font Path
    $t->font_path('demo/..:/tmp');
    $rc = GD::Text::_find_TTF('Dustismo_Sans', 18);
    is($rc,'./Dustismo_Sans.ttf', "font path no ttf");

    $t->font_path('demo/..:.:/tmp');
    $rc = GD::Text::_find_TTF('Dustismo_Sans', 18);
    is($rc,'demo/../Dustismo_Sans.ttf', "font path multi");

    $rc = GD::Text::_find_TTF('/usr/foo/font.ttf', 18);
    is($rc,'/usr/foo/font.ttf', "font path abs");

    $t->font_path(undef);
    $rc = GD::Text::_find_TTF('Dustismo_Sans.ttf', 18);
    is($rc,'./Dustismo_Sans.ttf', "named");
}

