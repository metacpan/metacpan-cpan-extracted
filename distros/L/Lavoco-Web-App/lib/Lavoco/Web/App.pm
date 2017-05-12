package Lavoco::Web::App;

use 5.006;

use Moose;

use Data::Dumper;
use DateTime;
use Email::Stuffer;
use Encode;
use File::Slurp;
use FindBin qw($Bin);
use JSON;
use Log::AutoDump;
use Plack::Handler::FCGI;
use Plack::Request;
use Template;
use Term::ANSIColor;
use Time::HiRes qw(gettimeofday);

$Data::Dumper::Sortkeys = 1;

=head1 NAME

Lavoco::Web::App - Experimental framework with two constraints: FastCGI and Template::Toolkit.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

Framework to run small web apps, URL dispatching based on a flexible config file, rendering Template::Toolkit templates, running as a FastCGI application.

 use Lavoco::Web::App;
 
 my $app = Lavoco::Web::App->new;
 
 my $action = lc( $ARGV[0] );   # (start|stop|restart)
 
 $app->$action;

=cut

=head1 METHODS

=head2 Class Methods

=head3 new

Creates a new instance of the web-app object.

=head2 Attributes

=cut

has  processes => ( is => 'rw', isa => 'Int',  default => 5         );
has  base      => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build_base'      );
has  dev       => ( is => 'rw', isa => 'Bool', lazy => 1, builder => '_build_dev'       );
has _pid       => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build__pid'      );
has _socket    => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build__socket'   );
has  templates => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build_templates' );
has  filename  => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build_filename'  );
has  config    => ( is => 'rw', isa => 'HashRef' );
has _mtime     => ( is => 'rw', isa => 'Num', default => 0 );

sub _build_base
{
    return $Bin;
}

sub _build_dev
{
    my $self = shift;

    return 0 if $self->base =~ m:/live:;

    return 1;
}

sub _build__pid
{
    my $self = shift;

    return $self->base . '/app.pid';
}

sub _build__socket
{
    my $self = shift;

    return $self->base . '/app.sock';
}

sub _build_templates
{
    my $self = shift;

    return $self->base . '/templates';
}

sub _build_filename
{
    my $self = shift;

    return $self->base . '/app.json';
}

=head3 base

The base directory of the application, detected using L<FindBin>.

=head3 dev

A simple boolean flag to indicate whether you're running a development instance of the web-app.

It's on by default, and currently turned off if the base directory contains C</live>.  Feel free to set it based on your own logic before calling C<start()>.

I typically use working directories such as C</home/user/www.example.com/dev> and C</home/user/www.example.com/live>.

This flag is useful to disable things like Google Analytics on the dev site.

The application object is available to all templates under the name C<app>.

e.g. C<[% IF app.dev %] ... [% END %]>

=head3 processes

Number of FastCGI process to spawn, 5 by default.

 $app->processes( 10 );

=head3 templates

The directory containing the TT templates, by default it's C<$app-E<gt>base . '/templates'>.

=head3 filename

Filename for the config file, default is C<app.json> and only JSON is currently supported.

=head3 config

The config as a hash-reference.

=head2 Instance Methods

=head3 start

Starts the FastCGI daemon.  Performs basic checks of your environment and dies if there's a problem.

=cut

sub start
{
    my $self = shift;

    if ( -e $self->_pid )
    {
        print "PID file " . $self->_pid . " already exists, I think you should kill that first, or specify a new pid file with the -p option\n";
        
        return $self;
    }

    $self->_init;

    print "Building FastCGI engine...\n";
    
    my $server = Plack::Handler::FCGI->new(
        nproc      =>   $self->processes,
        listen     => [ $self->_socket ],
        pid        =>   $self->_pid,
        detach     =>   1,
    );
    
    $server->run( $self->_handler );
}

