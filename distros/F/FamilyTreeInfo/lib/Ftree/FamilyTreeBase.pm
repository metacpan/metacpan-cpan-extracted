package Ftree::FamilyTreeBase;
use strict;
use warnings;

use version; our $VERSION = qv('2.3.41');

use Params::Validate qw(:all);
use CGI qw(:standard);
use Ftree::FamilyTreeDataFactory;
use Ftree::Person;
use Ftree::TextGeneratorFactory;
use Ftree::SettingsFactory;
use Ftree::Date::Tiny;
use CGI::Carp qw(warningsToBrowser);#fatalsToBrowser
# use Perl6::Export::Attrs;
use Sub::Exporter -setup => { exports => [ qw(new) ] };
use Encode qw(decode_utf8);
use utf8;

my $q = new CGI;

sub new {
    my ($classname, @args) = @_;
    my $self = {
        lang     => undef,
        password => undef,

        #    treeScript       => CGI::url(-relative=>1),
        treeScript    => 'ftree',
        personScript  => 'person_page',
        photoUrl      => undef,
        graphicsUrl   => '../graphics',
        imgwidth      => 60,
        reqLevels     => 2,
        textGenerator => undef,
        settings      => undef,
        cgi           => new CGI,
    };
    $self->{imgheight} = $self->{imgwidth} * 1.5;
    $self->{settings}  = Ftree::SettingsFactory::importSettings('perl', $args[0] );
    $self->{photoUrl}  = $self->{settings}{data_source}{config}{photo_url};

    if ( defined $self->{settings}{date_format} ){
        Ftree::Date::Tiny->set_format( $self->{settings}{date_format} );
    }

    return bless $self, $classname;
}

sub _process_parameters {
    my ($self) = validate_pos( @_, { type => HASHREF } );
    $self->{lang} = CGI::param('lang');
    $self->{lang} = $self->{settings}{default_language}
      unless defined $self->{lang};
    Ftree::TextGeneratorFactory::init( $self->{lang} );
    $self->{textGenerator} = Ftree::TextGeneratorFactory::getTextGenerator();
    $self->{password}      = CGI::param('passwd');
    $self->{password}      = "" unless defined $self->{password};

    return;
}

sub _toppage {
    my ( $self, $title ) =
      validate_pos( @_, { type => HASHREF }, { type => SCALAR } );
    binmode STDOUT, ":encoding(UTF-8)";
    print $self->{cgi}->header( -charset => 'UTF-8' ),
      $self->{cgi}->start_html(
        -title => $title,
        -style => { -src => $self->{settings}{css_filename} },
        -meta  => {
            http_equiv => 'Content-Type',
            content    => 'text/html',
            charset    => 'UTF-8'
        }
      );
    warningsToBrowser(1);
    print $self->{cgi}->center( $self->{cgi}->h1($title) ), "\n";

    return;
}

