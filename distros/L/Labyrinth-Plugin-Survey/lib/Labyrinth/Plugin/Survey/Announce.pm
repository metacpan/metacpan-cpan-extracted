package Labyrinth::Plugin::Survey::Announce;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.08';

=head1 NAME

Labyrinth::Plugin::Survey::Announce - YAPC Surveys' announcements plugin for Labyrinth framework

=head1 DESCRIPTION

Provides all the announcement handling functionality for YAPC Surveys.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Mailer;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

use Encode qw/encode decode/;
use HTML::Entities;
use Time::Piece;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea, 3 = full legal html

my %fields = (
    announceid  => { type => 0, html => 0 },
    hFrom       => { type => 1, html => 2 },    # can contain "<email>" which looks like a HTML tag
    hSubject    => { type => 1, html => 1 },
    body        => { type => 1, html => 2 },
    publish     => { type => 1, html => 0 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my @savefields  = qw(hFrom hSubject body publish);
my $INDEXKEY    = 'announceid';
my $ALLSQL      = 'GetAnnounces';
my $SAVESQL     = 'SaveAnnounce';
my $ADDSQL      = 'AddAnnounce';
my $GETSQL      = 'GetAnnounceByID';
my $DELETESQL   = 'DeleteAnnounce';
my $LEVEL       = ADMIN;

my %adddata = (
    announceid  => 0,
    hFrom       => '',
    hTo         => '',
    hSubject    => '',
    body        => '',
);

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=head2 General Management Methods

=over 4

=item Admin

Lists active announcements.

=item Add

Add an announcement.

=item Edit

Edit an announcement.

=item Save

Save an announcement.

=item Delete

Delete one or more announcements.

=back

=cut

sub Admin {
    return  unless(AccessUser($LEVEL));
    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete' ) { Delete();  }
    }
    my @rows = $dbi->GetQuery('hash',$ALLSQL);
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser($LEVEL);
    $tvars{data}{ddpublish} = PublishSelect(undef,1);
}

sub Edit {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);
    $tvars{data}{ddpublish} = PublishSelect($tvars{data}{publish},1);

    my @user = $dbi->GetQuery('array','CountConfirmedUsers');
    my @sent = $dbi->GetQuery('array','AnnounceSent',$cgiparams{$INDEXKEY});
    my @wait = $dbi->GetQuery('array','AnnounceNotSent',$cgiparams{$INDEXKEY});
    my @done = $dbi->GetQuery('hash','AdminSurveys');

    if(@user) {
        if(@sent) {
            $tvars{data}{sent}   = $sent[0]->[0];
            $tvars{data}{unsent} = $wait[0]->[0];
        } else {
            $tvars{data}{sent}   = 0;
            $tvars{data}{unsent} = $user[0]->[0];
        }
        if(@done) {
            $tvars{data}{done}   = scalar(@done);
            $tvars{data}{undone} = $user[0]->[0] - scalar(@done);
        } else {
            $tvars{data}{done}   = 0;
            $tvars{data}{undone} = $user[0]->[0];
        }
    } else {
        $tvars{data}{sent}   = 0;
        $tvars{data}{unsent} = 0;
        $tvars{data}{done}   = 0;
        $tvars{data}{undone} = 0;
    }
}

sub Save {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }
    return  if FieldCheck(\@allfields,\@mandatory);

    my @fields = map {$tvars{data}->{$_}} @savefields;
    if($cgiparams{$INDEXKEY}) {
        $dbi->DoQuery($SAVESQL,@fields,$cgiparams{$INDEXKEY});
    } else {
        $cgiparams{$INDEXKEY} = $dbi->IDQuery($ADDSQL,@fields);
    }

    $tvars{thanks} = 1;
}

sub Delete {
    return  unless AccessUser($LEVEL);
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    $dbi->DoQuery($DELETESQL,{ids=>join(",",@ids)});
}

=head2 Mail Management Methods

=over 4

=item Resend

List users who have previously been sent the selected announcement.

=item Unsent

List users who have never previously been sent the selected announcement.

=item Done

List users who have submitted the main conference survey

=item Undone

List users who have not submitted the main conference survey

=item SendOne

Send announcement to selected users.

=item SendAll

Resend announcement to all users.

=item SendNew

Send announcement to users who have not previously been sent it.

=item SendNot

Send announcement to users who have not taken the main conference survey.

=back

=cut

sub Resend {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);

    $cgiparams{sortname} ||= 'realname';

    my $sort = "ORDER BY u.$cgiparams{sortname} ";
    $sort .= $cgiparams{sorttype} ? 'ASC' : 'DESC';
    $tvars{sorttype} = $cgiparams{sorttype} ? 0 : 1;

    my @users = $dbi->GetQuery('hash','ListAnnounceSent',{'sort' => $sort},$cgiparams{$INDEXKEY});
    $tvars{users} = \@users if(@users)
}

