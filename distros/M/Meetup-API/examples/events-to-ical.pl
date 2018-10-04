#!perl
use strict;
use warnings;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use POSIX qw(strftime);
use Meetup::API;
use Meetup::ToICal qw(meetup_to_icalendar get_meetup_event_uid);
use Net::CalDAVTalk;

#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

use vars '$VERSION';
$VERSION = '0.01';

=head1 NAME

events-to-ical.pl - import Meetup events to iCal or a CalDAV server

=head1 SYNOPSIS

  events-to-ical.pl --group meetup-group-name [VCard filename or CalDAV URL]

=head1 DESCRIPTION

Import meetings from Meetup into iCal or CalDAV.

Existing events will not be overwritten.

=head1 ARGUMENTS

  --help        print documentation about Options and Arguments
  --version     print version number

=head1 OPTIONS

  --calendar    Name of the CalDAV calendar
  --server      Server of the CalDAV calendar (also, credentials)
  --group       URL name of the Meetup group
  --exclude     Don't include events matching this re
  --attendee    Email address used for rsvp synchronization
  --verbose     show more information
  --dry-run     don't update the calendar

=head1 EXAMPLE

  events-to-ical.pl --group Perl-User-Groups-Rhein-Main --server https://calendar.example.com/ --calendar MyEvents
  events-to-ical.pl --group Perl-User-Groups-Rhein-Main --calendar ~/.calendar/perl-rhine-main.ics

=cut

use Getopt::Long;
use Pod::Usage;

GetOptions(
    'c|calendar=s' => \my $davcalendar,
    's|server=s'   => \my $davserver,
    'g|group=s'    => \my $groupname,
    'sync-file=s'  => \my $sync_file,

    'attendee=s'   => \my $attendee,

    'x|exclude=s'  => \my @exclude,

    'f|force'      => \my $force,
    'n|dry-run'    => \my $dryrun,
    'v|verbose'    => \my $verbose,
    'help!' => \my $opt_help,
    'version!' => \my $opt_version,
) or pod2usage(-verbose => 1) && exit;

pod2usage(-verbose => 1) && exit if $opt_help;
if( $opt_version ) {
    print $VERSION;
    exit;
};

$groupname ||= 'Perl-User-Groups-Rhein-Main';
$davcalendar ||= 'Default';
$attendee ||= 'corion@corion.net';

my $today = strftime '%Y-%m-%dT00:00:01', localtime;
my $syncToken;
if( $sync_file and -r $sync_file ) {
    open my $fh, '<', $sync_file
        or die "Couldn't open '$sync_file': $!";
    binmode $fh;
    $syncToken = <$fh>;
    $syncToken =~ s!\s+$!!;
};
my $meetup = Meetup::API->new();

$meetup->read_credentials;

my $events = $meetup->group_events($groupname)->get;

sub verbose(@msg) {
    if( $verbose ) {
    #no warnings 'wide';
        print "$_\n" for @msg
    };
}

sub add_event {
    my( $caldav, $calendar, $event ) = @_;
    if( ! $dryrun ) {
        my $data = meetup_to_icalendar( $event, self => $attendee );
        my $handle = $caldav->NewEvent( $calendar, $data);
    } else {
        print "Would add event\n";
    };
}

sub update_event {
    my( $caldav, $href, $event ) = @_;
    if( ! $dryrun ) {
        my $data = meetup_to_icalendar( $event, self => $attendee );
        my $handle = $caldav->UpdateEvent( $href, $data);
    } else {
        print "Would update event\n";
    };
}

sub as_ical( $caldavArgs ) {
    Net::CalDAVTalk->_argsToVCalendar($caldavArgs)->{entries}->[0]
}

sub ical_prop( $ical, $property ) {
    if( my $p = $ical->property($property)) {
        $p->[0]->value
    } else {
        undef
    }
}

sub entry_is_different( $dav, $meetup, %upstream ) {
warn "--- meetup";
    my $meetup_ical = as_ical( meetup_to_icalendar( $meetup ));
warn "--- caldav";
    my $dav_ical = as_ical( $dav );
    die;
    
    my %differences;

    my %data = (
        'ical'   => $dav_ical,
        'meetup' => $meetup_ical,
    );
    my %other = (
        'ical'   => 'meetup',
        'meetup' => 'ical',
    );

    for my $attribute (qw( dtstart location )) {
        my $upstream_moniker   = $upstream{ $attribute } || 'meetup';
        my $downstream_moniker = $other{ $upstream_moniker };

        my $upstream = ical_prop( $data{ $upstream_moniker }, $attribute );
        my $local    = ical_prop( $data{ $downstream_moniker }, $attribute );

        # Exclude whitespace changes
        for ($local,$upstream) {
            s!\s+! !g if defined $_;
        };

        if( $local ne $upstream ) {
            #$Data::Dumper::Useqq = 1;
            #warn "Meetup " . Dumper $upstream;
            #warn "DAV    " . Dumper $local;
            verbose( "$attribute has changed from '$local' ($downstream_moniker) to '$upstream' ($upstream_moniker)");
            $differences{ $attribute } = $upstream;
        }
    };

    scalar keys %differences
};

