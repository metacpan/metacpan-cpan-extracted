#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   eidolon.pl - application code generator
#
# ==============================================================================  

use Getopt::Long;
use warnings;
use strict;

&main;

# ------------------------------------------------------------------------------
# print_usage()
# print usage information
# ------------------------------------------------------------------------------
sub print_usage
{
    print << "USAGE";
Usage: eidolon.pl [options] <application_name>

Generates code for application <application_name> with given options.

Options:
    -v --verbose    verbose output
    -h --help       print this help

USAGE
}

# ------------------------------------------------------------------------------
# create_directory(\%app, \%options, $dir)
# create directory
# ------------------------------------------------------------------------------
sub create_directory
{
    my ($app, $options, $dir, $len, $status);

    ($app, $options, $dir) = @_;

    # delete starting "dir:"
    substr($dir, 0, 4) = "";
    $dir =~ s/\[\$app_name\]/$app->{"name"}/g;

    $status = mkdir($dir);

    if ($options->{"verbose"})
    {
        $len = length($app->{"name"}) + 45;

        printf("  > %-".$len."s", $dir);
        print $status ? "OK" : "FAIL";
        print "\n";
    }

    shift @{ $app->{"skel"} };
    $app->{"fail"} = 1 unless $status;
}

# ------------------------------------------------------------------------------
# create_file(\%app, \%options, $file)
# create file
# ------------------------------------------------------------------------------
sub create_file
{
    my ($app, $options, $file, $content, $time, $type, $hex, $len, $status);

    ($app, $options, $file) = @_;

    # delete starting "file:"
    substr($file, 0, 5) = "";
    $hex = 0;

    # is it a hex-encoded file?
    if ($file =~ /^hex:/)
    {
        substr($file, 0, 4) = "";
        $hex = 1;
    }

    $file =~ s/\[\$app_name\]/$app->{"name"}/g;

    if ($status = open FILE, ">$file")
    {
        $time    = localtime;
        $content = shift @{ $app->{"skel"} }; 
        $content =~ s/\n$//;

        if ($hex)
        {
            # hex-encoded binary file
            binmode FILE;
            $content =~ s/\n//g;
            $len = 0;

            while ($len < length($content))
            {
                print FILE pack("H2", substr($content, $len, 2));
                $len += 2;
            }
        }
        else
        {
            # text file
            $content =~ s/\[\$app_name\]/$app->{"name"}/g;
            $content =~ s/\[\$time\]/$time/g;
            print FILE $content;
        }

        close FILE;
    }

    if ($options->{"verbose"})
    {
        $len = length($app->{"name"}) + 45;

        printf("  > %-".$len."s", $file);
        print $status ? "OK" : "FAIL";
        print "\n";
    }

    $app->{"fail"} = 1 unless $status;
}

# ------------------------------------------------------------------------------
# main()
# main function
# ------------------------------------------------------------------------------
sub main
{
    my (%app, %options, $data_section, $state, $part, $answer); 

    # get command line options
    Getopt::Long::Configure("bundling");

    GetOptions
    (
        \%options, 
        "verbose|v", 
        "help|h"
    );

    $app{"name"} = shift @ARGV || "";
    $app{"fail"} = 0;

    # check for mandatory options
    if ($options{"help"} || !$app{"name"} || $app{"name"} =~ /[^\w\d]+/)
    {
        print_usage;
        exit 0;
    }

    # proceed
    print "Creating application \"$app{'name'}\"\n";

    {
        # read entire data section
        local $/;
        $data_section = <DATA>;
    }

    # get files & directories structure
    $app{"skel"} = [ split /__([\w\d:\[\]\$\/\-\.]+|\_{1})__\n/, $data_section ];
    $state       = 0;

    # main cycle
    while (scalar @{ $app{"skel"} })
    {
        $part = shift @{ $app{"skel"} };

        next if $part =~ /^\n$/;
        
        # directory section
        if ($part =~ /^dir:/) 
        {
            if ($state == 0)
            {
                print "Creating directories...\n";
                $state = 1;
            }

            create_directory(\%app, \%options, $part);
            next;
        }

        # file section
        if ($part =~ /^file:/)
        {
            if ($state == 1)
            {
                print "Creating files...\n";
                $state = 2;
            }

            create_file(\%app, \%options, $part);
            next;
        }

        $app{"fail"} = 1;
        last;
    }

    print "\n";
    print $app{"fail"} ? "Failed creating application" : "Application successfully created";
    print ".\n\n";
}

=pod

=head1 NAME

eidolon.pl - Eidolon application code generator.

=head1 SYNOPSIS

eidolon.pl [options] <application_name>

Options:

    -v --verbose    verbose output
    -h --help       print this help

Examples:

    eidolon.pl -v Example
    eidolon.pl AnotherExample

=head1 DESCRIPTION

The I<eidolon.pl> code generator will help you to create the application skeleton, so
you won't need to make applications from scratch. It creates a simple example 
application with one default controller and a basic configuration with 
L<Eidolon::Driver::Router::Basic> as a router driver, so you need this package to
be installed.

The application name must consist of one or more alphanumeric characters.

Using the example application name I<Example> the application directory will 
contain the following items:

=over 4

=item bin/

