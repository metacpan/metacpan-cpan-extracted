package Labyrinth::Request;

use warnings;
use strict;

use vars qw($VERSION $AUTOLOAD);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Request - Request Manager for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::Request;

  # database object creation
  my ($content,@actions) = Request($realm);

=head1 DESCRIPTION

The Request package, given a request string (or defaults), will retrieve
the appropriate actions, template file and continuations for that request.

The configuration of request settings can either be held within INI files
within a designated path or in request table within a database.

If using INI files, each file represents a collection of commands within a
single section. There is one special section, 'realm', which describes the
overall layout files, actions and continuations for the type of account. 
Typically there are at least two realms, 'public' and 'admin'. To describe
the path to these request files, the following should exist within your global
settings file:

  requests=/path/to/request/files

Alternative if you wish to use the request settings from a database table, in
your globale settings file, you will need the following setting:

  requests=dbi

For more information for the database method, please see the 
L<Labyrinth::Request> distribution. 

=cut

# -------------------------------------
# Library Modules

use Config::IniFiles;

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::Variables;
use Labyrinth::Writer;

# -------------------------------------
# Variables

my @configkeys = qw(layout actions content onsuccess onfailure onerror secure rewrite);
my %resetkeys = (onsuccess => 1, onfailure => 1, onerror => 1);
my %stored;

my @autosubs = qw(
    layout
    content
    onsuccess
    onerror
    onfailure
);
my %autosubs = map {$_ => 1} @autosubs;

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=head2 Constructor

=over 4

=item new()

Create a new request object.

=back

=cut

sub new {
    my $self    = shift;
    my $realm   = shift;
    my $request = shift || 'home-'.$realm;
    my @actions;

    ## split the reset request into it's component parts
    my ($section,$command) = split("-",$request);
    $tvars{request} = $request;
    $tvars{section} = $section;
    $tvars{command} = $command;

    # sort the realm out
    my ($layout,$actions,$content,$onsuccess,$onfailure,$onerror)
        = $self->_read_config('realm',$realm,@configkeys);

    $onsuccess = $request;
    @actions = split(",",$actions)   if($actions);

    # create an attributes hash
    my $atts = {
        'actions'   => \@actions,
        'layout'    => $layout,
        'content'   => $content,
        'onsuccess' => $onsuccess,
        'onfailure' => $onfailure,
        'onerror'   => $onerror,
    };

    LogDebug("--new:actions=[@actions]");
#   LogDebug("--new:layout=[$layout]");
#   LogDebug("--new:content=[$content]");

    # create the object
    bless $atts, $self;
    return $atts;
}

=head2 Methods

=head3 Handling Actions

=over 4

=item next_action()

For the current command request, return the next action within its action list.

=item add_actions(@actions)

Add actions to the action list for the current command request.

=back

=cut

sub next_action { my $self = shift; shift @{$self->{actions}} }
sub add_actions { my $self = shift; push  @{$self->{actions}}, @_ }

=head3 Handling Command Resets

=over 4

=item reset_realm($realm)

Reloads settings for a new realm setting.

=item reset_request($request)

Reloads settings for a new command request.

=item redirect

Instead of a local template file or a continuation, a redirect may be used.
This method reformats the URL within a redirect request.

=back

=cut

sub reset_realm {
    my $self    = shift;
    my $realm   = shift;
    my %hash;

    @hash{@configkeys} = $self->_read_config('realm',$realm,@configkeys);

    $self->{section} = 'realm';
    $self->{command} = $realm;  # needed to check onsuccess, etc.

    for(@configkeys) {
        next    unless($hash{$_});
        if($_ eq 'actions') {
            my @actions = split(",",$hash{$_});
            $self->add_actions(@actions);
LogDebug("--reset_realm:actions=@actions");
        } else {
            $self->{$_} = $hash{$_};
#LogDebug("--reset_realm:$_=$self->{$_}");
        }
    }
}

