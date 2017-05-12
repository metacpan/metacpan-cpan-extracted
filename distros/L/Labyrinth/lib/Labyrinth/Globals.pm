package Labyrinth::Globals;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Globals - Configuration and Parameter Handler for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::Globals qw(:all);

  # database object creation
  DBConnect();

  # Interface (CGI) parameter handling
  ParseParams();

=head1 DESCRIPTION

The Globals package contains a number of variables and functions that are
used across the system. The variables contain input and output values,
and the functions are generic.

=head1 EXPORT

All by default.

  use Labyrinth::Globals qw(:all);          # all methods

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'all' => [ qw(
        LoadAll LoadSettings LoadRules ParseParams
        DBConnect dbh
        ScriptPath ScriptFile
    ) ]
);

@EXPORT_OK  = ( @{$EXPORT_TAGS{'all'}} );
@EXPORT     = ( @{$EXPORT_TAGS{'all'}} );

# -------------------------------------
# Library Modules

use Config::IniFiles;
use Data::Dumper;
use Data::FormValidator;
use Data::FormValidator::Constraints::Upload;
use Data::FormValidator::Constraints::Words;
use Data::FormValidator::Filters::Demoroniser qw(demoroniser);
use File::Basename;
use File::Path;
use File::Spec::Functions;
use IO::File;

use Labyrinth::Audit;
use Labyrinth::Constraints;
use Labyrinth::Constraints::Emails;
use Labyrinth::DBUtils;
use Labyrinth::DIUtils;
use Labyrinth::Filters qw(float2 float3 float5);
use Labyrinth::Media;
use Labyrinth::Variables;
use Labyrinth::Writer;

# -------------------------------------
# Variables

my %rules;          # internal rules hash

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=head2 Loaders

=over 4

=item LoadAll([$dir])

LoadAll() automatically loads and instatiates many global variables. The
method assumes default values are required. Can be called with a base install
directory path, which is then used by LoadSettings().

This method should be called at the beginning of any script.

=item LoadSettings($dir)

LoadSettings() loads a settings file (config/settings.ini) and stores them
in an internal hash. Typical settings are database settings (eq driver,
database, user, password) and general settings (eg administrator email).

LoadSettings() can be passed the name of the base install directory, or it will
attempt to figure it out via the current working directory.

=item LoadRules()

LoadRules() loads a rules file (default is parserules.ini or the name of the
'parsefile' in the settings configuration file) and store the rules in an
internal hash. This hash is then used to verify the contains of any interface
(CGI) parameters passed to the script.

Note that as LoadRules() can be called many times with different rules
files, only the last value of a given rule is stored. This is useful if
you wish to have a standard rules file and wish to load further or
different rules dependant upon the script being used.

=back

=cut

sub LoadAll {
    my $settings = shift;

    LoadSettings($settings);
    ParseParams();
    DBConnect();
}