sub read_ics( $filename ) {
    require Data::ICal::DAVAdapter;
    Data::ICal::DAVAdapter->new(
        filename => $filename
    );
}

sub read_dav( $davserver, $davcalendar ) {
    require Net::CalDAVTalk;
    my $url = URI::URL->new( $davserver );

    my @userinfo = split /:/, $url->userinfo, 2;
    my $CalDAV = Net::CalDAVTalk->new(
        user => $userinfo[0],
        password => $userinfo[1],
        host => $url->host(),
        port => $url->port(),
        scheme => $url->scheme,
        url => $url->path,
        expandurl => 1,
        logger => sub { warn "DAV: @_" },
    );

    return $CalDAV
}

my $calendar;
if( -f $davcalendar or ! $davserver) {
    #die "Don't know how to handle local calendar files yet";
    #my $vcard = Net::CalDAVTalk::VCard->new_fromfile($item);
    #push @contacts, $vcard;
    $calendar = read_ics( $davcalendar );

} else {
    $calendar = read_dav( $davserver, $davcalendar );
};

my ( $upstream_events, $removed, $errors );
if( $syncToken and !$force) {
    ( undef, $removed, $errors ) = $calendar->SyncEvents($davcalendar, after => $today, syncToken => $syncToken );
};

# Net::CardDAVTalk messes up the encoding by double-encoding it :(
# https://rt.cpan.org/Public/Bug/Display.html?id=120592
$upstream_events = $calendar->GetEvents($davcalendar, after => $today );

# The user deleted these on their DAV calendar, so we won't re-sync
# these unless --force'd
my %dav_deleted = map {
    $_ => 1
} @$removed;
%dav_deleted = () if $force;

my %upstream_events = map {
    $_->{uid} => $_
} @$upstream_events;

EVENT: for my $event (@$events) {
    # Convert new event, for easy comparison
    my $uid = get_meetup_event_uid( $event );

    if( $event->{time} !~ /^(\d+)\d\d\d$/ ) {
        warn "Weirdo timestamp '$event->{time}' for event";
        return;
    };
    my $start_epoch = $1;
    my $name = sprintf "%s at %s", $event->{name}, strftime( '%Y%m%dT%H%M%SZ', gmtime( $start_epoch ));

    for my $exclude (@exclude) {
        if( $event->{name} =~ /$exclude/ ) {
            verbose("'$name' excluded (/$exclude/)");
            next EVENT;
        };
    };

    if( my $dav_entry = $upstream_events{ $uid }) {
        # Well, determine if really different, also determine what changed
        # and then synchronize the two
        if( entry_is_different( $dav_entry, $event )) {
            verbose( "$name exists and is different, updating" );

            # This assumes that Meetup will be leading for all
            # attributes, even attendance...
            update_event( $calendar, $dav_entry->{href}, $event );
            #die Dumper $dav_entry;
        } else {
            verbose( "$name exists and is the same in CalDAV" );
        };

    } elsif( $dav_deleted{ $uid } ) {
        verbose("Skipping locally deleted event $name");

    } else {
        verbose("Found new entry $name, adding");
        add_event( $calendar, $davcalendar, $event );
        #warn sprintf "%s at %s", $meetup->{name}, strftime( '%Y%m%dT%H%M%SZ', gmtime( $start_epoch ));
    };
    #die;
};
#print sprintf "%d seconds taken to sync $url", time - $fb_sync;
if( $sync_file and my $token = $calendar->{syncToken}) {
    open my $fh, '>', $sync_file
        or warn "Couldn't create timestamp file '$sync_file'";
    binmode $fh;
    print $fh $token;
};

if( ! $davserver ) {
    open my $fh, '>', $davcalendar
        or die "Couldn't save calendar: $!";
    binmode $fh, ':raw';
    print $fh $calendar->ics->as_string;
}

=head1 KNOWN ISSUES

UTF-8 values in CalDAV servers get double-encoded. This is a bad heuristic
in L<Net::CardDAVTalk> that double-decodes values.

=cut