sub _init
{
    my ( $self, %args ) = @_;

    ###############################
    # make sure there's a log dir #
    ###############################

    printf( "%-50s", "Checking logs directory");

    my $log_dir = $self->base . '/logs';

    if ( ! -e $log_dir || ! -d $log_dir )
    {
        _print_red( "[ FAIL ]\n" );
        print $log_dir . " does not exist, or it's not a folder.\nExiting...\n";
        exit;
    }

    _print_green( "[  OK  ]\n" );

    #####################################
    # make sure there's a templates dir #
    #####################################

    printf( "%-50s", "Checking templates directory");

    if ( ! -e $self->templates || ! -d $self->templates )
    {
        _print_red( "[ FAIL ]\n" );
        print $self->templates . " does not exist, or it's not a folder.\nExiting...\n";
        exit;
    }

    _print_green( "[  OK  ]\n" );

    ###########################
    # make sure 404.tt exists #
    ###########################

    printf( "%-50s", "Checking 404 template");

    my $template_404_file = $self->templates . '/404.tt';

    if ( ! -e $template_404_file )
    {
        _print_red( "[ FAIL ]\n" );
        print $template_404_file . " does not exist.\nExiting...\n";
        exit;
    }

    _print_green( "[  OK  ]\n" );

    ########################
    # load the config file #
    ########################

    printf( "%-50s", "Checking config");

    if ( ! -e $self->filename )
    {
        _print_red( "[ FAIL ]\n" );
        print $self->filename . " does not exist.\nExiting...\n";
        exit;
    }

    my $string = read_file( $self->filename, { binmode => ':utf8' } );

    my $config = undef;

    eval {
        my $json = JSON->new;

        $json->relaxed( 1 );

        $config = $json->decode( $string );
    };

    if ( $@ )
    {
        _print_red( "[ FAIL ]\n" );
        print "Config file error...\n" . $@ . "Exiting...\n";
        exit;
    }

    ###################################
    # basic checks on the config file #
    ###################################

    if ( ! $config->{ pages } )
    {
        _print_red( "[ FAIL ]\n" );
        print "'pages' attribute missing at top level.\nExiting...\n";
        exit;
    }

    if ( ref $config->{ pages } ne 'ARRAY' )
    {
        _print_red( "[ FAIL ]\n" );
        print "'pages' attribute is not a list.\nExiting...\n";
        exit;
    }

    if ( scalar @{ $config->{ pages } } == 0 )
    {
        _print_organge( "[ISSUE]\n" );
        print "No 'pages' defined in config, this will result in a 404 for all requests.\n";
    }

    my %paths = ();

    foreach my $each_page ( @{ $config->{ pages } } )
    {
        if ( ! $each_page->{ path } )
        {
            _print_red( "[ FAIL ]\n" );
            print "'path' attribute missing for page..." . ( Dumper $each_page );
            exit;
        }

        if ( ! $each_page->{ template } )
        {
            _print_red( "[ FAIL ]\n" );
            print "'template' attribute missing for page..." . ( Dumper $each_page );
            exit;
        }

        if ( exists $paths{ $each_page->{ path } } )
        {
            _print_red( "[ FAIL ]\n" );
            print "Path '" . $each_page->{ path } . "' found more than once.\nExiting...\n";
            exit;
        }

        $paths{ $each_page->{ path } } = 1;
    }

    _print_green( "[  OK  ]\n" );

    return $self;
}

sub _print_green 
{
    my $string = shift;
    print color 'bold green'; 
    print $string;
    print color 'reset';
}

sub _print_orange 
{
    my $string = shift;
    print color 'bold orange'; 
    print $string;
    print color 'reset';
}

sub _print_red 
{
    my $string = shift;
    print color 'bold red'; 
    print $string;
    print color 'reset';
}

=head3 stop

Stops the FastCGI daemon.

=cut

sub stop
{
    my $self = shift;

    if ( ! -e $self->_pid )
    {
        return $self;
    }
    
    open( my $fh, "<", $self->_pid ) or die "Cannot open pidfile: $!";

    my @pids = <$fh>;

    close $fh;

    chomp( $pids[0] );

    print "Killing pid $pids[0] ...\n"; 

    kill 15, $pids[0];

    return $self;
}

=head3 restart

Restarts the FastCGI daemon, with a 1 second delay between stopping and starting.

=cut

sub restart
{
    my $self = shift;
    
    $self->stop;

    sleep 1;

    $self->start;

    return $self;
}

=head1 CONFIGURATION