sub reset_request {
    my $self    = shift;
    my $request = shift;
    my %hash;

    ## split the reset request into it's component parts
    my ($section,$command) = split("-",$request);
    $tvars{request} = $request;
    $tvars{section} = $section;
    $tvars{command} = $command;
    return  unless($section && $command);

    # remove any remaining actiona
    while($self->next_action){};

    @hash{@configkeys} = $self->_read_config($section,$command,@configkeys);

    #if($settings{$protocol} eq 'https' && !$hash{secure} || $hash{secure} !~ /^(on|either|both)$/) {
    #    # redirect to HTTP string
    #    $self->redirect('http',$hash{rewrite},$request);
    #    return;
    #} elsif($settings{$protocol} eq 'http' && $hash{secure} && $hash{secure} =~ /^(on|either|both)$/) {
    #    # redirect to HTTPS string
    #    $self->redirect('https',$hash{rewrite});
    #    return;
    #}

    for(@configkeys) {
        next    unless($hash{$_} || $resetkeys{$_});
        if($_ eq 'actions') {
            my @actions = split(",",$hash{$_});
            $self->add_actions(@actions);
LogDebug("--reset_request:actions=@actions");
        } else {
            $self->{$_} = $hash{$_};
LogDebug("--reset_request:$_=" . (defined $self->{$_} ? $self->{$_} : ''));
        }
    }
}

sub redirect {
    my ($self,$protocol,$rewrite,$request) = @_;

    return $tvars{redirect}    if(!$protocol);

    # set to existing query string, with new protocol
    $tvars{redirect} = "$protocol://$ENV{HTTP_HOST}";

    if(defined $rewrite) {
        $tvars{redirect} .= $rewrite;
    } else {
        $tvars{redirect} .= $ENV{REQUEST_URI}  if($ENV{REQUEST_URI});

        # rewrite query string
        if(defined $request) {
            $tvars{redirect} =~ s/\?.*//;
            $tvars{redirect} .= "?act=$request" if($request);
        }
    }
}

# private method to read config data

sub _read_config {
    my ($self,$section,$command,@keys) = @_;
    my @values;

LogDebug("--read_config:section=$section,command=$command,request=$settings{requests}");

    if($settings{requests} eq 'dbi') {
        my @rows = $dbi->GetQuery('hash','GetRequest',$section,$command);
        if(@rows) {
            push @values, map {$rows[0]->{$_}} @keys;
        } else {
            push @values, map {''} @keys;
        }
    } else {
        my $file = "$settings{requests}/$section.ini";
        Croak("Cannot read configuration file [$file]\n")   unless(-r $file);
        my $cfg = Config::IniFiles->new( -file => $file );
        Croak("Cannot access configuration file [$file]: @Config::IniFiles::errors\n") unless($cfg);

        for my $key (@keys) {
            my $value  = $cfg->val( $command, $key );
    #LogDebug("--_read_config:[$command-$key]=[$value], file=[$file]");
            push @values, ($value ? $value : undef);
        }
    }
    return @values;
}

=head2 Accessor Methods

=over 4

=item layout

Layout template to be used

=item content

Content template to be used

=item onsuccess

Command to execute if this command succeeds.

=item onerror

Command to execute if this command fails.

=item onfailure

Command to execute if this command fails with an unrecoverable error.

=back

=cut

sub AUTOLOAD {
    no strict 'refs';
    my $name = $AUTOLOAD;
    $name =~ s/^.*:://;
    die "Unknown sub $AUTOLOAD\n"   unless($autosubs{$name});

    *$name = sub {
        my $self = shift;
        my $value = $self->{$name};
        if($name =~ /^on/) { $self->{$name} = undef }   # once seen, forget it
        return $value;
    };
    goto &$name;
}

sub DESTROY {}

1;

__END__

=head1 SEE ALSO

  Config::IniFiles
  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
