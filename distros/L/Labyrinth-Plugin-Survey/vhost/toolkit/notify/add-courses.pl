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

use Getopt::Long;
use IO::File;

use Labyrinth::Globals;
use Labyrinth::Users;
use Labyrinth::Variables;

#----------------------------------------------------------
# Variables

my $config = "$BASE/config/settings.ini";

my %options;

#----------------------------------------------------------
# Code

if (! GetOptions( \%options, 'update', 'create' )) {
   print "usage: $0 [--update] [--create] <file>\n";
   exit;
}

die "Usage: $0 [--update] [--create] <file>\n"    unless(@ARGV);

my $file = $ARGV[0];

Labyrinth::Globals::LoadSettings($config);
Labyrinth::Globals::DBConnect();

my $fh = IO::File->new($file,'r') or die "Error: Cannot open file [$file]: $!\n";
while(<$fh>) {
    s/\s+$//;
    my ($acttalkid,$courseid,$title,$actuserid,$userid,$tutor,$email) = split(',',$_);
    my (@rows);

    unless($acttalkid || $courseid || $title) {
        print "NO COURSE DETAILS: $acttalkid,$courseid,$title\n";
        next;
    }

    unless($actuserid || $userid || $tutor || $email) {
        print "NO TUTOR DETAILS: $actuserid,$userid,$tutor,$email\n";
        next;
    }

    ## Find Tutor

    if($userid) {
        @rows = $dbi->GetQuery('hash','GetUserByID',$userid);
        unless(@rows) {
            print "TUTOR NOT FOUND BY ID: $actuserid,$userid,$tutor,$email\n";
            $userid = 0;
        }
    }

    if(!$userid && $actuserid) {
        @rows = $dbi->GetQuery('hash','FindUserByAct',$actuserid);
        unless(@rows) {
            print "TUTOR NOT FOUND BY ACTID: $actuserid,$userid,$tutor,$email\n";
            $userid = 0;
        } else {
            $userid = $rows[0]->{userid};
        }
    }

    if(!$userid && $email) {
        @rows = $dbi->GetQuery('hash','FindUser',$email);
        unless(@rows) {
            print "TUTOR NOT FOUND BY EMAIL: $actuserid,$userid,$tutor,$email\n";
            $userid = 0;
        } else {
            $userid = $rows[0]->{userid};
        }
    }

    if(!$userid && $options{create}) {
        my $pass = Labyrinth::Users::FreshPassword();
        $userid = $dbi->IDQuery('NewUser',$pass,'',$tutor,$email,$actuserid);
        print "TUTOR ADDED: $tutor <$email> => $userid\n";
    } else {
        print "TUTOR NOT KNOWN: $tutor <$email>\n";
        next;
    }

    ## Find Course

    if($courseid) {
        @rows = $dbi->GetQuery('hash','GetCourse',$courseid);
        unless(@rows) {
            print "COURSE NOT FOUND BY ID: $acttalkid,$courseid,$title\n";
            $courseid = 0;
        }
    }

    if(!$courseid && $acttalkid) {
        @rows = $dbi->GetQuery('hash','FindCourseByAct',$acttalkid);
        unless(@rows) {
            print "COURSE NOT FOUND BY ACTID: $acttalkid,$courseid,$title\n";
            $courseid = 0;
        } else {
            $courseid = $rows[0]->{courseid};
        }
    }

    if(!$courseid && $title) {
        @rows = $dbi->GetQuery('hash','FindCourseByName',$title);
        if(@rows) {
            $courseid = $rows[0]->{courseid};
        } else {
            print "COURSE NOT FOUND BY NAME: $acttalkid,$courseid,$title\n";
        }
    }

    if($courseid && $options{update}) {
        $dbi->DoQuery('UpdateCourse',$title,$tutor,'r1',time(),0,$userid,$actuserid,$courseid);
        print "COURSE UPDATED: $title => $tutor\n";
    } elsif(!$courseid) {
        $courseid = $dbi->IDQuery('InsertCourse',$title,$tutor,'r1',time(),0,$userid,$actuserid);
        print "COURSE ADDED: $title => $tutor\n";
    } else {
        print "COURSE IGNORED: $title => $tutor\n";
        next
    }
}


__END__

=head1 NAME

add-courses.pl - script to add or update courses/talks within the system.

=head1 DESCRIPTION

This script can add or update course details within the system, based on a CSV 
style file. File format is:

  #ActTalkID, Course ID, Course Title, ActUserID, User ID, Tutor, Email
  0,0,Perl 101,0,0,Cool Dude,cool.dude@example.com

If the Act IDs or system IDs are unknown, set to zero, and a course entry will
be created. Note that the Tutor may be a user that has not been created witin
the system. In this case the name is used to reference the tutor, but the tutor
may not be able to receive evaluation feedback without an appropriate email
address.

If a course is found, either by Title, ActTalkID or CourseID, and the 'update'
option is used, the title of the course and tutor details are updated for that
course.

Note that if a user is not found within the system, but an email address, or 
ActUserID, is provided, and the 'create' option is used, a user entry will be
created.

=head1 USAGE

  add-courses.pl [--update] [--create] <file>

=head1 OPTIONS

=over

=item --update

Update course details, if a course is already found within the system.

=item --create

If a tutor is not found by their email address or ActUserID, create a user, and
associate a new keycode, using the data provided for that user.

=back

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
