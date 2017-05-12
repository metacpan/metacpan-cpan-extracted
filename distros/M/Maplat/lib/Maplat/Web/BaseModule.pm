# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Web::BaseModule;
use strict;
use warnings;

our $VERSION = 0.995;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = bless \%config, $class;
    
    return $self;
}

sub reload {
    confess("Required method 'reload' not implemented!");
}

sub register {
    confess("Required method 'register' not implemented!");
}

sub endconfig {
    # Called after everything is configured and the webserver is ready to serve data.
    # This method is most likely only usefull in forking servers to dump any data
    # that needs to be re-initialized after forking, for example database handles
    # and memcached connections which are also in use before forking)
}

# Convenience functions for registering various callbacks
sub register_webpath {
    my ($self, $path, $funcname) = @_;
    
    $self->{server}->add_webpath($path, $self, $funcname);
    return;
}

BEGIN {
    # Auto-magically generate a number of similar functions without actually
    # writing them down one-by-one. This makes consistent changes much easier, but
    # you need perl wizardry level +10 to understand how it works...
    #
    # Added wizardry points are gained by this module beeing a parent class to
    # all other web modules, so this auto-generated functions are subclassed into
    # every child.
    my @stdFuncs = qw(prefilter postfilter defaultwebdata task loginitem
                        logoutitem sessionrefresh prerender cleanup);
    
    # -- Deep magic begins here...
    for my $a (@stdFuncs){
        #print STDERR "Function " . __PACKAGE__ . "::register_$a will call add_$a\n";
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::register_$a"} =
            sub {
                my $funcname = "add_$a";
                $_[0]->{server}->$funcname($_[0], $_[1]);
            };
    }
    # ... and ends here
}

#sub register_prefilter {
#    my ($self, $funcname) = @_;
#    
#    $self->{server}->add_prefilter($self, $funcname);
#}

1;
__END__

=head1 NAME

Maplat::Web::BaseModule - base module for web modules

=head1 SYNOPSIS

This module is the base module any web module should use.

=head1 DESCRIPTION

When writing a new web module, use this module as a base:

  use Maplat::Web::BaseModule;
  @ISA = ('Maplat::Web::BaseModule');

=head2 new

This creates a new instance of this module. Do not call this function directly, use the "configure" call in
Maplat::Web.

=head2 register

This function needs to be overloaded in every web module. This function is run during startup
once some time after new(). Within this function (and ONLY within this function) you can call
register_*() functions to register your callbacks/hooks.

=head2 reload

This function is called some time after register() and may be called again while the webgui is running. Everytime
reload() is called, you should empty all cached data in this application and reload it from the sources (if applicable).

=head2 endconfig

This is a callback, called when all modules are configured. During this callback, you should close all open
filehandles, network ports and database connections. The cause of this requirement is, that the user may configure
a forking webserver and filehandles/network connections should not be forked. In the case of network connections
and database handles, this might confuse the protocol (and certainly will screw with database transactions). In the case
of filehandles you will run into similar problems.

=head2 register_webpath

This function registers a function of its own module as a webpage. It takes two arguments, 
the webpath and the function name.

  ...
  sub register {
    $self->register_webpath("/foo/bar", "getFooBar");
  }
  ...
  sub getFooBar {
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pagetitle},
        webpath     =>  $self->{admin}->{webpath},
        subject     =>  $subject,
        mailtext   =>  $mailtext,
    );
    ...
    my $template = $self->{server}->{modules}->{templates}->get("sendmail", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
  }

It is possible to register multiple webpaths within the same web module.

The function should return a fully rendered page in the above shown data structure.

=head2 register_prefilter

This function registers a function of its own module as a prefilter (called before the actual rendering
module is called to render the page). It takes one argument, the function name.

The function itself gets called with the $cgi object in question. The module may either modify the CGI object,
or rather more common, return a rendered web page on its own (for example to redirect the browser).

