package Labyrinth::Plugin::Survey;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.08';

=head1 NAME

Labyrinth::Plugin::Survey - YAPC Surveys plugin for the Labyrinth framework

=head1 DESCRIPTION

Provides all the core survey management functionality for YAPC Surveys.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Crypt::Lite;
use Session::Token;
use Time::Local;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

# -------------------------------------
# Load Parser

BEGIN {
    my $loaded = 0;

	eval {
	    require YAML::Syck;
	    eval "use YAML::Syck qw(Load LoadFile)";
	    $loaded = 1;
	};

    if(!$loaded){
        eval {
            require YAML;
            eval "use YAML qw(Load LoadFile)";
            $loaded = 1;
        };
    }

    if(!$loaded){
        die "Cannot load a YAML parser!";
    }
}

# -------------------------------------
# Variables

my (%title_fixes,%single_names,%tutor_fixes);

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=head2 General Survey Methods

=over 4

=item LoadSurvey

Load the current survey configuration.

=item AnalyseSurvey

Analyses the survey configuration, to determine the mandatory and optional 
fields to be applied when the survey is submitted.

=item CheckQuestion

Check the configuration of a specific survey question set.

=item CheckParam

Check the specific question parameter.

=item CreateID

Create a unique ID to be used when collating questions.

=back

=cut

sub LoadSurvey {
    my ($self,$file) = @_;
    my $result;

    eval {
        $result = LoadFile($file);
        if(!defined $result){ # special case for YAML::Syck
            open my $fh, '<', $file or die "Can't open $file: $!";
            $result = do {local $/; <$fh> };
            close $fh;
        }
    };

    if($@) {
        $tvars{errmess} = "Survey parse error: $@";
        $tvars{errcode} = 'ERROR';
        return;
    }

    my $index = 1;
    for my $section (@{$result->{sections}}) {
        for my $question (@{$section->{questions}}) {
            if($question->{multipart}) {
                use Data::Dumper;
                LogDebug("multipart=".Dumper($question->{multipart}));
                for my $multipart (@{$question->{multipart}}) {
                    $multipart->{name} = sprintf 'qu%05d', $index;
                    $multipart->{data} = $cgiparams{$multipart->{name}};
                    $index++;
                }
            } else {
                $question->{name} = sprintf 'qu%05d', $index;
                $question->{data} = $cgiparams{$question->{name}};
                $index++;
            }

            if($question->{choices}) {
                for my $choice (@{$question->{choices}}) {
                    $choice =~ s!\\:\\ !: !g;
                }
            }
        }
    }
    return $result;
}

sub AnalyseSurvey {
    my $self = shift;
    my (@all,@man,%collate,%qu);

    # build mandatory & optional lists
    for my $section (@{$tvars{survey}->{sections}}) {
        for my $question (@{$section->{questions}}) {
            next    if($question->{status} && $question->{status} eq 'hidden');

            if(defined $question->{multipart}) {
                for my $part (@{$question->{multipart}}) {
                    next    if($part->{status} && $part->{status} eq 'hidden');

                    if($part->{name}) {
                        my ($a,$b,$c) = $self->CheckQuestion($part,$question);
                        push @all, @$a;
                        push @man, @$b;
                        $collate{$_} = 1    for(keys %$c);
                        $qu{$part->{name}} = $part;
                    }
                }
                push @man, $question->{name}    if($question->{mandatory});

            } elsif($question->{name}) {
                my ($a,$b,$c) = $self->CheckQuestion($question,$question);
                push @all, @$a;
                push @man, @$b;
                $collate{$_} = 1    for(keys %$c);
                $qu{$question->{name}} = $question;
            }
        }
    }

    return (\@all, \@man, \%collate, \%qu);
}

