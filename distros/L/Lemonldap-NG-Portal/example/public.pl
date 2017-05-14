#!/usr/bin/perl
#
# This script can be used to publish (without authentications) templates
# available in public subdirectory of your skin dir.
#
# To use it, configure Apache as so:
#   RewriteRule ^/public* /public.pl
#
# Then /public?page=myfile will display template /skins/pastel/public/myfile.tpl

use Lemonldap::NG::Portal::SharedConf;
use HTML::Template;
use strict;

# Load portal module
my $portal = Lemonldap::NG::Portal::SharedConf->new();

my $skin_dir   = $portal->getApacheHtdocsPath() . "/skins";
my $portal_url = $portal->{portal};
my $portalPath = $portal->{portal};
$portalPath =~ s#^https?://[^/]+/?#/#;
$portalPath =~ s#[^/]+\.pl$##;

my $skin = $portal->getSkin();

# Read query param "page" form url : http://<ip>:<port>/public?page=myPage
my $current_page = $portal->param("page");
$portal->abort('Bad page') unless ( $current_page =~ /^[\w\.\-]+$/ );
my $template_page = "$skin_dir/$skin/public/$current_page.tpl";

# Check if template exist otherwise return 404 (handled by ErrorDocument)
if ( !-e $template_page ) {
    print $portal->header( -status => 404 );
    $portal->quit();
}
else {

    # Template creation
    # Get the template using query param "page"
    my $template = HTML::Template->new(
        filename          => $template_page,
        die_on_bad_params => 0,
        cache             => 0,
        filter            => [
            sub { $portal->translate_template(@_) },
            sub { $portal->session_template(@_) }
        ],
    );

    $template->param(
        PORTAL_URL => $portal_url,
        SKIN_PATH  => $portalPath . "skins",
        SKIN       => $skin,
        SKIN_BG    => $portal->{portalSkinBackground}
    );

    # Custom template parameters
    if ( my $customParams = $portal->getCustomTemplateParameters() ) {
        foreach ( keys %$customParams ) {
            $template->param( $_, $customParams->{$_} );
        }
    }

    print $portal->header('text/html; charset=utf-8');
    print $template->output;
}