A directory with executable contents. All your application scripts are placed 
here. Contents of this directory should be moved into C<cgi-bin> directory on 
your web server.

=over 4

=item index.cgi

CGI gateway of the application. All user requests will come through this file.

=item index.fcgi

FastCGI gateway of the application. You need to install the L<FCGI> module to 
use this type of gateway.

=item lib/

A directory containing all application modules. If your application will use 
other modules, place them here too.

=over 4

=item Example.pm

A main module of the application. Contains almost nothing - some subclassing
stuff and application version definition. 

=item Example/

A directory with application configuration and other stuff used to interact with
I<Eidolon>.

=over 4

=item Config.pm

Application configuration. Generated configuration contains only basic settings,
so you should edit this file first and specify application settings manually.

=item Controller/

A directory containing application controllers.

=over 4

=item Default.pm

A default controller of the application.

=back

=back

=back

=back

=item static/

A directory containing static data - images, stylesheets and javascript. 
Contents of this directory should be moved into C<htdocs> (C<httpdocs>, 
C<www> or C<wwwroot>) directory of your web server.

=over 4

=item config/

Web-server configuration files.

=over 4

=item apache_cgi

I<Apache> configuration file for CGI application. Contains I<mod_rewrite> rules 
for the application. Rename this file to C<.htaccess> while deploying the 
application to web server.

=item apache_fcgi

I<Apache> configuration file for FastCGI application. Rename this file to 
C<.htaccess> while deploying the application to web server.

=back

=item img/

A directory containing images for the example application.

=over 4

=item flag.png

Nice flag image :)

=item logo.png

I<Eidolon> logo.

=back

=back

=back

=head1 NOTES

The application generated using this script will work only on I<Apache> web 
server with I<mod_rewrite> module installed. Support of other servers will
be added in future versions of this script.

=head1 DEPLOYMENT

To deploy your application perform the following actions:

1. Copy one of the files in C<bin> directory into the C<cgi-bin> directory of 
your web server. For CGI application, you should copy a C<index.cgi>, for 
FastCGI application - copy a C<index.fcgi> file.

2. Set C<rwxr-xr-x> (755) permissions on file that you copied at first step
(i.e. C<index.cgi> or C<index.fcgi>).

3. Copy the C<lib> directory into the C<cgi-bin> directory of your web server.
Actually, you can place this directory at your wish - in this case you will
need to fix a path to this directory in a file that you copied at first step 
(C<index.cgi> or C<index.fcgi>, line 11) and to specify a new path in your
application configuration.

4. Copy one of the C<config> directory files into the C<htdocs> 
(C<httpdocs>, C<www> or C<wwwroot>) directory of your web server. Choose a file
to copy according to file you copied at first step - if you want a CGI 
application - you will need to copy C<apache_cgi> and if you want a FastCGI
application - use C<apache_fcgi> instead. After copying, rename this file to
C<.htaccess>.

5. Copy the entire C<img> directory into the C<htdocs> (C<httpdocs>,
C<www> or C<wwwroot>) directory of you web server. 

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Application>

L<http://www.atma7.com/en/products/eidolon/> - official project web page.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut

__DATA__

__dir:[$app_name]__
__dir:[$app_name]/bin__
__dir:[$app_name]/bin/lib__
__dir:[$app_name]/bin/lib/[$app_name]__
__dir:[$app_name]/bin/lib/[$app_name]/Controller__
__dir:[$app_name]/static__
__dir:[$app_name]/static/img__
__dir:[$app_name]/static/config__

__file:[$app_name]/bin/index.cgi__
#!/usr/bin/perl
# ==============================================================================
#
#   [$app_name]
#   bin/index.cgi - CGI gateway
#
# ==============================================================================

use lib "./lib";
use Eidolon::Debug;
use [$app_name];
use warnings;
use strict;

# application initialization
my $app = [$app_name]->new;
$app->start([$app_name]->TYPE_CGI);
$app->handle_request;

__file:[$app_name]/bin/index.fcgi__
#!/usr/bin/perl
# ==============================================================================
#
#   [$app_name]
#   bin/index.fcgi - FCGI gateway
#
# ==============================================================================

use lib "./lib";
use Eidolon::Debug;
use FCGI;
use [$app_name];
use warnings;
use strict;

my ($rq, $app);

$rq  = FCGI::Request;
$app = [$app_name]->new;
$app->start([$app_name]->TYPE_FCGI);

while ($rq->Accept >= 0) 
{
    $app->handle_request;
}

__file:[$app_name]/bin/lib/[$app_name].pm__
package [$app_name];
# ==============================================================================
#
#   [$app_name]
#   bin/lib/[$app_name].pm - application main class
#
# ==============================================================================

use base qw/Eidolon::Application/;
use warnings;
use strict;

our $VERSION = "0.01"; # [$time]

# ------------------------------------------------------------------------------
# start($type)
# start the application
# ------------------------------------------------------------------------------
sub start
{
    my ($self, $type) = @_;
    $self->SUPER::start($type);
}

# ------------------------------------------------------------------------------
# handle_request()
# handle HTTP request
# ------------------------------------------------------------------------------
sub handle_request
{
    my $self = shift;
    $self->SUPER::handle_request;
}

1;