sub Unsent {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);

    $cgiparams{sortname} ||= 'realname';

    my $sort = "ORDER BY u.$cgiparams{sortname} ";
    $sort .= $cgiparams{sorttype} ? 'ASC' : 'DESC';
    $tvars{sorttype} = $cgiparams{sorttype} ? 0 : 1;

    my @users = $dbi->GetQuery('hash','ListAnnounceUnsent',{'sort' => $sort},$cgiparams{$INDEXKEY});
    $tvars{users} = \@users if(@users);
    $tvars{sorttype} ||= 0;
}

sub Done {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);

    $cgiparams{sortname} ||= 'realname';

    my $sort = "ORDER BY u.$cgiparams{sortname} ";
    $sort .= $cgiparams{sorttype} ? 'ASC' : 'DESC';
    $tvars{sorttype} = $cgiparams{sorttype} ? 0 : 1;

    my @users = $dbi->GetQuery('hash','AdminSurveys',{'sort' => $sort});
    $tvars{users} = \@users if(@users)
}

sub Undone {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);

    $cgiparams{sortname} ||= 'realname';

    my $sort = "ORDER BY u.$cgiparams{sortname} ";
    $sort .= $cgiparams{sorttype} ? 'ASC' : 'DESC';
    $tvars{sorttype} = $cgiparams{sorttype} ? 0 : 1;

    my @users = $dbi->GetQuery('hash','AdminSurveyNot',{'sort' => $sort});
    $tvars{users} = \@users if(@users)
}

sub SendOne {
    return  unless AccessUser($LEVEL);
    my @ids = CGIArray('LISTED');
    next    unless(@ids);
    my @users = $dbi->GetQuery('hash','ListSelectedUsers',{ids=>join(",",@ids)});
    _send_announcement($cgiparams{$INDEXKEY},\@users);
}

sub SendAll {
    return  unless AccessUser($LEVEL);
    my @users = $dbi->GetQuery('hash','ListConfirmedUsers');
    _send_announcement($cgiparams{$INDEXKEY},\@users);
}

sub SendNew {
    return  unless AccessUser($LEVEL);
    my @users = $dbi->GetQuery('hash','ListAnnounceUnsent',$cgiparams{$INDEXKEY});
    _send_announcement($cgiparams{$INDEXKEY},\@users);
}

sub SendNot {
    return  unless AccessUser($LEVEL);
    my @users = $dbi->GetQuery('hash','AdminSurveyNot');
    _send_announcement($cgiparams{$INDEXKEY},\@users);
}

# -------------------------------------
# Private Subs

sub _send_announcement {
    my $id = shift;
    my $users = shift;

    my %opts = (
        template => 'mailer/announce.eml',
        nowrap   => 1
    );

    $tvars{gotusers} = scalar(@$users);

    # get announcement details
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);

    $tvars{mailsent} = 0;
    for(qw( yapc_name yapc_host yapc_city yapc_mail yapc_http yapc_surv
            talks_open survey_open survey_close)) {
        $settings{$_} =~ s/\s*$//;
    }

    for my $user (@$users) {
        $opts{from} = $tvars{data}{hFrom};
        $opts{subj} = $tvars{data}{hSubject};
        $opts{body} = $tvars{data}{body};

        $user->{realname} = decode_entities($user->{realname} );

        my $t = localtime;
        $opts{edate}            = formatDate(16);
        $opts{email}            = $user->{email} or next;
        $opts{recipient_email}  = $user->{email} or next;
        $opts{ename}            = $user->{realname} || '';
        $opts{mname}            = encode('MIME-Q', decode('MIME-Header', $opts{ename}));

        for my $key (qw(from subj body)) {
            $opts{$key} =~ s/ENAME/$user->{realname}/g;
            $opts{$key} =~ s/EMAIL/$user->{email}/g;
            $opts{$key} =~ s!ECODE!$user->{code}/$user->{userid}!g;

            $opts{$key} =~ s/YAPC_CONF/$settings{yapc_name}/g;
            $opts{$key} =~ s/YAPC_HOST/$settings{yapc_host}/g;
            $opts{$key} =~ s/YAPC_CITY/$settings{yapc_city}/g;
            $opts{$key} =~ s/YAPC_MAIL/$settings{yapc_mail}/g;
            $opts{$key} =~ s/YAPC_HTTP/$settings{yapc_http}/g;
            $opts{$key} =~ s/YAPC_SURV/$settings{yapc_surv}/g;
            $opts{$key} =~ s/TALK_OPEN/$settings{talks_open}/g;
            $opts{$key} =~ s/YAPC_OPEN/$settings{survey_open}/g;
            $opts{$key} =~ s/YAPC_CLOSE/$settings{survey_close}/g;

            $opts{$key} =~ s/\r/ /g;    # a bodge
        }

#use Data::Dumper;
#LogDebug("opts=".Dumper(\%opts));
        MailSend(%opts);
        $dbi->DoQuery('InsertAnnounceIndex',$cgiparams{$INDEXKEY},$user->{userid},time());

        # if sent update index
        $tvars{mailsent}++  if(MailSent());
    }

    $tvars{thanks} = $tvars{mailsent} ? 2 : 3;
}

1;

__END__

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
