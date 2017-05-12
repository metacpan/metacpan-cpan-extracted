# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Web;
use strict;
use warnings;
use base qw(HTTP::Server::Simple::CGI);
use English '-no_match_vars';

# ------------------------------------------
# MAPLAT - Magna ProdLan Administration Tool
# ------------------------------------------
#   Command-line Version
# ------------------------------------------

our $VERSION = 0.995;

use Template;
use Data::Dumper;
use FileHandle;
use Socket;
use Data::Dumper;
use Maplat::Helpers::Mascot;
use Module::Load;
#use IO::Socket::SSL;

#=!=START-AUTO-INCLUDES
use Maplat::Web::Accesslog;
use Maplat::Web::AutoDialogs;
use Maplat::Web::BaseModule;
use Maplat::Web::BrowserWorkarounds;
use Maplat::Web::CommandQueue;
use Maplat::Web::ComputerDB::Computers;
use Maplat::Web::ComputerDB::GlobalCostunits;
use Maplat::Web::ComputerDB::GlobalOperatingSystem;
use Maplat::Web::ComputerDB::GlobalProdlines;
use Maplat::Web::Debuglog;
use Maplat::Web::DirCleaner;
use Maplat::Web::DocsSearch;
use Maplat::Web::DocsSpreadSheet;
use Maplat::Web::DocsWordProcessor;
use Maplat::Web::Errors;
use Maplat::Web::FileMan;
use Maplat::Web::FiltertableSupport;
use Maplat::Web::Logging::Devices;
use Maplat::Web::Logging::Graphs;
use Maplat::Web::Logging::Report;
use Maplat::Web::Login;
use Maplat::Web::LogoCache;
use Maplat::Web::MapMaker;
use Maplat::Web::MemCache;
use Maplat::Web::MemCachePg;
use Maplat::Web::MemCacheSim;
use Maplat::Web::OracleDB;
use Maplat::Web::PathRedirection;
use Maplat::Web::PostgresDB;
use Maplat::Web::PreventGetWithArgs;
use Maplat::Web::RootFiles;
use Maplat::Web::SendMail;
use Maplat::Web::SessionSettings;
use Maplat::Web::StandardFields;
use Maplat::Web::StaticCache;
use Maplat::Web::Status;
use Maplat::Web::TT::Translate;
use Maplat::Web::TemplateCache;
use Maplat::Web::Themes;
use Maplat::Web::Translate;
use Maplat::Web::UserSettings;
use Maplat::Web::VNC;
use Maplat::Web::VariablesADM;
use Maplat::Web::WebApps;
#=!=END-AUTO-INCLUDES

use Carp;

my %httpstatuscodes = (
    100 => "Continue",
    101 => "Swicthing Protocols",
    200 => "OK",
    201 => "Created",
    202 => "Accepted",
    203 => "Non-Authoritive Information",
    204 => "No Content",
    205 => "Reset Content",
    206 => "Partial Content",
    300 => "Multiple Choices",
    301 => "Moved Permanently",
    302 => "Found",
    303 => "See other",
    304 => "Not modified",
    305 => "Use Proxy",
    306 => "(Unused)",
    307 => "Temporary Redirect",
    400 => "Bad Request",
    401 => "Unauthorized",
    402 => "Payment Required",
    403 => "Forbidden",
    404 => "Not Found",
    405 => "Method Not Allowed",
    406 => "Not Acceptable",
    407 => "Proxy Authentification Required",
    408 => "Request Timeout",
    409 => "Conflict",
    410 => "Gone",
    411 => "Length Required",
    412 => "Precondition Failed",
    413 => "Request Entity Too Large",
    414 => "Request-URI Too Long",
    415 => "Unsupported Media Type",
    416 => "Requested Range Not Satisfiable",
    417 => "Expectation Failed",
    500 => "Internal Server Error",
    501 => "Not Implemented",
    502 => "Bad Gateway",
    503 => "Service Unavailable",
    504 => "Gateway Timeout",
    505 => "HTTP Version Not Supported",
);