sub CheckQuestion {
    my ($self,$part,$question) = @_;
    my (@man,@all,%collate);

    push @all, $part->{name};
    push @all, "$part->{name}X" if($part->{default});
    push @man, $part->{name}    if($part->{mandatory} || $question->{mandatory});
    $collate{$part->{name}} = 1 if($part->{collate} || $question->{collate});

    if($part->{type} =~ /text|count|currency/) {
        CheckParam($part->{name},$part);
        if($part->{default}) {
            CheckParam("$part->{name}X",$part);
            $collate{"$part->{name}X"} = 1   if($part->{collate} || $question->{collate});
        }

    } elsif($part->{type} =~ /radio/) {
        for my $opt (@{$part->{options}}) {
            next    unless($opt->{default});

            push @all, "$part->{name}X";
            CheckParam("$part->{name}X",$part);
            $collate{"$part->{name}X"} = 1   if($part->{collate} || $question->{collate});
        }

    } elsif($part->{default}) {
        CheckParam("$part->{name}X",$part);
        $collate{"$part->{name}X"} = 1   if($part->{collate} || $question->{collate});

    }

    if($part->{choices}) {
      my $opts = @{$part->{choices}};
      for my $inx (1..$opts) {
        push @all, "$part->{name}_$inx";
        CheckParam("$part->{name}_$inx",$part);
        $collate{"$part->{name}X"} = 1   if($part->{collate});
      }
    }

    return \@all,\@man,\%collate;
}

sub CheckParam {
    my ($name,$part) = @_;
    return  unless($name && $cgiparams{$name});
    my $clean = CleanTags($cgiparams{$name});
    $cgiparams{"${name}_err"} = ErrorSymbol()  if($clean cmp $cgiparams{$name});
    $part->{error} = ErrorSymbol()             if($clean cmp $cgiparams{$name});
    $cgiparams{$name} = $clean;
}

sub CreateID {
    my $generator = Session::Token->new(alphabet => [0..9], length => 8);
    return $generator->get();
}

=head2 User Interface Methods

=over 4

=item Login

Enable an automatic login, providing the keycode is correct.

=item Welcome

Provides the supporting data for the initial welcome page. This includes all
the courses attributed to the current user, and all the talks held during the
conference.

=item CheckOpenTimes

Check the configured start and end times, and set the appropriate template
variables to enable or disable access to surveys and evaluations as 
appropriate.

=back

=cut

sub Login {
    my @rows = $dbi->GetQuery('hash','SurveyLogin',$cgiparams{code});
    unless(@rows) {
        # force failure
        LogDebug("SurveyLogin: keycode not found");
        $tvars{errcode} = 'FAIL';
        return;
    }

    if($rows[0]->{userid} != $cgiparams{userid}) {
        # force failure
        LogDebug("SurveyCheck: crypt/userid look up failed");
        $tvars{errcode} = 'FAIL';
        return;
    }

    Labyrinth::Session::InternalLogin($rows[0]);
}

sub Welcome {
    my $self = shift;

    $self->ConfigureFixes;

    my @survey = $dbi->GetQuery('hash','GetUserCode',$tvars{loginid});
    $tvars{data}{survey}{completed} = $survey[0]->{completed} if(@survey);

    # list courses
    my @courses = $dbi->GetQuery('hash','ListCourses',$tvars{loginid});
    $tvars{data}{courses} = \@courses   if(@courses);

    # list talks
    my %talks;
    my @rows = $dbi->GetQuery('hash','ListTalks',$tvars{loginid});
    for my $row (@rows) {
        next    if($row->{course} =~ /Lightning Talks/);
        $row->{course} = $self->CourseFixes($row->{course});
        $row->{course} = "[LT] " . $row->{course}    if($row->{talk} == 2);  # Lightning Talks
        $row->{tutor} = $self->TutorFixes($row->{tutor});
        my $date = formatDate(9,$row->{datetime});
        $talks{$date}->{date} = formatDate(19,$row->{datetime});
        $row->{datetime} += $settings{timezone_offset};
        push @{$talks{$date}->{talks}}, $row;
    }
    my @talks = map {$talks{$_}} sort keys %talks;
    $tvars{data}{talks} = \@talks   if(@talks);
    $tvars{talks_time} = time;
    $tvars{thanks} = $cgiparams{thanks};
}

