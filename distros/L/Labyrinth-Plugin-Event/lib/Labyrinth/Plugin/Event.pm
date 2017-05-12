package Labyrinth::Plugin::Event;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.10';

=head1 NAME

Labyrinth::Plugin::Event - Events handler for the Labyrinth framework.

=head1 DESCRIPTION

Contains all the event functionality for Labyrinth.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Clone qw(clone);
use Time::Local;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

use Labyrinth::Plugin::Articles::Sections;
use Labyrinth::Plugin::Event::Sponsors;
use Labyrinth::Plugin::Event::Types;

# -------------------------------------
# Variables

my $ADAY = 86400;
my %abbreviations;

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    eventid     => { type => 0, html => 0 },
    folderid    => { type => 0, html => 0 },
    userid      => { type => 0, html => 0 },
    imageid     => { type => 0, html => 0 },
    title       => { type => 1, html => 1 },
    listeddate  => { type => 1, html => 1 },
    eventdate   => { type => 1, html => 1 },
    eventtime   => { type => 1, html => 1 },
    eventtypeid => { type => 1, html => 0 },
    sponsorid   => { type => 0, html => 0 },
    venueid     => { type => 0, html => 0 },
    publish     => { type => 1, html => 0 },
    body        => { type => 1, html => 2 },
    links       => { type => 0, html => 2 },
    image       => { type => 0, html => 0 },
    align       => { type => 0, html => 0 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $LEVEL = EDITOR;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=head2 Full Event Details

=over 4

=item NextEvent()

Retrieves the next event for event type.

=item NextEvents()

Retrieves all the future events for event type.

=item PrevEvents()

Retrieves all the future events for event type.

=back

=cut

sub NextEvent {
    my $timer = _get_timer();
    my @rows;

    $cgiparams{eventtypeid} ||= 0;

    if($cgiparams{eventtypeid}) {
        @rows = $dbi->GetQuery('hash','GetNextEventByType',$timer,$cgiparams{eventtypeid});
    } else {
        @rows = $dbi->GetQuery('hash','GetNextEvent',$timer);
    }
    return  unless(@rows);

    $tvars{event}{$cgiparams{eventtypeid}}{next} = $rows[0];

    my @talks = $dbi->GetQuery('hash','GetEventTalks',$rows[0]->{eventid});
    if(@talks) {
        for my $talk (@talks) {
            my %talk = map {$_ => $talk->{$_}} qw(userid realname guest talktitle abstract);
            push @{ $tvars{event}{$cgiparams{eventtypeid}}{talks} }, \%talk;
        }
    }

    my @dates;
    push @dates, formatDate(10,$_->{listdate})  for(@rows);
    $tvars{events}{$cgiparams{eventtypeid}}{dates} = \@dates  if(@dates);
}

sub NextEvents {
    my $timer = _get_timer();
    my @rows;

    $cgiparams{eventtypeid} ||= 0;

    if($cgiparams{eventtypeid}) {
        @rows = $dbi->GetQuery('hash','GetNextEventsByType',$timer,$cgiparams{eventtypeid});
    } else {
        @rows = $dbi->GetQuery('hash','GetNextEvents',$timer);
    }
    LogDebug("NextEvents rows=".scalar(@rows));
    return  unless(@rows);

    my @dates;
    for my $row (@rows) {
        push @dates, formatDate(10,$row->{listdate});
    }

    $tvars{events}{$cgiparams{eventtypeid}}{future} = $rows[0];
    $tvars{events}{$cgiparams{eventtypeid}}{dates}  = \@dates  if(@dates);

    if($cgiparams{eventtypeid}) {
        my $sections = Labyrinth::Plugin::Articles::Sections->new();
        $sections->GetSection('eventtype' . $cgiparams{eventtypeid});
        $tvars{events}{$cgiparams{eventtypeid}}{intro} = $tvars{page}{section};
    }
}

sub PrevEvents {
    my $timer = _get_timer();
    my @rows;

    $cgiparams{eventtypeid} ||= 0;

    if($cgiparams{eventtypeid}) {
        @rows = $dbi->GetQuery('hash','GetPrevEventsByType',$timer,$cgiparams{eventtypeid});
    } else {
        @rows = $dbi->GetQuery('hash','GetPrevEvents',$timer);
    }
    LogDebug("PrevEvents rows=".scalar(@rows));

    my %data;
    for my $row (@rows) {
        $data{$row->{listdate}}->{$_} = $row->{$_}  for(keys %$row);

        next    unless($row->{talktitle});  # ignore talks without a title
        my %talk = map {$_ => $row->{$_}} qw(realname guest talktitle);
        push @{$data{$row->{listdate}}->{talks}}, \%talk;

    }
    my @data = map {$data{$_}} reverse sort keys %data;
    $tvars{events}{$cgiparams{eventtypeid}}{past} = \@data   if(@data);

    if($cgiparams{eventtypeid}) {
        my $sections = Labyrinth::Plugin::Articles::Sections->new();
        $sections->GetSection('eventtype' . $cgiparams{eventtypeid});
        $tvars{events}{$cgiparams{eventtypeid}}{intro} = $tvars{page}{section};
    }
}

sub _get_timer {
    my $date  = formatDate(3);
    my ($day,$month,$year) = split("/",$date);

    return timelocal(0,0,0,$day,$month-1,$year);
}

=head2 Event Lists

=over 4

=item ShortList()

Provides a list of forthcoming events, with abbreviations as appropriate. 
Defaults to 365 days or 20 events, but these limits can be set in the 
configuration as 'eventsshortlistdays' and 'eventsshortlistcount' respectively.

=item LongList()

Provides a list of forthcoming events. No defaults, will return the list based
on the configured limits or all future events if no configuration. Values can
be set for 'eventslonglistdays' and 'eventslonglistcount'.

=item Item()

Provides the specified event.

=back

=cut

sub ShortList {
    my $date = formatDate(3);
    my ($day,$month,$year) = split("/",$date);
    my $daylimit = $settings{eventsshortlistdays}  || 365;
    my $numlimit = $settings{eventsshortlistcount} || 20;

    unless(%abbreviations) {
        for(@{ $settings{abbreviations} }) {
            my ($name,$value) = split(/=/,$_,2);
            $abbreviations{$name} = $value;
        }
    }

    my @events;   
    my $events = _events_list($year,$month,$day,$daylimit,$numlimit);
    for my $event (@$events) {
        for my $abbr (keys %abbreviations) {
            $event->{title} =~ s/$abbr/$abbreviations{$abbr}/;
        }
        $event->{eventdate} =~ s/\s+/&nbsp;/g;
        push @events, $event;
    }

    $tvars{events}{shortlist} = \@events;
}

sub LongList {
    my ($day,$month,$year) = _startdate();
    my $daylimit = $settings{eventslonglistdays};
    my $numlimit = $settings{eventslonglistcount};

    my $eventtypes = Labyrinth::Plugin::Event::Types->new();

    my $list = _events_list($year,$month,$day,$daylimit,$numlimit);

    $tvars{events}{longlist}  = $list   if(defined $list);
    $tvars{events}{ddpublish} = PublishSelect($cgiparams{'publish'},1);
    $tvars{events}{ddtypes}   = $eventtypes->EventTypeSelect($cgiparams{'eventtypeid'},1);
}

sub _events_list {
    my ($year,$month,$day,$daylimit,$numlimit) = @_;
    my @rows;

    $daylimit ||= 0;
    $numlimit ||= 0;

    my $timer = timelocal(0,0,0,$day,$month-1,$year);
    my $limit = $timer + ($daylimit * $ADAY);

    my @where = ("listdate>=$timer");
    push @where, "eventtypeid=$cgiparams{'eventtypeid'}"    if($cgiparams{'eventtypeid'});
    push @where, "publish=$cgiparams{'publish'}"            if($cgiparams{'publish'});
    my $where = @where ? join(' AND ',@where) : '';

    my $num = 0;
    my $next = $dbi->Iterator('hash','GetEventsByDate',{where=>$where});
    while(my $row = $next->()) {
        last    if($daylimit && $row->{listdate} > $limit);
        last    if($numlimit && $num > $numlimit);

        $row->{snippet}   = $row->{body};
        $row->{snippet}   =~ s!^(?:.*?)?<p>(.*?)</p>.*$!<p>$1...</p>!si if($row->{snippet});
        $row->{shortdate} = $row->{eventdate};
        $row->{shortdate} =~ s/([A-Za-z]{3}).*/$1/                      if($row->{shortdate});
        $row->{links} =~ s!\*!<br />!g                                  if($row->{links});
        push @rows, $row;
        $num++;
    }

    return  unless(@rows);
    return \@rows;
}

sub _startdate {
    my %base = (
        day     => 1,
        month   => isMonth(),
        year    => formatDate(1)
    );
    my $base = sprintf "%04d%02d%02d", $base{year},$base{month},$base{day};

    my @time = localtime(time);
    my $time = sprintf "%04d%02d%02d", $time[5]+1900,$time[4]+1,$time[3];

    my @date = map {$cgiparams{$_} || $base{$_}} qw(year month day);
    my $date = sprintf "%04d%02d%02d", @date;

#use Labyrinth::Audit;
#LogDebug("base=$base");
#LogDebug("time=$time");
#LogDebug("date=$date");

    if($date < $time) {
        return ($time[3],$time[4]+1,$time[5]+1900);
    }

    return reverse @date;
}

sub Item {
    return  unless($cgiparams{'eventid'});

    my @rows = $dbi->GetQuery('hash','GetEventByID',$cgiparams{'eventid'});
    $tvars{event} = $rows[0]    if(@rows);

    my @talks = $dbi->GetQuery('hash','GetEventTechTalks',$cgiparams{eventid});
    $tvars{event}{talks} = @talks ? \@talks : undef;
}

=head1 ADMIN INTERFACE METHODS

=head2 Events

=over 4

=item Admin

Provides list of the events currently available.

=item Add

Add a new event.

=item Edit

Edit an existing event.

=item Copy

Copy an existing event, creating a new event.

=item Save

Save the current event.

=item Promote

Promote the published status of the specified event by one level.

=item Delete

Delete the specified events.

=back

=cut

sub Admin {
    return  unless AccessUser(EDITOR);

    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete' ) { Delete();  }
        elsif($cgiparams{doaction} eq 'Copy'   ) { Copy();    }
        elsif($cgiparams{doaction} eq 'Promote') { Promote(); }
    }

    my $month = $cgiparams{'month'};
    my $year  = $cgiparams{'year'};

    my @where;
    push @where, "userid=$tvars{'loginid'}"             unless(Authorised(PUBLISHER));
    if($cgiparams{'publish'}) {
        push @where, "publish=$cgiparams{'publish'}";
    } else {
        push @where, "publish<4";
    }
    push @where, "eventtype=$cgiparams{'eventtype'}"    if($cgiparams{'eventtype'});
    my $where = @where ? 'WHERE '.join(' AND ',@where) : '';

    my $eventtypes = Labyrinth::Plugin::Event::Types->new();

    my @rows = $dbi->GetQuery('hash','AllEvents',{where=>$where});
    foreach my $row (@rows) {
        $row->{publishstate}    = PublishState($row->{publish});
        $row->{createdate}      = formatDate(3,$row->{listdate});
        $row->{eventtype}       = $eventtypes->EventType($row->{eventtypeid});
        $row->{name}            = UserName($row->{userid});
    }
    $tvars{data} = \@rows   if(@rows);

    $tvars{ddpublish}   = PublishSelect($cgiparams{'publish'},1);
    $tvars{ddtypes}     = $eventtypes->EventTypeSelect($cgiparams{'eventtype'},1);
}