sub handle_request {
    my ($self, $cgi) = @_;
    my $webpath = $cgi->path_info(); 
    my %header = (  -system  =>  "MAPLAT Version $VERSION",
                    -creator => 'Rene \'cavac\' Schickbauer',
                    -complaints_to   => 'rene.schickbauer@gmail.com',
                    -expires => 'now',
                    -cache_control=>"no-cache, no-store, must-revalidate",
                    -charset => 'utf-8',
                    -lang => 'en-EN',
                    -title => 'MAPLAT WebGUI',
            '-x-frame-options'    => 'deny', # deny clickjacking, see http://www.webmasterworld.com/webmaster/4022867.htm
        );
    
    my %result = (status    => 404, # Default result
                  type      => "text/plain",
                  data      => "Error 404: Kindly check you URL and try again!\n" .
                                "If you think this error is in error, please contact your " .
                                "system administrator or local network expert\n.",
                  pagedone => 0, # Remember if we still have only the ugly default page.
                  );
    my %fallbackresult = %result; # Just in case

    # At this point in time, we only allow GET, POST or HEAD requests.
    # The other defined HTTP/1.1 methods (PUT, DELETE, TRACE, CONNECT)
    # will get a "405 Method not allowed" response. Unknown method will
    # recieve a "501 Not Implemented"
    if($cgi->request_method() !~ /^(?:GET|POST|HEAD)$/io) {
        if($cgi->request_method() !~ /^(?:PUT|DELETE|TRACE|CONNECT)$/io) {
            $result{status} = 405;
        } else {
            $result{status} = 501;
        }
        delete $result{data};
        delete $result{type};
        $result{pagedone} = 1;
    }
    
    # This works on "prefilters" like Authentification checks, path
    # re-routing ("/" -> "302 /index") and similar.
    # We don't do this behind the scenes but use the appropriate return codes
    # as per RFC. This avoids browser troubles and search engines will show correct
    # results (with the correct links).
    if(!$result{pagedone}) {
        foreach my $filtermodule (@{$self->{prefilter}}) {
            my $module = $filtermodule->{Module};
            my $funcname = $filtermodule->{Function};
            my %preresult = $module->$funcname($cgi);
            if(%preresult) {
                %result = %preresult;
                $result{pagedone} = 1;
                last;
            }
        }
    }
    
    if(!$result{pagedone}) {
        foreach my $dpath (keys %{$self->{webpaths}}) {
            if($webpath =~ /^$dpath/) {
                my $pathmodule = $self->{webpaths}->{$dpath};
                my $module = $pathmodule->{Module};
                my $funcname = $pathmodule->{Function};
                %result = $module->$funcname($cgi);
                last;
            }
        }
    }
    
    foreach my $filtermodule (@{$self->{postfilter}}) {
        my $module = $filtermodule->{Module};
        my $funcname = $filtermodule->{Function};
        $module->$funcname($cgi, \%header, \%result);
    }
    
    # workaround for simpler in-module handling of 404, when no data segment is given
    if($result{status} == 404 && !defined($result{data})) {
        %result = %fallbackresult;
    }

    
    # Set statustext. This uses the standard RFC 2616 texts for the status codes.
    # If a module sets the statustext itself (bad idea except in special circumstances), this
    # is the default
    if(!defined($result{statustext}) || $result{statustext} eq "") {
        if(defined($httpstatuscodes{$result{status}})) {
            $result{statustext} = $httpstatuscodes{$result{status}};
        } else {
            $result{statustext} = "Warning UNDEFINED HTTP STATUS CODE";
        }
    }
       
    print "HTTP/1.1 " . $result{status} . " " . $result{statustext} . "\r\n";
    
    if(defined($result{type})) {
        $header{"-type"} = $result{type};
    }
    if(defined($result{location})) {
        $header{"-location"} = $result{location};
    }
    if(defined($result{expires})) {
        $header{"-expires"} = $result{expires};
    }
    if(defined($result{cache_control})) {
        $header{"-cache_control"} = $result{cache_control};
    }

    # Disable body generation for specific error codes as defined in RFC 2616
    foreach my $nbcode (qw[100 101 204 205 304]) {
        if($result{status} eq $nbcode) {
            delete $result{data};
        }
    }

    # Check to see if we are allowed to generate a Content-Length header field (a "should" in RFC 2616)
    if(defined($result{data})) {
        if(!defined($header{"-Transfer-Encoding"})) {
            $header{"-Content-Length"} = length($result{data});
        }
    }
    
    if(defined($result{"Content-Disposition"})) {
        $header{"-Content-Disposition"} = $result{"Content-Disposition"};
    }

    # Confirm to HEAD request standard. Disable body generation. This should
    # NOT touch any headers incl. Content-Length, we just don't *deliver*
    # the content.
    if($cgi->request_method() eq "HEAD" && defined($result{data})) {
        delete $result{data};
    }

    print $cgi->header(%header);
    if(defined($result{data})) {
        # Some results do not have a body
        print $result{data};
    }
    #print STDERR $result{status} . " $webpath\n";
    return; 
}