__file:[$app_name]/bin/lib/[$app_name]/Config.pm__
package [$app_name]::Config;
# ==============================================================================
#
#   [$app_name]
#   bin/lib/[$app_name]/Config.pm - application configuration
#
# ==============================================================================

use base qw/Eidolon::Core::Config/;
use warnings;
use strict;

our $VERSION  = "0.01"; # [$time]

# ------------------------------------------------------------------------------
# \% new($name)
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $name, $type, $self);

    ($class, $name, $type) = @_;

    $self = $class->SUPER::new($name, $type);
    $self->{"app"}->{"title"} = "[$app_name]";
    # $self->{"app"}->{"lib"} = "/path/to/application/lib"; # without trailing slash

    $self->{"drivers"} = [ { "class"  => "Eidolon::Driver::Router::Basic" } ];

    return $self;
}

1;

__file:[$app_name]/bin/lib/[$app_name]/Controller/Default.pm__
package [$app_name]::Controller::Default;
# ==============================================================================
#
#   [$app_name]
#   bin/lib/[$app_name]/Controller/Default.pm - default controller 
#
# ==============================================================================

use base qw/Eidolon::Core::Attributes/;
use Eidolon;
use warnings;
use strict;

# ------------------------------------------------------------------------------
# default()
# main page
# ------------------------------------------------------------------------------
sub default : Default : Action(".*")
{
    my ($r, $query, $app_name, $controller);

    $r          = Eidolon::Core::Registry->get_instance;
    $app_name   = $r->config->{"app"}->{"name"};
    $query      = $r->cgi->get_query || "";
    $controller = __PACKAGE__;

    if ($query eq "error")
    {
        throw DriverError::Router::NotFound($query);
    }

    $r->cgi->send_header;

    print << "EOT";
<html>
    <head>
        <title>Eidolon</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    </head>
    <body>
        <style type="text/css">
            body {
                margin: 0px;
                padding: 0px;
                text-align: center;
                background-color: #FFF;
            }

            div#window {
                width: 800px;
                height: 100%;
                background-color: #F0F0F0;
            }

            div#header {
                padding: 10px 10px 10px 10px;
                height: 88px;
                text-align: left;
                -moz-box-sizing: border-box;
                background-color: #FFF;
            }

            div#header span {
                color: #909090;
                font-family: Verdana, Tahoma;
                font-size: 7pt;
                margin-left: 3px;
            }

            div#content {
                width: 100%;
                font-size: 9pt;
                font-family: Verdana, Tahoma;
                text-align: left;
                color: #606060;
                padding: 15px 15px 15px 15px;
                -moz-box-sizing: border-box;
            }

            h1 {
                font-size: 16pt;
                margin-top: 0;
                text-transform: lowercase;
                font-weight: normal;
                border-bottom: 1px dashed #606060;
                padding-bottom: 5px;
            }
        </style>
        <center>
            <div id="window">
                <div id="header">
                    <a href="http://www.atma7.com/en/products/eidolon/" title="Eidolon"><img src="/img/logo.png" border="0"></a><br />
                    <span>version $Eidolon::VERSION</span>
                </div>
                <div id="content">
                    <h1><img src="/img/flag.png"> welcome</h1>
                    <p>This is the <em>"/$query"</em> page of <b>$app_name</b> 
                    application. It is handled by the <em>$controller</em> controller. 
                    This controller has only one function with <code>Action(".*")</code> code attribute, 
                    so all user requests except <a href="/error/">/error</a> will lead to this page. The 
                    <a href="/error/">/error</a> request will cause the controller to throw the 
                    <code>DriverError::Router::NotFound</code> exception to show you how error handling works.
                    </p>

                    <p><em>Eidolon</em> is intended to turn a headache of web user interface 
                    development into something easy and full of fun. The main goal of the project is
                    to ease the creation of various web-based backends and systems such as project 
                    management systems, customer relationship management systems, online payment 
                    services and so on. You can use <em>Eidolon</em> for web site creation too, but it
                    isn't recommended - try to use another powerful tools, that are intended for 
                    this task (for example, Typo3 CMF, Moveable Type or, say, Wordpress).
                    </p>

                    <h2>Yet another Perl framework? What for?</h2>

                    <p>
                    There is a lot of another Perl frameworks today - Jifty, Hyper, Konstrukt, Rose,
                    RWDE, Gantry, Catalyst, POE, BlackFramework, etc. Some of them have too much
                    dependencies, some take too much time to do easy things, some force you to use
                    only one way to do something (is it Perl or what?!), some of them are already 
                    unsupported, some are too complicated and have a confusing API... all of this 
                    was the cause of the <em>Eidolon</em> birth.
                    </p>

                    <h2>Features</h2>

                    <ul>
                        <li>
                            Small core
                        </li>
                        <li>
                            Object oriented API
                        </li>
                        <li>
                            CGI and FastCGI support
                        </li>
                        <li>
                            A few dependencies
                        </li>
                        <li>
                            TMTOWTDI
                        </li>
                        <li>
                            Code generator
                        </li>
                    </ul>

                    <br /><br />
                </div>
            </div>
        </center>
    </body>
</html>
EOT
}

1;

__file:[$app_name]/static/config/apache_cgi__
# ==============================================================================
#
#   [$app_name]
#   static/config/apache_cgi - Apache configuration file for CGI application
#
# ==============================================================================

