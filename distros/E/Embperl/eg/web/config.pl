
use File::Basename ;

sub new
    {
    my ($self, $r) = @_ ;

    # The following two values must be changed to meet your local setup
    # Additionally DBI and DBIx::Recordset must be installed
   
    $self -> {dbdsn}      = $^O eq 'MSWin32'?'dbi:ODBC:embperl':'dbi:mysql:embperl' ;
    $self -> {dbuser}     = 'www' ;
    $self -> {dbpassword} = undef ;
    $self -> {adminemail} = 'richter@ecos.de';
    $self -> {emailfrom}   = 'embperl@ecos.de';

    # There is normally no need to change anything below this line

    $self -> {basepath}  = '/eg/web/' ;
    $self -> {baseuri}   = $ENV{EMBPERL_BASEURI} || '/eg/web/' ;
    $self -> {basedepth} = $ENV{EMBPERL_BASEDEPTH} || 2 ;
    $self -> {imageuri}  = $ENV{EMBPERL_IMAGES} || '../images/' ;

    $self -> {supported_languages} = ['en', 'de'] ;
    
    # Embperl 2 source directory
    $self -> {root}      = $ENV{EMBPERL_SRC} . '/' ;
    
    # check if Embperl 1.3 is installed
    if ($INC{'Apache2/RequestRec.pm'})
	{
        my $lib_1_3 = dirname ($INC{'Apache2/RequestRec.pm'})  ;
        if (-e ($lib_1_3 . '/../HTML/Embperl.pod'))
            {
            $self -> {lib_1_3}     = dirname($lib_1_3) ;
            }
	}
    elsif ($INC{'Apache.pm'})
	{
        my $lib_1_3 = dirname ($INC{'Apache.pm'})  ;
        if (-e ($lib_1_3 . '/HTML/Embperl.pod'))
            {
            $self -> {lib_1_3}     = $lib_1_3 ;
            }
	}
    $self -> {lib_1_3} ||= '' ;

    # check if DBIx::Recordset is installed
    my $lib_dbix = $self -> {lib_1_3} ;
    if (-e ($lib_dbix . '/DBIx/Intrors.pod'))
        {
        $self -> {lib_dbix}     = $lib_dbix ;
        }
    elsif ($lib_dbix && (-e (dirname($lib_dbix) . '/DBIx/Intrors.pod')))
        {
        $self -> {lib_dbix}     = dirname($lib_dbix) ;
        }
    else
        {
        $self -> {lib_dbix}     = '' ;
        }


    }




