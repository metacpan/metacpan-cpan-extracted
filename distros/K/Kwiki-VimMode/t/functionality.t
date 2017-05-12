use strict;
use warnings;
use lib 't', 'lib';
use Test::More;
plan do {
    require Text::VimColor;
    no warnings 'once'; # excuse me for $Text::VimColor::VIM_COMMAND
    [qx( $Text::VimColor::VIM_COMMAND --version 2>&1 )]->[0]
        =~ m/Vi IMproved ([\d.]+) /;
    if ( not $1 ) {
        skip_all => "because I couldn't extract version of vim!";
    }
    elsif ( $1 < 6.1 ) {
        skip_all => "because Vim version is < 6.1";
    }
    else {
        tests => 3;
    }
};
use Kwiki;

my $hub = Kwiki->new->load_hub({
    vim_mode_class => 'Kwiki::VimMode',
});
$hub->load_class('vim_mode');
$hub->load_class('registry')->lookup( 
    bless { 
        wafl => { vim => [ vim_mode => 'Kwiki::VimMode::Wafl' ] }
    }, $hub->registry->lookup_class
);
my $formatter = $hub->load_class('formatter');

foreach (
    split(
        /(?:%%%\n)/s,
        do { local $/; <DATA> }
    )
) {
    my ( $in, $out ) = split /(?:<<<\n)/s;
    my $got_html = $formatter->text_to_html(".vim\n$in\n.vim\n");
    is( $got_html, $out );
}

__DATA__
# comment
# modeline - vim:set syn=off:
"string"
<<<
<pre class="vim"><span class="synComment"># comment</span>
<span class="synComment"># modeline - vim:set syn=off:</span>
<span class="synConstant">&quot;string&quot;</span>
</pre>
%%%
#!/bin/sh
echo "eggs bacon ham cheese"
<<<
<pre class="vim"><span class="synComment">#!/bin/sh</span>
<span class="synStatement">echo</span><span class="synConstant"> </span><span class="synStatement">&quot;</span><span class="synConstant">eggs bacon ham cheese</span><span class="synStatement">&quot;</span>
</pre>
%%%
filetype: conf

#!/bin/sh
echo "eggs bacon ham cheese"
<<<
<pre class="vim"><span class="synComment">#!/bin/sh</span>
echo <span class="synConstant">&quot;eggs bacon ham cheese&quot;</span>
</pre>
