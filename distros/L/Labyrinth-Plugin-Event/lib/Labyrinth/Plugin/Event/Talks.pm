package Labyrinth::Plugin::Event::Talks;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.10';

=head1 NAME

Labyrinth::Plugin::Event::Talks - Event Talk handler for the Labyrinth framework.

=head1 DESCRIPTION

Contains all the event talk functionality for Labyrinth.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Clone qw(clone);

use Labyrinth::DBUtils;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea


my %fields = (
    eventid     => { type => 1, html => 0 },
    talkid      => { type => 0, html => 0 },
    userid      => { type => 1, html => 0 },
    guest       => { type => 0, html => 0 },
    talktitle   => { type => 1, html => 1 },
    abstract    => { type => 1, html => 2 },
    resource    => { type => 0, html => 2 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

# -------------------------------------
# The Subs

=head1 ADMIN INTERFACE METHODS

=over 4

=item Admin

Provides list of the talks currently available.

=item Add

Add a new talk.

=item Edit

Edit an existing talk.

=item Save

Save the current talk.

=item Delete

Delete a talk.

=item EventSelect

Provides a dropdown list of events available.

=back

=cut

sub Admin {
    return  unless AccessUser(EDITOR);

    if($cgiparams{doaction}) {
        if($cgiparams{doaction} eq 'Delete') { Delete(); }
    }

    my @rows = $dbi->GetQuery('hash','AllTechTalks');
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    my $self = shift;

    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetEventByID','eventid',EDITOR);

    $tvars{data}{ddusers}  = UserSelect(0,1,0,'Speaker',1);
    $tvars{data}{ddevents} = $self->EventSelect($cgiparams{eventid});
}

sub Edit {
    my $self = shift;

    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetEventByID','eventid',EDITOR);

    if($cgiparams{talkid}) {
        my @rows = $dbi->GetQuery('hash','GetTechTalkByID',$cgiparams{talkid});
        $tvars{data} = $rows[0] if(@rows);
        $tvars{data}{abstracted} = $tvars{data}{abstract};
        $tvars{data}{resourced}  = $tvars{data}{resource};
        $cgiparams{eventid}    ||= $tvars{data}{eventid};
    }

    my $opt = $cgiparams{talkid} ? $tvars{data}{userid} : 0;
    $tvars{data}{ddusers}  = UserSelect($opt,1,0,'Speaker',1);
    $tvars{data}{ddevents} = $self->EventSelect($cgiparams{eventid});
}

sub Save {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetEventByID','eventid',EDITOR);

    my $opt = $cgiparams{talkid} ? $tvars{data}{userid} : 0;
    $tvars{data}{ddusers}  = UserSelect($opt,1,0,'Speaker',1);

    return  if FieldCheck(\@allfields,\@mandatory);

    $tvars{data}{guest} = ($tvars{data}{guest} ? 1 : 0);
    for(keys %fields) {
        next    unless($fields{$_});
           if($fields{$_}->{html} == 1) { $tvars{data}{$_} = CleanHTML($tvars{data}{$_}) }
        elsif($fields{$_}->{html} == 2) { $tvars{data}{$_} = CleanTags($tvars{data}{$_}) }
    }


    my @fields = (  $tvars{data}{eventid},
                    $tvars{data}{userid},
                    $tvars{data}{guest},
                    $tvars{data}{talktitle},
                    $tvars{data}{abstract},
                    $tvars{data}{resource}
    );

    if($cgiparams{talkid})
            { $dbi->DoQuery('SaveTechTalk',@fields,$cgiparams{talkid}); }
    else    { $cgiparams{talkid} = $dbi->IDQuery('AddTechTalk',@fields); }
}

sub Delete {
    return  unless AccessUser(ADMIN);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    for my $id (@ids) {
        $cgiparams{'talkid'} = $id;
        next    unless AuthorCheck('GetTechTalkByID','talkid',EDITOR);

        $dbi->DoQuery('DeleteTechTalk',$cgiparams{'talkid'});
    }
}

sub EventSelect {
    my ($self,$opt,$blank) = @_;
    $blank ||= 0;

    my @list;
    my @rows = $dbi->GetQuery('hash','AllTalkEvents');
    for(@rows) { push @list, { id => $_->{eventid}, value => $_->{eventdate} . ' - ' . $_->{title} }; }
    unshift @list, { id => 0, value => 'Select Event'}  if($blank == 1);
    DropDownRows($opt,'eventid','id','value',@list);
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
