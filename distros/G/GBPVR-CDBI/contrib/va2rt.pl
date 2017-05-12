
use strict;
use warnings;

use GBPVR::CDBI::VideoArchive::ArchiveTable;
use GBPVR::CDBI::RecTracker::RecordedShows;

my @VA= GBPVR::CDBI::VideoArchive::ArchiveTable->retrieve_all();
foreach my $va (@VA){
  next unless $va->UniqueID;
  my ($row) = GBPVR::CDBI::RecTracker::RecordedShows->search( unqiue_id => $va->UniqueID );
  next if $row;
  $row = GBPVR::CDBI::RecTracker::RecordedShows->create({
    name => $va->Title,
    sub_title => $va->Subtitle,
    description => $va->Description,
    unqiue_id => $va->UniqueID,
    startdate=> $va->RecordDate,
  });
}
GBPVR::CDBI::RecTracker::RecordedShows->dbi_commit;

exit;