BEGIN 
    {
    %messages = (
        'de' =>
            {
            'Introduction'                    => 'Einführung',
            'Documentation'                   => 'Dokumentation',
            'Examples'                        => 'Beispiele',
            'Changes'                         => 'Änderungen',
            'Sites using Embperl'             => 'Sites mit Embperl',
            'Add info about Embperl'          => 'Hinzufügen Infos',
            'More infos'                      => 'Weitere Infos',
            'Enter info to add about Embperl' => 'Eingabe von Informationen zu Embperl',
            'Show info added about Embperl'   => 'Anzeige der gespeicherten Informationen zu Embperl',
            'Infos about Embperl'             => 'Informationen über Embperl',  
            '1.3.6 documentation'             => '1.3.6 Dokumentation',
            'Configuration'                   => 'Konfiguration',
            'Conferences'                     => 'Konferenzen',
            'Books'                           => 'Bücher',
            'Articles'                        => 'Artikel',
            'Modules & Examples'              => 'Module & Beispiele',
            'Donate'                          => 'Spenden',
            }
        ) ;

    @menu = (
        { menu => 'Home',                   uri => '',                          file => { en => 'eg/web/index.htm', de => 'eg/web/indexD.htm'} },
        { menu => 'Features',               uri => 'pod/list/Features.htm',          file => { en => 'Features.pod',     de => 'FeaturesD.pod' }, sub =>
            [
            { menu => 'Features 1.3',               uri => 'Features13.htm',          path => { en => '%lib_1_3%/HTML/Embperl/Features.pod',     de => '%lib_1_3%/HTML/Embperl/FeaturesD.pod' } }
            ]
        
         },
        { menu => 'Introduction',           uri => 'pod/intro/', sub =>
            [
            { menu => 'Embperl',            uri => 'Intro.htm',                 file => 'Intro.pod', #file => { en => 'Intro.pod', 'de' => 'IntroD.pod'},
                  desc => { en => 'Introduction of Embperl basic capablitities', 
                            de => 'Einführung in die grundlegenden Möglichkeiten von Embperl' }},
            { menu => 'Embperl::Object',    uri => 'IntroEmbperlObject.htm',    file => 'IntroEmbperlObject.pod',
                  desc => { en => 'Introduction to object-oriented website creation with Embperl', 
                            de => 'Einführung in das objekt-orientierte Erstellen von Websites mit Embperl' }},
            { menu => 'Embperl 2 Advanced',    uri => 'IntroEmbperl2.htm',    file => 'IntroEmbperl2.pod',
                  desc => { en => 'Introduction to advanced features of Embperl 2', 
                            de => 'Einführung in erweiterte Möglichkeiten von Embperl 2' }},
            { menu => 'DBIx::Recordset',   uri => 'IntroRecordset.htm',    path => '%lib_dbix%/DBIx/Intrors.pod',
                  desc => { en => 'Introduction to database access with DBIx::Recordset', 
                            de => 'Einführung in den Datenbankzugriff mit DBIx::Recordset' }},
            ]
        },
        { menu => 'Documentation',          uri => 'pod/doc/', sub => 
            [
                { menu => 'README',            uri => 'README.txt',         file => { en => 'README', de => 'README'},
                  desc => { en => 'Short overview',
                            de => 'Kurzüberblick' }},
                { menu => 'README.v2',            uri => 'README.v2.txt',          file => { en => 'README.v2', de => 'README.v2'},
                  desc => { en => 'Contains what\'s new in Embperl 2.0 and differences to Embperl 1.3',
                            de => 'Enthält die Neuigkeiten von Embperl 2.0 und die Unterschiede zu Embperl 1.3' }},
                { menu => 'Configuration',           uri => 'Config.htm',               file => { en => 'Config.pod', de => 'Config.pod'},
                  desc => { en => 'Configuration and calling of Embperl', 
                            de => 'Konfiguration und Aufruf von Embperl' }},
                { menu => 'Embperl',            uri => 'Embperl.htm',               file => 'Embperl.pod', #{ en => 'Embperl.pod', de => 'EmbperlD.pod'},
                  desc => { en => 'Main Embperl documentation', de => 'Hauptdokumentation' }},
                { menu => 'Embperl::Object',    uri => 'EmbperlObject.htm',         file => 'Embperl/Object.pm',
                  desc => { en => 'Documentation for creating object-oriented websites', 
                            de => 'Dokumentation zur Erstellung von Objekt-Orientierten Websites' }},
                { menu => 'Embperl::Form::Validate',  uri => 'EmbperlFormValidate.htm',         file => 'Embperl/Form/Validate.pm' ,
                  desc => { en => 'Documentation for easy form validation (client- and server-side)', 
                            de => 'Dokumentation zur einfachen Überprüfung von Formulareingaben (Client- und Serverseitig)' }},
                { menu => 'Embperl::Syntax',    uri => 'EmbperlSyntax.htm',         file => 'Embperl/Syntax.pm', 
                  desc => { en => 'Documentation about differnent syntaxes in Embperl and how to create your own syntax', 
                            de => 'Dokumentation über verschiedene Syntaxen von Embperl und wie man eingene Syntaxen erstellt' },
                  sub =>
                    [
                    { menu => 'Embperl',        uri => 'Embperl.htm',               file => 'Embperl/Syntax/Embperl.pm'},
                    { menu => 'EmbperlBlocks',  uri => 'EmbperlBlocks.htm',         file => 'Embperl/Syntax/EmbperlBlocks.pm'},
                    { menu => 'EmbperlHTML',    uri => 'EmbperlHTML.htm',           file => 'Embperl/Syntax/EmbperlHTML.pm'},
                    { menu => 'HTML',           uri => 'HTML.htm',                  file => 'Embperl/Syntax/HTML.pm'},
                    { menu => 'ASP',            uri => 'ASP.htm',                   file => 'Embperl/Syntax/ASP.pm'},
                    { menu => 'SSI',            uri => 'SSI.htm',                   file => 'Embperl/Syntax/SSI.pm'},
                    { menu => 'Perl',           uri => 'Perl.htm',                  file => 'Embperl/Syntax/Perl.pm'},
                    { menu => 'POD',            uri => 'POD.htm',                   file => 'Embperl/Syntax/POD.pm'},
                    { menu => 'Text',           uri => 'Text.htm',                  file => 'Embperl/Syntax/Text.pm'},
                    { menu => 'RTF',            uri => 'RTF.htm',                   file => 'Embperl/Syntax/RTF.pm'},
                    { menu => 'Mail',           uri => 'Mail.htm',                  file => 'Embperl/Syntax/Mail.pm'},
                    ],
                },
                { menu => 'Embperl::Recipe',    uri => 'EmbperlRecipe.htm',         file => 'Embperl/Recipe.pm', 
                  desc => { en => 'Documentation about recipes and providers', 
                            de => 'Dokumentation über recipes und provider' },
                  sub =>
                    [
                    { menu => 'Embperl',        uri => 'Embperl.htm',               file => 'Embperl/Recipe/Embperl.pm'},
                    { menu => 'EmbperlXSLT',    uri => 'EmbperlXSLT.htm',           file => 'Embperl/Recipe/EmbperlXSLT.pm'},
                    { menu => 'XSLT',           uri => 'XSLT.htm',                  file => 'Embperl/Recipe/XSLT.pm'},
                    ],
                },
#                { menu => 'Embperl::Constant',    uri => 'EmbperlConstant.htm',         file => 'Embperl/Constant.pm'},
#                { menu => 'Embperl::Log',    uri => 'EmbperlLog.htm',         file => 'Embperl/Log.pm'},
#                { menu => 'Embperl::Out',    uri => 'EmbperlOut.htm',         file => 'Embperl/Out.pm'},
#                { menu => 'Embperl::Run',    uri => 'EmbperlRun.htm',         file => 'Embperl/Run.pm'},
                { menu => 'Embperl::Mail',    uri => 'EmbperlMail.htm',         file => 'Embperl/Mail.pm',
                  desc => { en => 'Documentation on how to use Embperl for generating and sending mail', 
                            de => 'Dokumentation wie man Embperl benutzt um Mail zu erstellen und zu senden' }},
#                { menu => 'Embperl::Util',    uri => 'EmbperlUtil.htm',         file => 'Embperl/Util.pm'},
            { menu => '1.3.6 documentation',              uri => 'doc13.htm', 
              desc => { en => 'Old documentation from Embperl 1.3.6', 
                        de => 'Alte Dokumentation von Embperl 1.3.6' },
              sub => ,
                [
                { menu => 'HTML::Embperl',         uri => 'HTML/Embperl.htm',               path => { en => '%lib_1_3%/HTML/Embperl.pod', de => '%lib_1_3%/HTML/EmbperlD.pod'},
                  desc => { en => 'Main Embperl documentation: Configuration, Syntax, Usage etc.', 
                            de => 'Hauptdokumentation: Konfiguration, Syntax, Benutzung, etc.' },
                },
                { menu => 'HTML::EmbperlObject',   uri => 'HTML/EmbperlObject.htm',         path => '%lib_1_3%/HTML/EmbperlObject.pm',
                  desc => { en => 'Documentation for creating object-oriented websites', 
                            de => 'Dokumentation zur Erstellung von Objekt-Orientierten Websites' }},
                { menu => 'HTML::Embperl::Mail',   uri => 'HTML/Embperl/Mail.htm',          path => '%lib_1_3%/HTML/Embperl/Mail.pm' ,
                  desc => { en => 'Documentation on how to use Embperl for generating and sending mail', 
                            de => 'Dokumentation wie man Embperl benutzt um Mail zu erstellen und zu senden' }},
                { menu => 'HTML::Embperl::Session',uri => 'HTML/Embperl/Session.htm',       path => '%lib_1_3%/HTML/Embperl/Session.pm' ,
                  desc => { en => 'Documentation for Embperls session handling object', 
                            de => 'Dokumentation über Embperls Session Objekt' }},
                { menu => 'Tips & Tricks',         uri => 'HTML/Embperl/TipsAndTricks.htm', path => '%lib_1_3%/HTML/Embperl/TipsAndTricks.pod' ,
                  desc => { en => 'Tips & Tricks for Embperl 1.3.6', 
                            de => 'Tips & Tricks für Embperl 1.3.6' }},

                { menu => 'FAQ',                    uri => 'pod/Faq.htm',               path => '%lib_1_3%/HTML/Embperl/Faq.pod',
                  desc => { en => 'FAQ for Embperl 1.3.6', 
                            de => 'FAQ für Embperl 1.3.6' }},

                ],
            },
            { menu => 'DBIx::Recordset',   uri => 'Recordset.htm',    path => '%lib_dbix%/DBIx/Recordset.pm',
                  desc => { en => 'Documentation of DBIx::Recordset', 
                            de => 'Dokumentation von DBIx::Recordset' }},
            ],
        },
        { menu => 'Installation',           uri => 'pod/INSTALL.htm',           file => 'INSTALL.pod', sub =>
            [
            { menu => 'SVN',                relurl => 'pod/doc/SVN.htm',               file => 'SVN.pod' }
            ]
        
         },        #{ menu => 'FAQ',                    uri => 'pod/Faq.htm',               file => 'Faq.pod' },
        #{ menu => 'Examples',               uri => 'examples/' },
        { menu => 'Download',                uri => 'pod/doc/Embperl.-page-19-.htm'},    #sect_44' },
        { menu => 'Support',                uri => 'pod/doc/Embperl.-page-18-.htm', sub =>
            [
            { menu => 'Donate',                relurl => 'donate.htm',               file => { en => 'eg/web/donate.htm', de => 'eg/web/donateD.htm'} }
            ]
        
         },
        { menu => 'Changes',                 uri => 'pod/Changes.htm',           file => 'Changes.pod' },
        #{ menu => 'Sites using Embperl',    uri => 'pod/Sites.htm',             file => 'Sites.pod' },
        { menu => 'Wiki',                uri => 'db/wiki/index.htm', file => '/eg/web/db/wiki.epl', same =>
          [ 
          { menu => 'Wiki',                uri => 'db/wiki/index.cgi', file => '/eg/web/db/wiki.epl' }, 
          ] },
        { menu => 'More infos',          uri => 'db/', sub => 
            [
            { menu => 'News',                    uri => 'news/news.htm',          file => 'eg/web/db/news/data.epd', fdat => { 'category_id' => 1 }, 
                  desc => { en => 'Full list of all news.',
                            de => 'Vollständige Liste aller Neuigkeiten.' }},
            { menu => 'Sites using Embperl',     uri => 'sites/sites.htm',        file => 'eg/web/db/data.epd', fdat => { 'category_id' => 2 },
                  desc => { en => 'Description of Websites that use Embperl.',
                            de => 'Beschreibung von Websites die Embperl einsetzen.' }},
            { menu => 'Books',     uri => 'sites/books.htm',        file => 'eg/web/db/data.epd', fdat => { 'category_id' => 3 },
                  desc => { en => 'Books that contain information about Embperl.',
                            de => 'Bücher die Embperl behandeln.' }},
            { menu => 'Articles',     uri => 'sites/articles.htm',        file => 'eg/web/db/data.epd', fdat => { 'category_id' => 4 },
                  desc => { en => 'Articles that cover Embperl.',
                            de => 'Artikel die Embperl behandeln.' }},
            { menu => 'Modules & Examples',     uri => 'sites/examples.htm',        file => 'eg/web/db/data.epd', fdat => { 'category_id' => 6 },
                  desc => { en => 'Modules and Examples with source code for use/that uses Embperl.',
                            de => 'Modules und Beispiele incl. Quelltext zur/unter Benutzung von Embperl.' }},
            { menu => 'Editorsupport',     uri => 'sites/editors.htm',        file => 'eg/web/db/data.epd', fdat => { 'category_id' => 5 },
                  desc => { en => 'Syntax highlighting and other support for editors.',
                            de => 'Syntaxhervorhebungen unter Unterstützung für Editoren.' }},
            { menu => 'Conferences',     uri => 'sites/conferences.htm',        file => 'eg/web/db/data.epd', fdat => { 'category_id' => 7 },
                  desc => { en => 'Talks about Embperl.',
                            de => 'Vorträge über Embperl.' }},
            ],
        },
        { menu => 'Add info about Embperl',  uri => 'db/addsel.epl', same => 
            [
            { menu => 'Enter info to add about Embperl',    uri => 'db/add.epl' },
            { menu => 'Show info added about Embperl',      uri => 'db/show.epl'},
            { menu => 'Infos about Embperl',                uri => 'db/data.epd' },
            { menu => 'Infos about Embperl',                uri => 'db/list.epl' },
            ],
        },
        { menu => 'Login',                   uri => 'db/login.epl'},
        ) ;


    } ;



      

sub get_menu 
    { 
    my ($self, $r) = @_ ;

    push @{$r -> messages}, $messages{$r -> param -> language} ;

    return \@menu ; 
    } 


