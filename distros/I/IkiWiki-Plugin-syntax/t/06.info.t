#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::File;

use lib qw(lib t/lib);
use IkiWiki q(2.0);
use MyTestTools qw(:all);

my @engines = MyTestTools::Engines();

# open the output example file
my $file = "examples/plugin-info.html";
if (not ResultsFile($file)) {
    plan( skip_all => "Could not write to the ${file} file" );
}
else {
    plan( tests => (scalar @engines + 1));
}

use_ok("IkiWiki::Plugin::syntax");

my $info_header = <<EOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<HTML> 
<HEAD>
    <TITLE>Information about the backends</TITLE>
    <STYLE type="text/css">
        table {
            border:     solid 1px green;
            margin:     1em;
            }
        thead {
        background: gray;
        color: white;
        text-align: center;
        }
    </STYLE>
</HEAD>
<BODY>
EOF
my $info_footer = <<EOF;
</BODY>
</HTML>
EOF

my $info_fh = ResultsFile();
$info_fh->print($info_header);

ENGINES: 
foreach my $engine (@engines) {
    $IkiWiki::config{syntax_engine} = $engine;

    eval {
        IkiWiki::Plugin::syntax::checkconfig();
    };

    if ($@) {
        fail "load the plugin ${engine}";
        next ENGINES;
    }

    # call the preprocess function without parameters to obtain the 
    # HTML information
    my $plugin_info = eval { 
        IkiWiki::Plugin::syntax::preprocess();
    };

    if ($@) {
        fail ("extended information about ${engine} - ${@}");
        next ENGINES;
    }
    else {
        $info_fh->print($plugin_info);
        pass ("extended information about ${engine}");
    }
}

$info_fh->print($info_footer);
$info_fh->close();


