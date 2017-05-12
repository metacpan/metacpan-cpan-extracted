# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 258 };
use HTML::Template::Filter::Dreamweaver qw( DWT2HTML DWT2HTMLExpr );
ok(1); # If we made it this far, we're ok.

#########################

my @escapes = ( "", "HTML", "URL" );
my $text;
my $filter;

# Test transform of begin/end editables
foreach my $i ( @escapes ) {
    my $text = "<!-- TemplateBeginEditable name=\"FOO\"";
    $text .= " escape=\"$i\"" if $i;
    $text .= " -->\n<!-- TemplateEndEditable -->";

    my $filter = "<!-- TMPL_VAR NAME=\"FOO\"";
    $filter .= " ESCAPE=$i" if $i;
    $filter .= " -->";

    my $input = $text;
    DWT2HTML( \$input );
    ok( $input, $filter );
    
    $input = $text;
    DWT2HTMLExpr( \$input );
    ok( $input, $filter );
}

# Test transform of @@(FOO)@@ syntax
foreach my $i ( @escapes ) {
    foreach my $val ( "", "<b>BAR</b>", "<b>\"BAR\"</b>", "<b>'BAR'</b>"  ) {
	my $text = "<!-- TemplateParam name=\"FOO\" type=\"text\"";
	$text .= " value=\"$val\"" if $val !~ /\"/;
	$text .= " value=\'$val\'" if $val =~ /\"/;
	$text .= " escape=\"$i\"" if $i;
	$text .= " -->\n@@(FOO)@@";
	
	my $filter = "<!-- TMPL_VAR NAME='FOO'";
	$filter .= " ESCAPE=$i" if $i;
	$filter .= " DEFAULT='$val'" if $val && $val !~ /\'/;
	$filter .= " DEFAULT=\"$val\"" if $val && $val =~ /\'/;
	$filter .= " -->";
	
	my $input = $text;
	DWT2HTML( \$input );
	ok( $input, $filter );
	
	$input = $text;
	DWT2HTMLExpr( \$input );
	ok( $input, $filter );
    }
}

# Test transform of TemplateExpr syntax
foreach my $i ( @escapes ) {
    foreach my $j ( @escapes, "NOESCAPE" ) {
	foreach my $val ( "", "<b>BAR</b>", "<b>\"BAR\"</b>", "<b>'BAR'</b>"  ) {
	    my $text = "<!-- TemplateParam name=\"FOO\" type=\"text\"";
	    $text .= " value=\"$val\"" if $val !~ /\"/;
	    $text .= " value=\'$val\'" if $val =~ /\"/;
	    $text .= " escape=\"$i\"" if $i;
	    $text .= " -->\n<!-- TemplateExpr expr=\"FOO\"";
	    $text .= " escape=\"$j\"" if $j ne "NOESCAPE";
	    $text .= " -->";

	    my $filter = "<!-- TMPL_VAR NAME=\"FOO\"";
	    if ( $j eq "NOESCAPE" ) {
		$filter .= " ESCAPE=$i" if $i;
	    }
	    else {
		$filter .= " ESCAPE=$j" if $j;
	    }

	    $filter .= " DEFAULT='$val'" if $val && $val !~ /\'/;
	    $filter .= " DEFAULT=\"$val\"" if $val && $val =~ /\'/;
	    $filter .= " -->";
	    
	    my $input = $text;
	    DWT2HTML( \$input );
	    ok( $input, $filter );
	    
	    $input = $text;
	    DWT2HTMLExpr( \$input );
	    ok( $input, $filter );
	}
    }
}

# Test transform of @@(_document._Get())@@ syntax
foreach my $i ( @escapes ) {
    foreach my $j ( @escapes, "NOESCAPE" ) {
	foreach my $val ( "", "<b>BAR</b>", "<b>\"BAR\"</b>", "<b>'BAR'</b>"  ) {
	    my $text = "<!-- TemplateParam name=\"FOO\" type=\"text\"";
	    $text .= " value=\"$val\"" if $val !~ /\"/;
	    $text .= " value=\'$val\'" if $val =~ /\"/;
	    $text .= " escape=\"$i\"" if $i;
	    $text .= " -->\n@@(_document._Get( \"FOO\"";
	    $text .= ",\"$j\"" if $j ne "NOESCAPE";
	    $text .= " ))@@";

	    my $filter = "<!-- TMPL_VAR NAME=\"FOO\"";
	    if ( $j eq "NOESCAPE" ) {
		$filter .= " ESCAPE=$i" if $i;
	    }
	    else {
		$filter .= " ESCAPE=$j" if $j;
	    }

	    $filter .= " DEFAULT='$val'" if $val && $val !~ /\'/;
	    $filter .= " DEFAULT=\"$val\"" if $val && $val =~ /\'/;
	    $filter .= " -->";
	    
	    my $input = $text;
	    DWT2HTML( \$input );
	    ok( $input, $filter );
	    
	    $input = $text;
	    DWT2HTMLExpr( \$input );
	    ok( $input, $filter );
	}
    }
}

