#!/usr/bin/perl

use strict;
use warnings;

use GRNOC::WebService::Dispatcher;
use GRNOC::WebService::Method;
use GRNOC::WebService::Method::CDS;
use GRNOC::WebService::Regex;

sub test {
    my $method = shift;
    my $p_ref = shift;
    my $state_ref = shift;

    return {'results' => {'success' => 1}};
}

sub echo {

    my ( $method, $args, $state ) = @_;

    return {'results' => [{'foo' => $args->{'foo'}{'value'}}]};
}

sub page {

    my ( $method, $args ) = @_;

    my $limit = $args->{'limit'}{'value'};
    my $offset = $args->{'offset'}{'value'};
    my $hard_error = $args->{'hard_error'}{'value'};
    my $soft_error = $args->{'soft_error'}{'value'};

    die( 'hard erroring out' ) if ( $hard_error );

    return {'error' => 1, 'error_text' => 'soft error'} if ( $soft_error );

    my @data = ( {'lol' => 'wut'},
                 {'foo' => 'bar'},
                 {'deez' => 'nutz'},
                 {'meow' => 'mix'} );

    my $total = @data;

    if ( defined( $limit ) ) {

        @data = splice( @data, $offset, $limit );
    }

    return {'total' => $total,
            'offset' => $offset,
            'results' => \@data};
}

sub error_out {
    die;
}

my $web_svc = GRNOC::WebService::Dispatcher->new(allowed_proxy_users => ["cds-remote-user"]);

my $test_meth = GRNOC::WebService::Method->new(
    name           => 'test',
    description    => 'test webservice',
    expires        => "-1d",
    callback       =>  \&test,
    );

my $echo_meth = GRNOC::WebService::Method->new( name => 'echo',
                                                description => 'echo method',
                                                expires => '-1d',
                                                callback => \&echo );

$echo_meth->add_input_parameter( name => 'foo',
                                 pattern => $NAME_ID,
                                 required => 0,
                                 multiple => 1,
                                 description => 'test input param' );

my $error_meth = GRNOC::WebService::Method->new (name => 'error_out',
                                                 description => 'method that just dies',
                                                 expires => '-1d',
                                                 callback => \&error_out);

my $page_meth = GRNOC::WebService::Method::CDS->new( name => 'page',
                                                     description => 'Method that supports limit and offset parameters.',
                                                     default_order_by => ['lol'],
                                                     expires => '-1d',
                                                     callback => \&page );

$page_meth->add_input_parameter( name => 'hard_error',
                                 pattern => '^(0|1)$',
                                 required => 0,
                                 multiple => 0,
                                 description => 'Whether to hard error out of the request.' );

$page_meth->add_input_parameter( name => 'soft_error',
                                 pattern => '^(0|1)$',
                                 required => 0,
                                 multiple => 0,
                                 description => 'Whether to soft error out of the request.' );

$web_svc->register_method( $echo_meth );
$web_svc->register_method( $test_meth );
$web_svc->register_method( $error_meth );
$web_svc->register_method( $page_meth );

my $status = $web_svc->handle_request();