sub startconfig {
    my ($self, $maplatconfig, $isCompiled) = @_;
    
    if(!defined($isCompiled)) {
        $isCompiled = 0;
    }
    $self->{compiled} = $isCompiled;

    $self->{maplat} = $maplatconfig;

    if(defined($self->{maplat}->{forking}) && $self->{maplat}->{forking}) {
        # Create new subroutine to tell HTTP::Server::Simple that we want
        # to be a preforking server
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::net_server"} = sub {
            my $server = 'Net::Server::PreFork';
            return $server;
        };

        $self->{maplat}->{forking} = 1;
    } else {
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::net_server"} = sub {
            my $server = 'Net::Server::Single';
            return $server;
        };
        
        $self->{maplat}->{forking} = 0;
    }


    if(defined($self->{maplat}->{usessl}) && $self->{maplat}->{usessl}) {
        # we need to ovverride the _process_request sub, because we need to disable
        # the two calls to binmode.
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::_process_request"} =
            sub {
                my $self = shift;
                
                    # Create a callback closure that is invoked for each incoming request;
                    # the $self above is bound into the closure.
                    sub {
                
                        $self->stdio_handle(*STDIN) unless $self->stdio_handle;
                
                 # Default to unencoded, raw data out.
                 # if you're sending utf8 and latin1 data mixed, you may need to override this
                        #binmode STDIN,  ':raw';
                        #binmode STDOUT, ':raw';
                
                        # The ternary operator below is to protect against a crash caused by IE
                        # Ported from Catalyst::Engine::HTTP (Originally by Jasper Krogh and Peter Edwards)
                        # ( http://dev.catalyst.perl.org/changeset/5195, 5221 )
                        
                        my $remote_sockaddr = getpeername( $self->stdio_handle );
                        my ( $iport, $iaddr ) = $remote_sockaddr ? sockaddr_in($remote_sockaddr) : (undef,undef);
                        my $peeraddr = $iaddr ? ( inet_ntoa($iaddr) || "127.0.0.1" ) : '127.0.0.1';
                        
                        my ( $method, $request_uri, $proto ) = $self->parse_request;
                        
                        if(!$self->valid_http_method($method) ) {
                            $self->bad_request;
                            return;
                        }
                
                        $proto ||= "HTTP/0.9";
                
                        my ( $file, $query_string )
                            = ( $request_uri =~ /([^?]*)(?:\?(.*))?/s );    # split at ?
                
                        $self->setup(
                            method       => $method,
                            protocol     => $proto,
                            query_string => ( defined($query_string) ? $query_string : '' ),
                            request_uri  => $request_uri,
                            path         => $file,
                            localname    => $self->host,
                            localport    => $self->port,
                            peername     => $peeraddr,
                            peeraddr     => $peeraddr,
                            peerport     => $iport,
                        );
                
                        # HTTP/0.9 didn't have any headers (I think)
                        if ( $proto =~ m{HTTP/(\d(\.\d)?)$} and $1 >= 1 ) {
                
                            my $headers = $self->parse_headers
                                or do { $self->bad_request; return };
                
                            $self->headers($headers);
                
                        }
                
                        $self->post_setup_hook if $self->can("post_setup_hook");
                
                        $self->handler;
                    }
                }                
    }
        
    # Clean up configuration
    my %tmpPaths;
    $self->{paths} = \%tmpPaths;
    my %tmpModules;
    $self->{modules} = \%tmpModules;
    my @prefilter;
    $self->{prefilter} = \@prefilter;
    my @prerender;
    $self->{prerender} = \@prerender;
    my @tasks;
    $self->{tasks} = \@tasks;
    my @postfilter;
    $self->{postfilter} = \@postfilter;
    my @default_webdata;
    $self->{default_webdata} = \@default_webdata;
    my @loginitems;
    $self->{loginitems} = \@loginitems;
    my @logoutitems;
    $self->{logoutitems} = \@logoutitems;
    my @sessionrefresh;
    $self->{sessionrefresh} = \@sessionrefresh;
    my @cleanup;
    $self->{cleanup} = \@cleanup;
    
    return; 
}

