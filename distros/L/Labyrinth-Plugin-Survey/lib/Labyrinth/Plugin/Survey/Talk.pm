package Labyrinth::Plugin::Survey::Talk;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.08';

=head1 NAME

Labyrinth::Plugin::Survey::Talk - YAPC Surveys' Talk management plugin for Labyrinth framework

=head1 DESCRIPTION

Provides all the talk evaluation survey handling functionality for YAPC Surveys.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Survey);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    courseid    => { type => 1, html => 0 },
    tutor       => { type => 1, html => 1 },
    course      => { type => 1, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $LEVEL = ADMIN;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Check

Checks whether the user has signed in, if they have, have they already 
submitted a response to this talk evaluation survey?

If not, then load the evaluation questions.

=item Save

Saves the question responses from the given talk evaluation.

=back

=cut

sub Check {
    my $self = shift;

    unless($tvars{loggedin}) {
        LogDebug("TalkCheck: user session timed out");
        $tvars{errcode} = 'FAIL';
        return;
    }

    unless($cgiparams{courseid}) {
        LogDebug("TalkCheck: missing courseid");
        $tvars{errcode} = 'FAIL';
        return;
    }

    my @rows = $dbi->GetQuery('hash','TalkCheck',$tvars{loginid},$cgiparams{courseid});
    unless(@rows) {
        # force failure
        LogDebug("TalkCheck: course not found");
        $tvars{errcode} = 'FAIL';
        return;
    }

    $tvars{course}{tutor}   = $self->TutorFixes($rows[0]->{tutor});
    $tvars{course}{title}   = $self->CourseFixes($rows[0]->{course});

    if(@rows && $rows[0]->{completed} && $rows[0]->{completed} > 0) {
        # force failure
        LogDebug("TalkCheck: user already submitted assessment for this talk");
        $tvars{data}->{submitted} = 1;
        return;
    }

    $tvars{data}{userid}    = $tvars{loginid};
    $tvars{data}{courseid}  = $cgiparams{courseid};

    $tvars{survey} = $self->LoadSurvey($settings{'evaluate'});
}

sub Save {
    return  if($tvars{data}->{submitted});

    my $self = shift;

    # reload survey with valid inputs
    $tvars{survey} = $self->LoadSurvey($settings{'evaluate'});
    return  unless($tvars{survey});

    my ($all,$man,$collate,$qu) = $self->AnalyseSurvey();

    # ensure we have a valid survey
	return	if FieldCheck($all,$man);

	# now save the survey results
    my $taken = 0;
    my $idcode = $self->CreateID();
    for my $name (@$all) {
        my $c = $idcode    if($collate->{$name});

        if($qu->{$name}{tag}) {
            if($cgiparams{$name}) {
                $cgiparams{$name} = sprintf "%s <%s>", $tvars{user}{name}, $tvars{user}{email};
            }
        }

        $dbi->DoQuery('SaveEvaluation',$cgiparams{courseid},$name,$cgiparams{$name},$c)   if($cgiparams{$name});
        $taken = 1;
    }

    if($taken) {
        my $completed = $self->CreateID();
        $dbi->DoQuery('SaveTalkIndex',$completed,$cgiparams{courseid},$tvars{loginid});
        $tvars{data}->{thanks} = 1;
    } else {
        $tvars{data}->{thanks} = 2;
    }
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item Admin

Provides talk and course management for the administrator.

=item Update

Updates type setting for the given course or talk.

There are 4 settings for each course or talk:

=over 4

=item * Course

=item * Talk

=item * Lightning Talk

=item * Ignore

=back

=item Edit

Edit details for the given course or talk.

=item AdminSave

Save edits for the given course or talk.

=item TalkTypeSelect

Provides dropdown code for the list of talk types.

=back

=cut

sub Admin {
    my (@rows_lt,@rows_rt,@rows_mc,@rows_ig);
    my @lt = ({id => -1, value => 'Ignore'},{id => 0, value => 'Course'}, {id => 1, value => 'Regular Talk'});
    my @rows = $dbi->GetQuery('hash','AdminTalkList');
    for my $talk (@rows) {
        next    unless($talk->{course} =~ /Lightning Talk/);
        push @lt, {id => $talk->{datetime}, value => $talk->{course}};
    }
    for my $talk (@rows) {
        my $type = $talk->{talk};
        $type = $talk->{datetime}   if($talk->{talk} == 2);
        $talk->{ddtype} = TalkTypeSelect($type,$talk->{courseid},@lt);

        $tvars{count1}++    if($talk->{talk} == 2);
        $tvars{count2}++    if($talk->{talk} == 1);
        $tvars{count3}++    if($talk->{talk} == 0);
        $tvars{count4}++    if($talk->{talk} == -1);

        push @rows_lt, $talk    if($talk->{talk} == 2);
        push @rows_rt, $talk    if($talk->{talk} == 1);
        push @rows_mc, $talk    if($talk->{talk} == 0);
        push @rows_ig, $talk    if($talk->{talk} == -1);
    }

    $tvars{talks} = \@rows  if(@rows);
    $tvars{talks_lt} = \@rows_lt  if(@rows_lt);
    $tvars{talks_rt} = \@rows_rt  if(@rows_rt);
    $tvars{talks_mc} = \@rows_mc  if(@rows_mc);
    $tvars{talks_ig} = \@rows_ig  if(@rows_ig);
}

sub Update {
    my @rows = $dbi->GetQuery('hash','AdminTalkList');
    for my $talk (@rows) {
        my $type = $cgiparams{'TYPE'.$talk->{courseid}};
        next    if($talk->{talk} == $type);
        next    if($talk->{talk} == 2 && $talk->{datetime} == $type);

        if($type < 2) {
            $talk->{talk} = $type;
        } else {
            $talk->{talk} = 2;
            $talk->{datetime} = $type;
        }

        # do query
        $dbi->DoQuery('SaveCourse',$talk->{course},$talk->{tutor},$talk->{room},$talk->{datetime},$talk->{talk},$talk->{courseid});
    }
}

sub Edit {
    my $self = shift;
    return  unless $cgiparams{'courseid'};
    my @rows = $dbi->GetQuery('hash','GetTalkByID',$cgiparams{courseid});
    return  unless(@rows);

    my @lt = ({id => 0, value => 'Course'}, {id => 1, value => 'Regular Talk'});
    my @lts = $dbi->GetQuery('hash','AdminTalkList');
    for my $talk (@lts) {
        next    unless($talk->{course} =~ /Lightning Talk/);
        push @lt, {id => $talk->{datetime}, value => $talk->{course}};
    }

    my $type = $rows[0]->{talk};
    $type = $rows[0]->{datetime}   if($rows[0]->{talk} == 2);

    $tvars{data}{courseid}  = $rows[0]->{courseid};
    $tvars{data}{tutor}     = $self->TutorFixes($rows[0]->{tutor});
    $tvars{data}{course}    = $self->CourseFixes($rows[0]->{course});
    $tvars{data}{ddtype}    = TalkTypeSelect($type,$rows[0]->{courseid},@lt);
}

sub AdminSave {
    return  unless $cgiparams{'courseid'};
    return  unless AuthorCheck('GetTalkByID','courseid',$LEVEL);

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    return  if FieldCheck(\@allfields,\@mandatory);

    my $datetime = $tvars{data}{datetime};
    my $talk     = $tvars{data}{talk};
    my $type     = $cgiparams{'TYPE' . $cgiparams{'courseid'}};

    if($type < 2) {
        $talk = $type;
    } else {
        $talk = 2;
        $datetime = $type;
    }

    $cgiparams{'datetime'} = $datetime;
    $cgiparams{'talk'}     = $talk;

    $dbi->DoQuery('SaveTalk',   $cgiparams{'tutor'}, $cgiparams{'course'}, $cgiparams{'datetime'},
                                $cgiparams{'talk'},  $cgiparams{'courseid'});

}

sub TalkTypeSelect {
    my ($opt,$id,@list) = @_;
    DropDownRows($opt,'TYPE'.$id,'id','value',@list);
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
