use strict;

use Test::More tests => 5;

use Gantry qw{ -Engine=CGI -TemplateEngine=Default };

unshift @Gantry::Engine::CGI::ISA, 'Gantry';

my $cgi_engine_obj = Gantry::Engine::CGI->new(
    {
        config => {
            useless_param => 5,
            other => 12,
            inherited_from => 'root',
            GantryLocation => {
                '/not_root' => {
                    other  => 15,
                    unique => 'hello',
                    inherited_from => 'not_root',
                },
                '/not_root/child' => {
                    other => 25,
                },
            },
        },
        locations => {
            '/' => 'NoSuchApp',
            '/not_root' => 'NoSuchApp::NotRoot',
        },
    }
);

$cgi_engine_obj->location( '/' );
$cgi_engine_obj->{ config }->{ location } = '/';
$cgi_engine_obj->cgi_obj( $cgi_engine_obj );

#--------------------------------------------------------------------
# top level config param retrieval
#--------------------------------------------------------------------

my $useless = $cgi_engine_obj->fish_config( 'useless_param' );

is( $useless, 5, 'top level param' );

#--------------------------------------------------------------------
# overriden param at top level
#--------------------------------------------------------------------

my $other = $cgi_engine_obj->fish_config( 'other' );

is( $other, 12, 'top level param not overriden' );

#--------------------------------------------------------------------
# overriden param at controller level
#--------------------------------------------------------------------

$cgi_engine_obj->location( '/not_root' );
$cgi_engine_obj->{ config }->{ location } = '/not_root';

$other = $cgi_engine_obj->fish_config( 'other' );

is( $other, 15, 'overriden param' );

#--------------------------------------------------------------------
# twice overriden param at second nested controller level
#--------------------------------------------------------------------

$cgi_engine_obj->location( '/not_root/child' );
$cgi_engine_obj->{ config }->{ location } = '/not_root/child';

$other = $cgi_engine_obj->fish_config( 'other' );

is( $other, 25, 'twice overriden' );

#--------------------------------------------------------------------
# inherited from parent location not from root
#--------------------------------------------------------------------

$cgi_engine_obj->location( '/not_root/child' );
$cgi_engine_obj->{ config }->{ location } = '/not_root/child';

my $inherited_from = $cgi_engine_obj->fish_config( 'inherited_from' );

is( $inherited_from, 'not_root', 'twice overriden' );