sub CheckOpenTimes {
    for my $dt (qw(survey_start course_start talks_start survey_end)) {
        #LogDebug("CheckOpenTimes: $dt=$tvars{$dt}");
        if($tvars{$dt} && $tvars{$dt} =~ /(\d{4})\W(\d{2})\W(\d{2})\W(\d{2})\W(\d{2})\W(\d{2})/) {
            my $t = timelocal(int($6),int($5),int($4),int($3),int($2-1),int($1-1900));
            my $n = time + $settings{timezone_offset};

        LogDebug("CheckOpenTimes: dt=$dt, $tvars{$dt}, t=$t, n=$n");
            $tvars{$dt} = $t < $n ? 1 : 0
        } else {
            $tvars{$dt} ||= 0;
        }
        #LogDebug("CheckOpenTimes: $dt=$tvars{$dt}");
    }
}

=head2 Admin Interface Methods

=over 4

=item Admin

Loads the data when presenting the survey management pages.

=back

=cut

sub Admin {
    return  unless AccessUser(ADMIN);
    my @surveys = $dbi->GetQuery('hash','AdminSurveys',{'sort' => 'ORDER BY u.realname'});
    my @courses = $dbi->GetQuery('hash','AdminCourses');
    my @talks   = $dbi->GetQuery('hash','AdminTalks');

    if(@surveys) {
        $tvars{surveys} = \@surveys;
        $tvars{scount}  = scalar(@surveys);
    }
    if(@courses) {
        $tvars{courses} = \@courses;
        $tvars{ccount}  = scalar(@courses);
    }
    if(@talks) {
        $tvars{talks}   = \@talks;
        $tvars{tcount}  = scalar(@talks);
    }
}

=head2 Internal Object Methods

Both the following methods are defined by configuration settings.

=over 4

=item CourseFixes

Specific configuration to fix course or talk titles.

Use a list of key/value pairs in the configuration file:

  title_fixes=<<LIST
  Mishpselt=Misspelt
  LIST

Note that for title_fixes, the values should be the full replacement string.

=item TutorFixes

Specific configuration to fix names used by tutors.

Two configurable lists used here. The first is a simple list, while the second
uses a list of key/value pairs in the configuration file:

  single_names=<<LIST
  Barbie
  LIST

  tutor_fixes=<<LIST
  Mishpselt=Misspelt
  LIST

Note that for tutor_fixes, the values should be the full replacement string.

=item ConfigureFixes

Creates the internal hashes for fixes from loaded settings.

=back

=cut

sub CourseFixes {
    my ($self,$title) = @_;
    for my $fix (keys %title_fixes) {
        return $title_fixes{$fix}   if($title =~ /$fix/);
    }
    return $title;
}

sub TutorFixes {
    my ($self,$tutor) = @_;
    for my $fix (keys %single_names) {
        return $1   if($tutor =~ /^($fix)[^a-z]*$/);
    }
    for my $fix (keys %tutor_fixes) {
        return $tutor_fixes{$fix}   if($tutor =~ /$fix/);
    }
    return $tutor;
}

sub ConfigureFixes {
    my $self = shift;

    if($settings{title_fixes}) {
        for my $fix (@{ $settings{title_fixes} }) {
            my ($key,$value) = split('=',$fix,2);
            $title_fixes{$key} = $value if($key);
        }
    }

    if($settings{single_names}) {
        for my $fix (@{ $settings{single_names} }) {
            $single_names{$fix} = 1;
        }
    }

    if($settings{tutor_fixes}) {
        for my $fix (@{ $settings{tutor_fixes} }) {
            my ($key,$value) = split('=',$fix,2);
            $tutor_fixes{$key} = $value if($key);
        }
    }
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
