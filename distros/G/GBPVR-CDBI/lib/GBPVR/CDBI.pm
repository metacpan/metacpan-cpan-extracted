package GBPVR::CDBI;

use warnings;
use strict;

our $VERSION = '0.04';

use base 'Class::DBI';
use Win32::TieRegistry;
use File::Spec;

our $gbpvr_dir = $Registry->{'LMachine\software\devnz\GBPVR InstallDir'} || 'C:\program files\devnz\gbpvr';

__PACKAGE__->db_setup(file => 'gbpvr.mdb');

sub db_setup {
  my $self = shift;
  my $p = { @_ };
  my $file = $p->{file};
  $file = File::Spec->rel2abs($file, $gbpvr_dir);  # if file was a relative path, make it full with respect to GBPVR
  my $dbopts = $p->{dbopts} || { AutoCommit=>0, LongTruncOk => 1, LongReadLen => 255 };
  my $dsn = 'driver=Microsoft Access Driver (*.mdb);dbq=' . $file;
  my $rc;
  # trap errors, specifically for the case that GBPVR isn't installed so the
  # default mdb's don't exist (e.g. for cpan-testers)
  eval { $rc = $self->set_db('Main', "dbi:ODBC:$dsn", '', '', $dbopts ); };
  warn "ERROR in db_setup('$file'): $@" if $@;
  return $rc;
}

1;
__END__

=pod

=head1 NAME

GBPVR::CDBI - Database Abstraction for GBPVR

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

Example to search the program listings:

        use GBPVR::CDBI::Programme;
        my @rows = GBPVR::CDBI::Programme->search_like(name => 'Star%');

Example to display the recorded shows:

        use GBPVR::CDBI::RecordingSchedule;
        my @rows = GBPVR::CDBI::RecordingSchedule->search(status => 2);
        foreach my $row (@rows){
          printf "-----------------------\n";
          printf "%s - '%s'\n", $row->programme_oid->name, $row->programme_oid->sub_title;
          printf "<%s>\n", $row->filename;
          printf "   %s\n", $row->programme_oid->description;
        }

Example to show pending shows (yes, you should be able to order_by via search() and not have to call sort):

        use GBPVR::CDBI::RecordingSchedule;
        my @rows = GBPVR::CDBI::RecordingSchedule->search(status => 0);
        @rows = sort { $a->manual_start_time cmp $b->manual_start_time } @rows;
        foreach my $row (@rows){
          printf "%-20s %8s %s - '%s'\n",
                $row->manual_start_time,
                $row->programme_oid->channel_oid->name,
                $row->programme_oid->name,
                $row->programme_oid->sub_title;
          printf "   %s\n", $row->programme_oid->description;
        }

Example to force all scheduled 'Simpsons' recordings to be low quality:

        use GBPVR::CDBI::RecordingSchedule;
        my $iterator = GBPVR::CDBI::RecordingSchedule->retrieve_all;
        while( my $row = $iterator->next ){
          next unless $row->programme_oid->name =~ /simpsons/i;
          next if $row->quality_level == 2;
          $row->quality_level(2);
          $row->update;
        }
        GBPVR::CDBI::RecordingSchedule->dbi_commit;

=head1 INTRODUCTION

This set of classes provides an easy to use, robust, and well-documented way to access the GBPVR database via the Class::DBI module.  The major tables are included as well as that of the Video Archive plugin.

B<This is a windows-only module> since GBPVR is a windows-only application.

What is GBPVR? It is a Personal Video Recorder (PVR) program. The Microsoft Access .mdb database that is creates stores information such as recording schedules and details about completed recordings. GBPVR can be obtained here:
  http://gbpvr.com

Note that this allows both read and transactional write access to the database.

Why was this written?  In part, as an exercise in L<Class::DBI>, but largely to make it very easy to write stand-alone apps/scripts in perl for GBPVR.  To run any kind of custom task involving setting schedules or listing schedules or listing recorded shows.

More details will follow, but it is possible to compile perl scripts that use this into stand-alone exe's to distribute to systems without perl installed (see L<PAR>).

=head1 GBPVR CLASSES

The following are the provided GBPVR classes. Note that they all inherit from Class::DBI, so that having an attribute of 'foo' means that $obj->foo is an accessor and $obj->foo('bar') is a mutator. Also note that for the foreign keys, the attribute method will return either the foreign key value or the foreign object, depending on the context.

=over 2

=item *

L<GBPVR::CDBI> - Base class for providing access to the GBPVR database.

=item *

L<GBPVR::CDBI::RecordingSchedule> - Access to the 'recording_schedule' table.

=item *

L<GBPVR::CDBI::Programme> - Access to the 'programme' table.

=item *

L<GBPVR::CDBI::PlaybackPosition> - Access to the 'playback_position' table.