sub LoadSettings {
    my $settings = shift;
    $settings ||= '';

    # default file names
    my $LOGFILE     = 'audit.log';
    my $PHRASEBOOK  = 'phrasebook.ini';
    my $PARSEFILE   = 'parserules.ini';

#print STDERR "# ENV $_ => $ENV{$_}\n"   for('HTTP_HOST', 'REMOTE_ADDR', 'SERVER_PROTOCOL', 'SERVER_PORT');
    # Server/HTTP values
    my $host            = $ENV{'HTTP_HOST'}   || '';
    my $ipaddr          = $ENV{'REMOTE_ADDR'} || '';
    my ($protocol)      = $ENV{'SERVER_PROTOCOL'}
                            ? ($ENV{'SERVER_PROTOCOL'} =~ m!^(\w+)\b!)
                            : $ENV{'SERVER_PORT'} && $ENV{'SERVER_PORT'} eq '443'
                                ? ('https')
                                : ('http');
    $protocol = lc($protocol);

    my $path            = $ENV{'REQUEST_URI'}  ? 'REQUEST_URI' : 'PATH_INFO';
    my ($req,$script)   = ($ENV{$path} && $ENV{$path} =~ m|^(.*)/([^?]+)|) ? ($1,$2) : ('','');
    my $cgiroot         = ($req =~ /^$protocol:/) ? $req : $protocol . '://' . ($ENV{'HTTP_HOST'} ? $ENV{'HTTP_HOST'} : '') . $req;
    my $docroot         = ($req && $cgiroot =~ m!^((.*)/.*?)! ? $1 : $cgiroot);
    $cgiroot =~ s!/$!!;
    $docroot =~ s!/$!!;

    # set defaults
    my ($cgipath,$webpath) = ($cgiroot,$docroot);

    # load the configuration data
    unless($settings && -r $settings) {
        LogError("Cannot read settings file [$settings]");
        SetError('ERROR',"Cannot read settings file");
        return;
    }

    my $cfg = Config::IniFiles->new( -file => $settings );
    unless(defined $cfg) {
        LogError("Unable to load settings file [$settings]: @Config::IniFiles::errors");
        SetError('ERROR',"Unable to load settings file");
        return;
    }

    # load the configuration data
    for my $sect ($cfg->Sections()) {
        for my $name ($cfg->Parameters($sect)) {
            my @value = $cfg->val($sect,$name);
            next    unless(@value);
            if(@value > 1) {
                $settings{$name} = \@value;
                $tvars{$name}    = \@value      if($sect =~ /^(PROJECT|HTTP|CMS)$/);
            } elsif(@value == 1) {
                $settings{$name} = $value[0];
                $tvars{$name}    = $value[0]    if($sect =~ /^(PROJECT|HTTP|CMS)$/);
            }
        }
    }
    $cfg = undef;

    SetLogFile( FILE   => $settings{'logfile'},
                USER   => 'labyrinth',
                LEVEL  => ($settings{'loglevel'} || 0),
                CLEAR  => (defined $settings{'logclear'}  ? $settings{'logclear'}  : 1),
                CALLER => (defined $settings{'logcaller'} ? $settings{'logcaller'} : 1)
        );

    # evaluate standard path settings
    $settings{'protocol'}   = $protocol;
    $settings{'host'}       = $host;
    $settings{'ipaddr'}     = $ipaddr;
    $settings{'docroot'}    = $docroot;
    $settings{'cgiroot'}    = $cgiroot;
    $settings{'script'}     = $script;
    $settings{'logdir'}     = "$settings{'webdir'}/cache"       unless($settings{'logdir'});
    $settings{'config'}     = "$settings{'cgidir'}/config"      unless($settings{'config'});
    $settings{'templates'}  = "$settings{'cgidir'}/templates"   unless($settings{'templates'});
    $settings{'webpath'}    = $webpath                          unless(exists $settings{'webpath'});
    $settings{'cgipath'}    = $cgipath                          unless(exists $settings{'cgipath'});

    $tvars{$_} = $settings{$_}  for(qw(host docroot cgiroot webpath cgipath script ipaddr));

    $settings{'logfile'}    = "$settings{'logdir'}/$LOGFILE"    unless($settings{'logfile'});
    $settings{'phrasebook'} = "$settings{'config'}/$PHRASEBOOK" unless($settings{'phrasebook'});
    $settings{'parsefile'}  = "$settings{'config'}/$PARSEFILE"  unless($settings{'parsefile'});

    # generate the absolute path, in the event of errors
    foreach my $key (qw(logfile phrasebook parsefile)) {
        next    unless $settings{$key};
        next    if $settings{$key} =~ m|^/|;
        $settings{$key} = File::Spec->rel2abs( $settings{$key} ) ;
    }

    # path & title mappings
    for my $map (qw(path title)) {
        next    unless($settings{$map . 'maps'});
        if( ref($settings{$map . 'maps'}) eq 'ARRAY') {
            for(@{ $settings{$map . 'maps'} }) {
                my ($name,$value) = split(/=/,$_,2);
                $settings{$map . 'map'}{$name} = $value;
            }
        } elsif($settings{$map . 'maps'}) {
            my ($name,$value) = split(/=/,$settings{$map . 'maps'},2);
            $settings{$map . 'map'}{$name} = $value;
        }
    }

#LogDebug("settings=".Dumper(\%settings));

    # set image processing driver, if specified
    Labyrinth::DIUtils::Tool($settings{diutils})    if($settings{diutils});

    $settings{settingsloaded} = 1;
}