RewriteEngine on
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ cgi-bin/index.cgi?query=$1 [L,QSA]

__file:[$app_name]/static/config/apache_fcgi__
# ==============================================================================
#
#   [$app_name]
#   static/config/apache_fcgi - Apache configuration file for FCGI application
#
# ==============================================================================

RewriteEngine on
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ cgi-bin/index.fcgi?query=$1 [L,QSA]

__file:hex:[$app_name]/static/img/flag.png__
89504E470D0A1A0A0000000D4948445200000010000000100804000000B5FA37EA00000001735247
4200AECE1CE900000002624B474400FF878FCCBF000000097048597300000B1300000B1301009A9C
180000000774494D4507D80A13031E34CD16A1010000016D4944415428CF7591CF2B047118C63F3B
6397B1CBEE22739291522E426DCAC54564F30FB06DE6A275A1F6EA42FE816DF803F630B9B82837CA
414AA4945CFC3A6C2416B3CBECDAC9B0BE0EEB67F2BE97A7B74F4F4FCF8B3EA70B5D13FCB78CE4B6
45F4BE7BAF6FF4F3342B4F2E44CFFA6F06BB04822ACCE04C5BA3D5E82E47A67C3B01A7395C9D5092
ED5C624D33091E5DAB3E98082F3825C5C6CDFA8AF5AA16D078E596E38212D93891D2990BD34F87E2
12A45E55DA6B03322F78F113AE7B4E80046A6A291F23E40A643CB8142901358470E3C3AD12A43357
A6974EDF2B32E052A24889323EEA9A9C8404A0A616F3E3281410BCE16063E3F08883352D01A43359
137A286FE5AC322F3C51C0E2127B575A93A0E261E4C7E93D9487EECEEFB9E69C53A464C3C051CC23
2A0451637E66959BB63DFF73DCD3EAB5039BFB2B005F95EADA58EE50E8C69FAABFE588B12366FFFC
E5234325472A3F06497ECD0F209D299A0FB4C4FF05404DAD231BBF81770FC4ADCEB05386CD000000
0049454E44AE426082

