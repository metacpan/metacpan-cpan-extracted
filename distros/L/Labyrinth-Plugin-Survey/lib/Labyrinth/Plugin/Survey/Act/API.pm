package Labyrinth::Plugin::Survey::Act::API;

use warnings;
use strict;
use utf8;

use vars qw($VERSION);
$VERSION = '0.08';

=head1 NAME

Labyrinth::Plugin::Survey::Act::API - YAPC Surveys' Act API plugin for Labyrinth framework

=head1 DESCRIPTION

Provides all the interfaces to an Act software instance for YAPC Surveys.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

use Crypt::Lite;
use Digest::SHA1  qw(sha1_hex);
use HTML::Entities;
use JSON;
use Time::Local;
use WWW::Mechanize;

#----------------------------------------------------------
# Variables

my $crypt = Crypt::Lite->new( debug => 0, encoding => 'hex8' );
my $mech = WWW::Mechanize->new();
$mech->agent_alias( 'Linux Mozilla' );

my %rooms;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item LoadUsers

Builds the API call to retrieve the users, and stores the returned JSON into
the database, referencing all the users within Act, who have been recorded as
a speaker and/or registered for the conference event.

=item LoadTalks

Builds he API call to retrieve the talks for the conference event. Parses the
returned JSON, filtering the talks based on day, room and type into specific
categories and stores within the database.

Note that LoadUsers should be called before LoadTalks in order to properly
attribute the tutor/speaker for a course or talk to the correct user within
the system.

=back

=cut

sub LoadUsers {
    my (@saved,%names,%users);
    my $key  = $settings{yapc_name};
    $tvars{counts}{$_} = 0  for(qw(found saved users));

    # get data
    my $url = sprintf $settings{actapi_users}, $settings{icode}, $settings{actapi_pass};
    $mech->get($url);
    unless($mech->success) {
        $tvars{errmess} = 'Unable to access Act instance';
        return;
    }

    my $data = from_json($mech->content());

    for(@{ $settings{othernames} }) {
        my ($k,$v) = split(':');
        $names{$k} = $v;
    }

    for my $user (@$data) {
        $user->{full_name} = $names{$user->{full_name}} if($names{$user->{full_name}});
        my $name = encode_entities($user->{full_name});
        my $nick = encode_entities($user->{nick_name});
        $users{$user->{email}} = 1;

        my @rows;
        @rows = $dbi->GetQuery('hash','FindUserByAct',$user->{user_id})  if($user->{user_id});
        @rows = $dbi->GetQuery('hash','FindUser',$user->{email})        unless(@rows);

        if(@rows) {
            $tvars{counts}{all}++;
            next    unless($rows[0]->{search}); # ignore disabled users
            $tvars{counts}{enabled}++;
    
            if(!$rows[0]->{actuserid} || $rows[0]->{actuserid} == 0) {
                $dbi->DoQuery('UpdateActUser',$user->{user_id},$rows[0]->{userid});
            }

            if($rows[0]->{userid} > 2) {
                $tvars{counts}{found}++;

                # could have signed up, then been registered
                unless($rows[0]->{code}) {
                    my $str = $$ . $user->{email} . time();
                    $rows[0]->{code} = sha1_hex($crypt->encrypt($str, $key));
                    $dbi->DoQuery('SaveUserCode',$rows[0]->{code},$rows[0]->{userid});
                    push @saved, { status => 'REGISTERED', name => $name, email => $user->{email}, link => "$rows[0]->{code}/$rows[0]->{userid}" };
                    $tvars{counts}{registered}++;
                }

                next    if($rows[0]->{confirmed});  # already confirmed
                $tvars{counts}{confirmed}++;

                $dbi->DoQuery('ConfirmUser',1,$rows[0]->{userid});
                push @saved, { status => 'CONFIRMED', name => $name, email => $user->{email}, link => "$rows[0]->{code}/$rows[0]->{userid}" };
            }

            next;
        }

        my $str = $$ . $user->{email} . time();
        my $code = sha1_hex($crypt->encrypt($str, $key));

        $user->{user_id} ||= 0;
        my $userid = $dbi->IDQuery('NewUser',$user->{email},$nick,$name,$user->{email},$user->{user_id});
        $dbi->DoQuery('ConfirmUser',1,$userid);
        $dbi->DoQuery('SaveUserCode',$code,$userid);

        push @saved, { status => 'SAVED', name => $name, email => $user->{email}, link => "$code/$userid" };
        $tvars{counts}{saved}++
    }

    $tvars{data}{saved} = \@saved;

    my @users = $dbi->GetQuery('hash','AllUsers');
    $tvars{counts}{users} = scalar(@users);
}