If it returns undef, the page handling continues as usual, if it returns a webpage, this is taken as the actual
rendered page and the "real" rendering module is not called at all.

  ...
  sub register {
    $self->register_prefilter("filterFooBar");
  }
  ...
  sub filterFooBar {
    my ($self, $cgi) = @_;

    my $webpath = $cgi->path_info();

    # if there is a redirect for the current path, just return the
    # pre-parsed response
    if(defined($self->{paths}->{$webpath})) {
        return %{$self->{paths}->{$webpath}};
    }

    return; # No redirection
  }

=head2 register_postfilter

This function registers a function of its own module as a postfilter (called after the actual rendering
module is called to render the page). It takes one argument, the function name.

The function itself gets called with the $cgi object in question plus the $header and the $result references of the rendered
page. The module can change $header and $result as it sees fit. It should return undef in any case.


  ...
  sub register {
    $self->register_postfilter("filterFooBar");
  }
  ...
  sub filterFooBar {
      my ($self, $cgi, $header, $result) = @_;
  
      # Just add the cookie to the header
      if($self->{cookie}) {
          $header->{cookie} = $self->{cookie};
      }

      return;
  }

=head2 register_defaultwebdata

This function registers a function of its own module to add to the %defaultwebdata hash usually used by every
module to start its own webpage hash. It takes one argument, the function name to call

The function itself gets called with the a reference to a %webdata hash. The module can change it as it sees fit, but generally
should not delete any keys.


  ...
  sub register {
    $self->register_defaultwebdata("get_defaultwebdata");
  }
  ...
  sub get_defaultwebdata {
      my ($self, $webdata) = @_;
  
      if($self->{currentData}) {
          $webdata->{userData} = $self->{currentData};
      }
  }


=head2 register_task

This function registers a function of its own module as a cyclic worker function. It takes
one argument, the name of the cyclic function, for example:

  ...
  sub register {
    $self->register_worker("doWork");
  }
  ...
  sub doWork {
    # update $bar with @foo
    ...
  }

It is possible to register multiple cyclic functions within the same web module.

=head2 register_loginitem

This function registers a function of its own module as a hook for whenever a user logs in. It takes
one argument, the function to call.

The function itself gets called with the username and sessionid.

  ...
  sub register {
    $self->register_loginitem("on_login");
  }
  ...
  sub on_login {
    my ($self, $username, $sessionid) = @_;
    # do something
  }

=head2 register_logoutitem

This function registers a function of its own module as a hook for whenever a user logs out. It takes
one argument, the function to call.

The function itself gets called with the sessionid.

  ...
  sub register {
    $self->register_logoutitem("on_logout");
  }
  ...
  sub on_logout {
    my ($self, $sessionid) = @_;
    # do something
  }

=head2 register_sessionrefresh

This function registers a function of its own module as a hook for whenever a logged in user loads a page. It takes
one argument, the function to call.

The function itself gets called with the sessionid.

This is usefull to detect stale sessions.

  ...
  sub register {
    $self->register_sessionrefresh("on_refresh");
  }
  ...
  sub on_refresh {
    my ($self, $sessionid) = @_;
    # do something
  }


=head2 register_prerender

This function registers a function of its own module as a hook for everytime a page is ready to be rendered by the template engine
(it gets triggered by the TemplateCache module).

The function itself gets called with a reference to %webdata.

This is usefull to when you need to modify %webdata, but need all the data from the userpage available. This is for example used in
generating the dynamic menus and views in module Login.

  ...
  sub register {
    $self->register_prerender("on_prerender");
  }
  ...
  sub on_prerender {
    my ($self, $webdata) = @_;
    if($webdata->{foo} eq $bar) {
       $webdata->{baz} = 1;
    }
  }

=head2 register_cleanup

Register a callback for "cleanup" operations after a page has been rendered. This might for example be a function in a
database module that makes sure there are no open transactions.

=head2 get_defaultwebdata

See register_defaultwebdata()

=head1 Configuration

This module is not used directly and doesn't need configuration.

=head1 Dependencies

This module does not depend on other worker modules (but modules using it will, depending on which
register_* callbacks they use)

=head1 SEE ALSO

Maplat::Worker

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
