#!/usr/bin/perl

use strict;
use warnings;

use IO::String;
use File::Temp qw(tempfile);

#######################
# TESTING starts here #
#######################
use Test::More tests => 29;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI::Driver::POD';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);
isa_ok($obj, 'Pod::Parser');

can_ok($obj, 'pagemode');
can_ok($obj, 'head0_mode');
can_ok($obj, 'debug_on');
can_ok($obj, 'debug_off');

################################
# We define some parsing input #
# and also how the result      #
# should look like             #
################################
my %pod_input; # parsing input
my %html_out;  # parsing result

# 1
$pod_input{minimal} = <<'HEREDOC';
=head1 MINIMAL

Text

=cut
HEREDOC

$html_out{minimal} = <<'HEREDOC';
<h1>MINIMAL</h1>
<p>Text</p>
HEREDOC

# 2
$pod_input{lists} = <<'HEREDOC';
=head1 LISTS

=over

=item normal list (1)

=item normal list (2)

=back

=over

=item 1 numbered list

=item 2 numbered list

=back

=over

=item * 5

=item normal list with number as first item

=back

=cut
HEREDOC

$html_out{lists} = <<'HEREDOC';
<h1>LISTS</h1>
<ul>
<li>normal list (1)</li>
<li>normal list (2)</li>
</ul>
<ol>
<li>numbered list</li>
<li>numbered list</li>
</ol>
<ul>
<li>5</li>
<li>normal list with number as first item</li>
</ul>
HEREDOC

# 3
$pod_input{lists_breakline} = <<'HEREDOC';
=head1 LISTS

=over

=item

normal list (1)

=item

normal list (2)

=back

=over

=item 1

numbered list

=item 2

numbered list

=back

=over

=item *

5

=item

normal list with number as first item

=back

=cut
HEREDOC

$html_out{lists_breakline} = <<'HEREDOC';
<h1>LISTS</h1>
<ul>
<li>normal list (1)</li>
<li>normal list (2)</li>
</ul>
<ol>
<li>numbered list</li>
<li>numbered list</li>
</ol>
<ul>
<li>5</li>
<li>normal list with number as first item</li>
</ul>
HEREDOC

$pod_input{lists_contentInCommand} = <<'HEREDOC';
=head1 Content in Command

=over

=item * First item.

=item * Second item.

=item * Third item.

=back
HEREDOC

$html_out{lists_contentInCommand} = <<'HEREDOC';
<h1>Content in Command</h1>
<ul>
<li>First item.</li>
<li>Second item.</li>
<li>Third item.</li>
</ul>
HEREDOC

$pod_input{lists_contentInTextblock} = <<'HEREDOC';
=head1 Content in Textblock

=over

=item

First item.

=item

Second item.

=item

Third item.

=back
HEREDOC

$html_out{lists_contentInTextblock} = <<'HEREDOC';
<h1>Content in Textblock</h1>
<ul>
<li>First item.</li>
<li>Second item.</li>
<li>Third item.</li>
</ul>
HEREDOC

$pod_input{lists_contentInTextblock2} = <<'HEREDOC';
=head1 Content as Textblock with *

=over

=item *

First item.

=item *

Second item.

=item *

Third item.

=back
HEREDOC

$html_out{lists_contentInTextblock2} = <<'HEREDOC';
<h1>Content as Textblock with *</h1>
<ul>
<li>First item.</li>
<li>Second item.</li>
<li>Third item.</li>
</ul>
HEREDOC

$pod_input{lists_contentMixed} = <<'HEREDOC';
=head1 Content mixed as Command and Textblock

=over

=item * First item.

=item * Second item.

With additional Text.

=item * Third item.

With additional Text.
With additional Text.

=back
HEREDOC

$html_out{lists_contentMixed} = <<'HEREDOC';
<h1>Content mixed as Command and Textblock</h1>
<ul>
<li>First item.</li>
<li>Second item.<br />With additional Text.</li>
<li>Third item.<br />With additional Text.
With additional Text.</li>
</ul>
HEREDOC

$pod_input{lists_nested} = <<'HEREDOC';
=head1 Nested List

=over

=item * First item.

=over

=item 1 First item.

=item 2 Second item.

=item 3 Third item.

=back

=item * Second item.

=item * Third item.

=back
HEREDOC

$html_out{lists_nested} = <<'HEREDOC';
<h1>Nested List</h1>
<ul>
<li>First item.</li>
<ol>
<li>First item.</li>
<li>Second item.</li>
<li>Third item.</li>
</ol>
<li>Second item.</li>
<li>Third item.</li>
</ul>
HEREDOC

$pod_input{lists_noItems} = <<'HEREDOC';
=head1 No Items (Blockquote)

=over

First item.

Second item.

Third item.

=back
HEREDOC

$html_out{lists_noItems} = <<'HEREDOC';
<h1>No Items (Blockquote)</h1>
<blockquote>First item.</blockquote>
<blockquote>Second item.</blockquote>
<blockquote>Third item.</blockquote>
HEREDOC

