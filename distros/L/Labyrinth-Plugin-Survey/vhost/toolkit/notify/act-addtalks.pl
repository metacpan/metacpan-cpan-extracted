#!/usr/bin/perl -w
use strict;

my $VERSION = '0.08';

#----------------------------------------------------------
# Loader Variables

my $BASE;
BEGIN {
    $BASE = '../../cgi-bin';
}

#----------------------------------------------------------
# Library Modules

use lib ( "$BASE/lib", "$BASE/plugins" );
use utf8;

use HTML::Entities;
use JSON;
use WWW::Mechanize;
use Time::Local;

use Labyrinth::Globals;
use Labyrinth::Variables;

#----------------------------------------------------------
# Variables

my $config = "$BASE/config/settings.ini";
my %rooms;

#----------------------------------------------------------
# Code

## Prepare data

my $mech = WWW::Mechanize->new();
$mech->agent_alias( 'Linux Mozilla' );

Labyrinth::Globals::LoadSettings($config);
Labyrinth::Globals::DBConnect();

my $api  = $settings{actapi_pass};
my $fmt  = $settings{actapi_talks};
my $yapc = $settings{icode};

my $rooms = $settings{act_rooms};
for my $room (@$rooms) {
    my ($r,$v) = split(':',$room);
    $rooms{$r} = $v;
}

my ($ydays,$ydayf,$ymon,$yyear) = split_dates($settings{event_start},$settings{event_end});


## Retrieve Act API data

my $url = sprintf $fmt, $yapc, $api;
$mech->get($url);
unless($mech->success) {
    print "FAIL: url=$url\n";
    exit;
}

#use Data::Dumper;
#print STDERR "content=".Dumper($mech->content());


## Process data

#my $data = from_json($mech->content(), {utf8 => 1});
my $data = from_json($mech->content());

#print STDERR "data=".Dumper($data);

my %counts = map { $_ => 0 } qw(insert update ignore found totals);
for my $talk (@$data) {
    my $title = encode_entities($talk->{title});
    my $tutor = encode_entities($talk->{speaker});
    $talk->{room}     ||= '';
    $talk->{datetime} ||= '';
    my $type = check_room($talk->{room}, $talk->{datetime});

    my @rows;
    @rows = $dbi->GetQuery('hash','FindCourseByAct',$talk->{talk_id})   if($talk->{talk_id});
    @rows = $dbi->GetQuery('hash','FindCourse',$title,$tutor)           unless(@rows);

    if(@rows) {
        if(!$rows[0]->{acttalkid} || $rows[0]->{acttalkid} == 0) {
            $dbi->DoQuery('UpdateActCourse',$talk->{talk_id},$talk->{user_id},$rows[0]->{courseid});
        }

        if($rows[0]->{talk} == -1) { # ignore this talk
            print "IGNORE: $rows[0]->{courseid},$title,$tutor,$talk->{room},$talk->{datetime} = $type\n";
            $counts{ignore}++;
            next;
        }

        if($rows[0]->{talk} == 2) { # preset LT
            $type = $rows[0]->{talk};
            $talk->{datetime} = $rows[0]->{datetime};
        }

       my $diff = 0;
       $diff = 1       if(different($title,$rows[0]->{course}));
       $diff = 1       if(different($tutor,$rows[0]->{tutor}));
       $diff = 1       if(different($talk->{room},$rows[0]->{room}));
       $diff = 1       if(different($talk->{datetime},$rows[0]->{datetime}));
       $diff = 1       if(differant($type,$rows[0]->{talk}));

        if($diff) {
            $dbi->DoQuery('SaveCourse',$title,$tutor,$talk->{room},$talk->{datetime},$type,$rows[0]->{courseid});
            print "UPDATE: $rows[0]->{courseid},$title,$tutor,$talk->{room},$talk->{datetime} = $type\n";
            print STDERR "UPDATE: WAS=$rows[0]->{courseid},$rows[0]->{course},$rows[0]->{tutor},$rows[0]->{room},$rows[0]->{datetime} = $rows[0]->{talk}\n";
            print STDERR "UPDATE: NOW=$rows[0]->{courseid},$title,$tutor,$talk->{room},$talk->{datetime} = $type\n";
            $counts{update}++;
        } else {
            $counts{found}++;
        }
    } else {
        my $id = $dbi->IDQuery('AddCourse',$title,$tutor,$talk->{room},$talk->{datetime},$type);
        print "INSERT: $id,$title,$tutor,$talk->{room},$talk->{datetime} = $type\n";
        $counts{insert}++;
    }
}

$counts{totals} += $counts{$_}             for(qw(insert update ignore found));
printf "%6s = %d\n", uc($_), $counts{$_}    for(qw(found ignore update insert totals));

sub check_room {
    my $room = shift or return 0;
    my $time = shift or return 0;
    my $type = $rooms{$room} ? 1 : 0;

    print STDERR "Undefined room: $room\n"  if(!defined $rooms{$room});

    for my $day ($ydays .. $ydayf) {
        my $start = timegm(0,0, 8,$day,$ymon-1,$yyear);
        my $end   = timegm(0,0,18,$day,$ymon-1,$yyear);
        return 0    if($time < $start);

        return $type   if($time < $end);
    }

    return 0;
}

sub different {
    my ($val1,$val2) = @_;

    return 1   if( $val1 && !$val2);
    return 1   if(!$val1 &&  $val2);
    return 0   if(!$val1 && !$val2);
    return 1   if( $val1 ne  $val2);
    return 0;
}

sub differant {
    my ($val1,$val2) = @_;

    return 1   if( $val1 && !$val2);
    return 1   if(!$val1 &&  $val2);
    return 0   if(!$val1 && !$val2);
    return 1   if( $val1 !=  $val2);
    return 0;
}

sub split_dates {
    my ($start,$end) = @_;
    my ($y1,$m1,$d1) = split(/\D+/,$start);
    my ($y2,$m2,$d2) = split(/\D+/,$end);

    return ($d1,$d2,$m2,$y2);
}