sub LoadRules {
    return  if($settings{rulesloaded});

    # ensure we can access the rules file
    my $rules = shift || $settings{'parsefile'} || '';
    if(!$rules || !-f $rules || !-r $rules) {
        LogError("Cannot read rules file [$rules]");
        SetError('ERROR',"Cannot read rules file");
        return;
    }

    my $fh = IO::File->new($rules, 'r');
    unless(defined $fh) {
        LogError("Cannot open rules file [$rules]: $!");
        SetError('ERROR',"Cannot open rules file");
        return;
    }

    %rules = (
        validator_packages => [qw(  Data::FormValidator::Constraints::Upload
                                    Data::FormValidator::Constraints::Words
                                    Labyrinth::Constraints::Emails
                                    Labyrinth::Constraints
                                    Labyrinth::Filters
                               )],
        filters => ['trim', demoroniser()],
        msgs => {prefix=> 'err_'},      # set a custom error prefix
#       untaint_all_constraints => 1,
        missing_optional_valid => 1,
        constraint_methods => {
            realname    => \&realname,
            basicwords  => \&basicwords,
            simplewords => \&simplewords,
            paragraph   => \&paragraph,
            emails      => \&emails,
            url         => \&url,
            ddmmyy      => \&ddmmyy
        },
    );

    my ($required_regex,$optional_regex);

    while(<$fh>) {
        s/\s+$//;

        my ($name,$required,$default,$filters,$constraint,$regex) = split(',',$_,6);
        next    unless($name);

        $name       =~ s/\s+$// if(defined $name);
        $required   =~ s/\s+$// if(defined $required);
        $default    =~ s/\s+$// if(defined $default);
        $filters    =~ s/\s+$// if(defined $filters);
        $constraint =~ s/\s+$// if(defined $constraint);

#       $rules{$name}->{required}   = $required;
#       $rules{$name}->{default}    = $default;
#       $rules{$name}->{constraint} = $constraint;
#       $rules{$name}->{regex}      = "@regex";

        if($name =~ /^:(.*)/) {
            $name = qr/$1/;
            if($required)   {   $required_regex .= "$name|" }
            else            {   $optional_regex .= "$name|" }
            if($constraint) {   $rules{constraint_regexp_map}->{$name} = _constraint($constraint) }
            elsif($regex)   {   $rules{constraint_regexp_map}->{$name} = qr/^$regex$/ }
            else            {   die "no constraint or regex for entry: $name" }
            if($filters)    {   $rules{field_filter_regexp_map}->{$name} = [split(":",$filters)] }
        } else {
            if($required)   {   push @{$rules{required}}, $name }
            else            {   push @{$rules{optional}}, $name }
            if($constraint) {   $rules{constraints}->{$name} = _constraint($constraint) }
            elsif($regex)   {   $rules{constraints}->{$name} = qr/^$regex$/ }
            else            {   die "no constraint or regex for entry: $name" }
            if($default)    {   $rules{defaults}->{$name} = $default }
            if($filters)    {   $rules{field_filters}->{$name} = [split(":",$filters)] }
        }
    }
    $fh->close;

#LogDebug("Constraints: rules=" . Dumper(\%rules));

    if($required_regex) {
        $required_regex =~ s/|$//;
        $rules{required_regexp} = qr/^$required_regex$/;
    }

    if($optional_regex) {
        $optional_regex =~ s/|$//;
        $rules{optional_regexp} = qr/^$optional_regex$/;
    }

    $rules{debug} = 0;

    $settings{rulesloaded} = 1;
}

sub _constraint {
    my $constraint = shift;
    if($constraint eq 'imagefile') {
        my %hash = (
            constraint_method => 'file_format',
            params => [mime_types => [qw!image/jpe image/jpg image/jpeg image/gif image/png!]],
        );
        return \%hash;
    } else {
        my %hash = (
            constraint_method => $constraint,
        );
        return \%hash;
    }

    return $constraint;
}

=head2 Script Name

=over 4

=item ScriptPath()

=item ScriptFile()

=back

=cut

sub ScriptPath {
    return $settings{cgipath}   if($settings{cgipath} =~ m!^http!); # we're assuming only http/https
    return $settings{cgiroot};
}

sub ScriptFile {
    my %hash  = @_;
    my $path  = ScriptPath() || '';
    my $file  = $hash{file} || $settings{script};
    my $query = $hash{query} ? '?' . $hash{query} : '';

    return "$path/$file$query";
}

=head2 Database Handling

=over 4

=item DBConnect()

The method to initiate the Database access object. The method passes the
values held within the internal settings (set LoadSettings()), to the DB
access object constructor. It returns and stores internally the object
reference, which can be accessed across the system via the $dbi scalar.

=item dbh

Returns the reference to the DB access object, as created by the DBConnect()
method, or calls DBConnect() if not previously invoked.

=back

=cut

sub DBConnect {
    return $dbi if $dbi;        # object already exists

    # use settings or defaults
    my $logfile     = $settings{logfile};
    my $phrasebook  = $settings{phrasebook};
    my $dictionary  = $settings{dictionary};

    $dbi = Labyrinth::DBUtils->new({
        driver          => $settings{driver},
        database        => $settings{database},
        dbfile          => $settings{dbfile},
        dbhost          => $settings{dbhost},
        dbport          => $settings{dbport},
        dbuser          => $settings{dbuser},
        dbpass          => $settings{dbpass},
        autocommit      => $settings{autocommit},
        logfile         => $logfile,
        phrasebook      => $phrasebook,
        dictionary      => $dictionary,
    });
    LogDebug("DBConnect DONE");

    $dbi;
}

