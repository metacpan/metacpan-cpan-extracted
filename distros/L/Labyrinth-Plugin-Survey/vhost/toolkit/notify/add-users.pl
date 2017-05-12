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

use Crypt::Lite;
use Digest::SHA1  qw(sha1_hex);
use Getopt::Long;
use IO::File;

use Labyrinth::Globals;
use Labyrinth::Users;
use Labyrinth::Variables;

#----------------------------------------------------------
# Variables

my $config = "$BASE/config/settings.ini";

my $crypt = Crypt::Lite->new( debug => 0, encoding => 'hex8' );

my %options;

#----------------------------------------------------------
# Code

if (! GetOptions( \%options, 'update', 'nocode' )) {
   print "usage: $0 [--update] [--nocode] <file>\n";
   exit;
}

die "Usage: $0 [--update] [--nocode] <file>\n"    unless(@ARGV);

my $file = $ARGV[0];

Labyrinth::Globals::LoadSettings($config);
Labyrinth::Globals::DBConnect();

my $key  = $settings{yapc_name};

my $fh = IO::File->new($file,'r') or die "Error: Cannot open file [$file]: $!\n";
while(<$fh>) {
    next    if(/^\s*$/);
    $_ =~ s/\s+$//;

    my ($name,$email,$actuserid) = split(',',$_);
    my $userid;

    my @rows = $dbi->GetQuery('hash','FindUser',$email);
    if(@rows) {
        my @keys = $dbi->GetQuery('hash','GetUserCode',$rows[0]->{userid});
        print "FOUND: $email => $keys[0]->{code}/$rows[0]->{userid}\n";
        next    unless($options{update});
        $userid = $rows[0]->{userid};
    }

    @rows = $dbi->GetQuery('hash','FindUserByAct',$actuserid);
    if(@rows) {
        my @keys = $dbi->GetQuery('hash','GetUserCode',$rows[0]->{userid});
        print "FOUND: $email => $keys[0]->{code}/$rows[0]->{userid}\n";
        next    unless($options{update});
        $userid = $rows[0]->{userid};
    }

    my $str = $$ . $email . time();
    my $code = sha1_hex($crypt->encrypt($str, $key));

    if($userid) {
        if($options{nocode}) {
            @rows = $dbi->GetQuery('hash','GetUserCode',$userid);
            $code = $rows[0]->{code}    if(@rows);
        }
        $dbi->DoQuery('SaveUser','',$name,$email,$userid);
        $dbi->DoQuery('UpdateActUser',$actuserid,$userid)   if($actuserid);

    } else {
        #$name = encode_entities($name);
        my $pass = Labyrinth::Users::FreshPassword();
        $userid = $dbi->IDQuery('NewUser',$pass,'',$name,$email,0);
    }

    $dbi->DoQuery('ConfirmUser',1,$userid);
    $dbi->DoQuery('SaveUserCode',$code,$userid) unless($options{nocode});
    print "SAVED: $email => $code/$userid\n";
}

__END__

=head1 NAME

addusers.pl - script to add users to the survey system.

=head1 DESCRIPTION

This script adds users to the system, based on a CSV style file. File format
is:

  #User Name, Email Address, ActUserID (if known)
  Test User,test@example.com,

The ActUserID is the id of the user within the Act system, if known. The
ActUserID isn't needed generally, but it can help to verify whether a user has
already been added to the system with a different spelling of their name, or
different email address.

=head1 USAGE

  addusers.pl [--update] [--nocode] <file>

=head1 OPTIONS

=over

=item --update

If a user is found by their email address, or actuserid if known, update the
user details with the data provided for that user.

=item --nocode

If the user has been found, this option will prevent a new keycode being
generated.

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