$pod_input{lists_noItemsNested} = <<'HEREDOC';
=head1 Nested Blockquote

=over

First item.

Second item.

=over

First.

Second.

Third.

=back

Third item.

=back
HEREDOC

$html_out{lists_noItemsNested} = <<'HEREDOC';
<h1>Nested Blockquote</h1>
<blockquote>First item.</blockquote>
<blockquote>Second item.</blockquote>
<blockquote><blockquote>First.</blockquote>
</blockquote>
<blockquote><blockquote>Second.</blockquote>
</blockquote>
<blockquote><blockquote>Third.</blockquote>
</blockquote>
<blockquote>Third item.</blockquote>
HEREDOC

$pod_input{lists_deepNested} = <<'HEREDOC';
=head1 Nested List of Depth 5 !!!

=over

=item * First item.

=item * First item.

=item * First item.

=over

=item 1 One.

=item 2 Two.

=over

=item * A

=over

=item * First item.

=item * First item.

=item * First item.

=over

=item 1 One.

=item 2 Two.

=over

=item * A

=item * B

=item * C

=back

=item 3 Three.

=back

=item * Second item.

=item * Third item.

=back

=item * B

=item * C

=back

=item 3 Three.

=back

=item * Second item.

=item * Third item.

=back
HEREDOC

$html_out{lists_deepNested} = <<'HEREDOC';
<h1>Nested List of Depth 5 !!!</h1>
<ul>
<li>First item.</li>
<li>First item.</li>
<li>First item.</li>
<ol>
<li>One.</li>
<li>Two.</li>
<ul>
<li>A</li>
<ul>
<li>First item.</li>
<li>First item.</li>
<li>First item.</li>
<ol>
<li>One.</li>
<li>Two.</li>
<ul>
<li>A</li>
<li>B</li>
<li>C</li>
</ul>
<li>Three.</li>
</ol>
<li>Second item.</li>
<li>Third item.</li>
</ul>
<li>B</li>
<li>C</li>
</ul>
<li>Three.</li>
</ol>
<li>Second item.</li>
<li>Third item.</li>
</ul>
HEREDOC

$pod_input{lists_nestedMixed1} = <<'HEREDOC';
=head1 Nested List with Blockquote

=over

=item 1 One.

=item 2 Two.

=over

A

B

C

=back

=item 3 Three.

=back
HEREDOC

$html_out{lists_nestedMixed1} = <<'HEREDOC';
<h1>Nested List with Blockquote</h1>
<ol>
<li>One.</li>
<li>Two.</li>
<blockquote><blockquote>A</blockquote>
</blockquote>
<blockquote><blockquote>B</blockquote>
</blockquote>
<blockquote><blockquote>C</blockquote>
</blockquote>
<li>Three.</li>
</ol>
HEREDOC

$pod_input{lists_nestedMixed2} = <<'HEREDOC';
=head1 Nested Blockquote with List

=over

One.

Two.

=over

=item * A

=item * B

=item * C

=back

Three.

=back
HEREDOC

$html_out{lists_nestedMixed2} = <<'HEREDOC';
<h1>Nested Blockquote with List</h1>
<blockquote>One.</blockquote>
<blockquote>Two.</blockquote>
<ul>
<li>A</li>
<li>B</li>
<li>C</li>
</ul>
<blockquote>Three.</blockquote>
HEREDOC

# 4
$pod_input{pic} = <<'HEREDOC';
=head2 PIC

Some text?

=image /path/to/pic.jpg This is the description!

Some other text...

=cut
HEREDOC

$html_out{pic} = <<'HEREDOC';
<h2>PIC</h2>
<p>Some text?</p>
<img src="/path/to/pic.jpg" recindex="1" >
<p>This is the description!</p>
<p>Some other text...</p>
HEREDOC

$pod_input{image} = <<'HEREDOC';
=head2 IMAGE

Some text?

=for image /path/to/pic.jpg This is the description!

Some other text...

=cut
HEREDOC

$html_out{image} = <<'HEREDOC';
<h2>IMAGE</h2>
<p>Some text?</p>
<img src="/path/to/pic.jpg" recindex="1" >
<p>This is the description!</p>
<p>Some other text...</p>
HEREDOC

# 5
$pod_input{umlaut} = <<'HEREDOC';
=head3 UMLAUT

üöäÜÖÄ
éàèÉÀÈ

=cut
HEREDOC

$html_out{umlaut} = <<'HEREDOC';
<h3>UMLAUT</h3>
<p>&uuml;&ouml;&auml;&Uuml;&Ouml;&Auml;
&eacute;&agrave;&egrave;&Eacute;&Agrave;&Egrave;</p>
HEREDOC

# 6
$pod_input{angle_bracket} = <<'HEREDOC';
=head4 ANGLE BRACKET

HTML chars:
<html> &nbsp; </html>

POD markup:
B<BOLD> C<CODE> F<FILE> I<ITALIC> E<nbsp> L<perl.org>

=cut
HEREDOC

