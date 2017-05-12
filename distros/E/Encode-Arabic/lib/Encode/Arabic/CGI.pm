# ###################################################################### Otakar Smrz, 2003/01/23
#
# Encode Arabic Online #########################################################################

package Encode::Arabic::CGI;

our $VERSION = '14.1';

use strict;

use base 'CGI::Application::FastCGI';

use CGI::Fast ':standard';

use Benchmark;

use Encode::Arabic;
use Encode::Arabic::ArabTeX ':xml';
use Encode::Arabic::ArabTeX::ZDMG ':xml';
use Encode::Arabic::Buckwalter ':xml';


our $session;

our %enc_hash = ( 'ArabTeX',                 'ArabTeX',
                  'Buckwalter',              'Buckwalter',
                  'Habash-Soudi-Buckwalter', 'Habash',
                  'Parkinson',               'Parkinson',
                  'Unicode',                 'UTF-8'          );

our @dec_list = ('ArabTeX', 'Buckwalter', 'Habash-Soudi-Buckwalter', 'Parkinson', 'Unicode');

our @enc_list = ('Unicode', 'Buckwalter', 'Habash-Soudi-Buckwalter', 'Parkinson', 'ArabTeX');


our %url_hash = ();

foreach (keys %enc_hash) {

    my $url = $enc_hash{$_};

    $url =~ tr[-][/];

    $url_hash{$_} = 'http://search.cpan.org/dist/Encode-Arabic/lib/Encode/Arabic/' . $url . '.pm';
}

$url_hash{'Unicode'} = 'http://search.cpan.org/dist/Encode/Encode.pm';


sub setup {

    my $c = shift;

    $c->mode_param('runmode');

    $c->start_mode('recode');
    $c->error_mode('recode');

    $c->run_modes(map { $_ => $_ } qw 'recode');
}

sub cgiapp_prerun {

    $session++;
}

# use base 'CGI::Application::FastCGI';

sub run {
    my $self = shift;
    my $request = FCGI::Request();
    $self->fastcgi($request);
    while ($request->Accept >= 0) {
        $self->reset_query;
        $self->CGI::Application::run;
        last if $self->reinit();
    }
}

sub reinit {

    return -M $0 < 0;
}


sub escape ($) {

    my $x = shift;

    $x =~ s/\&/\&amp;/g;
    $x =~ s/\</\&lt;/g;
    $x =~ s/\>/\&gt;/g;

    return $x;
}

sub timer (@) {

    return sprintf "%04d/%02d/%02d %02d:%02d:%02d", $_[5] + 1900, $_[4] + 1, @_[3, 2, 1, 0];
}


sub display_header ($) {

    my $c = shift;
    my $q = $c->query();
    my $r;

    $q->charset('utf-8');

    $r .= $q->start_html(-title  => "Encode Arabic Online Interface", '-encoding' => $q->charset(),
                         -style  => {-src => 'http://quest.ms.mff.cuni.cz/encode/encode.css', '-type' => 'text/css'},
                         -script => {-src => 'http://quest.ms.mff.cuni.cz/encode/encode.js', -type => 'text/javascript'});

    return $r;
}

sub display_headline ($) {

    my $c = shift;
    my $q = $c->query();
    my $r;

    $r .= $q->h1($q->a({'href' => 'http://sourceforge.net/projects/encode-arabic/'}, "Encode Arabic"), 'Online Interface');

    return $r;
}

sub display_welcome ($) {

    my $c = shift;
    my $q = $c->query();
    my $r;

    $r .= $q->p("Welcome to the online interface to", $q->a({-href => 'http://sourceforge.net/projects/encode-arabic/'}, "Encode Arabic") .
                ", a library for processing various encodings and notations of Arabic with",
                $q->a({-href => 'http://search.cpan.org/dist/Encode-Arabic/'}, "Perl"), "or",
                $q->a({-href => 'http://hackage.haskell.org/cgi-bin/hackage-scripts/package/Encode/'}, "Haskell") . ".");

    $r .= $q->p('You must have Unicode fonts installed to appreciate this site. If you need some, try the',
                $q->a({'href' => 'http://sourceforge.net/projects/dejavu/'}, 'DejaVu Fonts'), 'from SourceForge.');

    return $r;
}

sub display_footline ($) {

    my $c = shift;
    my $q = $c->query();
    my $r;

    $r .= $q->br();

    $r .= $q->p("(C) Otakar Smr\x{017E} 2012-2003. GNU General Public License", $q->a({-href => 'http://www.gnu.org/licenses/'}, "GNU GPL 3") . ".");

    $r .= $q->p("Encode Arabic is an", $q->a({-href => 'http://sourceforge.net/projects/encode-arabic/'}, "open-source online"), "project.",
                "You can contribute to its development with your suggestions!");

    $r .= $q->p("Contact", $q->a({-href => 'http://otakar-smrz.users.sf.net/'}, "otakar-smrz users.sf.net") . ",",
                "Institute of Formal and Applied Linguistics, Charles University in Prague.");

    return $r;
}