sub Add {
    return  unless AccessUser(EDITOR);

    my $eventtypes = Labyrinth::Plugin::Event::Types->new();
    my $sponsors   = Labyrinth::Plugin::Event::Sponsors->new();

    my %data = (
        folderid    => 1,
        title       => '',
        userid      => $tvars{loginid},
        name        => $tvars{user}->{name},
        createdate  => formatDate(4),
        body        => '',
        imageid     => 1,
        ddalign     => AlignSelect(1),
        ddtype      => $eventtypes->EventTypeSelect(0,1),
        link        => 'images/blank.png',
        ddpublish   => PublishAction(1,1),
    );

    $tvars{data} = \%data;

    my $promote = 0;
    $promote = 1    if(Authorised(EDITOR));
    $tvars{data}{ddpublish} = PublishAction(1,$promote);
    $tvars{data}{ddpublish} = PublishSelect(1)  if(Authorised(ADMIN));
    $tvars{data}{ddvenue}   = VenueSelect($tvars{data}{venueid},1);
    $tvars{data}{ddsponsor} = $sponsors->SponsorSelect($tvars{data}{sponsorid},1);
}

sub Edit {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetEventByID','eventid',EDITOR);
    return  unless($tvars{data});   # no data, no event

    if($tvars{data}{publish} == 4 && $tvars{command} ne 'view') {
        $tvars{errcode} = 'FAILURE';
        return;
    }

    my $eventtypes = Labyrinth::Plugin::Event::Types->new();
    my $sponsors   = Labyrinth::Plugin::Event::Sponsors->new();

    $tvars{data}{align}       = $cgiparams{ALIGN0};
    $tvars{data}{alignment}   = AlignClass($tvars{data}{align});
    $tvars{data}{ddalign}     = AlignSelect($tvars{data}{align});
    $tvars{data}{name}        = UserName($tvars{data}{userid});
    $tvars{data}{ddtype}      = $eventtypes->EventTypeSelect($tvars{data}{eventtypeid},1);
    $tvars{data}{createdate}  = formatDate(4,$tvars{data}{createdate});
    $tvars{data}{ddvenue}     = VenueSelect($tvars{data}{venueid},1);
    $tvars{data}{ddsponsor}   = $sponsors->SponsorSelect($tvars{data}{sponsorid},1);

    my $promote = 0;
    $promote = 1    if($tvars{data}{publish} == 1 && Authorised(EDITOR));
    $promote = 1    if($tvars{data}{publish} == 2 && Authorised(PUBLISHER));
    $promote = 1    if($tvars{data}{publish} == 3 && Authorised(PUBLISHER));
    $tvars{data}{ddpublish} = PublishAction($tvars{data}{publish},$promote);
    $tvars{data}{ddpublish} = PublishSelect($tvars{data}{publish})  if(Authorised(ADMIN));

    my @rows = $dbi->GetQuery('hash','GetEventTechTalks',$tvars{data}{eventid});
    $tvars{data}{talks} = @rows ? \@rows : undef;
    $tvars{preview} = clone($tvars{data});  # data fields need to be editable

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $tvars{data}{$_} = CleanHTML($tvars{data}{$_}) }
        elsif($fields{$_}->{html} == 2) { $tvars{data}{$_} =  SafeHTML($tvars{data}{$_});
                                       $tvars{preview}{$_} = CleanTags($tvars{preview}{$_}) }
        elsif($fields{$_}->{html} == 3) { $tvars{data}{$_} =  SafeHTML($tvars{data}{$_});
                                       $tvars{preview}{$_} = CleanTags($tvars{preview}{$_}) }
    }

    $tvars{data}{listeddate}  = formatDate(3,$tvars{data}{listdate});
}

