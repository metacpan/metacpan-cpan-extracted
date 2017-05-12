package Labyrinth::Plugin::Users::Info;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Users::Info - Additional Users Info handler for Labyrinth

=head1 DESCRIPTION

Contains all the additional user info handling functionality for the Labyrinth
framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Media;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Writer;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

use Clone   qw/clone/;
use Config::IniFiles;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    userid    => { type => 1, html => 0 },
);

#    distros   => { type => 0, html => 1 },
#    skills    => { type => 0, html => 1 },
#    hobbies   => { type => 0, html => 1 },
#    location  => { type => 0, html => 1 },
#    hometitle => { type => 0, html => 1 },


my (@mandatory,@allfields,@fieldorder,@fieldnames);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $LEVEL = ADMIN;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Item

Provides the addition user information for the given user.

=back

=cut

sub Item {
    return  unless($cgiparams{'userid'});
    my @rows = $dbi->GetQuery('hash','GetUserInfoByID',$cgiparams{'userid'});
    $tvars{user}->{info} = $rows[0];
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item Edit

Edit the addition user information for the given user.

=item Save

Save the addition user information for the given user.

=item Delete

Delete the addition user information for the given user.

=item LoadInfo

Load the user information required.

=back

=cut

sub Edit {
    $cgiparams{userid} ||= $tvars{'loginid'};
    return  unless MasterCheck();
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck('GetUserInfoByID','userid',$LEVEL);

    LoadInfo();
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $tvars{user}{data}->{$_}    = CleanHTML($tvars{data}->{$_});
                                          $tvars{user}{preview}->{$_} = CleanHTML($tvars{data}->{$_});  }
        elsif($fields{$_}->{html} == 2) { $tvars{user}{data}->{$_}    = CleanTags($tvars{data}->{$_});  }
    }
}

sub Save {
    return  unless MasterCheck();
    return  unless AccessUser($LEVEL);

    my $newuser = $cgiparams{'userid'} ? 0 : 1;
    if(!$newuser && $cgiparams{userid} != $tvars{'loginid'} && !Authorised($LEVEL)) {
        $tvars{errcode} = 'BADACCESS';
        return;
    }

    return  unless AuthorCheck('GetUserInfoByID','userid',$LEVEL);

    LoadInfo();
    $tvars{newuser} = $newuser;
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    return  if FieldCheck(\@allfields,\@mandatory);

    my @fields = ((map {$tvars{data}->{$_}} @fieldorder), $tvars{data}->{'userid'});
    $dbi->DoQuery('SaveUserInfo',{ 'keys' => join(',', map {"$_=?"} @fieldnames) },@fields);
}

sub LoadInfo {
    my $file = $settings{config} . '/user-info.ini';
    return  unless(-f $file);

    my $cfg = Config::IniFiles->new( -file => $file );
    unless(defined $cfg) {
        LogWarn("Unable to load user info file [$file]");
        return;
    }

    for my $name ($cfg->Parameters('EXTRA')) {
        my $value = $cfg->val('EXTRA',$name);
        next    unless($value);

        my ($type,$html,$field) = split(',',$value);
        $fields{$name} = {type => $type, html => $html};
        push @fieldorder, $name;
        push @fieldnames, $field;
    }

    (@mandatory,@allfields) = ();
    for(keys %fields) {
        push @mandatory, $_     if($fields{$_}->{type});
        push @allfields, $_;
    }
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