sub display_footer ($) {

    my $c = shift;
    my $q = $c->query();
    my $r;

    $r .= $q->p({'style' => 'text-align: right;'},
                '<a href="http://validator.w3.org/check?uri=referer"><img border="0"
                    src="http://www.w3.org/Icons/valid-xhtml10"
                    alt="Valid XHTML 1.0 Transitional" height="31" width="88" /></a>',
                '<a href="http://jigsaw.w3.org/css-validator/check?uri=referer"><img border="0"
                    src="http://www.w3.org/Icons/valid-css2"
                    alt="Valid CSS level 2.1" height="31" width="88" /></a>');

    $r .= $q->script({-type => 'text/javascript', -src => 'http://api.yamli.com/js/yamli_api.js'}, "");

    $r .= $q->script({-type => 'text/javascript'}, join ' ', split ' ', q {

                            if (typeof(Yamli) == "object") {

                                Yamli.init({ uiLanguage: "en", startMode: "onOrUserDefault",
                                             settingsPlacement: 'inside',
                                             showTutorialLink: false, showDirectionLink: true });

                                encodeYamli('');
                            }
                    });

    $r .= $q->end_html();

    return $r;
}


sub recode {

    my $c = shift;

    my $q = $c->query();

    my $r = '';

    my @tick = ();

    $q->param($c->mode_param(), 'recode');

    $r .= display_header $c;

    $r .= display_headline $c;

    my @example = ( [ 'ArabTeX',    "\\cap al-waqtu al-'Ana " . (timer gmtime time) . " bi-tawqIti <GMT>, 'ah\"laN wa-sah\"laN!" ],
                    [ 'ArabTeX',    "\\cap iqra' h_a_dA an-na.s.sa bi-intibAhiN: li-al-laylaTayni yusAwI li-llaylatayni, wa-lA li-a|l-laylaT-|ayni." ],
                    [ 'ArabTeX',    "iqra'-i ad-darsa al-'awwala" ],
                    [ 'Buckwalter', "AqrO Aldrs AlOwl" ],
                    [ 'Buckwalter', "yEtbr mDy}A" ],
                    [ 'Unicode',    decode "buckwalter", "AqrO Aldrs AlOwl" ],
                    [ 'Unicode',    decode "buckwalter", "Aldrs AlOwl" ],
                    [ 'Unicode',    decode "buckwalter", "yEtbr mDy}A" ] );

    if (defined $q->param('submit') and $q->param('submit') eq 'Example') {

        my $idx = rand @example;

        $q->param('text', $example[$idx][1]);
        $q->param('decode', $example[$idx][0]);
    }
    else {

        if (defined $q->param('text') and $q->param('text') != /^\s*$/) {

            $q->param('text', decode "utf8", $q->param('text'));
            $q->param('decode', @dec_list) unless defined $q->param('decode');
        }
        else {

            $q->param('text', $example[0][1]);
            $q->param('decode', $example[0][0]);
        }
    }

    $q->param('encode', @enc_list) unless defined $q->param('encode');

    $r .= display_welcome $c;

    $r .= $q->h2('Your Request');

    $r .= $q->start_form('-method' => 'POST');

    $r .= $q->table({-border => 0},
                    Tr({-align => 'left', -valign => 'middle'},
                       [
                        td({-colspan => 3},
                           [$q->textfield(-name       =>  'text',
                                          -default    =>  $q->param('text'),
                                          -size       =>  120,
                                          -maxlength  =>  200,
                            )]),

                        td({-colspan => 3},
                           table({-border => 0, -width => "100%"},
                                 Tr({-align => 'left', -valign => 'top'},
                                    [
                                     td({-align => 'left'}, 'Decode Setting') .
                                     td({-align => 'center'},
                                        [$q->radio_group(-name      =>  'decode',
                                                         -onchange  =>  "encodeYamli('text')",
                                                         -values    =>  [@dec_list],
                                                         -default   =>  [$q->param('decode')]),
                                        ]),
                                     td({-align => 'left'}, 'Encode Setting') .
                                     td({-align => 'center'},
                                        [$q->checkbox_group(-name      =>  'encode',
                                                            -values    =>  [@enc_list],
                                                            -default   =>  [$q->param('encode')]),
                                        ]),
                                    ])
                           )),
                       ]),

                    Tr({-align => 'left', -valign => 'middle'},
                       td({-align => 'left'},   $q->submit(-name => 'submit', -value => 'Submit')),
                       td({-align => 'center'}, $q->reset('Reset')),
                       td({-align => 'right'},  $q->submit(-name => 'submit', -value => 'Example')),
                    ));

    $r .= $q->hidden( -name => $c->mode_param(), -value => $q->param($c->mode_param()) );

    $r .= $q->end_form();


    $r .= $q->h2('Decode');

    $r .= $q->h3($q->a({'href' => $url_hash{$q->param('decode')}}, $q->param('decode')));

    $r .= $q->p({'class' => $q->param('text') =~ /\p{Arabic}/ ? 'arabic' : ''}, $q->param('text') ne '' ? escape $q->param('text') : '&nbsp;');

    my $decode = decode $enc_hash{$q->param('decode')}, encode "utf8", $q->param('text');


    $r .= $q->h2('Encode');

    foreach ($q->param('encode')) {

        $r .= $q->h3($q->a({'href' => $url_hash{$_}}, $_));

        my $encode = decode "utf8", encode $enc_hash{$_}, $decode;

        $r .= $q->p({'class' => $encode =~ /\p{Arabic}/ ? 'arabic' : ''}, $encode ne '' ? escape $encode : '&nbsp;');

        if ($_ eq 'Unicode' and $q->param('decode') eq 'ArabTeX') {

            my $encode = decode "arabtex-zdmg", encode "utf8", $q->param('text');

            $r .= $q->p({'class' => $encode =~ /\p{Arabic}/ ? 'arabic' : ''}, $encode ne '' ? escape $encode : '&nbsp;');
        }
    }

    $r .= display_footline $c;

    $r .= display_footer $c;

    return encode "utf8", $r;
}


1;
