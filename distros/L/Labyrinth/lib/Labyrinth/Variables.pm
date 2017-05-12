package Labyrinth::Variables;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Variables - Generic Variables for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::Variables;

  # output values
  $tvars{title} = 'My Title';

=head1 DESCRIPTION

The Variables package contains a number of variables that are
used across the system. The variables contain input and output values,
and the functions are generic.

=head1 EXPORT

  use Labyrinth::Variables;             # default (:all) = (:vars :subs)
  use Labyrinth::Variables  qw(:vars);  # all variable containers
  use Labyrinth::Variables  qw(:subs);  # all standard subroutines
  use Labyrinth::Variables  qw(:xsub);  # all extended subroutines

=cut

# -------------------------------------
# Constants

use constant    PUBLIC      => 0;
use constant    USER        => 1;
use constant    EDITOR      => 2;
use constant    PUBLISHER   => 3;
use constant    ADMIN       => 4;
use constant    MASTER      => 5;

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'vars' => [ qw(
        PUBLIC USER EDITOR PUBLISHER ADMIN MASTER
        $dbi %cgiparams %tvars %settings $cgi
    ) ],
    'subs' => [ qw(
        CGIArray ParamsCheck SetError SetCommand
    ) ],
    'all' => [ qw(
        PUBLIC USER EDITOR PUBLISHER ADMIN MASTER
        $dbi %cgiparams %tvars %settings $cgi
        CGIArray ParamsCheck SetError SetCommand
        LoadProfiles LoadAccess
    ) ],
);

@EXPORT_OK  = ( @{$EXPORT_TAGS{'all'}} );
@EXPORT     = ( @{$EXPORT_TAGS{'all'}} );

# -------------------------------------
# Library Modules

use Config::IniFiles;
use Regexp::Assemble;

# -------------------------------------
# Variables

=head2 Global Variables

=over 4

=item %cgiparams

Holds all the scalar CGI parameter values. Access parameters as:

  my $value = $cgiparams{$name};

=item %tvars

Holds all the template variable values, for use with the template parser.
Access template variables as:

  my $value = $tvars{$name};    # get the named variable
  $tvars{$name} = $value;       # set scalar variable
  $tvars{$hash} = \%hash;       # set hash variable
  $tvars{$list} = \@list;       # set array variable

=item $dbi

Holds the reference to the DB access object. Created by the DBConnect()
method, which must be called before any database activity commences.

=back

=cut

our %cgiparams;     # contains valid CGI parameters
our %tvars;         # template variable container
our %settings;      # internal settings hash
our $dbi;           # database object
our $cgi;           # CGI object

# -------------------------------------
# Variable Functions

=head2 Initialisation

=over 4

=item init

Prepares the standard variable values, so that they are only called once on setup.

=back

=cut