The app should be a simple Perl script in a folder with the following structure:

 app.pl      # see the synopsis
 app.json    # see below
 app.pid     # generated, to control the process
 app.sock    # generated, to accept incoming FastCGI connections
 logs/
 templates/
     404.tt

The config file is read for each and every request, this makes adding new pages easy, without the need to restart the application.

The config file should be placed in the C<base> directory of your application.

See the C<examples> directory for a sample JSON config file, something like the following...

 {
    "pages" : [
       {
          "path" : "/",
          "template":"index.tt",
          ...
       },
       ...
    ]
    ...
    "send_alerts_from":"The Example App <no-reply@example.com>",
    "send_404_alerts_to":"you@example.com",
    ...
 }

The entire config hash is available in all templates via C<[% app.config %]>, there are only a couple of mandatory/reserved attributes.

The mandatory field in the config is C<pages>, an array of pages.

Each C<page> should contain a C<path> (for URL matching) and C<template> to render.

All other fields are completely up to you, to fit your requirements.

When a request is made, a lookup is performed for a page by matching the C<path>, which then results in rendering the associated C<template>.

If no page is found, the template C<404.tt> will be rendered, make sure you have this file ready in the templates directory.

The C<page> object is available in the rendered template, eg, C<[% page.path %]>

It is often useful to have sub-pages and categories, etc.  Simply create a C<pages> attribute in a C<page> object as another array of C<page> objects.

If a sub-page is matched and selected for a request, an extra key for C<parents> is included in the C<page> object as a list of the parent pages, this is useful for building breadcrumb links.

=cut

# returns a code-ref for the FCGI handler/server.

sub _handler
{
    my $self = shift;

    return sub {

        ##############
        # initialise #
        ##############

        my $req = Plack::Request->new( shift );

        my %stash = (
            app      => $self,
            req      => $req,
            now      => DateTime->now,
            started  => join( '.', gettimeofday ),
        );

        my $log = Log::AutoDump->new( base_dir => $stash{ app }->base . '/logs', filename => 'app.log' );

        $log->debug("Started");

        my $path = $req->uri->path;

        $log->debug( "Requested path: " . $path ); 

        $stash{ app }->_reload_config( log => $log );

        ###############
        # sitemap xml #
        ###############

        if ( $path eq '/sitemap.xml' )
        {
            return $stash{ app }->_sitemap( log => $log, req => $req, stash => \%stash );
        }

        ##########################################################################
        # find a matching 'page' from the config that matches the requested path #
        ##########################################################################

        # need to do proper recursion here

        foreach my $each_page ( @{ $stash{ app }->{ config }->{ pages } } )
        {
            if ( $path eq $each_page->{ path } )
            {
                $stash{ page } = $each_page;

                last;
            }

            if ( ref $each_page->{ pages } eq 'ARRAY' )
            {
                foreach my $each_sub_page ( @{ $each_page->{ pages } } )
                {
                    if ( $path eq $each_sub_page->{ path } )
                    {
                        $stash{ page } = $each_sub_page;

                        $stash{ page }->{ parents } = [];
                        
                        push @{ $stash{ page }->{ parents } }, $each_page;
                        
                        last;
                    }
                }
            }
        }

        $log->debug( "Matching page found in config...", $stash{ page } ) if exists $stash{ page };

        #######
        # 404 #
        #######
        
        if ( ! exists $stash{ page } )
        {
            return $stash{ app }->_404( log => $log, req => $req, stash => \%stash );
        }

        ##############################
        # responding with a template #
        ##############################

        my $res = $req->new_response;

        $res->status( 200 );

        my $tt = Template->new( ENCODING => 'UTF-8', INCLUDE_PATH => $stash{ app }->templates );

        $log->debug("Processing template: " . $stash{ app }->templates . "/" . $stash{ page }->{ template } );

        my $body = '';

        $tt->process( $stash{ page }->{ template }, \%stash, \$body ) or $log->debug( $tt->error );

        $res->content_type('text/html; charset=utf-8');

        $res->body( encode( "UTF-8", $body ) );

        #########
        # stats #
        #########

        $stash{ took } = join( '.', gettimeofday ) - $stash{ started };
        
        $log->debug( "Took " . sprintf("%.5f", $stash{ took } ) . " seconds");

        #######################################
        # cleanup (circular references, etc.) #
        #######################################

        # need to do deep pages too!

        delete $stash{ page }->{ parents } if exists $stash{ page };

        return $res->finalize;
    }
}

