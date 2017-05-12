#!/usr/bin/perl -w
use strict;

my $VERSION = '0.08';

#----------------------------------------------------------
# Loader Variables

my ($CODE,$BASE,$LANG);
BEGIN {
    $BASE = '../../cgi-bin';
    $LANG = 'en';
}

#----------------------------------------------------------
# Library Modules

use lib ( "$BASE/lib", "$BASE/plugins" );

use Encode qw/encode decode/;
use File::Basename;
use Getopt::Long;
use HTML::Entities;
use IO::File;
use Template;
use Text::Wrap;
use Time::Piece;

use Labyrinth::Audit;
use Labyrinth::DTUtils;
use Labyrinth::Globals;
use Labyrinth::Mailer;
use Labyrinth::Variables;
use Labyrinth::Plugin::Survey;

#----------------------------------------------------------
# Variables

my $plugin = Labyrinth::Plugin::Survey->new();

my $config = "$BASE/config/settings.ini";

my $MODERATOR = 'barbie@missbarbell.co.uk';

my %LABEL = (
    'en' => {
        'Ratings'   => 'Ratings',
        'Feedback'  => 'Feedback',
        'Anonymous' => 'Anonymous',
    },
    'de' => {
        'Ratings'   => 'Bewertungen',
        'Feedback'  => 'Feedback',
        'Anonymous' => 'anonyme Bewertung',
    }
);

my $TARGET = './results';
my (@users,%options,%filter);

$Text::Wrap::columns = 72;

my @dotw = (
    "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday" );

my @months = (
    { 'id' =>  1,   'value' => "January",   },
    { 'id' =>  2,   'value' => "February",  },
    { 'id' =>  3,   'value' => "March",     },
    { 'id' =>  4,   'value' => "April",     },
    { 'id' =>  5,   'value' => "May",       },
    { 'id' =>  6,   'value' => "June",      },
    { 'id' =>  7,   'value' => "July",      },
    { 'id' =>  8,   'value' => "August",    },
    { 'id' =>  9,   'value' => "September", },
    { 'id' => 10,   'value' => "October",   },
    { 'id' => 11,   'value' => "November",  },
    { 'id' => 12,   'value' => "December"   },
);

#----------------------------------------------------------
# Code

Labyrinth::Globals::LoadSettings($config);
Labyrinth::Globals::DBConnect();

$CODE = $settings{icode};
die "No conference code is set\n"   unless($CODE);

    #SetLogFile( FILE   => $settings{'logfile'},
    SetLogFile( FILE   => 'audit.log',
                USER   => 'labyrinth',
                LEVEL  => 4,
                CLEAR  => 1,
                CALLER => 1);

init();
process();

results_talks();

# -------------------------------------
# The Subs

sub init {
    GetOptions(\%options,
        'tutor=s',
        'email=s',
        'live',
        'test',
        'courses',
        'talks',
        'lightning',
        'moderator=s');

    MailSet(mailsend => $settings{mailsend}, logdir => $settings{logdir});
    $tvars{survey} = $plugin->LoadSurvey($settings{'evaluate'});
    @users = $dbi->GetQuery('hash','AllUsers');

    if(!$options{live}) {
        $tvars{output}  = "$settings{logdir}/mailtest.eml";
        unlink($tvars{output});
    }

    $options{test} = 1  if($options{moderator});
    $options{moderator} ||= $settings{moderator};
    $options{moderator} ||= $MODERATOR;

    $filter{ 0 } = 1 if($options{courses});
    $filter{ 1 } = 1 if($options{talks});
    $filter{ 2 } = 1 if($options{lightning});
}

