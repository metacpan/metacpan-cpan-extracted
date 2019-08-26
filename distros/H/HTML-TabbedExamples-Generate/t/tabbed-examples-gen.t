#!/usr/bin/perl

use Test::More tests => 2;

use Test::Differences qw(eq_or_diff);

use HTML::TabbedExamples::Generate;

use strict;
use warnings;

{
    # Examples generator:
    my $ex_gen = HTML::TabbedExamples::Generate->new(
        {
            default_syntax => 'perl',
        }
    );

    # TEST
    ok( $ex_gen, 'Init object' );

    my $markup = $ex_gen->html_with_title(
        {
            title    => "Copying a file",
            id_base  => "copying_a_file",
            examples => [
                {
                    id    => "io_all",
                    label => "IO-All",

                    # To avoid CPANTS thinking that IO::All is a dependency
                    # we obscure the use statement.
                    code => ( lc("USE ") . "IO::All;\n" . <<'EOF'),

my ($source_filename, $dest_filename) = @_;
io->file($source_filename) > io->file($dest_filename);
EOF

                },
                {
                    id    => "core",
                    label => "Core Perl",
                    code  => <<'EOF',
use File::Copy qw(copy);

my ($source_filename, $dest_filename) = @_;

copy($source_filename, $dest_filename);
EOF
                },
            ],
        }
    );

    my $expected = <<'END_OF_HTML';
<h3 id="copying_a_file">Copying a file</h3>

<div class="tabs">
<ul>
<li><a href="#copying_a_file__io_all">IO-All</a></li>

<li><a href="#copying_a_file__core">Core Perl</a></li>

</ul>
<div id="copying_a_file__io_all"><pre class="code perl">
<span class="PreProc">#!/usr/bin/perl</span>

<span class="Statement">use strict</span>;
<span class="Statement">use warnings</span>;

<span class="Statement">use </span>IO::All;

<span class="Statement">my</span> (<span class="Identifier">$source_filename</span>, <span class="Identifier">$dest_filename</span>) = <span class="Identifier">@_</span>;
io-&gt;file(<span class="Identifier">$source_filename</span>) &gt; io-&gt;file(<span class="Identifier">$dest_filename</span>);


</pre>
</div>
<div id="copying_a_file__core"><pre class="code perl">
<span class="PreProc">#!/usr/bin/perl</span>

<span class="Statement">use strict</span>;
<span class="Statement">use warnings</span>;

<span class="Statement">use </span>File::Copy <span class="Constant">qw(copy)</span>;

<span class="Statement">my</span> (<span class="Identifier">$source_filename</span>, <span class="Identifier">$dest_filename</span>) = <span class="Identifier">@_</span>;

copy(<span class="Identifier">$source_filename</span>, <span class="Identifier">$dest_filename</span>);


</pre>
</div></div>
END_OF_HTML

    # TEST
    eq_or_diff( $markup, $expected, 'Markup is fine', );
}
