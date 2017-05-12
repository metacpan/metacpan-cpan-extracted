package Win32::OLE::Const;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '0.01';

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
	'all' => [ qw(
        olMailItem
        olFolderInbox olFolderOutbox olFolderSentMail olFolderDrafts 
        olFolderDeletedItems
	) ],
);

@EXPORT_OK	= ( @{$EXPORT_TAGS{'all'}} );
@EXPORT		= ( @{$EXPORT_TAGS{'all'}} );

use constant    olMailItem              => 1;

use constant    olFolderInbox           => 1;
use constant    olFolderOutbox          => 2;
use constant    olFolderSentMail        => 3;
use constant    olFolderDrafts          => 4;
use constant    olFolderDeletedItems    => 5;

sub import { caller };



1;
__END__