sub Copy {
    return  unless AccessUser(EDITOR);
    $cgiparams{'eventid'} = $cgiparams{'LISTED'};
    return  unless AuthorCheck('GetEventByID','eventid',EDITOR);

    my @fields = (  $tvars{data}{folderid},
                    $tvars{data}{title},
                    $tvars{data}{eventdate},
                    $tvars{data}{eventtime},
                    $tvars{data}{eventtypeid},
                    $tvars{data}{venueid},
                    $tvars{data}{imageid},
                    $tvars{data}{align},
                    1,
                    $tvars{data}{sponsorid} || 0,
                    $tvars{data}{listdate},
                    $tvars{data}{body},
                    $tvars{data}{links},
                    $tvars{loginid});

    $cgiparams{eventid} = $dbi->IDQuery('AddEvent',@fields);

    $tvars{errcode} = 'NEXT';
    $tvars{command} = 'event-edit';
}

sub Save {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetEventByID','eventid',EDITOR);

    $tvars{data}{align} = $cgiparams{ALIGN0};

    for(keys %fields) {
        next    unless($fields{$_});
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
    }

    return  if FieldCheck(\@allfields,\@mandatory);

    # check whether listing date has changed
    my $listeddate  = formatDate(3,$tvars{data}{listdate});
    $tvars{data}{listdate} = unformatDate(3,$tvars{data}{listeddate})
        unless($listeddate eq $tvars{data}{listeddate});

    my $imageid = 1;
    # withdrawn, may be reintroduced later.
    #my $imageid = $tvars{data}{'imageid'} || 1;
    #($imageid) = Images::SaveImageFile(
    #                    param   => 'image',
    #                    stock   => 4)   if($cgiparams{image});

    my %fields = map {$_ => 1} @allfields;
    delete $fields{$_}  for @mandatory;
    for(keys %fields) {
        if(/align|id/)  { $tvars{data}{$_} ||= 0; }
        else            { $tvars{data}{$_} ||= undef; }
    }

    my @fields = (  $tvars{data}{folderid},
                    $tvars{data}{title},
                    $tvars{data}{eventdate},
                    $tvars{data}{eventtime},
                    $tvars{data}{eventtypeid},
                    $tvars{data}{venueid},
                    $imageid,
                    $tvars{data}{align},
                    $tvars{data}{publish},
                    $tvars{data}{sponsorid} || 0,
                    $tvars{data}{listdate},
                    $tvars{data}{body},
                    $tvars{data}{links}
    );

    if($cgiparams{eventid})
            { $dbi->DoQuery('SaveEvent',@fields,$cgiparams{eventid}); }
    else    { $cgiparams{eventid} = $dbi->IDQuery('AddEvent',@fields,$tvars{loginid}); }

    $tvars{thanks} = 1;
}