# Test transform of @@(_document.[])@@ syntax
foreach my $i ( @escapes ) {
    foreach my $val ( "", "<b>BAR</b>", "<b>\"BAR\"</b>", "<b>'BAR'</b>"  ) {
	my $text = "<!-- TemplateParam name=\"FOO\" type=\"text\"";
	$text .= " value=\"$val\"" if $val !~ /\"/;
	$text .= " value=\'$val\'" if $val =~ /\"/;
	$text .= " escape=\"$i\"" if $i;
	$text .= " -->\n@@(_document[\"FOO\"])@@";

	my $filter = "<!-- TMPL_VAR NAME='FOO'";
	$filter .= " ESCAPE=$i" if $i;

	$filter .= " DEFAULT='$val'" if $val && $val !~ /\'/;
	$filter .= " DEFAULT=\"$val\"" if $val && $val =~ /\'/;
	$filter .= " -->";
	    
	my $input = $text;
	DWT2HTML( \$input );
	ok( $input, $filter );
	
	$input = $text;
	DWT2HTMLExpr( \$input );
	ok( $input, $filter );
    }
}

# Test transform of TemplateBeginIf with no expression syntax
$text = <<EOF;
<!-- TemplateBeginIf cond="_document['FOO']" -->
<!-- TemplateBeginIf cond="!_document['FOO']" -->
<!-- TemplateBeginIf cond="BAR" -->
<!-- TemplateBeginIf cond="!BAR" -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
EOF

DWT2HTML( \$text );
$filter = <<EOF;
<TMPL_IF NAME="FOO">
<TMPL_UNLESS NAME="FOO">
<TMPL_IF NAME="BAR">
<TMPL_UNLESS NAME="BAR">
</TMPL_UNLESS>
</TMPL_IF>
</TMPL_UNLESS>
</TMPL_IF>
EOF
ok( $text, $filter );

# Test transform of TemplateBeginIf with expression syntax
$text = <<EOF;
<!-- TemplateBeginIf cond="_document['FOO'] > 5" -->
<!-- TemplateBeginIf cond="BAR == 4" -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
EOF

DWT2HTMLExpr( \$text );
$filter = <<EOF;
<TMPL_IF EXPR="FOO > 5">
<TMPL_IF EXPR="BAR == 4">
</TMPL_IF>
</TMPL_IF>
EOF
ok( $text, $filter );

# Test transform of TemplateBeginIf with expression syntax and a text parameter
$text = <<EOF;
<!-- TemplateParam name="FOO" type="text" value="" -->
<!-- TemplateBeginIf cond="FOO == 'BAR'" -->
<!-- TemplateBeginIf cond="FOO != 'BAR'" -->
<!-- TemplateBeginIf cond="FOO <=> 'BAR'" -->
<!-- TemplateBeginIf cond="FOO >= 'BAR'" -->
<!-- TemplateBeginIf cond="FOO > 'BAR'" -->
<!-- TemplateBeginIf cond="FOO <= 'BAR'" -->
<!-- TemplateBeginIf cond="FOO < 'BAR'" -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
<!-- TemplateEndIf -->
EOF

DWT2HTMLExpr( \$text );
$filter = <<EOF;
<TMPL_IF EXPR="FOO eq 'BAR'">
<TMPL_IF EXPR="FOO ne 'BAR'">
<TMPL_IF EXPR="FOO cmp 'BAR'">
<TMPL_IF EXPR="FOO ge 'BAR'">
<TMPL_IF EXPR="FOO gt 'BAR'">
<TMPL_IF EXPR="FOO le 'BAR'">
<TMPL_IF EXPR="FOO lt 'BAR'">
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
EOF
ok( $text, $filter );

$text = <<EOF;
<!-- TemplateBeginMultipleIf -->
<!-- TemplateBeginIfClause cond="FOO == 1" --> 1
<!-- TemplateEndIfClause -->
<!-- TemplateBeginIfClause cond="FOO == 2" --> 2
<!-- TemplateEndIfClause -->
<!-- TemplateBeginIfClause cond="FOO == 3" --> 3
<!-- TemplateEndIfClause -->
<!-- TemplateBeginIfClause cond="FOO == 4" --> 4
<!-- TemplateEndIfClause -->
<!-- TemplateEndMultipleIf -->
EOF
$filter = <<EOF;

<TMPL_IF EXPR="FOO == 1"> 1
<TMPL_ELSE>
<TMPL_IF EXPR="FOO == 2"> 2
<TMPL_ELSE>
<TMPL_IF EXPR="FOO == 3"> 3
<TMPL_ELSE>
<TMPL_IF EXPR="FOO == 4"> 4
<TMPL_ELSE>
</TMPL_IF></TMPL_IF></TMPL_IF></TMPL_IF>
EOF