=item *

L<GBPVR::CDBI::Channel> - Access to the 'channel' table.

=item *

L<GBPVR::CDBI::CaptureSource> - Access to the 'capture_source' table.

=back

=head1 PLUGIN CLASSES

=head2 Video Archive

The Video Archive plug-in:
  http://gbpvr.com/pmwiki/pmwiki.php/Plugin/VideoArchive

=over 2

=item *

L<GBPVR::CDBI::VideoArchive> - Base class for providing access to the Video Archive database.

=item *

L<GBPVR::CDBI::VideoArchive::ArchiveTable> - Access to the 'archivetable' table.

=back

=head2 RecTracker

The RecTracker Utility:
  http://gbpvr.com/pmwiki/pmwiki.php/Utility/RecTracker

=over 2

=item *

L<GBPVR::CDBI::RecTracker> - Base class for providing access to the RecTracker database.

=item *

L<GBPVR::CDBI::RecTracker::RecordedShows> - Access to the 'RecordedShows' table.

=back

=head1 METHODS

=head2 db_setup

Wrapper for Class::DBI->set_db -- takes just a filename of a MS Access file (.mdb) and calls set_db w/the proper connection string.  Takes two named parameters -- 'file' is required. If it is a relative path, it will be with respect to the GBPVR home directory.  'dbopts' is an optional hashref to path through to set_db() -- it defaults to { AutoCommit=>0, LongTruncOk => 1, LongReadLen => 255 }

=head1 EXAMPLES

The I<contrib> directory of the distribution contains several short sample scripts to illustrate quick & easy code to perform useful tasks.

=head2 pending.pl

Prints out pending recordings, earliest first; includes times, channel, title, and show description.

=head2 pending2ical.pl

The same as I<pending.pl> but outputs them in iCal format with each recording as a separate event. Also takes into account recurring recordings and treats them differently.  Requires L<Data::ICal>.

=head2 va2rt.pl

Good example of cross-database usage. This finds all of the shows from the VideoArchive database (i.e. everything that's been recorded already), and checks if it exists in the RecTracker database (i.e. to see if it's already flagged as 'do not record again'). Any that are not found are simply created as new records in the RecTracker database.  This is especially handy if you install RecTracker after having used VideoArchive for a while.

=head2 manual.pl

Usage: manual.pl channel HH:MM HH:MM

Basically a "quick record" -- just put the channel number (what you would hit on the tv remote), and the start and end times (24-hr format), and it will create a pending-recording entry for today for that channel and time.

=head2 clean_pending.pl

This is a utility clean up script i was using for a while when running GBPVR on a low-end machine (PIII-400).  It does two tasks -- 1) deletes any pending entry more than 3 days in the future (otherwise the MVP server was too slow to load; these deleted entries get remade by the EPG update nightly anyways); 2) forces all recordings to be low quality (I found that, on an older GBPVR version, the requested quality wouldn't always take, especially if done from the listings or search screens).

This is written using Class::DBI methods.

=head3 clean_pending-sql.pl

Same as I<clean_pending.pl> but written by just feeding SQL through Class::DBI.

=head3 clean_pending-AbstractSearch.pl

Same as I<clean_pending.pl> but written using L<Class::DBI::AbstractSearch> calls.

=head3 clean_pending-Win32_ODBC.pl

Same as I<clean_pending.pl> but written using L<Win32::ODBC> instead of L<DBI>/L<Class::DBI>.  Provided solely for reference as yet another way to do the task.

=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 PREREQUISITES

GBPVR::CDBI is only intended for use on Win32, as GBPVR will only run on windows.

GBPVR::CDBI requires the following modules:

L<DBI>

L<DBD::ODBC>

L<Class::DBI>

L<Win32::TieRegistry>

L<File::Spec>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gbpvr-cdbi at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GBPVR-CDBI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GBPVR::CDBI

You can also look for information at:

=over 4

=item * Perl Monks -- /msg davidrw

L<http://perlmonks.org>

=item * GBPVR Forums -- pm dwestbrook

L<http://forums.gbpvr.com>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GBPVR-CDBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GBPVR-CDBI>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GBPVR-CDBI>

=item * Search CPAN

L<http://search.cpan.org/dist/GBPVR-CDBI>

=back

=head1 ACKNOWLEDGEMENTS

Sub for creating GBPVR

jeff for the VideoArchive plugin

jorm for the RecTracker utility

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<DBD::ODBC>

The initial release/announcement:
  http://forums.gbpvr.com/showthread.php?p=35938#poststop

GBPVR:
  http://gbpvr.com/

GBPVR wiki (documents the program, configuration, plugins, utilities, etc):
  http://www.gbpvr.com/pmwiki

=cut