sub endconfig {
    my ($self) = @_;
    
    # TODO: IMPLEMENT SOME SANITY CHECKS HERE
    
    print "For great justice...\n"; # We REQUIRE an all-your-base reference here!!!
    print "Loading dynamic data...\n";
    foreach my $modname (keys %{$self->{modules}}) {
        print "  Loading data for $modname\n";
        $self->{modules}->{$modname}->reload;   # Reload module's data
    }
    print "Data loaded - calling endconfig...\n";
    foreach my $modname (keys %{$self->{modules}}) {
           $self->{modules}->{$modname}->endconfig;   # Mostly used in preforking servers
    }
    print "Done.\n";
        
    print "\n";
    print "Startup configuration complete! We're go for auto-sequence start.\n";
    print "Starting Maplat Server...\n";
    my $lines = Mascot();
    foreach my $line (@{$lines}) {
        print "$line";
    }
    print "\n";
    return; 

}

sub configure {
    my ($self, $modname, $perlmodulename, %config) = @_;
    
    # Let the module know its configured module name...
    $config{modname} = $modname;
    
    # ...what perl module it's supposed to be...
    my $perlmodule = "Maplat::Web::$perlmodulename";
    if(!defined($perlmodule->VERSION)) {
        if($self->{compiled}) {
            croak("$perlmodule not loaded - no dynamic loading within compiled binaries!");
        } else {
            print "Dynamically loading $perlmodule...\n";
            load $perlmodule;
        }
    }
    
    # Check again
    if(!defined($perlmodule->VERSION)) {
        croak("$perlmodule not loaded");
    }

    $config{pmname} = $perlmodule;

    # and its parent
    $config{server} = $self;

    # also notify the module if it needs to take care of forking issues (database
    # modules probably will)
    $config{forking} = $self->{maplat}->{forking};
    
    $self->{modules}->{$modname} = $perlmodule->new(%config);
    $self->{modules}->{$modname}->register; # Register handlers provided by the module
    print "Module $modname ($perlmodule) configured.\n";
    return; 
}

sub reload {
    my ($self) = @_;
    
    foreach my $modname (keys %{$self->{modules}}) {
        $self->{modules}->{$modname}->reload;   # Reload module's data
    }
    return; 
}

sub run_task {
    my ($self) = @_;
    
    
    # only run tasks if there was no connection (there might be a browser just loading more files)
    my $taskCount = 0;
    foreach my $task (@{$self->{tasks}}) {
        my $module = $task->{Module};
        my $funcname = $task->{Function};
        $taskCount += $module->$funcname();
    }
    return ($taskCount);
}

