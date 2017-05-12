# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'


require 5.006;
use strict;
use warnings;


use Test;
BEGIN { plan tests => 165 };

use vars qw($module $class $ok $skip);

# The name of the module to test.
$module = 'HTML::Template::HTX';

# The class of objects the module creates (usually the name of the module).
$class = $module;


use FileHandle;

use vars qw($htx $fh $template_file $template_scalar $output_scalar $expected_output);

# The .htx template file used for testing.
$template_file = 'template.htx';

# Read the template in memory and the expected output.
($template_scalar, $expected_output) = split(/__MOREDATA__\n/o, join('', <DATA>));
close(DATA);


# Load the HTML::Template::HTX module.
eval "use $module;";
ok(!$@) or die;
ok(eval '$'.$class.'::VERSION == 0.07');
die if($@);

# Open a template file with output to STDOUT.
undef $htx;
$skip = !-e $template_file;
skip($skip, defined(eval "\$htx = $class->new(\$template_file);"));
die if($@);
skip($skip, ref($htx) eq $class);
skip($skip, ($htx and UNIVERSAL::isa($htx->{_file}, 'GLOB')));
skip($skip, ($htx and (fileno($htx->{_output}) == fileno(STDOUT))));

# Close the template file.
skip($skip, ($htx and $htx->close));

# "Open" a template in an open file handle using named parameters.
undef $htx;
$fh = new FileHandle '<&STDIN' or die;
ok(defined(eval "\$htx = $class->new(filename => \$fh);"));
die if($@);
ok(fileno($htx->{_file}) == fileno($fh));
ok(!$htx->{_utf8}); # Test UTF-8 with named parameters
ok($htx->detail_section eq ''); # Detail section should still be nameless
$htx->close;
ok(close($fh));

# "Open" a template in memory with output to a file.
undef $htx;
ok(defined(eval "\$htx = $class->new(\\\$template_scalar, '&STDERR');"));
die if($@);
ok(ref($htx->{_file}) eq 'SCALAR');
ok($htx->{_file} == \$template_scalar);
ok($htx and UNIVERSAL::isa($htx->{_output}, 'GLOB'));

# By default UTF-8 coding should be disabled.
ok(!$htx->{_utf8});

# Close the template file by destroying the object.
ok(!defined(undef $htx));

# "Open" a template in memory with output to a file handle.
undef $htx;
$fh = new FileHandle '>&STDERR' or die;
ok(defined(eval "\$htx = $class->new(\\\$template_scalar, \$fh);"));
die if($@);
ok(fileno($htx->{_output}) == fileno($fh));
$htx->close;
ok(close($fh));

# "Open" a template in memory with output to a scalar using named
# parameters.
undef $htx;
undef $output_scalar;
ok(defined(eval "\$htx = $class->new(template => \\\$template_scalar, output => \\\$output_scalar, -utf8);"));
die if($@);
ok(ref($htx->{_output}) eq 'SCALAR');
ok($htx->{_output} == \$output_scalar);
ok($output_scalar eq '');

# UTF-8 coding should now be enabled.
ok($htx->{_utf8});

# Disable and enable UTF-8 coding again and again.
$htx->utf8('');
ok(!$htx->{_utf8});
$htx->utf8;
ok($htx->{_utf8});
$htx->utf8(1);
ok($htx->{_utf8});
$htx->utf8(0);
ok(!$htx->{_utf8});

# Define a user defined parameter.
ok(!defined($htx->param('Count')));
$htx->param('Count' => '?');
ok($htx->param('Count') eq '?');

# Redefine a user defined parameter.
$htx->param('Count' => 29);
ok($htx->param('Count') == 29);

# Define a set of user defined parameters.
ok(!($htx->param('Module') or $htx->param('Class') or $htx->param('Script')));
$htx->param(
  'Module' => $module,
  'Class'  => $class,
  'Script' => __FILE__,
);
ok($htx->param('Module') and $htx->param('Class') and $htx->param('Script'));

# Get a list of names of user defined parameters.
{
  my @params = $htx->param;
  ok(join(' ', sort @params) eq 'Class Count Module Script');
}