sub process {
    my @rs = $dbi->GetQuery('hash','AllActiveCourses');

    my %ignore; # = map { $_ => 1 } (1,2,3);

    for my $course (@rs) {
        next    if($course->{course} =~ /Lightning Talks/);
        next    if($ignore{$course->{courseid}});
        #print STDERR "tutor=$course->{tutor}, course=[$course->{courseid}] $course->{course}\n";
        next    if($options{tutor} && $course->{tutor} ne $options{tutor});

        # are we allowing this talk type?
        next    if(%filter && !$filter{ $course->{talk} });

        $course->{tutor} = 'Moderator'  if($options{test});

        unless($course->{tutor}) {
            print STDERR "ENONAME: $course->{course}\n";
            next;
        }

        $course->{tutor} =~ s/[- \.]+$//;
        my $email = _find_user($course->{actuserid},$course->{tutor});
        unless($email) {
            print STDERR "ENOMAIL: $course->{course}\n";
            print STDERR "         tutor=[$course->{tutor}]\n";
            print STDERR "         room=[$course->{room}]\n";
            next;
        }

        $tvars{users}->{$email}{name} = decode_entities($course->{tutor});
        my $talk   = decode_entities($course->{course});
        my $talkid = $course->{courseid};
#print STDERR "tutor=$tvars{users}->{$email}{name}, talk=$talk\n";

        $tvars{users}->{$email}{talk}{$talkid}{title} = $talk;

        my (%values,%tag);

        for my $section (@{$tvars{survey}->{sections}}) {
#LogDebug("label=$section->{label}");
            if($section->{label} eq $LABEL{$LANG}{'Ratings'}) {
                for my $question (@{$section->{questions}}) {
                    my $choices = @{$question->{choices}};

                    for my $inx (1 .. $choices) {
                        my @rs = $dbi->GetQuery('array','CourseQuestionResults',$talkid,$question->{name} .'_' . $inx);
                        $tvars{users}->{$email}{talk}{$talkid}{responses} = 1 if(@rs);

                        for my $rs (@rs) {
                            next    unless($rs->[0]);
                            $tvars{users}->{$email}{talk}{$talkid}{matrix}{$inx}->{$rs->[0]} = $rs->[1];
                        }
                        my $options = @{$question->{options}};
                        for my $opt (1 .. $options) {
                            $tvars{users}->{$email}{talk}{$talkid}{matrix}{$inx}->{$opt} ||= '-';
                        }

                    }
                    $tvars{users}->{$email}{talk}{$talkid}{choices} = $question->{choices};
                    $tvars{users}->{$email}{talk}{$talkid}{options} = $question->{options};
#use Data::Dumper;
#LogDebug("talk=[$talkid] $talk" . Dumper($tvars{users}->{$email}{talk}{$talkid}));
                }
            } elsif($section->{label} eq $LABEL{$LANG}{'Feedback'}) {
                for my $question (@{$section->{questions}}) {
                    my @rs = $dbi->GetQuery('array','CourseQuestionFeedback',$talkid,$question->{name});
                    $tvars{users}->{$email}{talk}{$talkid}{responses} = 1 if(@rs);
                    $tvars{users}->{$email}{talk}{$talkid}{feedback}{$question->{name}}{label} = $question->{label};
                    $values{$question->{name}} = \@rs;
                }
            } elsif($section->{label} =~ $LABEL{$LANG}{'Anonymous'}) {
                for my $question (@{$section->{questions}}) {
                    next    unless($question->{tag});
                    my @rs = $dbi->GetQuery('array','CourseQuestionFeedback',$talkid,$question->{name});
                    next    unless(@rs);
                    $tag{$_->[1]} = $_->[0]  for(@rs);
                }
            }

            for my $question (keys %values) {
                $tvars{users}->{$email}{talk}{$talkid}{feedback}{$question}{value} =
                    join('',
                        map {
                            if($_->[0]) {   $_->[0] =~ s/[\n\r]\s*/\n/g;
                                            $_->[0] =~ s/\n{2,}/\n/g;
                                            $_->[0] =~ s/&#8206;//g;
                                            $_->[0] .= " [$tag{$_->[1]}]"   if($tag{$_->[1]});
                                            wrap('* ','  ',decode_entities($_->[0])) . "\n" }
                            else        {   '' }
                        } @{ $values{$question} });
            }
        }
    }
#use Data::Dumper;
#LogDebug("tvars" . Dumper(\%tvars));
}


sub _find_user {
    my ($userid,$name) = @_;
    my $id;

    #return $options{moderator}  if($course->{tutor} eq 'Moderator');
    return $options{email}      if($options{tutor} && $options{email});

    for my $user (@users) {
        if(defined $user->{actuserid} && defined $userid) {
            $id ||= $user->{email}  if($user->{actuserid} == $userid);

        } elsif(defined $user->{realname} && defined $name) {
            return $user->{email}   if($user->{realname} eq $name);
            $id ||= $user->{email}  if($user->{realname} =~ /$name/);

        } elsif(defined $user->{nickname} && defined $name) {
            return $user->{email}   if($user->{nickname} eq $name);
            $id ||= $user->{email}  if($user->{nickname} =~ /$name/);
        }

        return $id if($id);
    }

    return;
}


sub results_talks {
    $tvars{emaildate} = emaildate();
    $tvars{emaildate} =~ s/\s+$//;

    for my $user (keys %{$tvars{users}}) {
        $tvars{user} = $user;
        writer('survey/results-tutorials.eml',\%tvars);
    }
}

sub writer {
    my ($template,$vars) = @_;

    $vars->{template}           = $template;
    $vars->{recipient_email}    = $vars->{user};
    $vars->{email}              = $vars->{user};
    $vars->{name}               = $vars->{users}{$tvars{user}}->{name};
    $vars->{nowrap}             = 1;
    $vars->{mname}              = encode('MIME-Q', decode('MIME-Header', $vars->{name}));
    $vars->{output}             = "$settings{logdir}/mailtest.eml"  unless($options{live});
    $vars->{email}              = $options{moderator}               if($options{test});

    MailSend( %$vars );

    if(MailSent())  { print STDERR "PASS: $tvars{user}\n"; } 
    else            { print STDERR "FAIL: $tvars{user}\n"; }
}

sub emaildate {
    return formatDate(16);
}

__END__

=head1 NAME

results-tuts.pl - script to generate emails for speakers for evaluations.

=head1 DESCRIPTION

this script creates the emails for each speaker based on the course and talk
evaluations submitted by attendees. The email is then either saved to disk for
manual evaluation, or sent to the email address provided for the speaker.

=head1 USAGE

  results-tuts.pl [--tutor=<name>] [--email=<email>] [--live] [--test]

=head1 OPTIONS

=over

=item --tutor=<name>

In the event a speaker didn't receive their feedback, this option allows you 
to resend the email, just for this speaker. Note that if the speaker has 
changed their email address, or the email address provided by Act was 
incorrect, this may need to be manually amended within the database.

=item --email=<email>

If a tutor name is given, this option can be used to override the email address
stored within the database. If no --tutor option is given, this option is 
ignored.

=item --live

This options triggers an email to be sent. If not provided, the emails are 
written to the file 'mailtest.eml' in the configured log directory.

=item --test

Emails are sent to the designated moderator address for evaluation, to ensure
emails are received in the correct format.

=item --moderator=<email>

Moderator emails are sent to the given email address for evaluation. The --test
option is enabled automatically when this option is used.

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