DWT2HTMLExpr( \$text );
ok( $text, $filter );

# Test transform of IgnoreTemplateBeginIf with no expression syntax
$text = <<EOF;
<!-- IgnoreTemplateBeginIf cond="_document['FOO']" -->
<!-- IgnoreTemplateBeginIf cond="!_document['FOO']" -->
<!-- IgnoreTemplateBeginIf cond="BAR" -->
<!-- IgnoreTemplateBeginIf cond="!BAR" -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
EOF

DWT2HTML( \$text );
$filter = <<EOF;
<TMPL_IF NAME="FOO">
<TMPL_UNLESS NAME="FOO">
<TMPL_IF NAME="BAR">
<TMPL_UNLESS NAME="BAR">
</TMPL_UNLESS>
</TMPL_IF>
</TMPL_UNLESS>
</TMPL_IF>
EOF
ok( $text, $filter );

# Test transform of IgnoreTemplateBeginIf with expression syntax
$text = <<EOF;
<!-- IgnoreTemplateBeginIf cond="_document['FOO'] > 5" -->
<!-- IgnoreTemplateBeginIf cond="BAR == 4" -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
EOF

DWT2HTMLExpr( \$text );
$filter = <<EOF;
<TMPL_IF EXPR="FOO > 5">
<TMPL_IF EXPR="BAR == 4">
</TMPL_IF>
</TMPL_IF>
EOF
ok( $text, $filter );

# Test transform of IgnoreTemplateBeginIf with expression syntax and a text parameter
$text = <<EOF;
<!-- TemplateParam name="FOO" type="text" value="" -->
<!-- IgnoreTemplateBeginIf cond="FOO == 'BAR'" -->
<!-- IgnoreTemplateBeginIf cond="FOO != 'BAR'" -->
<!-- IgnoreTemplateBeginIf cond="FOO <=> 'BAR'" -->
<!-- IgnoreTemplateBeginIf cond="FOO >= 'BAR'" -->
<!-- IgnoreTemplateBeginIf cond="FOO > 'BAR'" -->
<!-- IgnoreTemplateBeginIf cond="FOO <= 'BAR'" -->
<!-- IgnoreTemplateBeginIf cond="FOO < 'BAR'" -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
<!-- IgnoreTemplateEndIf -->
EOF

$filter = <<EOF;
<TMPL_IF EXPR="FOO eq 'BAR'">
<TMPL_IF EXPR="FOO ne 'BAR'">
<TMPL_IF EXPR="FOO cmp 'BAR'">
<TMPL_IF EXPR="FOO ge 'BAR'">
<TMPL_IF EXPR="FOO gt 'BAR'">
<TMPL_IF EXPR="FOO le 'BAR'">
<TMPL_IF EXPR="FOO lt 'BAR'">
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
</TMPL_IF>
EOF
DWT2HTMLExpr( \$text );
ok( $text, $filter );

# Test transform of TemplateBeginRepeat
$text = <<EOF;
<!-- TemplateBeginRepeat name="FOO" -->
<!-- TemplateBeginIf cond="_isFirst" -->FOO<!-- TemplateEndIf -->
@@(_index)@@
<!-- TemplateBeginIf cond="_isLast" -->FOO<!-- TemplateEndIf -->
<!-- TemplateEndRepeat -->
EOF

$filter = <<EOF;
<TMPL_LOOP NAME="FOO">
<TMPL_IF NAME="__FIRST__">FOO</TMPL_IF>
<!-- TMPL_VAR NAME='__COUNTER__' -->
<TMPL_IF NAME="__LAST__">FOO</TMPL_IF>
</TMPL_LOOP>
EOF

DWT2HTML( \$text );
ok( $text, $filter );

# Test transform of ternary variables
$text = <<EOF;
@@(foo ? <b> : <i>)@@
EOF

$filter = <<EOF;
<TMPL_IF NAME='foo'><b><TMPL_ELSE><i></TMPL_IF>
EOF

DWT2HTML( \$text );
ok( $text, $filter );

$text = <<EOF;
@@(foo > 5 ? <b> : <i>)@@
EOF

$filter = <<EOF;
<TMPL_IF EXPR='foo > 5'><b><TMPL_ELSE><i></TMPL_IF>
EOF

DWT2HTMLExpr( \$text );
ok( $text, $filter );



$text = <<EOF;
<!-- TemplateParam name="foo" type="text" value="" -->
@@(foo=='bar' ? <b> : <i>)@@
EOF

$filter = <<EOF;
<TMPL_IF EXPR="foo eq 'bar'"><b><TMPL_ELSE><i></TMPL_IF>
EOF

DWT2HTMLExpr( \$text );
ok( $text, $filter );



