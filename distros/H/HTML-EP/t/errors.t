# -*- perl -*-

use strict;


use HTML::EP ();
use HTML::EP::Config ();
use Getopt::Long ();

use vars qw($opt_debug);
Getopt::Long::GetOptions('debug');


$HTML::EP::Config::CONFIGURATION->{'ok_templates'} = '.ep';
$HTML::EP::Config::CONFIGURATION->{'debug_hosts'} = '127.0.0.1';


print "1..3\n";


{
    my $numTests = 0;
    sub Test($;@) {
	my $result = shift;
	if (@_ > 0) { printf(@_); }
	++$numTests;
	if (!$result) { print "not " };
	print "ok $numTests\n";
	$result;
    }
}

sub Test2($$;@) {
    my $a = shift;
    my $b = shift;
    $a =~ s/\d+/1/sg;
    $b =~ s/\d+/1/sg;

    # ActivePerl prints the full path of the error location rather
    # than the relative path...
    $a =~ s/\S:\/.*?\/blib\/lib/blib\/lib/m;
    my $c = ($a eq $b);
    if (!Test($c, @_)) {
	printf("Expected:\n%s\nGot:\n%s\n", unpack("H*", $b),
	       unpack("H*", $a));
	printf("Ascii:\n$b\nvs.\n$a\n");
    }
    $c;
}

sub Test3($$;@) {
    my $a = shift;
    my $b = shift;
    my $c;
    require Symbol;
    {
	local $| = 1;
	my $fh = Symbol::gensym();
	open($fh, ">foo.ep") || die "Cannot create file 'foo.ep': $!";
	((print $fh $a) && close($fh))
	    or die "Error while writing 'foo.ep': $!";
    }
    $ENV{PATH_TRANSLATED} = 'foo.ep';
    $ENV{SERVER_ADMIN} = 'root@ispsoft.de';
    my $inc = '';
    foreach my $i (@INC) {
	$inc .= " -I$i";
    }
    if (!open(PIPE, "$^X $inc ep.cgi |")) {
	die "Cannot create pipe: $!";
    }
    local $/ = undef;
    $c = <PIPE>;
    close(PIPE);
    Test2($c, $b, @_);
}




$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'} = $opt_debug ? 'debug=1' : '';
$ENV{'REMOTE_ADDR'} = '127.0.0.1';


my $parser = HTML::EP->new();
Test($parser, "Creating the parser.\n");

my $input = <<'END_OF_HTML';
<HTML><ep-error>Something strange happened!</ep-error></HTML>
END_OF_HTML

my $output = <<'END_OF_HTML';
content-type: text/html

<HTML><HEAD><TITLE>Fatal internal error</TITLE></HEAD>
<BODY><H1>Fatal internal error</H1>
<P>An internal error occurred. The error message is:</P>
<PRE>
Something strange happened! at blib/lib/HTML/EP.pm line 7.
.
</PRE>
<P>Please contact the <A HREF="mailto:root@ispsoft.de">Webmaster</A> and tell him URL, time and error message.</P>
<P>We apologize for any inconvenience, please try again later.</P>
<BR><BR><BR>
<P>Yours sincerely</P>
</BODY></HTML>
END_OF_HTML
Test3($input, $output, "Simple error.\n");

$input = <<'END_OF_HTML';
<HTML>
<ep-errhandler><HTML>Oops: $errmsg$</HTML>
</ep-errhandler><ep-error>So what!</ep-error></HTML>
END_OF_HTML

$output = <<'END_OF_HTML';
content-type: text/html

<HTML>Oops: So what! at blib/lib/HTML/EP.pm line 7.
</HTML>
END_OF_HTML
Test3($input, $output, "Error template.\n");


unlink "foo.ep";