sub init {
    my $prot    = qr{(?:http|https|ftp|afs|news|nntp|mid|cid|mailto|wais|prospero|telnet|gopher|git|file)://};
    my $atom    = qr{[a-z\d]}i;
    my $host    = qr{(?:$atom(?:(?:$atom|-)*$atom)?)};
    my $domain  = qr{(?:(?:(?:$host(?:\.$host)*))*(?:\.[a-zA-Z](?:$atom)*$atom)+)};
    my $ip      = qr{(?:(?:\d+)(?:\.(?:\d+)){3})(?::(?:\d+))?};
    my $enc     = qr{%[a-fA-F\d]{2}};
    my $legal1  = qr{[a-zA-Z\d\$_.+!*\'(),~\#-]};
    my $legal2  = qr{[\/;:@&=]};
    my $legal3  = qr{(?:(?:$legal1|$enc)+(?:(?:$legal2)+(?:$legal1|$enc)+)*)};
    my $path    = qr{\/(?:$legal3)+};
    my $query   = qr{(?:\?$legal3)+};
    my $local   = qr{[-\w\'=.]+};

    my $url1    = qr{(?: ($prot)? ($domain|$ip|\/$|$path) ($path)* ($query)? ) (\#[-\w.]+)?}x;
    my $url2    = qr{(?: (?:$prot)  (?:$domain|$ip|\/$|$path) (?:$path)* (?:$query)? ) (?:\#[-\w.]+)?}x;
    my $email   = qr{$local\@(?:$domain|$ip)};

    $settings{protregex}  = $prot;
    $settings{urlregex}   = $url1; #qr{\b$url1\b};
    $settings{urlstrict}  = $url2; #qr{\b$url2\b};
    $settings{emailregex} = $email;


    $settings{crawler} = 0;
    if($settings{crawlers}) {
        my $ra = Regexp::Assemble->new;
        $ra->add( '\b' . quotemeta( $_ ) . '\b' )   for(@{ $settings{crawlers} });
        my $re = $ra->re;
        $settings{crawler} = 1  if($ENV{'HTTP_USER_AGENT'} =~ $re);
    }


    $settings{'query-parser'} ||= 'CGI';
    my $class = 'Labyrinth::Query::' . $settings{'query-parser'};

    eval {
        eval "CORE::require $class";
        $cgi = $class->new();
    };

    die "Cannot load Query package for '$settings{'query-parser'}': $@" if($@);
}

=head2 CGI Parameter Handling

=over 4

=item CGIArray($name)

ParseParams only handles the scalar interface (CGI) parameters. In the event 
an array is required, CGIArray() is used to find and validate the parameter, 
before returning the list of values.

=item ParamsCheck

Given a list of fields, checks whether the interface (CGI) parameters have 
been set. Sets error conditions if any are missing.

=back

=cut

sub CGIArray {
    my $name = shift;
    return ()                   unless(defined $cgiparams{$name} && $cgiparams{$name});
    return ($cgiparams{$name})  unless(ref $cgiparams{$name} eq 'ARRAY');
    return @{$cgiparams{$name}};
}

sub ParamsCheck {
    for my $field (@_) {
        next    if($cgiparams{$field});
        $tvars{errcode} = 'MESSAGE';
        $tvars{errmess} = "Missing parameter ($field)";
        return 0;
    }

    return 1;
}

=head2 Process Flow Handling

=over

=item SetError

Sets the error condition as given.

=item SetCommand

Set the next commmand to be run.

=back

=cut

sub SetError {
    $tvars{errcode} = shift;
    $tvars{errmess} = shift if(@_);
}

sub SetCommand {
    $tvars{errcode} = 'NEXT';
    $tvars{command} = shift;
}

=head2 Default Variable Loaders

=over

=item LoadProfiles

Loads the permissions profiles, as stored in profiles config file.

=item LoadAccess

Loads the access permissions, as stored in the database.

=back

=cut

sub LoadProfiles {
    return  if(defined $settings{profiles});

    # ensure we can access the profile file
    if(!$settings{profile} || !-f $settings{profile} || !-r $settings{profile}) {
        LogError("Cannot read profile file [$settings{profile}]");
        $tvars{errcode} = 'ERROR';
        return;
    }

    my $cfg = Config::IniFiles->new( -file => $settings{profile} );
    unless(defined $cfg) {
        LogError("Unable to load profile file [$settings{profile}]: @Config::IniFiles::errors");
        $tvars{errcode} = 'ERROR';
        return;
    }

    # load the configuration data
    my $value = $cfg->val('MAIN','default');
    my @value = $cfg->val('MAIN','profiles');

    $settings{profiles}{default} = $value;

    for my $profile (@value) {
        for my $name ($cfg->Parameters($profile)) {
            $value = $cfg->val($profile,$name);
            $settings{profiles}{profiles}{$profile}{$name} = $value;
        }
    }
}

sub LoadAccess {
    return  if(defined $settings{access});

    my @rows = $dbi->GetQuery('hash','AllAccess',9);
    for my $row (@rows) {
        $settings{access}{names}{$row->{accessname}} = $row->{accessid};
        $settings{access}{ids}{$row->{accessid}}     = $row->{accessname};
    }
}

1;

__END__

=head1 SEE ALSO

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
