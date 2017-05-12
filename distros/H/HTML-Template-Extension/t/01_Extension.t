# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok " . ++$testid . "\n" unless $loaded;}

use HTML::Template::Extension;
use HTML::Template::Extension::ObjBase;


# Create test obj with support for doing nothing but standart:=)
# DON'T USE DO_NOTHING...IT'S ONLY AN BASE EXTENSION MODULE FOR CREATING NEW ONES
my $comp		= new HTML::Template::Extension(		
											filename => 'templates/standard.tmpl',
											plugins=>["DO_NOTHING"],
						);
						
$comp->param('test' => "It works!!!");
$_ = $comp->output;
print;

if (m/It works/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}


## Standard HTML::Template use with support for <TMPL_VAR>..</TMPL_VAR>
$comp->plugin_add("SLASH_VAR");
$comp->filename('templates/simple.tmpl');
$comp->param('test' => "It works!!!");
$_ = $comp->output;
print;

if (m/It works/ && !m/placeholder/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# Advanced output method use
$_ = $comp->output(as => {'test' => "It works!!!"});
print;

if (m/It works/ && !m/placeholder/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# check vanguard mode
$_ = $comp->html({'test' => "It works!!!"},'templates/simple_vanguard.tmpl');
print;

if (m/It works/ && m/vanguard/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# html method use and replacing filename
$_ = $comp->html({'test' => "It works!!!"},'templates/simple_html.tmpl');
print;

if (m/It works/ && !m/placeholder/ && m/\<HTML\>/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# ...again to check caching
$_ = $comp->html({'test' => "It works!!!"},'templates/simple_html.tmpl');
print;

if (m/It works/ && !m/placeholder/ && m/\<HTML\>/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# ...check autoDeleteHeader
$comp->plugin_add("HEAD_BODY");
$comp->autoDeleteHeader(1);
$_ = $comp->html({'test' => "It works!!!"},'templates/simple_html.tmpl');
print;
print $comp->header;

if (m/It works/ && !m/placeholder/ && !m/\<HTML\>/ && $comp->header=~m/\<HTML\>/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# check js_header
$comp->autoDeleteHeader(1);
$_ = $comp->html({'test' => "It works!!!"},'templates/html_js.tmpl');
print;
$_ = $comp->header_js;
print;

if (m/doNothing/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# check header_css
$comp->autoDeleteHeader(1);
$_ = $comp->html({'test' => "It works!!!"},'templates/html_js.tmpl');
$_ = $comp->header_css;
print;
if (m/\.body/) {
        print "\nok " . ++$testid . "\n";
} else {
    exit;
}
#check header_tokens
$comp->autoDeleteHeader(1);
$_ = $comp->html({'test' => "It works!!!"},'templates/html_js.tmpl');
$_ = $comp->header_tokens->{meta};
print Data::Dumper::Dumper($_);
$_ = $_->[1]->[0];
print ;
if (m/windows\-1252/) {
        print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# check support for TMPL_DOC tag
$comp->autoDeleteHeader(0);
$comp->plugin_add("DOC");
$_ = $comp->html({'test' => "It works!!!"},'templates/html_doc.tmpl');
print;

if (!m/comment/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# check support for TMPL_CSTART tag
$comp->plugin_add("CSTART");
$_ = $comp->html({'test' => "It works!!!"},'templates/html_cstart.tmpl');
print;

if (!m/BAD/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# check support for IF_TERN plug-in
$comp->plugins_clear;
$comp->plugin_add("IF_TERN");
$_ = $comp->html({'test' => 1},'templates/if_tern.tmpl');
print;

if (!m/BAD/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# check ObjBase

my $base = new HTML::Template::Extension::ObjBase;

$comp->plugin_add($base);

$_ = $comp->html({'test' => 1},'templates/if_tern.tmpl');

print;


if (!m/BAD/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}


# try to remove IF_TERN plug-in

$comp->plugin_remove('IF_TERN');
$_ = $comp->html({'test' => 1},'templates/if_tern.tmpl');
print;
if (m/BAD/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}

# check support for TAG_ATTRIBUTE_NORMALIZER plug-in
$comp->plugins_clear;
$comp->plugin_add("SLASH_VAR");
$comp->plugin_add("TAG_ATTRIBUTE_NORMALIZER");
$_ = $comp->html({'test' => 'It works!!!'},'templates/tag_normalizer.tmpl');
print;

if (m/It works/) {
	print "\nok " . ++$testid . "\n";
} else {
    exit;
}


$loaded = 1;

1;
