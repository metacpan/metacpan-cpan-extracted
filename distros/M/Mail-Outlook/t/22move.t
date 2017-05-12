use strict;
use warnings;
use Test::More;

use_ok('Mail::Outlook');

my $outlook = Mail::Outlook->new();

#my $folder = $outlook->folder('Inbox/London PM');
#ok( $folder, "Got a folder." );

#my $message = $folder->first;
#isa_ok($message,'Mail::Outlook::Message');

#my $destination = $outlook->folder('Inbox/Cricket');
#isa_ok($destination,'Mail::Outlook::Folder');

#$destination->move( $message );

done_testing;