#!/usr/bin/perl
use strict;
use Metadata::DB::WUI;
BEGIN { use CGI::Carp 'fatalsToBrowser'; }
use LEOCHARRE::DEBUG;
#$DEBUG = 1;

# # # # # # 



#my $abs_conf = './mdw.conf';


   

# # # # # #
if ( $DEBUG ){
   $Metadata::DB::WUI::DEBUG = 1;
   $CGI::Application::Plugin::MetadataDB::DEBUG = 1;
}


$ENV{HTML_TEMPLATE_ROOT} ||= '/var/www/cgi-bin';
debug("tmpl root $ENV{HTML_TEMPLATE_ROOT}");

my $wui = Metadata::DB::WUI->new();

$wui->run;

