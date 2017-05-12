package Labyrinth::Plugin::Survey::YAPC;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.08';

=head1 NAME

Labyrinth::Plugin::Survey::YAPC - YAPC Surveys' Conference Survey management plugin for Labyrinth framework

=head1 DESCRIPTION

Provides all the main conference survey handling functionality for YAPC Surveys.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Survey);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Check

Checks whether the user has signed in, if they have, have they already 
submitted a response to the main conference survey?

If not, then load the survey questions.

=item Save

Saves the question responses from the given survey.

=back

=cut

sub Check {
	unless($tvars{loggedin}) {
		LogDebug("YAPCCheck: user session timed out");
		$tvars{errcode} = 'FAIL';
		return;
    }

    my @rows = $dbi->GetQuery('hash','SurveyCheck',$tvars{loginid});
    unless(@rows) {
        # force failure
        LogDebug("SurveyCheck: look up failed");
        $tvars{errcode} = 'FAIL';
        return;
    }

    my $self = shift;
  	$tvars{data}{submitted} = 1 if($rows[0]->{completed} && $rows[0]->{completed} > 0);
	$tvars{data}{code} = $cgiparams{code};
    $tvars{survey} = $self->LoadSurvey($settings{'survey'});
}

sub Save {
    return  if(!$tvars{loggedin});
    return  if($tvars{data}{submitted});

    my $self = shift;

    # reload survey with valid inputs
    $tvars{survey} = $self->LoadSurvey($settings{'survey'});
    return  unless($tvars{survey});

    my ($all,$man,$collate,$qu) = $self->AnalyseSurvey();

    # ensure we have a valid survey
	return	if FieldCheck($all,$man);

	# now save the survey results
    my $taken = 0;
    my $idcode = $self->CreateID();
    for my $name (@$all) {
        my $c = $collate->{$name} ? $idcode : '';
        if($qu->{max}) {
            $cgiparams{$name} = $qu->{max} if($cgiparams{$name} eq 'ALL');
            $cgiparams{$name} = 0          if($cgiparams{$name} =~ /\D/);
            $cgiparams{$name} = $qu->{max} if($cgiparams{$name} > $qu->{max});
        }
        if($qu->{type} eq 'count') {
            $cgiparams{$name} = 0           if($cgiparams{$name} =~ /\D/);
        }
	    $dbi->DoQuery('SaveSurvey',$name,$cgiparams{$name},$c)   if($cgiparams{$name});
        $taken = 1;
    }

    if($taken) {
        my $completed = $self->CreateID();
        $dbi->DoQuery('SaveSurveyIndex',$completed,$tvars{loginid});
        $tvars{data}->{thanks} = 1;
    } else {
        $tvars{data}->{thanks} = 2;
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
