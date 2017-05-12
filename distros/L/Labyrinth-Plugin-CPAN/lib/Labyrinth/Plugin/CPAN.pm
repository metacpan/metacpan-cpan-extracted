package Labyrinth::Plugin::CPAN;

use strict;
use warnings;

our $VERSION = '3.56';

=head1 NAME

Labyrinth::Plugin::CPAN - CPAN Testers plugin for the Labyrinth framework

=head1 DESCRIPTION

Labyrinth is a Website Management Framework. This distribution enables Labyrinth
to manage access to the CPAN Testers databases and data about CPAN releases and
testers.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);
use base qw(Class::Accessor::Fast);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Variables;
use Labyrinth::Users;

use Email::Address;
use Sort::Versions;

#----------------------------------------------------------------------------
# Variables

my (%DBX,%TESTER,%TESTERS);

#----------------------------------------------------------------------------
# Public Interface Functions

__PACKAGE__->mk_accessors(qw( perls osnames exceptions symlinks merged ignore distindex ));

=head1 METHODS

=head1 General Methods

=over 4

=item DBX

Creates a database connection to the cpanstats database.

=item Configure

Reads the CPAN configuration file and stores settings.

=item GetTesterProfile

Given the profile id of a tester, returns their credentials, if known.

=item FindTester

Given a tester string, determines who to record it as in the system.

=item Rename

Used by the preferences system to impersonate a user for administration 
and/or purposes.

=item OSName

Given an operating system string, returns the values used in the system.

=item DistIndex

Given a distribution name and a version, returns the index value used by the 
system.

=item OnCPAN

Given a distribution name and a version, returns whether stored on CPAN (1) or 
not (0).

=back

=cut

sub DBX  {
    my ($self,$prefix,$autocommit) = @_;
    $autocommit ||= 0;

    return                              unless(defined $prefix);
    return $DBX{$prefix.$autocommit}    if(defined $DBX{$prefix.$autocommit});

    my %hash = map {$_ => $settings{"${prefix}_$_"}} grep {$settings{"${prefix}_$_"}} qw(dictionary driver database dbfile dbhost dbport dbuser dbpass);
    return  unless(%hash);

    $hash{$_} = $settings{$_}   for(qw(logfile phrasebook));
    $hash{autocommit} = $autocommit if($autocommit);

    $DBX{$prefix.$autocommit} = Labyrinth::DBUtils->new(\%hash);
    die "Unable to connect to '$prefix' database\n" unless($DBX{$prefix.$autocommit});

    return $DBX{$prefix.$autocommit};
}

sub Configure {
    my $self = shift;
    my $cfg;
    
    $cfg = Config::IniFiles->new( -file => $settings{cpan_config} )
        if(-f $settings{cpan_config});

    if($cfg && $cfg->SectionExists('EXCEPTIONS')) {
        my @values = $cfg->val('EXCEPTIONS','LIST');
        $self->exceptions( join('|',@values) );
    }

    if($cfg && $cfg->SectionExists('IGNORE')) {
        my @values = $cfg->val('IGNORE','LIST');
        my %IGNORE;
        $IGNORE{$_} = 1  for(@values);
        $self->ignore( \%IGNORE );
    }

    if($cfg && $cfg->SectionExists('SYMLINKS')) {
        my %SYMLINKS;
        $SYMLINKS{$_} = $cfg->val('SYMLINKS',$_)  for($cfg->Parameters('SYMLINKS'));
        $self->symlinks( \%SYMLINKS );
        my %MERGED;
        push @{$MERGED{$SYMLINKS{$_}}}, $_              for(keys %SYMLINKS);
        push @{$MERGED{$SYMLINKS{$_}}}, $SYMLINKS{$_}   for(keys %SYMLINKS);
        $self->merged( \%MERGED );
    }

    my $OSNAMES = $self->osnames;
    my @rows = $dbi->GetQuery('hash','AllOSNames');
    for my $row (@rows) {
        $OSNAMES->{lc $row->{osname}} = $row->{ostitle};
    }
    $self->osnames($OSNAMES);

    my $INDEX = {};
    @rows = $dbi->GetQuery('hash','AllDistIndices');
    for my $row (@rows) {
        $INDEX->{$row->{dist}}{$row->{version}}{id}   = $row->{uploadid};
        $INDEX->{$row->{dist}}{$row->{version}}{type} = $row->{type};
    }
    $self->distindex($INDEX);
}

#----------------------------------------------------------------------------
# Private Interface Functions