$html_out{angle_bracket} = <<'HEREDOC';
<h4>ANGLE BRACKET</h4>
<p>HTML chars:
&lt;html&gt; &amp;nbsp; &lt;/html&gt;</p>
<p>POD markup:
<b>BOLD</b> <code>CODE</code> <code>FILE</code> <i>ITALIC</i> &nbsp; <a href='perl.org'>perl.org</a></p>
HEREDOC

# 7
$pod_input{code} = <<'HEREDOC';
=head1 CODE

Text1

  # Code
  # Multiline
  # No special chars
  # We only want to test
  # multiline code

Text2

=cut
HEREDOC

$html_out{code} = <<'HEREDOC';
<h1>CODE</h1>
<p>Text1</p>
<code>&nbsp;&nbsp;#&nbsp;Code<br />
&nbsp;&nbsp;#&nbsp;Multiline<br />
&nbsp;&nbsp;#&nbsp;No&nbsp;special&nbsp;chars<br />
&nbsp;&nbsp;#&nbsp;We&nbsp;only&nbsp;want&nbsp;to&nbsp;test<br />
&nbsp;&nbsp;#&nbsp;multiline&nbsp;code<br />
<br /></code>
<p>Text2</p>
HEREDOC

# 8
$pod_input{pagebreak} = <<'HEREDOC';
=head1 PAGEBREAK

Text1

=head1 Here should be a break

Text2

=cut
HEREDOC

$html_out{pagebreak} = <<'HEREDOC';
<h1>PAGEBREAK</h1>
<p>Text1</p>
<mbp:pagebreak />
<h1>Here should be a break</h1>
<p>Text2</p>
HEREDOC

# 9
$pod_input{inline_links} = <<'HEREDOC';
=head1 Inline Links

Link 1 L<Module>

Link 2 L<Module/Chapter>

Link 3 L<Name|Module>

Link 4 L<Name|Module/Chapter>

Link 5 L<Name|/Chapter>

Link 6 L</Chapter>

Link 7 L<http://perl.org>

Link 8 L<perl.org>

Link 9 L<Perl|http://perl.org>

Link 10 L<Perl|perl.org>

=cut
HEREDOC

$html_out{inline_links} = <<'HEREDOC';
<h1>Inline Links</h1>
<p>Link 1 <a href='https://metacpan.org/module/Module'>Module</a></p>
<p>Link 2 <a href='https://metacpan.org/module/Module#Chapter'>Module/Chapter</a></p>
<p>Link 3 <a href='https://metacpan.org/module/Module'>Name</a></p>
<p>Link 4 <a href='https://metacpan.org/module/Module#Chapter'>Name</a></p>
<p>Link 5 Name (Chapter)</p>
<p>Link 6 "Chapter"</p>
<p>Link 7 <a href='http://perl.org'>http://perl.org</a></p>
<p>Link 8 <a href='perl.org'>perl.org</a></p>
<p>Link 9 <a href='http://perl.org'>Perl</a></p>
<p>Link 10 <a href='perl.org'>Perl</a></p>
HEREDOC

#10
$pod_input{begin_html} = <<'HEREDOC';

=head1 HTML in POD

Just some B<HTML> in the I<POD>:

=begin html

Das ist <b>DICK</b>!

=end html

=cut
HEREDOC

$html_out{begin_html} = <<'HEREDOC';
<h1>HTML in POD</h1>
<p>Just some <b>HTML</b> in the <i>POD</i>:</p>
<p>
Das ist <b>DICK</b>!

</p>
HEREDOC

#################################################
# Now we parse the input and compare the result #
# with what we expected...                      #
#################################################
for my $key (keys %pod_input) {
    # we reset the parser, because the <mbp:pagebreak /> (see Parser-code)
    my $obj = $module->new();

    my ($fh,$f_name) = tempfile();
    binmode $fh;
    print $fh $pod_input{$key};
    close $fh;
    open my $pod_handle, "<:encoding(utf-8)", $f_name;

    my $html_res; # this variable will contain the result!!!
    my $res_handle = IO::String->new($html_res);

    $obj->pagemode(1);
    $obj->parse_from_filehandle($pod_handle, $res_handle);
    is($html_res, $html_out{$key}, "POD to HTML -> $key");
}

# Ok, and we should also test what happens if we
# use $obj->head0_mode() so we do a seperate test here.
$obj = $module->new();
$obj->head0_mode(1);

my ($fh,$f_name) = tempfile();
binmode $fh;
print $fh "=head0 Biggest Title

Some text...

=head1 Head One

...should now be Head Two!

=cut
";
close $fh;
open my $pod_handle, "<:encoding(utf-8)", $f_name;

my $html_res;
my $res_handle = IO::String->new($html_res);

$obj->parse_from_filehandle($pod_handle, $res_handle);
is($html_res,
   "<h1>Biggest Title</h1>\n<p>Some text...</p>\n<h2>Head One</h2>\n<p>...should now be Head Two!</p>\n",
   "POD to HTML -> head0_mode"
  );

########
# done #
########
1;

