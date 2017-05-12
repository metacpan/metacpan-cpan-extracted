package Jifty::Plugin::NoIE::View;
use warnings;
use strict;
use Jifty::View::Declare -base;
use Jifty::View::Declare::Helpers;

template '/noie' => page { }
content { 
    div { { style is 'margin:50px; padding: 30px; text-align:left; border:1px solid #ccc; background: #ddd' };
        h1 { _('You Can Have A Better Web Browser!'); };
        h1 { _('Please Try:'); };
        ul { { style is 'font-size:24px;list-style:none' };
            li { hyperlink( label => 'Firefox' , url => 'http://www.mozilla.com/firefox/' ); };
            li { hyperlink( label => 'Opera'   , url => 'http://www.opera.com/' ); };
            li { hyperlink( label => 'Safari'  , url => 'http://www.apple.com/safari/' ); };
        };
    };
};

template '/noie_redirect' => sub {
    outs_raw(qq|
    <script type="text/javascript">
        if( browser.msie ) { window.location = '/noie'; }
    </script>
    |);
};



1;