sub LoadTalks {
    my (@talks);
    my $yapc = $settings{icode};
    $tvars{counts}{$_} = 0  for(qw(insert update ignore found totals));

    for(@{ $settings{act_rooms} }) {
        my ($k,$v) = split(':');
        $rooms{$k} = $v;
    }

    my ($y,$m,$d) = $settings{talks_start} =~ /^(\d+)\D(\d+)\D(\d+)\D/;
    $tvars{yapc}{talks_start} = timegm(0,0,0,$d,$m-1,$y);
    ($y,$m,$d) = $settings{survey_start} =~ /^(\d+)\D(\d+)\D(\d+)\D/;
    $tvars{yapc}{talks_end} = timegm(23,59,59,$d,$m-1,$y);

    # get data
    my $url = sprintf $settings{actapi_talks}, $settings{icode}, $settings{actapi_pass};
    $mech->get($url);
    unless($mech->success) {
        $tvars{errmess} = 'Unable to access Act instance';
        return;
    }

    #my $data = from_json($mech->content(), {utf8 => 1});
    my $data = from_json($mech->content());

    #print STDERR "data=".Dumper($data);

    for my $talk (@$data) {
        my $title = encode_entities($talk->{title});
        my $tutor = encode_entities($talk->{speaker});
        $talk->{room}     ||= '';
        $talk->{datetime} ||= '';
        my $type = _check_room($talk->{room}, $talk->{datetime});

        my @rows;
        @rows = $dbi->GetQuery('hash','FindCourseByAct',$talk->{talk_id})   if($talk->{talk_id});
        @rows = $dbi->GetQuery('hash','FindCourse',$title,$tutor)           unless(@rows);

        if(@rows) {
            if(!$rows[0]->{acttalkid} || $rows[0]->{acttalkid} == 0) {
                $dbi->DoQuery('UpdateActCourse',$talk->{talk_id},$talk->{user_id},$rows[0]->{courseid});
            }

            if($rows[0]->{talk} == -1) { # ignore this talk
                push @talks, { status => 'IGNORE', courseid => $rows[0]->{courseid}, title => $title, tutor => $tutor, room => $talk->{room}, datetime => formatDate(21,$talk->{datetime}), timestamp => $talk->{datetime}, type => $type };
                $tvars{counts}{ignore}++;
                next;
            }

            if($rows[0]->{talk} == 2) { # preset LT
                $type = $rows[0]->{talk};
                $talk->{datetime} = $rows[0]->{datetime};
            }

           my $diff = 0;
           $diff = 1       if(_different($title,$rows[0]->{course}));
           $diff = 1       if(_different($tutor,$rows[0]->{tutor}));
           $diff = 1       if(_different($talk->{room},$rows[0]->{room}));
           $diff = 1       if(_different($talk->{datetime},$rows[0]->{datetime}));
           $diff = 1       if(_differant($type,$rows[0]->{talk}));

            if($diff) {
                $dbi->DoQuery('SaveCourse',$title,$tutor,$talk->{room},$talk->{datetime},$type,$rows[0]->{courseid});
                push @talks, { status => 'UPDATE', courseid => $rows[0]->{courseid}, title => $title, tutor => $tutor, room => $talk->{room}, datetime => formatDate(21,$talk->{datetime}), timestamp => $talk->{datetime}, type => $type };
                push @talks, { status => 'WAS', courseid => $rows[0]->{courseid}, title => $rows[0]->{course}, tutor => $rows[0]->{tutor}, room => $rows[0]->{room}, datetime => formatDate(21,$rows[0]->{datetime}), timestamp => $rows[0]->{datetime}, type => $rows[0]->{talk} };
                $tvars{counts}{update}++;
            } else {
                $tvars{counts}{found}++;
            }
        } else {
            my $id = $dbi->IDQuery('AddCourse',$title,$tutor,$talk->{room},$talk->{datetime},$type);
            push @talks, { status => 'INSERT', courseid => $id, title => $title, tutor => $tutor, room => $talk->{room}, datetime => formatDate(21,$talk->{datetime}), timestamp => $talk->{datetime}, type => $type };
            $tvars{counts}{insert}++;
        }
    }

    $tvars{data}{talks} = \@talks   if(@talks);
    $tvars{counts}{totals} += $tvars{counts}{$_}    for(qw(insert update ignore found));
}

#----------------------------------------------------------
# Private functions

sub _check_room {
    my $room = shift or return 0;
    my $time = shift or return 0;
    my $type = $rooms{$room} ? 1 : 0;

    push @{$tvars{errors}}, "Undefined room: $room"  if(!defined $rooms{$room});

    my $day = $tvars{yapc}{talks_start};
    while($day < $tvars{yapc}{talks_end}) {
        my $start = $day + (60*60*8);
        my $end   = $day + (60*60*18);
        return 0        if($time < $start);
        return $type    if($time < $end);
        $day += (60*60*24);
    }

    return 0;
}

sub _different {
    my ($val1,$val2) = @_;

    return 1   if( $val1 && !$val2);
    return 1   if(!$val1 &&  $val2);
    return 0   if(!$val1 && !$val2);
    return 1   if( $val1 ne  $val2);
    return 0;
}

sub _differant {
    my ($val1,$val2) = @_;

    return 1   if( $val1 && !$val2);
    return 1   if(!$val1 &&  $val2);
    return 0   if(!$val1 && !$val2);
    return 1   if( $val1 !=  $val2);
    return 0;
}

1;

__END__

=head1 NOTES

The system assumes the following settings:

=over

=item * userid == 1 is the guest user in the event of errors or no login
=item * userid == 2 is the master admin user
=item * userid == 3 is the test user

=back

All these users do not have any bearing on the survey attendance, and are
purely used to manage the site through development, QA and release.

=head1 SEE ALSO

L<Labyrinth>

L<http://yapc-surveys.org>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug report and/or patch via RT [1], or raise
an issue or submit a pull request via GitHub [2]. Note that it helps 
immensely if you are able to pinpoint problems with examples, or supply a 
patch.

[1] http://rt.cpan.org/Public/Dist/Display.html?Name=Labyrinth-Plugin-Survey
[2] http://github.com/barbie/labyrinth-plugin-survey

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

Barbie, <barbie@cpan.org>
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT

  Copyright (C) 2006-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