# used by the DB access object
sub _errors {
    my $err = shift;
    my $sql = shift;
    my $message = '';

    $message  = "$err<br />"                if($err);
    $message .= "<br />SQL=$sql<br />"      if($sql);
    $message .= "ARGS=[".join(",",@_)."]"   if(@_);

    $tvars{failures} = [ { code => 'DB', message => $message } ];
    PublishCode('MESSAGE');
    exit;
}

sub dbh {
    $dbi || DBConnect;
}

=head2 Interface Parameter Handling

=over 4

=item ParseParams($rules)

ParseParams() reads and validates the interface (CGI) parameters that are sent
via a HTTP request, before storing them in the %cgiparams hash. Each parameter
must have a rule for it to be accepted.

The rules file (default is parserules.ini) is automatically loaded and stored.

All valid input parameter values (scalars only) are also automatically stored
in the template variable hash, %tvars. This is to enable templates to be
reparsed in the event of an error, and retain the user's valid entries.

=back

=cut

sub ParseParams {
    LoadRules($_[0])    unless($settings{rulesloaded});

    my $results;

#   LogDebug("rules=".Dumper(\%rules));

    if(!defined $ENV{'SERVER_SOFTWARE'}) {  # commandline testing
        my $file = "$settings{'config'}/cgiparams.nfo";
        if(-r $file) {
            my $fh = IO::File->new($file, 'r')  or return;
            my (%params,$params);
            { local $/ = undef; $params = <$fh>; }
            $fh->close;
            foreach my $param (split(/[\r\n]+/,$params)) {
                my ($name,$value) = $param =~ /(\w+)=(.*)/;
                next    unless($name);

                if($value =~ /\[([^\]]+)\]/) {
                    @{$params{$name}} = split(",",$1);
                } else {
                    $params{$name} = $value;
                }
            }

            LogDebug("params=".Dumper(\%params));
            $results = Data::FormValidator->check(\%params, \%rules);
            $settings{testing} = 1;
        }

    } else {
        my %fdat = $cgi->Vars;
        LogDebug("fdat=".Dumper(\%fdat));

        # Due to a problem with DFV, we handle images separately
        for my $param ( grep { /^IMAGEUPLOAD/ } keys %fdat ) {
            if( $cgi->param($param) ) {
                CGIFile($param);
                $settings{cgiimages}{$param} = 1;
            }
            $cgi->delete($param)
        }

#        my %fields = map {$_ => 1} @{$rules{required}}, @{$rules{optional}};
#        for (keys %fdat) {
#            LogDebug("NO RULE: $_")
#                unless( $fields{$_} ||
#                        ($rules{required_regexp} && $_ =~ $rules{required_regexp}) ||
#                        ($rules{optional_regexp} && $_ =~ $rules{optional_regexp})
#                );
#        }

        $results = Data::FormValidator->check($cgi, \%rules);
    }

    if($results) {
#        LogDebug("results=".Dumper($results));
        my $values = $results->valid;
        %cgiparams = %$values;
        $values = $results->msgs;
        foreach my $key (keys %$values) {
            $tvars{$key} = $values->{$key}  if($key =~ /^err_/);
        }

#       LogDebug("GOT RULE: env="     . Dumper(\%ENV));
#       LogDebug("GOT RULE: rules="   . Dumper(\%rules));
    } else {
        LogDebug("NO Data::FormValidator RESULTS!");
        my( $valids, $missings, $invalids, $unknowns ) = Data::FormValidator->validate($cgi, \%rules);
        LogDebug("NO RULE: valids="   . Dumper($valids));
        LogDebug("NO RULE: invalids=" . Dumper($invalids));
#       LogDebug("NO RULE: missings=" . Dumper($missings));
#       LogDebug("NO RULE: unknowns=" . Dumper($unknowns));
#       LogDebug("NO RULE: env="      . Dumper(\%ENV));
#       LogDebug("NO RULE: rules="    . Dumper(\%rules));
        %cgiparams = %$valids;
        $cgiparams{'err_'.$_} = 'Invalid'   for(@$invalids);
    }

    $cgiparams{$_} = 1 for(keys %{$settings{cgiimages}});

    LogDebug("cgiparams=".Dumper(\%cgiparams));
    LogInfo("ParseParams DONE");
}


1;

__END__

=head1 SEE ALSO

  IO::File,
  Cwd,
  File::Path,
  File::Basename,
  File::Spec::Functions,
  Data::FormValidator,
  Data::FormValidator::Constraints::Upload
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