sub Promote {
    return  unless AccessUser(PUBLISHER);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    for my $id (@ids) {
        $cgiparams{'eventid'} = $id;
        next    unless AuthorCheck('GetEventByID','eventid');

        my $publish = $tvars{data}{publish} + 1;
        next    unless($publish < 5);
        $dbi->DoQuery('PromoteEvent',$publish,$cgiparams{'eventid'});
    }
}

sub Delete {
    return  unless AccessUser(ADMIN);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    for my $id (@ids) {
        $cgiparams{'eventid'} = $id;
        next    unless AuthorCheck('GetEventByID','eventid',EDITOR);
        $dbi->DoQuery('DeleteEvent',$cgiparams{'eventid'});
    }
}

=head2 Event Attributes

=over 4

=item VenueSelect

Provides a dropdown list of venues available.

=back

=cut

sub VenueSelect {
    my ($opt,$blank) = @_;
    $blank ||= 0;

    my @list = $dbi->GetQuery('hash','AllVenues');
    unshift @list, { venueid => 0, venue => 'Select A Venue' } if($blank == 1);
    DropDownRows($opt,'venueid','venueid','venue',@list);
}

# withdrawn, may be reintroduced later.
#sub ImageCheck  {
#    my @rows = $dbi->GetQuery('array','EventsImageCheck',$_[0]);
#    @rows ? 1 : 0;
#}


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