sub GetTesterProfile {
    my ($self,$guid,$addr) = @_;
    my @rows;

    return  unless($guid);
    return $TESTERS{$guid}    if($TESTERS{$guid});
    
    # check report mapping
    @rows = $dbi->GetQuery('hash','GetTesterProfile',$guid);

    # check previous tester mapping
    if(!@rows && $addr) {
        @rows = $dbi->GetQuery('hash','FindTesterProfile',$addr);
    }

    return unless(@rows);

    if($rows[0]->{name}) {
        $rows[0]->{display} = $rows[0]->{name};
        $rows[0]->{display} .= " ($rows[0]->{pause})"    if($rows[0]->{pause});
    } elsif($rows[0]->{email}) {
        $rows[0]->{display} = $rows[0]->{email};
    } else {
        $rows[0]->{display} = $rows[0]->{address};
    }
    
    $TESTERS{$guid} = $rows[0];
    return $TESTERS{$guid};
}

sub FindTester {
    my ($self,$str) = @_;

    my ($addr)  = Email::Address->parse($str);
    return ('admin@cpantesters.org','CPAN Testers Admin',-1,0) unless($addr);
    my $address = $addr->address;
    return ('admin@cpantesters.org','CPAN Testers Admin',-1,0) unless($address);

    unless($TESTER{$address}) {
        my @rows = $dbi->GetQuery('hash','FindTesterIndex',$address);
        return ($address,'CPAN Tester',-1,0)    unless(@rows);

        my @user = $dbi->GetQuery('hash','GetUserByID',$rows[0]->{userid});
        $TESTER{$address}{userid}    = $user[0]->{userid};
        $TESTER{$address}{name}      = $user[0]->{realname};
        $TESTER{$address}{addressid} = $rows[0]->{addressid} || 0;
    }

    return ($address,$TESTER{$address}{name},$TESTER{$address}{userid},$TESTER{$address}{addressid});
}

sub Rename {
    LogDebug("Rename: user=$tvars{user}{name}");
    if($tvars{user}{name} =~ /pause:(\w+)/) {
        $tvars{user}{author} = uc $1;
        $tvars{user}{fakename} = $tvars{user}{author};
        LogDebug("Rename: author=$tvars{user}{author}, fakename=$tvars{user}{fakename}");
    } elsif($tvars{user}{name} =~ /imposter:(\d+)/) {
        $tvars{user}{tester} = $1;
        $tvars{user}{fakename} = UserName($tvars{user}{tester});
        LogDebug("Rename: tester=$tvars{user}{tester}, fakename=$tvars{user}{fakename}");
    } elsif($tvars{user}{name} =~ /imposter:([A-Z]+)/i) {
        $tvars{user}{author}   = uc $1;
        $tvars{user}{fakename} = $tvars{user}{author};
        LogDebug("Rename: author=$tvars{user}{author}, fakename=$tvars{user}{fakename}");
    }
}

sub OSName {
    my ($self,$name) = @_;
    return  unless($name);

    my $code = lc $name;
    $code =~ s/[^\w]+//g;
    my $OSNAMES = $self->osnames;
    return(($OSNAMES->{$code} || uc($name)), $code);
}

sub DistIndex {
    my ($self,$dist,$version) = @_;
    return 0    unless(defined $dist && defined $version);

    my $INDEX = $self->distindex;
    return $INDEX->{$dist}{$version}{id} || 0;
}

sub OnCPAN {
    my ($self,$dist,$version) = @_;
    return  unless(defined $dist && defined $version);

    my $INDEX = $self->distindex;
    my $type = $INDEX->{$dist}{$version}{type} || undef;

    return 1    unless($type);          # assume it's a new release
    return 0    if($type eq 'backpan'); # on backpan only
    return 1;                           # on cpan or new upload
}

#----------------------------------------------------------------------------
# Private Interface Functions

=head1 Private Methods

=over 4

=item check_oncpan

Check whether a given distribution/version is on CPAN or in BACKPAN.

=item mklist_perls

Provides a list of the perl versions currently in the system.

=back

=cut

sub check_oncpan {
    my ($self,$dist,$vers) = @_;

    my @rows = $dbi->GetQuery('array','OnCPAN',$dist,$vers);
    my $type = @rows ? $rows[0]->[0] : undef;

    return 1    unless($type);          # assume it's a new release
    return 0    if($type eq 'backpan'); # on backpan only
    return 1;                           # on cpan or new upload
}

sub mklist_perls {
    my $self = shift;

    my @perls;
    my $perls = $self->perls;
    return $perls  if($perls);

    my @rows = $dbi->GetQuery('array','GetPerls');

    for my $row (@rows) {
        push @perls, $row->[0] if($row->[0] && $row->[0] !~ /patch|RC/i);
    }

    @perls = sort { versioncmp($b,$a) } @perls;
    $self->perls(\@perls);
    return \@perls;
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2016 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
