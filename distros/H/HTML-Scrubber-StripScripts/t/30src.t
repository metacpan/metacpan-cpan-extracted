
use strict;
use Test::More tests => 40;

BEGIN { $^W = 1 }

use_ok( 'HTML::Scrubber::StripScripts' );

use vars qw($s);

$s = HTML::Scrubber::StripScripts->new( Allow_src => 1 );
isa_ok($s, 'HTML::Scrubber');

test( 'hello <foo>', 'hello ', 'remove unknown tag' );
test( 'hello <i foo=foo>', 'hello <i>', 'remove unknown attr' );

test( '<html><head><title>hello</title></head><body bgcolor="pink">foo</body></html>',
      'hellofoo', 'whole doc');

test( '<a href="http://www.example.com/">', '<a>', 'a href' );
test( '<a href="mailto:foo@example.com">', '<a>', 'a mailto' );
test( '<q cite="http://www.example.com/">', '<q>', 'q cite' );
test( '<q cite="mailto:foo@example.com">', '<q>', 'q cite mailto' );
test( '<blockquote cite="http://www.example.com/">', '<blockquote>', 'blockquote cite' );
test( '<blockquote cite="mailto:foo@example.com">', '<blockquote>', 'blockquote cite mailto' );

test( '<img src="javascript:alert">', '<img>', 'img src javascript' );
test( '<img src="about:foo">', '<img>', 'img src about' );
test( '<img src="http://www.example.com/">', '<img src="http://www.example.com/">', 'img src' );
test( '<img src="http://www.example.com/cgi-bin/foo?asdf=asdf;fs=sdf&asdf=&$#54">',
      '<img src="http://www.example.com/cgi-bin/foo?asdf=asdf;fs=sdf&amp;asdf=&amp;$#54">',
      'img src query' );
test( '<img src="https://www.example.com/cgi-bin/foo">', '<img src="https://www.example.com/cgi-bin/foo">', 'img src https' );
test( '<img src="HTTPS://WWW.EXAMPLE.COM/CGI-BIN/FOO">', '<img src="HTTPS://WWW.EXAMPLE.COM/CGI-BIN/FOO">', 'img src caps' );
test( '<img src="ftp://ftp.example.com/foo.gif">', '<img src="ftp://ftp.example.com/foo.gif">', 'img src ftp' );
test( '<img src="/images/foo.gif">', '<img src="/images/foo.gif">', 'img src abs local part' );
test( '<img src="foo.gif">', '<img src="foo.gif">', 'img src rel local part' );
test( '<img src="../images/foo.gif">', '<img src="../images/foo.gif">', 'img src .. local part' );
test( '<table background="http://www.example.com/">', '<table background="http://www.example.com/">', 'table background' );
test( '<body background="http://www.example.com/">', '', 'body background' );

test( '<?php foo ?>', '', 'process' );
test( '<!-- foo -->', '', 'comment' );
test( '<!--# foo -->', '', 'ssi' );

test( '<font color="pink">', '<font color="pink">', 'font color pink' );
test( '<font color="#FFFFFF">', '<font color="#FFFFFF">', 'font color FFFFFF' );
test( '<font color="#FFFFFFF">', '<font>', 'font color one F too many' );
test( '<font color="!!">', '<font>', 'font color !!' );

test( '<font size="12">', '<font size="12">', 'font size 12' );
test( '<font size="+1">', '<font size="+1">', 'font size +2' );
test( '<font size="-1">', '<font size="-1">', 'font size -1' );
test( '<font size="pink">', '<font>', 'font size pink' );

test( '<font face="gothic">', '<font face="gothic">', 'font face gothic' );
test( '<font face="gothic, courier">', '<font face="gothic, courier">', 'font face gothic,courier' );
test( '<font face="?$(&$%(">', '<font>', 'font face ?$(&$%(' );

test( '<img alt="some alt text !!!!">', '<img alt="some alt text !!!!">', 'img alt' );

my $alltags = <<END;
<br><em><strong><dfn><code><samp><kbd><var><cite><abbr><acronym><q>
<blockquote><sub><sup><tt><i><b><big><small><u><s><strike><font>
<table><caption><colgroup><col><thead><tfoot><tbody><tr><th><td>
<ins><del><a><h1><h2><h3><h4><h5><h6><p><div><span><ul><ol><li><dl>
<dt><dd><address><hr><pre><center><nobr><img>
END
test( $alltags, $alltags, 'open all permitted tags' );

$alltags =~ s#<#</#g;
test( $alltags, $alltags, 'close all permitted tags' );

sub test {
    my ($in, $out, $name) = @_;

    is( $s->scrub($in), $out, "src $name" );
}

