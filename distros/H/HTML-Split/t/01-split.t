use strict;
use Test::Base tests => 14;
use HTML::Split;

filters {
    input    => [ qw( chomp ) ],
    expected => [ qw( lines chomp array ) ],
};

sub paginate {
    my $len = filter_arguments;
    return [ HTML::Split->split(html => $_, length => $len) ];
}

sub paginate_extend {
    my $len = filter_arguments;
    # find extend tag
    # ex: [E:typhoon]
    return [ HTML::Split->split(
        html        => $_,
        length      => $len,
        extend_tags => [
            {
                full  => qr/\[E:[\w\-]+\]/,
                begin => qr/\[[^\]]*?/,
                end   => qr/[^\]]+\]/,
            },
        ])
    ];
}

run_compare;

__END__

=== Blocked html
--- input paginate=10
<p>www.sixapart.com</p>
--- expected
<p>www.six</p>
<p>apart.com</p>

=== Split in the middle of start tag
--- input paginate=30
<p>www.sixapart.com<span class="test">sixapart</span></p>
--- expected
<p>www.sixapart.com</p>
<p><span class="test">sixapart</span></p>
<p></p>

=== Split in the middle of end tag
--- input paginate=25
<p class="test">typepad</p><p>movabletype</p>
--- expected
<p class="test">typepad</p>
<p>movabletype</p>

=== Plain text
--- input paginate=10
abcdefghij0123456789ABCDEFGHIJ0123456789
--- expected
abcdefghij
0123456789
ABCDEFGHIJ
0123456789

=== Just limit plain text
--- input paginate=20
abcdefghij0123456789
--- expected
abcdefghij0123456789

=== None tagged text at the end of text
--- input paginate=15
typepad<em>2.0</em>sixapart
--- expected
typepad<em>2.0</em>
sixapart

=== Unclosed tag
--- input paginate=10
<p>www.sixapart.com
--- expected
<p>www.six</p>
<p>apart.com</p>

=== If split in the middle of 'a' element's text, append it current page.
--- input paginate=50
<p>example<a href="http://example.com/">example.com</a>test</p>
--- expected
<p>example<a href="http://example.com/">example.com</a></p>
<p>test</p>

=== Exclude empty element from start tag group
--- input paginate=20
<hr><p>foofoofoo<br />barbarbar<br></p><p>gazooo<img src="http://example.com/img.gif" />test</p>
--- expected
<hr><p>foofoofoo<br /></p>
<p>barbarbar<br></p><p></p>
<p>gazooo<img src="http://example.com/img.gif" /></p>
<p>test</p>

=== 'A' element has text over limits chars per page
--- input paginate=30
<p>fooooo<a href="http://exapmle.com/aaaaaaa" />bar</a></p>
--- expected
<p>fooooo</p>
<p><a href="http://exapmle.com/aaaaaaa" />bar</a></p>
<p></p>

=== 'A' element has img over limits chars per page
--- input paginate=30
<p>fooooo<a href="http://exapmle.com/" /><img src="hoge" /></a></p>
--- expected
<p>fooooo</p>
<p><a href="http://exapmle.com/" /><img src="hoge" /></a></p>
<p></p>

=== 'A' element has img and text over limits chars per page
--- input paginate=30
<p>fooooo<a href="http://exapmle.com/" />hoge<img src="hoge" /></a></p>
--- expected
<p>fooooo</p>
<p><a href="http://exapmle.com/" />hoge<img src="hoge" /></a></p>
<p></p>

=== Split in the middle of typepad emoticon
--- input paginate_extend=10
foobar[E:typhoon]あいうえお1234[E:sun]abcdefghi[test]
--- expected
foobar[E:typhoon]
あいうえお1234[E:sun]
abcdefghi[
test]

=== 'strong' in 'a'
--- input paginate=50
<a href="http://www.typepad.com/"><strong>TypePad.com</strong></a>
--- expected
<a href="http://www.typepad.com/"><strong>TypePad.com</strong></a>