sub _sitemap
{
    my ( $self, %args ) = @_;

    my $log = $args{ log };    
    my $req = $args{ req };
    my $stash = $args{ stash };

    my $base = ($req->env->{'psgi.url_scheme'} || "http") .
        "://" . ($req->env->{HTTP_HOST} || (($req->env->{SERVER_NAME} || "") . ":" . ($req->env->{SERVER_PORT} || 80)));

    my $sitemap = '<?xml version="1.0" encoding="UTF-8"?>';

    $sitemap .= "\n";

    $sitemap .= '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">';

    $sitemap .= "\n";

    # need to do proper recursion here

    foreach my $each_page ( @{ $stash->{ app }->config->{ pages } } )
    {
        $sitemap .= "<url><loc>" . $base . $each_page->{ path } . "</loc></url>\n";

        if ( ref $each_page->{ pages } eq 'ARRAY' )
        {
            foreach my $each_sub_page ( @{ $each_page->{ pages } } )
            {
                $sitemap .= "<url><loc>" . $base . $each_sub_page->{ path } . "</loc></url>\n";        
            }
        }
    }
    
    $sitemap .= "</urlset>\n";

    my $res = $req->new_response;

    $res->status(200);

    $res->content_type('application/xml; charset=utf-8');
    
    $res->body( encode( "UTF-8", $sitemap ) );

    return $res->finalize;
}

sub _404
{
    my ( $self, %args ) = @_;

    my $log = $args{ log };    
    my $req = $args{ req };
    my $stash = $args{ stash };

    $stash->{ page } = { template => '404.tt' };

    if ( $stash->{ config }->{ send_alerts_from } && $stash->{ config }->{ send_404_alerts_to } )
    {
        $stash->{ app }->_send_email(
            from      => $stash->{ config }->{ send_alerts_from },
            to        => $stash->{ config }->{ send_404_alerts_to },
            subject   => "404 - " . $req->uri,
            text_body => "404 - " . $req->uri . "\n\nReferrer: " . ( $req->referer || 'None' ) . "\n\n" . Dumper( $req ) . "\n\n" . Dumper( \%ENV ),
        );
    }

    my $res = $req->new_response;

    $res->status( 404 );

    $res->content_type('text/html; charset=utf-8');

    my $tt = Template->new( ENCODING => 'UTF-8', INCLUDE_PATH => $stash->{ app }->templates );

    $log->debug("Processing template: " . $stash->{ app }->templates . "/" . $stash->{ page }->{ template } );

    my $body = '';

    $tt->process( $stash->{ page }->{ template }, $stash, \$body ) or $log->debug( $tt->error );

    $res->content_type('text/html; charset=utf-8');

    $res->body( encode( "UTF-8", $body ) );

    return $res->finalize;
}

sub _reload_config
{
    my ( $self, %args ) = @_;

    my $log = $args{ log };    

    my $mtime = ( stat $self->filename )[ 9 ];

    return $self if $mtime == $self->_mtime;

    $log->debug( "Opening config file: " . $self->filename );

    my $string = read_file( $self->filename, { binmode => ':utf8' } );

    my $config = undef;

    eval {
        my $json = JSON->new;

        $json->relaxed( 1 );

        $self->config( $json->decode( $string ) );
    };

    $log->debug( $@ ) if $@;

    $self->_mtime( ( stat $self->filename )[ 9 ] );

    $log->debug( $self->filename . " last modified " . $self->_mtime );

    return $self;
}

sub _send_email
{
    my ( $self, %args ) = @_;

    if ( $args{ to } )
    {
        Email::Stuffer->from( $args{ from } )
            ->to( $args{ to } )
            ->subject( $args{ subject } )
            ->text_body( $args{ text_body } )
            ->send;
    }

    return $self;
}

=head1 TODO

Deep recursion for page/path lookups.

Deep recursion for sitemap.

Cleanup deeper recursion in pages with parents.

Searching, somehow, of some set of templates.

=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