# Print the header of the template, HTTP header included the first time.
ok($htx->print_header(1) eq 'LIST');
ok($htx->detail_section eq 'LIST');
ok($output_scalar =~ m#^Content-Type: text/html\n\n#o);
$output_scalar = '';
ok($htx->print_header(1) == 1);
ok($htx->detail_section eq '');
ok($output_scalar !~ m#^Content-Type:#o);
$output_scalar = '';
ok($htx->print_header eq 'SPONSORS');
ok($htx->detail_section eq 'SPONSORS');
ok($output_scalar !~ m#^Content-Type:#o);
ok(!$htx->print_header);

# "Open" a template in memory with output *appended* to a scalar.
undef $htx;
$output_scalar = 'Not empty';
ok(defined(eval "\$htx = $class->new(\\\$template_scalar, \\\$output_scalar);"));
die if($@);
ok($output_scalar ne '');
ok($htx->print_header eq 'LIST'); # Template header without HTTP header
ok($output_scalar =~ s/^Not empty//o);
ok($output_scalar !~ m#^Content-Type:#o);

# "Open" a template in memory with output to a scalar...
undef $htx;
$output_scalar = '';
ok(defined(eval "\$htx = $class->new(\\\$template_scalar, \\\$output_scalar);"));
die if($@);
# ... and print a template header with a customized content type.
ok($htx->print_header('text/html; charset=ISO-8859-1') eq 'LIST');
ok($output_scalar =~ m#^Content-Type: text/html; charset=ISO-8859-1\n\n#o);

# "Open" a template in memory with output to a scalar...
undef $htx;
$output_scalar = '';
ok(defined(eval "\$htx = $class->new(\\\$template_scalar, \\\$output_scalar);"));
die if($@);
# ... and print a template header with a fully customized HTTP header.
ok($htx->print_header("Content-Type: text/html\nX-Powered-By: Perl\n\n") eq 'LIST');
ok($output_scalar =~ m#^Content-Type: text/html\nX-Powered-By: Perl\n\n#o);

# "Open" a template in memory with output to a scalar...
undef $htx;
$output_scalar = '';
ok(defined(eval "\$htx = $class->new(\\\$template_scalar, \\\$output_scalar);"));
die if($@);
# ... and print a template footer with UTF-8 enabled.
$htx->utf8;
$htx->print_footer(1);
ok($output_scalar =~ m#^Content-Type: text/html; charset=utf-8\n\n#o);
ok(!$htx->print_header);
ok($output_scalar =~ m#</BODY></HTML>$#o);

# Set and retrieve the detail section name.
$htx->detail_section('');
ok($htx->detail_section eq '');
$htx->detail_section('PRODUCTS');
ok($htx->detail_section eq 'PRODUCTS');

# Include a file inside the template.
{
  my $fragment = '';
  $skip = !-e $template_file;
  skip($skip, $htx->_include($template_file, \$fragment, \'PreMatch', \'PostMatch'));
  skip($skip, length($fragment) > length('PreMatchPostMatch'));
  ok($fragment =~ /^PreMatch.*PostMatch$/os);
}

# Parse a couple of HTX variables and constants.
$htx->param(
  'Count'  => 29,
  'Module' => $module,
  #'Class'  => $class, # Not defined, as part of the test
  'Script' => '',
);
ok($htx->_express('"Module"') eq 'Module');
ok($htx->_express('29.3010') == 29.3010);
ok($htx->_express('Module') eq $module);
ok($htx->_express('Script') eq '');
ok($htx->_express('Class') eq '');
ok($htx->_express('Count') == 29);
$skip = !$ENV{'PATH'};
skip($skip, $htx->_express('PATH') eq $ENV{'PATH'});

# Evaluate a couple of expressions.
ok($htx->_evaluate('Count eq 29'));
ok($htx->_evaluate('Count gt 28.999'));
ok($htx->_evaluate('Count ge 29'));
ok($htx->_evaluate('Count lt 29.001'));
ok($htx->_evaluate('Count le 29'));
ok($htx->_evaluate('Count ne 30'));
ok($htx->_evaluate('Count ne "String"'));
ok($htx->_evaluate("Module eq \"$module\""));
ok($htx->_evaluate("Module eq \"\L$module\E\""));
ok($htx->_evaluate('Class isempty'));
ok($htx->_evaluate('Script isempty'));
ok($htx->_evaluate('Module istypeeq Class'));
ok($htx->_evaluate('Module contains "htx"'));

# Encode a couple of values.
$ok = ($htx->_encode('"Chester & Casey"', 'html') eq 'Chester &amp; Casey');
skip(!$ok, $ok);
$ok = ($htx->_encode('"Chester & Casey"', 'url') eq 'Chester%20%26%20Casey');
skip(!$ok, $ok);
$htx->param('Java' => "\"Chester & Casey\"\r\n");
ok($htx->_encode('Java', 'js') eq '\\"Chester & Casey\\"\\r\\n');
ok($htx->_encode('Java', 'scramble') ne '');
ok($htx->_encode('Module') eq $module);

# Parse a couple of HTX fragments.
{
  my $fragment = 'Fancy rat<%EscapeRaw "s Chester &"%> Casey';
    ok($htx->_parse(\$fragment));
    ok($fragment eq 'Fancy rats Chester & Casey');
  $fragment = '<%EscapeHTML "Chester & "%>Casey';
    ok($htx->_parse(\$fragment));
    ok($fragment eq 'Chester &amp; Casey');
  $fragment = 'Chester <%EscapeURL "& Casey"%>';
    ok($htx->_parse(\$fragment));
    ok($fragment eq 'Chester %26%20Casey');
  $fragment = 'document.write("<%EscapeJS Java%>");';
    ok($htx->_parse(\$fragment));
    ok($fragment eq 'document.write("\\"Chester & Casey\\"\\r\\n");');
  $fragment = '<%EscapeScramble "niessink@martinic.nl"%>");';
    ok($htx->_parse(\$fragment));
    ok(length($fragment) > length('niessink@martinic.nl'));
  $fragment = 'Include this <%include %>!'; # Not a valid file name
    ok($htx->_parse(\$fragment));
    ok($fragment eq 'Include this !');
  $fragment = '<%if Count lt 30%>Young';
    ok($htx->_parse(\$fragment));
    ok($fragment eq 'Young');
  $fragment = '<%endif%><%if Count lt 30%>Young<%else%>Old';
    ok(!$htx->_parse(\$fragment));
    ok($fragment eq 'Young');
  $fragment = '<%endif%><%if Count ge 20%>Old<%else%>Young<%endif%>';
    ok($htx->_parse(\$fragment));
    ok($fragment eq 'Old');
  $fragment = '<%Module%>';
    ok($htx->_parse(\$fragment));
    ok($fragment eq $module); # HTML encoding shouldn't do much in this case
}

# Parse a couple of UTF-8 and non-UTF-8 HTX fragments.
{
  use bytes; # Apparently required for ActiveState Perl build 631
  my($utf8, $fragment);
  $htx->param(
    'Copyright' => "\xA9 MARTINIC",
    'CopyUTF8'  => "\x{A9} MARTINIC",
  );
  $skip = $] < 5.006;
  if(($] >= 5.006) and ($] < 5.008)) {
    $utf8 = "\x{A9} MARTINIC";
  } else {
    $utf8 = "\xC2\xA9 MARTINIC";
  }
  $htx->utf8(1);
  $fragment = '<%EscapeRaw Copyright%>';
    ok($htx->_parse(\$fragment));
    skip($skip, $fragment eq $utf8);
  $fragment = '<%EscapeRaw CopyUTF8%>';
    ok($htx->_parse(\$fragment));
    skip($skip, $fragment eq $utf8);
  $fragment = '<%EscapeRaw Copyright%> <%EscapeRaw CopyUTF8%>';
    ok($htx->_parse(\$fragment));
    skip($skip, $fragment eq "$utf8 $utf8");
  $fragment = "\xA9 MARTINIC";
    ok($htx->_parse(\$fragment));
    ok($fragment eq "\xA9 MARTINIC");
  $fragment = "\xC2\xA9 MARTINIC";
    ok($htx->_parse(\$fragment));
    ok($fragment eq "\xC2\xA9 MARTINIC");
  $htx->utf8(0);
  $fragment = '<%EscapeRaw Copyright%>';
    ok($htx->_parse(\$fragment));
    skip($skip, $fragment eq "\xA9 MARTINIC");
  $fragment = '<%EscapeRaw CopyUTF8%>';
    ok($htx->_parse(\$fragment));
    skip($skip, $fragment eq "\xA9 MARTINIC");
  $fragment = '<%EscapeRaw Copyright%> <%EscapeRaw CopyUTF8%>';
    ok($htx->_parse(\$fragment));
    skip($skip, $fragment eq "\xA9 MARTINIC \xA9 MARTINIC");
  $fragment = "\xA9 MARTINIC";
    ok($htx->_parse(\$fragment));
    ok($fragment eq "\xA9 MARTINIC");
  $fragment = "\xC2\xA9 MARTINIC";
    ok($htx->_parse(\$fragment));
    ok($fragment eq "\xC2\xA9 MARTINIC");
}

# Print (and parse) a couple of strings.
$output_scalar = '';
ok($htx->_print(\'Chester & Casey'));
ok($output_scalar eq 'Chester & Casey');
$output_scalar = '';
ok($htx->_print('<%EscapeHTML "Chester &"%> Casey'));
ok($output_scalar eq 'Chester &amp; Casey');

# By default no common parameters should be defined.
ok(!defined($htx->param('COUNT')));
ok(!defined($htx->param('DATE')));

# Define the automated counter parameters.
$htx->common_params(-count);
ok(defined($htx->param('COUNT')));
ok(!defined($htx->param('DATE')));

# Define the date/time parameters.
$htx->common_params(-date);
ok(defined($htx->param('DATE')));
ok($htx->param('GMT_TIME_ZONE') eq 'GMT');
{
  my $epoch = time;
  $htx->common_params(-date => $epoch);
  my $date = localtime($epoch);
  ok($htx->param('DATE') eq sprintf("%02d" , substr($date, 8, 2)).' '.substr($date, 4, 3).' '.substr($date, 20, 4));
}

# Now, lets do a "live" test.
undef $htx;
undef $output_scalar;
ok(defined(eval "\$htx = $class->new(\\\$template_scalar, \\\$output_scalar, -count, -date);"));
die if($@);
ok(defined($htx->param('COUNT'))); # With automated counters
ok(defined($htx->param('DATE'))); # With date/time parameters
$htx->param(
  #'Version' => '?',
  'Module'   => $module,
  'Class'    => $class,
  'Script'   => __FILE__,
);
while(my $section = $htx->print_header(1)) {
  if($section eq 'SPONSORS') {
    ok($htx->param('SECTION') eq $section);
    $htx->common_params(-count => '');
    my %sponsors = (
      'MARTINIC' => 'http://www.martinic.nl/',
      'Tale'     => 'http://www.tanetn.com/',
    );
    my $count = 0;
    foreach(sort keys %sponsors) {
      $htx->param(
        'Count' => ++$count,
        'Name'  => $_,
        'URL'   => $sponsors{$_},
      );
      $htx->print_detail;
    }
    ok($htx->param('COUNT') == 0);
  }
  if($section eq 'LIST') {
    ok($htx->param('SECTION') eq $section);
    my $count = 0;
    foreach(qw(An' now people just get uglier an' I have no sense of time)) {
      $htx->param(
        'Count' => ++$count,
        'Item'  => $_,
      );
      $htx->print_detail;
      ok($htx->param('COUNT') == $count);
    }
    ok($htx->param('COUNT?') == $count%2);
    next;
  }
}
ok($htx->param('TOTAL') == 13);
ok($htx->param('TOTAL?') == 13%2);
$htx->close;
ok($output_scalar eq $expected_output);

# Ready!
exit 0;

__DATA__
<%else%>These are remarks, which will not appear in the output.<%endif%>
<HTML><HEAD><TITLE>Test</TITLE>

</HEAD><BODY>

 <H1>Test <%Class%><%if Version isempty%><%else%> v<%Version%><%endif%></H1>

<%detailsection LIST%><%begindetail%> <%Count%>. <%EscapeHTML Item%><BR>
<%enddetail%>

<%begindetail%>This nameless detail section should not appear in the output<%enddetail%>

 <%detailsection SPONSORS%>
 <H3>Sponsors</H3>
 <%begindetail%><%if Count gt 1%>, <%endif%><%if URL isempty%><%Name%><%else%><A HREF="<%EscapeRaw URL%>"><%Name%></A><%endif%><%enddetail%>

 <HR>
 &copy; <A HREF="http://www.martinic.nl/"><%EscapeHTML "MARTINIC Computers"%></A> 2005

</BODY></HTML>
__MOREDATA__
Content-Type: text/html


<HTML><HEAD><TITLE>Test</TITLE>

</HEAD><BODY>

 <H1>Test HTML::Template::HTX</H1>

 1. An'<BR>
 2. now<BR>
 3. people<BR>
 4. just<BR>
 5. get<BR>
 6. uglier<BR>
 7. an'<BR>
 8. I<BR>
 9. have<BR>
 10. no<BR>
 11. sense<BR>
 12. of<BR>
 13. time<BR>




 
 <H3>Sponsors</H3>
 <A HREF="http://www.martinic.nl/">MARTINIC</A>, <A HREF="http://www.tanetn.com/">Tale</A>

 <HR>
 &copy; <A HREF="http://www.martinic.nl/">MARTINIC Computers</A> 2005

</BODY></HTML>