__file:hex:[$app_name]/static/img/logo.png__
89504E470D0A1A0A0000000D494844520000010900000033080600000084FEFD1B00000001735247
4200AECE1CE900000006624B474400FF00FF00FFA0BDA793000000097048597300000B1300000B13
01009A9C180000000774494D4507D906110B1A2EFEAE3AE800001AC64944415478DAED5D697054D7
95FEDEEB4DDD927A915A4BABB522A15D080964B188CDBB1D63C038368E93F2128F13A79C38E571CD
8FFC7255A66AA6E6872B93A9C44EEC380961522E0CC60EC161317830BB50B48224B46FADAD5B522F
EABDFBBDF9D148A8F5EEEB5D3236FD5551C07DAFEF7BEF2EDF3DE7DC73CEA558966511471C71C4C1
033ADE0471C411479C24E288238E3849C411471C2B03E14A55EC6518982D36982C36586C0E389D1E
781906142888C542244A255024CBA094CB201609E33D11471CDF769260591686390BFA47A63034AE
C7A4DE08A7CB0386B96D1765814513290BB0B7FF168904485526234FAB46515E067234291008E202
4E1C71DC2DA0A2DDDD70BADCE8EC1F435BF730A667CC60D8050658460A048220DD234F92A2AA341B
351579502912E33D14471CDF549270B93D68E91AC2F58E3E58ED4EBFC9BF4802242258728DE5230D
16100A0558579A8D6DF52550244BE33D15471CDF249218D24DE38B2B1D9831CE872731842B61B040
4282083BEA4B50B7BE20AE86C411C7DD4E121E8F17179ABBD174A3DF676B08A23A049AFC4BCB4251
470AF3D2B0E7911AC85758AAF07818381C6EB8DC5E783D0C42691EA1488014958C536EB7BB61B138
38E5292932088502625D737336B8DDDEF03B92A2400B28080534C46221241221689A5AF101E470B8
A1D7CF6362D282B9391BE6E79D70BABC60181662B100091221542A19D4EA446469E490CB13405191
BDD79CD10EB7CBE3DFF64201525264AB3661EC7637A6A62C989CB6606ED606ABCD05A7D3F74E2291
0052A908292A19D2D489D06429909C2489F859168B0376BB9B532E120BA152463F0F6666ADF07A18
BF32954A069148101949389C2EFCEDCB260C8EE9399379690D7C12C372F52253ADC0A69A42646B52
C0302C86460DB8FCCF3ECC1AADBCA4A3944B71606F3D34198A9875FAFCBC133D7D7AF4F519A0D399
3067B4C3E5F2C0739B2042699DEC6C25DE7C6307A7FC6AE3300E7FDCCA29FFB77FDD85CC4C39B1AE
DFBC7B11FD0333117D0B4D53A0690A42A18F2852545268B54A9495A6A3A8280D629120266DE6767B
D1D93589E6161DFAFB0DB01106320922218DB4F424ACAFD662434D3654AAF026F76FDFBB84BE7E83
5F5996468EB7DEDCB5A2C4E0747AD0DE318E96561D868667E1707842FA9D58244066A61CB5355AD4
D464874D18878FB4E2EAB5614EB94422C49B3FDF8134755254DFF59FFF7516D3FA79BFB29FFF6C3B
727354FE441C4A6536871347CF5CC3F8D45C681243200903C0FAB25C3CB6739DDF6A9AAA4A4245B1
16473F6F42EFE03451AA9833D971F0F0653CBF7F13B2B35451B3E8D973BD686DD385DCE9773B1886
05C3B0B7A5210FCC66078686E770E9F22052536578605731EA36E644ACB6310C8B8E1BE3F8FC6437
F4CB065748E4E261303E6EC6F8B81967CFF562537D1E1E7EB00452A9E8AE6C4FAF97C1F5A6519CFE
E2168C467B04763B2F4646E730323A87D35FDCC2F68642ECDC591435593B9D1E1CFDA41DAFBEB279
55A4C5A0A3C5E972E3D899461F41B04B240596A02EB0016C11B7EF29C84EC3E3BBAA89E276428208
FBBFB311E9EA64FF3A97D4336F73E1D0916B989C3647F4C12CCBE27AD308DEF9D5795CBD36FCAD21
88A0A43863C3E123ADF8C31FAFC132EF8C48CCFEEB47CD3878A8292282200DF4F35FF5E3BFFFE72B
8C8D19EFBAF6B2581CF8C31FAFE1F091D6880882B3D0DADC3879BA1BBFF9ED45180CD6A8EBEBE9D5
A3F1FAC8AAB4051D6CE53875B10D6353B36009937FE99FC5321EFB03CBFAC4E1477756055CC91224
223CB2A3929780C00256AB131F7DD208ABCD1936417C71B6071F1D6E21EA7AF702BA6F4DE3BDDF5D
82D9EC08F93756AB0BEFFFE10A9A5BC678D52F914880B4B4249496A4A37A5D166AAAB5282D49477A
5A1247C75D8A69FD3C7EF7C1150C0DCFDE356D3467B4E337EF5D42F7AD69DE7B2412213232925156
9A8E9A6A2DD65767A1B8380DEAD4C480E37B74CC88777F7F09D3D396A8DFF3F8899B3121B0A036B7
4017DB6E0DA1AB5FC7AB3A802431805F05599B9701B52A39E84B15E4A621335D81F12913AF5A6398
B5E2F8C9763CB36F23E8100D6157AF0DE3E4E96EE24097CB1350519E89FC3C15525264904AC5100A
E990EA160A5776D7252323193F7CB13E882AC0C0ED66609977625A6FC1C0C02C6EF54C2F1AD59662
62D2823F1D6CC48F5FDD02B1581854643E78E83A8686E7C87D959F822D9B0BB0B6488DE46409C728
C9B22C2C16276EF54CE3E2A5418C12A406ABD58583879AF0B3D7B741A9F87AB7BBED76373EF8F02A
A6A7E709C661A0786D1AB66C2E4041410A921225C485D564B2A3B36B0A172F0D628A4006737376FC
F950135E7FAD212A55CB6E77E3E8A7ED78F985FB223606474512268B0DE71BBB38BB10818820987F
4449A12664035C495126C6274D0149E746D7382A4AC75155AE0D5AA76EDC84CFFE76834310020185
FB77AEC5CE1D4577AD6E2C14D250AB43772C2B2D49C7F6864298CD0EFCE354171AAF8F70BE7B6878
0EA7CEDCC2EEEF5404ACEBECD91EF4F619882BE9537BABB0A13627A05E4C5114E4F204D46DCC456D
4D362E5F19C2DF3FEFE4ECE0188D767CFA59075EF841DD8A0EF860F8F46F1D9898E0AAB24949123C
F374352ACA3303BE1F4D5350A964D8BAA5007575B938F7652FBE38DB73C7F37881A827CC3879AA1B
FBF65645F5BE376F4EA2A54D87DAF5D9ABAF6E5CF867371C2EB79F3D6171AE920862994D825DA696
8005B499AA654C68C7F1E3C771E8D0210C0FFB5B71B3352AAE2AB3CCBEC1B2C0E92F3B836E19320C
8BA3C7DAE15A769F4040E1C0333578ECD1B2BB9620A2815C9E80679E5E8F471F2E255EFFEA423FC6
27F86D3BD3D3169CFFAA9F532E1609F0CACBF5A8DB981B96E14C20A0B1AD610D9E7FAE96289277DC
98C0E0E0D7A7760C0ECDA2E99FA35C824814E3C7AF6E416585262C02138B0478F4E1523CC5430457
AE0D71761782212181BBAE7FFAD98D88EC4C5191C48CD182AE3EDD9D090FFF89B9DCFEB0606F4810
8B20110B7D223ACB952A967B4EBEFFFEFB3879F2247A7A7AF0CB5FFE12B3B37706C8A23F04CBFDB3
F41D66666D686E1F0DF8911D37C63134C41D7CF7EF5A8B0DB539DF6A1B04455178E0FE6254946772
AE79BD2C4E9FE9E6F505397F618043AC00F0C477CA51B8461DF13BADABCAC2AE9D45049B1170FE42
FFD7D65667CFF570242E8A02BEFBF47A6469E411D7BB657301366EE08E338F87C1A54B8361D5B575
4B01542AFF79343FEFBC2D25B3AB4712CD9D43F0320C67E526FD3B492AC1C30D95F8C9F71FC49BAF
3C8A375F790C3F7A7E17766C2E5DD47717DE5D20F03760B5B6B6E2C08103F8C52F7E018661D0D7D7
7747C416D05CC3E8320965A1F0F2D581800DF47FE7B9034FA592E2FE9D6BEF0963254D5378F2890A
E2AA7FB373127304E397CDE6425B9B8E53AED1C8B1A93E3FEA77DAB5A308C9C95C9DFED6AD69A203
DA8A1B2BE76CE8EA9EE294AF5D9B4624D870F1F8636544DB555BC7385CAED077D86452319E7EAA1A
CB059AE69631DCEC9C5C1D92F078BCE8ECD371496199F40016D0A429F1F2B33B71DFFA4228E532D0
340D8180865A958CEDF795E095033BA094CB16EB7038DDCB3A602D8E1F3F8E77DF7D170CC3202F2F
6FF19AC3E921EE7090D48E698305A36364C3DAD4940523A3DC6B751B722191DC3B21EA696949BCD2
C48D1B139CF29E5E3DD1496AF3A6FC98186AA55211D6576B8986D2DE7EC3AAB74F5BFB38D1A0DDB0
B92026BE084A8514E565199C72B3D981319D29ACBA4A4BD251B7219753FEC9A71DB0D95C2B4F12BA
A959D896046CB104E9012C20160BB1EF918D484E4CE0AD3C559584FD8F6F5C9CE886597FFDEBB5D7
5E43797939689AC65B6FBD858C8C3B8D68989927920240268BAE1E328B76754F113BBFA23C03F71A
6AD6930DBC3DBD7A4E5977F734C1A640A1BC3476ED469A3400D0DF3FB3EA6DD3DD334DD4FF8B8AD4
317B4619EFF786478A144561F7EE0A28E4FE73CF68B4E3EF9F77C65CEDE02CA523E33321C55E9415
66F985720F0D0DE1E38F3F86DBEDC6934F3E89CACA4A003E6365414E1A0686F5181A3520579B7287
5D954ABCF8E28BC4171B1836841517D23F486EE881C119E22A96969674CF91C4DAB569C4F2F17113
3C1EEFA2831BC3B01818E2B69B5229E5E8C3D1202B4B019148C0313CEB74ABEB5CC5302C860806D3
2C8D020909B13368E7E5AA4051E02C5AE14A120090281363FFBE75F8F0CF8D7EE5D71A87B17E5D16
8A8BD3574E92983018438AE4CC4C572EFEC6ED76E357BFFA1518868142A1C03BEFBC83F9F93B5283
2643019605DA3BC77CF92682C0E170A3AB6782EB941540F5999834C3EB650813C04C10FD12EE2955
63E9C04A4DE5C64B98CC0E3FCF53ABCD05B3896B17C8CC94C7747B52261511E3190C3356CE96E14A
C26098271A683599C9317D8E3A351142C2AE8E61C61AD1EA5F59A9416D8DBF74C8B2C09163ED7038
DC2B471273B703AC583E3BC0ED17F12C695487C381E9E969ECDEBD1BCF3EFB2CEC763BF47AFD1212
F14D5EBDC1828ECEB1A02F75A5690056ABCBDF164122AB25D7DC2E2FCCCB0C5E6EB7174613D72897
1C4524E237DE3641080A62591F512C9286C94E9C3429CAD8465B0A0434E40AAEBAEA727961B3BB56
AD4DF43C6ED2AA1847970A8502241148717EDE09B78789A8CEBD7BAA38751A0C569C3C7D6BE5D40D
9BCDC9EF1CB5E4FFFD237A6CAAF56D6325262662DDBA75F8F5AF7F0D914884ECEC6CE4E4F8B67C18
96C5C0B07E71629F3C7703D9592AA4AAC8E2FEF0E82CCE5FEA25479906906C18D6E7B9A75A32902D
162791A1756326FCCF6F2FC4AC11D3D392F0EC776BBE1124A150906D484B0D5E261379772129491C
7BE926514C14FFED7637D1A37125C0FBBD2BF0FCC424096737C9E9F4C0E3F64614F8959428C1537B
AB70F050935FF9C54B03A85E978582FC94D89384DBCB708C84249BC0C0B01EBD8353585B90019AA6
F1C61B6FE0E2C58B70BBDD6868688050E8ABBAB97D18D306CB623DF356173EFCDF4B7866CF46E4E5
A4FA3DBBF3D6048E1E6F81CBE525E79CE021888577F378FC573FBBDD4D345A5A6DAE983AED2C484A
DF04C864E489EE7279FDD43D125642454B20D4C9302CDC2EEFAAB589FD6BFE5E8F87894ABD5A5FAD
456B9B0EED1D137E6D78E4682BDEF8E9F6A0AEF76193044D519CF80CD28464181647FFD1847D8FD4
A2A45003A9548A871E7A688908CBA2B9630427BEE8E04825668B031FFCE522F2F3D4C8C95281F1B2
181836606CDCC825842061E74BEFA1697FEDC9EDF1228EE5222F79FB925D3248F944DF95084BE60B
865A4D9B8487C76357B002DF4B0B28E2B746BB23F1D4DE75E8EF9F81758944383169C1D973BD78EC
D1B2D892448244BCE8A3104CCC773A3CF8E8D346E4E7AA5151AC45AA2A092CCB624A6F4647970E63
E3730127F6C0900103B7772542CE4BC1431614C075AD8E1F60C80105F2C05F1AA9C937395664E2F2
54B91A7912823DCBBB4ADF4BD31410A58D4C2E4FC09E272BF1D78F9AFDCABF3CDF87AA4A0DB2B395
B1230965B20C46932DAC643283C3060C0C1938F7879210371489812F69EE5222A3698A1341C8B76A
A6A725A1B25213B37EE7D3F3EF46F049574B49422C26EBC62E77EC25338F975B27450102E1EAE533
E513C7DD2BF1BD04294D703BA358B4D8509B8DB6F6713FCF4B8F87C1914FDAF0FA4F1A785326864D
12E96A0506470D01576EBE09CDF21839F96C0B6127CD0DF07CB59A9BB7402C1610F7A5D5EA443CF1
78F93D2949D8ACE45D0359E21D292C392921ACDF46650FB07B082B2B0D6988FE09B158EB49EEE180
CF101E6B90EC3D628930265EAC1445E1A97DEB303834039BEDCE7346468D387F61000FEC8A2C0C81
F366B95929BC59A1FCA241F93C3211384B15CB2270DABB00CFE5D4B9E4DE82BC5442E793B73A57C2
75F59B02529C064D53902727F889AEA4956D6E05129C90E23484429AB8EB4111DE898D813ECF9754
7645BE9710AD2993892112C626FFA84A29C51384F0FF335FDCC2E4A439362491A755FBC4121EFF88
E593DD4F6A0834B103A5D467B912064B083B2749130BF79512DC85A5521171459A99B5AD88E8FC4D
C0E49485B8922E5531E48A0462E8FCD49425A6EFE2767BFDFC3316909A2A231A3449B6128F9789DA
56929141769A9A9A32C7F47BED7637513A51A726C6D40673DFC65C9496F87B5CBA5C5E1C3DD64E74
380C9B24A40962ACCDCFE04C4C924AC147047C7920964B1E6C9812064B9066C0028989121417915D
8EB3B40AC2EAE58C499EC66F1A6666ADC4B4759A4CB99FBE2A16099049983833B3B698E62D30991C
C449A3CD22674327E552F09D311B1D49C86462A853B9497DC627CC31B54B4C4C9A898496AD55C4B4
9F699AC2FE7DEB3844DF3F3083CB5787A2270900D850951F9234C0F2A8201C02899184C1A7FAD4D7
E5F2E6512CC8233B9374744CDC732471E30639082E2F8F9B79BCB0504D5CF9FB6318A1D93F68204E
9AA242725015C9B9C96A75C5C4A7A2704D2A71318924AE820F7D7DE4B62B2C54C7BCAF535313F138
61EBF3E4A9EEB013F11249223F478D5C6D6AC0AC5041FF8D006A0A824FFE4092CAD23A132442346C
5DC3FB8115E519C4DDA56B8DC331F56FBFDBE1F532B8726D88A78DB821E4E565E4768B5586668661
D1DCC2CD572112D2BC8168A443781886C5C464F46A015FCE88C6EBC331FBDE96561D81F8C4C8CB55
AD489F6FAACFE3B4A5DDEEC6B1CFC2533B683E2BE9030D65FE19A648640104DF8508450A21481C7C
84B2FCB73BB717F919DD38A2AB56090DE1201C93D981AF2E0CDC332471AD718498DC35232399D83E
DA2C05D2D3B92A474FAF9E18591BFEAAAA475F1F3744BDB4348337196E168F1AD2D63E1EF5FB1417
A74126E3DA615A5A7431C96CDDDC32464C8ABBBE5ABB62C18602018DFDFBD671D4B4AEEE6934358F
4647120090AB4DC586EA7CF2F666801D0EA2DD00A1A9177CC15C7C5BA65A8D023B761405D5CFB66F
2B245E3BFB652F3197C2B70D43C3B3387EE226F1DAB6AD6BC84642018DCDF579C415F1E3236D7E9E
7DE1C26C76E0C8B176CED6344D53D8C1D357802FD49A34A1AE378D4017A55A20160B515FC7FD5E97
DB8BC347DAE074457E3E8BC160C567C76F70A52691000D5B0B56B4EFD3D39288394E4F9CE80C798B
37E0E6EC83DBCAA0495784B72D0972C25A225900A16D8712EE91888538F06C4D484131B535D9C41C
856EB7177F3AD888D636DDAABA01AFA68A71BD6904BFFFE00A31B57E9A3A111B37F06759BEAF2E97
78C6E9D4B4051F7C78157373B68826CCFB1F5E25EAC5D555592828E00F48924884A8AECAE24E6497
17EF7F78159D5D5351F5E38EED8544E3E8C0E00CFE72A809F311186D75E326BCF7FE65E284DCBA39
9F28ADC51A5B3617706C2EF35657C8442F78FBEDB7DFE6BB281408909FAB46E7AD09B85C9E889C9C
2209D40AE66DE9CB725D8B621EDD95244D68340A34B78C710691C7C3A0BD631C0303336059402416
2C9EA94951882AA47C4C6722E61DDCBAA5801832BCB02ACECDF9EFCFCBE509D8B2293FE0B358D677
C4DFC201BECD2D3A1CFBAC0397AF0C11BDFC689AC20B3FA80B987C47281440A592A1BD839BDACD64
72A0B9790C000575AA2CA8C86C32D971F1D2203E3ADC82D9591BD1DEF0E20BF705AD272323198DD7
47E0F5FABF90D3E9414BEB1806077DFD2896086E7B32D221F7A1442284542A42671737D7A5DE6045
6B9B0E22910029A9B2808B13CBB2989DB3E1DCB95E1C39DA86790241646B1578EE406D4027AA9B9D
931CC36949717AD8919D344D21374789A6E6B1A0B6884DF579502CF75C0EF600754A129EDF5F8F83
87AFC26A7586962D2AC809E1CBEFE110440022A2690A4FED5DC79B8A8D0F05F92978F2890A1CFBAC
8333E05916E8EB37A0AFDF008AF21D3728160B20A0692084F1A5D1C8831E9E130D26272DF8F7FF38
13F82616F0320C9C4E4FD0A30B290AD8B3BB92771761292A2B32F1F083253879BA9B736DDEEAC2F1
133771EA4C3772B295C8CE5642A594429220F4C5F6383D9899B5614C67844E67F28B345D0A853C01
2FBF581FD281BA696949D8B3BB12473E6923F6636F9F01BD7DBE7E944A45108B039FAE5E909F82E7
9FDBB06492E443376EC615C256E19CD18E239FB4E1C43F3A9193A38456A380522585442C04C3B270
D8DD9899B56174D488F10913919C17BEE1A510083196C8CC94E3A1078AF1F7CF3BC3FE6D486F9995
A9C40BCF6EC6A18FAFC164B6F34EF0480F100E7A0F7BC7F2FDF4FE6AD46DCC8DA8A1B66E2900C3B0
387EA293975159D667010EE71840BEF0EB58AA0DA4D53712888434763F5181AD5B42D385298AC283
0F1483A28053676E11C57997CB8BFE8199884E43D76A15F8C1F7368425766FAACF83DDEEC6E727BB
78D50B96F59DBFB9D43D9984D4653B26BE45A80A42018D8B970788A906EC76377A7AF4E8E909DF9E
5554A8C6F3CFD57256EBD5C0F66D6B70E3E604EF696C11D924FC56CB0C055EF97E0372B35388C646
BEAD4BA29133947B96D5A95024E0872FD5474C100B037EFBB642FCE85F36232B4B8E7B0D39D94AFC
E4B5AD68D8BA262C358AA67D44F1C397EA63961B542211E2C1078AF1FA6B0D61EBE51445E1FE5D6B
F1D20BF7116D26D14220A0B1774F259EFFDE06286314BC279389B0FB890ABCFACAA6AF852016D4C7
FDFBAAC34E6E1396BCA352CAF0D2735BF0D5E55E5CB8DC0797C71B5C7508243184206150145055A9
C1BE3D55316BDCA242357EFED3EDE8EA9E464BEB18FA076660B5BABE75C64B9AA620938AB0668D1A
751B73505A921EF030DB6013B3AC34036BD6A4A2A55587CB9707313E610EABCD28CA974CB7B6261B
5B36E54315E504AF28CF44E1EDF7696E19836EDC04A7D38358248BA6280AB5EBB351569281C6EB23
B8DA380CBD7E3EECEF55AB9350B721079BEAF378ED50AB09AD5681FBEF5F8B93A7BA43FF0E36C2E8
98C969334E9DED444FDFB4AFE14208E70E852096DA243499C978ECD132949765AE687E01AF9781D1
68C79CD10EB3C50197D30B8FC71BF2604B4A92106D24935366F4F672BDEC6A6BB391C8A3A2B4778C
F3A6530BDC93BED806A15000894488C4443114F2042895D280A77A470A9665A1D7CF6370681623A3
46CCCC586134D96FA76263400B2848C44224CB25484D4984364B8E8282546469142B76C0B2C3E1C6
9CD10EA3D1EEF3C4747BE159C8B4C603A5528AAA10D206300C8BC94933868667313A6AC4CCAC0D26
B3032EA7071E0F03819086442C805C9E00756A22B45A05D614A4222323396262EEEDD36372D2DFB7
A2A02005D95A6554EDE4727BD1D4344A54B9D75767217999DF51C424B130504646E770F95A3F3A7B
A6E076790367B50AC1B0495314727355D8B6750DAA2A352B7E62771C71C4B14292C47298CD76DCEC
9E4467F724464666615FB0B093A48765642114D0C8CC94A3BC3403555559D06426DFB3D9ACE388E3
5B4B127EE28CCB8329BD059393669F586672C06177C3E36540D31424122192122548499121333D19
991AF9AA65468E238E38EE029288238E38BE3D882BFC71C411479C24E288238E3849C411471C2B84
FF076895E09830EECEB90000000049454E44AE426082