#######################################################
# generates the html for the end of the page
sub _endpage {
    my ($self) = validate_pos( @_, { type => HASHREF } );
    my $password = $self->{settings}{password};
    $password = ( defined $password ) ? $password : "";
    print $self->{cgi}->br(), $self->{cgi}->hr(), "\n",
      $self->{cgi}->start_strong(),
      $self->{cgi}->a(
        {
                -href => ${self}->{treeScript}
              . '?type=;passwd='
              . $password
              . ';lang='
              . $self->{lang}
        },
        $self->{textGenerator}->{Relatives}
      ),
      " - \n",
      $self->{cgi}->a(
        {
                -href => ${self}->{treeScript}
              . '?type=faces;passwd='
              . $password
              . ';lang='
              . $self->{lang}
        },
        $self->{textGenerator}->{Faces}
      ),
      " - \n",
      $self->{cgi}->a(
        {
                -href => ${self}->{treeScript}
              . '?type=snames;passwd='
              . $password
              . ';lang='
              . $self->{lang}
        },
        $self->{textGenerator}->{Surnames}
      ),
      " - \n",
      $self->{cgi}->a(
        {
                -href => ${self}->{treeScript}
              . '?type=hpages;passwd='
              . $password
              . ';lang='
              . $self->{lang}
        },
        $self->{textGenerator}->{Homepages}
      ),
      " - \n",
      $self->{cgi}->a(
        {
                -href => ${self}->{treeScript}
              . '?type=emails;passwd='
              . $password
              . ';lang='
              . $self->{lang}
        },
        $self->{textGenerator}->{Emails}
      ),
      " - \n",
      $self->{cgi}->a(
        {
                -href => ${self}->{treeScript}
              . '?type=bdays;passwd='
              . $password
              . ';lang='
              . $self->{lang}
        },
        $self->{textGenerator}->{Birthdays}
      ),
      "\n",
      $self->{cgi}->end_strong(), $self->{cgi}->br, $self->{cgi}->br, "\n";
    $self->language_chooser();

    print "\n",
'<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">',
      '</script>',
      '<script type="text/javascript">',
      '_uacct = "UA-1237567-1";',
      'urchinTracker();',
      '</script>', "\n";
    print $self->{cgi}->start_i,
      $self->{textGenerator}->maintainer(
        $self->{settings}{adminName},
        $self->{settings}{adminEmail},
        $self->{settings}{adminHomepage}
      ),
      $self->{cgi}->br,
      $self->{textGenerator}->software($VERSION), "\n",
      $self->{cgi}->end_i, $self->{cgi}->br;
    print $self->{cgi}->i( $self->{textGenerator}{DonationSentence} ),
      <<"END_PAYPAL";
  <form action="https://www.paypal.com/cgi-bin/webscr" method="post">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="image" src="https://www.paypal.com/en_US/i/btn/x-click-but04.gif" border="0" name="submit" alt="Make payments with PayPal - it is fast, free and secure!">
<img alt="" border="0" src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1" height="1">
<input type="hidden" name="encrypted" value="-----BEGIN PKCS7-----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-----END PKCS7-----">
</form>
END_PAYPAL

    if ( $self->{settings}{sitemeter_needed} ) {
        print
          "<!--WEBBOT bot=\"HTMLMarkup\" startspan ALT=\"Site Meter\" -->\n",
"<script type=\"text/javascript\" language=\"JavaScript\">var site=\"$self->{settings}{sitemeter_id}\"</script>\n",
"<script type=\"text/javascript\" language=\"JavaScript1.2\" src=\"http://s22.sitemeter.com/js/counter.js?site=$self->{settings}{sitemeter_id}\">\n",
          "</script>\n",
          "<noscript>\n",
"<a href=\"http://s22.sitemeter.com/stats.asp?site=$self->{settings}{sitemeter_id}\" target=\"_top\">\n",
"<img src=\"http://s22.sitemeter.com/meter.asp?site=$self->{settings}{sitemeter_id}\" alt=\"Site Meter\" border=\"0\"/></a>\n",
          "</noscript>\n",
          "<!-- Copyright (c)2005 Site Meter -->\n",
          "<!--WEBBOT bot=\"HTMLMarkup\" Endspan -->\n";
    }
    print $self->{cgi}->end_html;

    return;
}

#########################################################
# check password
sub _password_check {
    my ($self) = validate_pos( @_, { type => HASHREF } );
    if (   defined $self->{settings}{passwordReq}
        && $self->{settings}{passwordReq} ne ""
        && $self->{settings}{password} ne $self->{password} )
    {
        $self->_toppage( $self->{textGenerator}->{Error} );
        printf "<br>\n<br/>\n"
          . $self->{textGenerator}->{Sorry}
          . "!<br><br>\n";
        if ( $self->{settings}{password} eq "" ) {
            print $self->{textGenerator}->{Passwd_need};
        }
        else {
            print 'You have given the wrong password for these pages.';
        }

        print "<br><form action=\"$self->{treeScript}\" method=\"GET\">",
          "<input type=\"hidden\" name=\"type\" value=\"$self->{pagetype}\">",
          "<p><strong>$self->{settings}{passwordPrompt}</strong><br>",
          '<input type="text" size="25" name="passwd">',
          '<input type="submit" value="Go"></p>',
          "</form>\n";
        $self->_endpage();
        exit 1;
    }
}

