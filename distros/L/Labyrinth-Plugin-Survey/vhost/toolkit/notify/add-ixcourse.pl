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

if (! GetOptions( \%options, 'create' )) {
   print "usage: $0 [--create] <file>\n";
   exit;
}

die "Usage: $0 [--create] <file>\n"    unless(@ARGV);

my $file = $ARGV[0];

Labyrinth::Globals::LoadSettings($config);
Labyrinth::Globals::DBConnect();

my $fh = IO::File->new($file,'r') or die "Error: Cannot open file [$file]: $!\n";
while(<$fh>) {
    s/\s+$//;
    my ($name1,$name2,$email,$courseid,$course) = split(',',$_);
    my ($userid,@rows);

    #print "[$email][$course]\n";

    unless($courseid) {
        @rows = $dbi->GetQuery('hash','FindCourseByName',$course);
        if(@rows) {
            $courseid = $rows[0]->{courseid};
        } else {
            print "COURSE NOT FOUND: $course\n";
            next;
        }
    }

    @rows = $dbi->GetQuery('hash','FindUser',$email);
    if(@rows) {
        $userid = $rows[0]->{userid};
    } elsif($options{create}) {
        my $name = join(' ', $name1, $name2);
        my $pass = Labyrinth::Users::FreshPassword();
        $userid = $dbi->IDQuery('NewUser',$pass,'',$name,$email,0);
        print "USER ADDED: $name1 $name2 <$email> => $userid\n";
    } else {
        print "USER NOT KNOWN: $name1 $name2 <$email>\n";
        next;
    }

    my @rs = $dbi->GetQuery('array','CheckCourse',$courseid,$userid);
    if(@rs) {
        print "COURSE INDEX FOUND: $userid => $courseid ($name1 $name2 <$email>)\n";
    } else {
        $dbi->DoQuery('SaveTalkIndex',0,$courseid,$userid);
        print "COURSE INDEX ADDED: $userid => $courseid ($name1 $name2 <$email>)\n";
    }
}


__END__

=head1 NAME

add-ixcourse.pl - script to add users to a course.

=head1 DESCRIPTION

This script adds users to a course previously setup within the system, based on
a CSV style file. File format is:

  #First Name, Surname, Email Address, Course ID, Course Title
  Test,User,test@example.com,0,Perl 101

The course title must match one that has already been created within the
system, unless a courseid is provided.

The user's email address should match a user within the system, unless the
'create' option is used.

=head1 USAGE

  add-ixcourse.pl [--create] <file>

=head1 OPTIONS

=over

=item --create

If a user is not found by their email address, create a user,and associated
keycode, using the data provided for that user.

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
