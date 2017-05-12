package Labyrinth;

use warnings;
use strict;

our $VERSION = '5.32';

=head1 NAME

Labyrinth - An extensible website in a box.

=head1 SYNOPSIS

  use Labyrinth;
  my $labyrinth = Labyrinth->new();
  $labyrinth->run();

=head1 DESCRIPTION

Documentation overview for Labyrinth.

Labyrinth began life in 2002, with a small set of plugins to enable various
features of web site management. The core set of plugins are now available as
the Labyrinth-Plugin-Core package, with this package providing the core 
functionality that drives the Labyrinth framework system.

See the individual files for more details on how to use them.

=cut

# -------------------------------------
# Library Modules

use Module::Pluggable   search_path => ['Labyrinth::Plugin'];

# Required Core
use Labyrinth::Audit;
use Labyrinth::DTUtils;
use Labyrinth::Globals  qw(:all);
use Labyrinth::Mailer;
use Labyrinth::Plugins;
use Labyrinth::Request;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Writer;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my %plugins;

# -------------------------------------
# The Program

=head1 FUNCTIONS

=head2 Constructor

=over 4

=item new()

Instantiates the Labyrinth object.

=back

=cut

sub new {
    my $self    = shift;

    # create an attributes hash
    my $atts = {};

    # create the object
    bless $atts, $self;
    return $atts;
}

=head2 Methods

=over 4

=item run()

Provides the dispatch loop, instantiating any configuration required, then
processes each command in turn, before finally publishing the result.

=cut

sub run {
    my ($self,$file,%hash) = @_;
    my ($user,$realm,$command,$request);

    my $LAYOUT = 'public/layout.html';
    my $default_realm = 'public';
    $default_realm = $hash{realm} if(%hash && $hash{realm});

    $tvars{errcode} = '';

    eval {
        Labyrinth::Variables::init();   # initial standard variable values

        UnPublish();                    # Start a fresh slate
        LoadSettings($file);            # Load All Global Settings

        eval "use Labyrinth::Paths";
        unless($@) {
            my $paths = Labyrinth::Paths->new();
            $paths->parse();
        }

        die $tvars{errmess} if($tvars{errcode} && $tvars{errcode} eq 'ERROR');

        MailSet(mailsend => $settings{mailsend}, logdir => $settings{logdir});

        DBConnect();
        ParseParams();

        ## defaults in the event of errors
        $tvars{layout} = $LAYOUT;
        $tvars{content} = '';

        ## session validation & the request
        $user    = ValidSession();
        $realm   = $user ? $user->realm : $default_realm;
        $command = $cgiparams{act};
        $request = Labyrinth::Request->new($realm,$command);
        $tvars{realm} = $realm;

        $self->load;
    };

    die "Cannot start Labyrinth: $@\n"  if($@);

    ## 1. each request is only the start.
    ## 2. upon success or failure it is possible other commands will follow.
    ## 3. the content for each command can be different.
    ## 4. if errcode is set, we check if a failure command is required first.
    ## 5. if no more commands we publish.

    do {
        $tvars{errcode} = undef;

        while(my $action = $request->next_action) {
LogDebug("run: action=$action");
            $self->action($action);

            if($tvars{errcode} && $tvars{errcode} eq 'NEXT')    {
                $tvars{errcode} = undef;
                $command = $tvars{command};
                while($request->next_action) {} # ignore remaining actions
                $request->reset_request($command)   if($command);
                #if($tvars{redirect}) {
                #    Publish();
                #    return;
                #}
            }

            $realm        ||= '';
            $tvars{realm} ||= '';

            if($realm ne $tvars{realm} ) {      # just in case of a login/logout
                $realm = $tvars{realm};
                $request->reset_realm($tvars{realm});
            }

            last if $tvars{errcode};
        }

LogDebug("run: 1.errcode=".($tvars{errcode} || 'undef'));

        if(!defined $tvars{errcode})        { $command = $request->onsuccess }
        elsif($tvars{errcode} eq 'NEXT')    { $command = $tvars{command}     }
        elsif($tvars{errcode} eq 'ERROR')   { $command = $request->onerror   }
        elsif($tvars{errcode} eq 'FAIL')    { $command = $request->onfailure }
        elsif($tvars{errcode})              { $command = 'error-' . lc($tvars{errcode}) }
        else                                { $command = $request->onsuccess }

LogDebug("run: command=".($command || 'undef'));

        if($command)    { $request->reset_request($command) }
        else            { $command = undef }

        #if($tvars{redirect}) {
        #    Publish();
        #    return;
        #}
    } while($command);

    # just in case some joker has tried to access the realm directly
    $request->reset_realm($tvars{realm});

    foreach my $field (qw(layout content)) {
        my $value = $request->$field();
        $tvars{$field} = $value if($value);
    }
LogDebug("run: layout=$tvars{layout}");
LogDebug("run: content=$tvars{content}");
LogDebug("run: loggedin=$tvars{loggedin}");

    return Publish();
}

=item load()

Loads plugins found within the plugin directory.

=item action($action)

Calls the appropriate plugin method.

=back

=cut

sub load {
    my $self = shift;
    load_plugins($self->plugins());
}

sub action {
    my ($self,$action) = @_;
    my ($class,$method) = ($action =~ /(.*)::(.*)/);
    $class = ($class =~ /^Labyrinth/ ? $class : 'Labyrinth::Plugin::' . $class);

    if(my $plugin = get_plugin($class)) {
        eval { $plugin->$method(); };

        # this may fail at the moment, as not all requests have an onerror entry.
        # as such a default (badcommand?) may need to be set.

        if($@) {
            $tvars{errcode} = 'ERROR';
            LogError("action: class=$class, method=$method, FAULT: $@");
        }
    } else {
        $tvars{errcode} = 'MESSAGE';
        LogError("action: class=$class, method=$method, FAULT: class not loaded");
    }
}

1;

__END__

=head1 ADDITIONAL FILES

Additional files are needed to enable Labyrinth and any installed plugins to
work correctly. These files consist of SQL, HTML template and configuration 
files, together with some basic CSS and Javascript files.

Please see the Labyrinth-Demo package for a set of these files.

However, these files are only the beginning, and to implement your website,
you will need to update the appropriate files to use your layout design.

=head1 ADDITION INFORMATION

Although Labyrinth has long been in development, documentation has not been a
priority. As such much of the documentation you may need to understand how to
use Labyrinth is the code itself. If you have the inclination, documentation
patches would be very gratefully received.

The Labyrinth website [1] will eventually feature a documentation site, wiki
and other features which are intended to provide you with the information to
use and extend Labyrinth as you wish.

[1] http://labyrinth.missbarbell.co.uk

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