# Multi-Module calls: Called from one module to run multiple other module functions
sub get_defaultwebdata {
    my ($self) = @_;

    my %webdata = ();
    foreach my $item (@{$self->{default_webdata}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname(\%webdata);
    }
    
    return %webdata;
}

# This is used by the template engine to get last-minute data fields
# just before rendering webdata with a template into a webpage
# Takes a reference to webdata
sub prerender {
    my ($self, $webdata) = @_;

    foreach my $item (@{$self->{prerender}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname($webdata);
    }
    return; 
}

sub user_login {
    my ($self, $username, $sessionid) = @_;

    foreach my $item (@{$self->{loginitems}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname($username, $sessionid);
    }
    return; 
}

sub user_logout {
    my ($self, $sessionid) = @_;

    foreach my $item (@{$self->{logoutitems}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname($sessionid);
    }
    return; 
}

sub sessionrefresh {
    my ($self, $sessionid) = @_;

    foreach my $item (@{$self->{sessionrefresh}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname($sessionid);
    }
    return; 
}

# TRIGGER REGISTRATION: Reserve calls from modules
sub add_webpath {
    my ($self, $path, $module, $funcname) = @_;
    
    my %conf = (
        Module  => $module,
        Function=> $funcname
    );
    
    $self->{webpaths}->{$path} = \%conf;
    return; 
}

BEGIN {
    # Auto-magically generate a number of similar functions without actually
    # writing them down one-by-one. This makes consistent changes much easier, but
    # you need perl wizardry level +12 to understand how it works...

    no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
    
    # -- Deep magic begins here...
    my %varsubs = (
        prefilter       => "prefilter",
        postfilter      => "postfilter",
        defaultwebdata  => "default_webdata",
        task            => "tasks",
        loginitem       => "loginitems",
        logoutitem      => "logoutitems",
        sessionrefresh  => "sessionrefresh",
        cleanup         => "cleanup",
        prerender       => "prerender",
    );
    for my $a (keys %varsubs){
        *{__PACKAGE__ . "::add_$a"} =
            sub {
                my %conf = (
                    Module  => $_[1],
                    Function=> $_[2],
                );
                push @{$_[0]->{$varsubs{$a}}}, \%conf;
            };
    }
    # ... and ends here
}

1;
__END__

=head1 NAME

Maplat::Web - the Maplat WebGUI

=head1 SYNOPSIS

The webgui module is the one responsible for loading all actual rendering modules, dispatches
calls and handles the browser requests.

  my $config = XMLin($configfile,
                    ForceArray => [ 'module', 'redirect', 'menu', 'view', 'userlevel' ],);
  
  $APPNAME = $config->{appname};
  print "Changing application name to '$APPNAME'\n\n";
  
  my @modlist = @{$config->{module}};
  my $webserver = MaplatWeb->new($config->{server}->{port});
  $webserver->startconfig($config->{server});
  
  foreach my $module (@modlist) {
      $webserver->configure($module->{modname}, $module->{pm}, %{$module->{options}});
  }
  
  
  $webserver->endconfig();
  
  # Everything ready to run - notify user
  $webserver->run();


=head1 DESCRIPTION

This webgui is "the root of all evil". It loads and configures the rendering modules, dispatches
browser requests and callbacks/hooks and renders the occasional 404 error messages if no applicable
module for the the browsers request is found.

=head1 WARNING

Warning! If you are upgrading from 0.91 or lower, beware: There are a few incompatible changes in the server
initialization! Please see the Example in the tarball for details.

=head1 SSL Support

SSL support is currently disabled in the source code due to multiple problems with the implementation.

=head1 Configuration and Startup

Configuration is done in stages from the main application, after new(), the first thing to call is startconfig()
to prepare the webserver for module configuration. It takes one argument, the maplat specific part of the webserver
configuration.

After that, for each module to load, configure() is called, during which the module is loaded and configured.

Next thing is to call endconfig(), which notifies the webserver that all required modules are loaded (the webserver
then automatically calls reload() to load all cached data).

After a call to prepare() and an optional call to print_banner() (which the author strongly recommends *grin*) the webserver
is ready to handle browser requests.

=head2 startconfig

Prepare Maplat::Web for module configuration.

=head2 configure

Configure a Maplat::Web module.

=head2 endconfig

Finish up module configuration. Also close all open file handles, database and network connections
in preparation of forking the webserver if applicable.

=head2 handle_request

Handle a web request (internal function).

=head2 get_defaultwebdata

Get the %defaultwebdata hash. Internally, this calls all the defaultwebdata callbacks and generates the hash step-by-step.

=head2 prerender

Call all registered prerender callbacks. Used by Maplat::Web::TemplateCache.

=head2 reload

Call reload() on all configured modules to reload their cached data. This function will not work as expected in a
(pre)forking server.

=head2 run_task

Run all registered task callbacks. Running tasks in the webgui are deprecated, please use a worker for this
functionality. In Maplat::Web, all work should be done on demand, e.g. whenever a page is requested by the
client.

=head2 sessionrefresh

Run all registered sessionrefresh callbacks.

=head2 user_login

Calls all "on login" callbacks when a user is login in.

=head2 user_logout

Calls all "on logout" callbacks when a user logs out.

=head2 add_defaultwebdata

Add a defaultwebdata callback.

=head2 add_loginitem

Add a on login callback.

=head2 add_logoutitem

Add a on logout callback.

=head2 add_postfilter

Add a postfilter callback.

=head2 add_prefilter

Add a prefilter callback.

=head2 add_prerender

Add a prerender callback.

=head2 add_sessionrefresh

Add a sessionrefresh callback.

=head2 add_task

Add a task callback. DEPRECATED, use Maplat::Worker for tasks.

=head2 add_webpath

Register a webpath. The registered module/function is called whenever a corresponding path is used
in a browser request.

=head2 add_cleanup

Add a callback for "cleanup" operations after a page is rendered.

=head1 SEE ALSO

Maplat::Worker

Please also take a look in the example provided in the tarball available on CPAN.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