sub get_cell_class {
    my ( $self, $person, $nr_of_man, $nr_of_woman ) = validate_pos(
        @_,
        { type => HASHREF },
        { type => SCALARREF },
        { type => SCALARREF },
        { type => SCALARREF }
    );
    if ( !defined $person->get_gender() ) {
        return 'unknown';
    }
    elsif ( $person->get_gender() == 0 ) {
        ++${$nr_of_man};
        return 'man';
    }
    else {
        ++${$nr_of_woman};
        return 'woman';
    }
}

sub language_chooser {

    #I guess this function can be done simpler!
    my ($self) = validate_pos( @_, { type => HASHREF } );
    my $anchor = $self->{cgi}->url( -relative => 0 ) . '?';
    my %params = CGI::Vars();
    while ( my ( $key, $value ) = each %params ) {
        if ( $key ne 'lang' ) {
            $anchor .= "$key=" . decode_utf8("$value") . ';';
        }

    }
    print "\n", $self->{cgi}->start_table( { -cellpadding => '3' } ), "\n",
      $self->{cgi}->start_Tr;
    my %lang_to_pict = Ftree::TextGeneratorFactory::getLangToPict();
    while ( my ( $lang, $pic ) = each %lang_to_pict ) {
        print $self->{cgi}->td(
            { -align => 'center' },
            $self->{cgi}->a(
                {
                    -href  => "${anchor}lang=$pic",
                    -title => $self->{textGenerator}->{$lang}
                },
                $self->{cgi}->img(
                    {
                        -width => 40,
                        -src   => "$self->{graphicsUrl}/flags/${pic}.gif",
                        -alt   => $self->{textGenerator}->{$lang}
                    }
                )
            )
          ),
          "\n",
          ;
    }
    print $self->{cgi}->end_Tr, "\n", $self->{cgi}->end_table,
      $self->{cgi}->br, "\n";

    return;
}

sub html_img {
    my ( $self, $person ) =
      validate_pos( @_, { type => HASHREF }, { type => SCALARREF } );
    if ( !defined $person ) {
        return "";
    }
    else {
        my $picture_file =
          defined $person->get_default_picture()
          ? $self->{photoUrl} . $person->get_default_picture()->get_file_name()
          : $self->{graphicsUrl}
          . (
              defined $person->get_gender()
            ? $person->get_gender() == 0
                  ? '/nophoto_m.jpg'
                  : '/nophoto_f.jpg'
            : '/nophoto.gif'
          );

        return $self->{cgi}->img(
            {
                -border => $self->{imgwidth} / 15,
                -src    => $picture_file,
                -class  => $person->get_is_living() ? 'alive' : 'dead',
                -alt    => ( defined $person->get_name() )
                ? $person->get_name()->get_full_name()
                : 'UNKNOWN',
                -width  => $self->{imgwidth},
                -height => $self->{imgheight}
            }
        );
    }
}

sub aref_tree {
    my ( $self, $to_ref, $person, $levels ) = validate_pos(
        @_,
        { type     => HASHREF },
        { type     => SCALAR },
        { type     => SCALARREF },
        { optional => 1, type => SCALAR }
    );
    if ( !defined $levels ) {
        $levels = $self->{reqLevels};
        $person = $self->$self->{target_person} unless ( defined $person );
    }
    if ( $levels > 0 ) {

        my $brief_info = $person->brief_info( $self->{textGenerator} );
        $brief_info = ( defined $brief_info ) ? $brief_info : "";
        my $password = $self->{settings}{password};
        $password = ( defined $password ) ? $password : "";
        return $self->{cgi}->a(
            {
                -href => "$self->{treeScript}?type=tree;"
                  . 'target='
                  . $person->get_id()
                  . ";levels=$levels;"
                  . "passwd=$password;lang=$self->{lang}",
                -title => $brief_info,
            },
            $to_ref
        );
    }
    else {
        return $self->{cgi}->a(
            {
                -href => "$self->{personScript}?target="
                  . $person->get_id()
                  . ";passwd=$self->{settings}{password};lang=$self->{lang}",
                -title => $person->brief_info( $self->{textGenerator} )
            },
            $to_ref
        );
    }
}

1;
