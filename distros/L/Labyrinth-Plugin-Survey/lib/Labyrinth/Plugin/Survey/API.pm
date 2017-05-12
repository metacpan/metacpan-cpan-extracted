package Labyrinth::Plugin::Survey::API;

use warnings;
use strict;
use utf8;

use vars qw($VERSION);
$VERSION = '0.08';

=head1 NAME

Labyrinth::Plugin::Survey::API - YAPC Surveys' API plugin via Labyrinth framework

=head1 DESCRIPTION

Provides all the interfaces needed by external event instances to access data
from the current YAPC Surveys.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

#----------------------------------------------------------
# Variables

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=head2 User Methods

=over 4

=item GetUserLink

Returns the login link for a specific user.

=item DisableUser

Disables the user login and any communication via announcements for a specific
user.

=back

=cut

sub GetUserLink {
    my @users = $dbi->GetQuery('hash','FindUserByAct',$cgiparams{actuserid});
    return  unless(@users);             # act user not registered
    return  unless($users[0]->{code});  # if no code, not a logged in user
    $tvars{act}{link} = sprintf "http://%s.yapc-surveys.org/key/%s/%d", $settings{icode}, $users[0]->{code}, $users[0]->{userid};
}

sub DisableUser {
    my @users = $dbi->GetQuery('hash','FindUserByAct',$cgiparams{actuserid});
    return  unless(@users);             # act user not registered
    $dbi->DoQuery('hash','DisableUser',$cgiparams{actuserid});
    $tvars{act}{disabled} = 1;
}

=head2 Talk Methods

=over 4

=item GetTalkLink

Returns the talk link for a specific talk/course.

For an open user, i.e. for anyone watching the video stream, these users will
need to register and login. Feedback from these users is stored separately.

=item DisableTalk

Disables the ability to receive evaluations for the given talk.

=back

=cut

sub GetTalkLink {
    my @talks = $dbi->GetQuery('hash','FindCourseByAct',$cgiparams{acttalkid});
    return  unless(@talks);             # act talk not registered
    $tvars{act}{link} = sprintf "http://%s.yapc-surveys.org/talk/%d", $settings{icode}, $talks[0]->{talkid};
}

sub DisableTalk {
    my @talks = $dbi->GetQuery('hash','FindCourseByAct',$cgiparams{acttalkid});
    return  unless(@talks);             # act talk not registered
    $dbi->DoQuery('hash','DisableTalk',$cgiparams{acttalkid});
    $tvars{act}{disabled} = 1;
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
