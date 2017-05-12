package MOSES::MOBY::Tags;
use strict;
use vars qw( @ISA @EXPORT );

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

BEGIN {
	@ISA = qw( Exporter );
	@EXPORT = qw(
	  ARTICLENAME
	  AUTHORITY
	  AUTHURI
	  COLLECTION
	  COMMENT
	  CROSSREFERENCE
	  DATABASECOMMENT
	  DATABASENAME
	  DATABASEVERSION
	  EVIDENCECODE
	  EXCEPTIONCODE
	  EXCEPTIONMESSAGE
	  MOBY_XML_NS_PREFIX
	  MOBY_XML_NS
	  MOBY
	  MOBYBOOLEAN
	  MOBYCONTENT
	  MOBYDATA
	  MOBYDATETIME
	  MOBYEXCEPTION
	  MOBYFLOAT
	  MOBYINTEGER
	  MOBYOBJECT
	  MOBYSTRING
	  NOTES
	  OBJ_ID
	  OBJ_NAMESPACE
	  PARAMETER
	  PLAINVERSION
	  PROVISIONINFORMATION
	  QUERYID
	  REFELEMENT
	  REFQUERYID
	  SERVICECOMMENT
	  SERVICEDATABASE
	  SERVICENAME
	  SERVICENOTES
	  SERVICESOFTWARE
	  SEVERITY
	  SIMPLE
	  SOFTWARECOMMENT
	  SOFTWARENAME
	  SOFTWAREVERSION
	  VALUE
	  XREF
	  XREFTYPE
	);
use constant MOBY_XML_NS_PREFIX => 'moby';

use constant MOBY_XML_NS => 'http://www.biomoby.org/moby';

################################
## PCDATA elements            ##
################################

use constant NOTES => 'Notes';

use constant SERVICECOMMENT => 'serviceComment';

use constant COMMENT => 'comment';

use constant VALUE => 'Value';

use constant XREF => 'Xref';

use constant EXCEPTIONCODE => 'exceptionCode';

use constant EXCEPTIONMESSAGE => 'exceptionMessage';

################################
## Biomoby primitive types    ##
################################
use constant MOBYSTRING => 'String';

use constant MOBYINTEGER => 'Integer';

use constant MOBYFLOAT => 'Float';

use constant MOBYBOOLEAN => 'Boolean';

use constant MOBYDATETIME => 'DateTime';

################################
## non-PCDATA elements        ##
################################

use constant MOBY => 'MOBY';

use constant MOBYCONTENT => 'mobyContent';

use constant SERVICENOTES => 'serviceNotes';

use constant MOBYDATA => 'mobyData';

use constant SIMPLE => 'Simple';

use constant COLLECTION => 'Collection';

use constant PARAMETER => 'Parameter';

use constant MOBYOBJECT => 'Object';

use constant CROSSREFERENCE => 'CrossReference';

use constant PROVISIONINFORMATION => 'ProvisionInforomation';

use constant SERVICESOFTWARE => 'serviceSoftware';

use constant SERVICEDATABASE => 'serviceDatabase';

use constant MOBYEXCEPTION => 'mobyException';

################################
## attribute names            ##
################################

use constant AUTHORITY => 'authority';

use constant QUERYID => 'queryID';

use constant OBJ_NAMESPACE => 'namespace';

use constant OBJ_ID => 'id';

use constant ARTICLENAME => 'articleName';

use constant PLAINVERSION => 'version';

use constant SOFTWARENAME => 'software_name';

use constant SOFTWAREVERSION => 'software_version';

use constant SOFTWARECOMMENT => 'software_comment';

use constant DATABASENAME => 'datatbase_name';

use constant DATABASEVERSION => 'database_version';

use constant DATABASECOMMENT => 'database_comment';

use constant AUTHURI => 'authURI';

use constant SERVICENAME => 'serviceName';

use constant EVIDENCECODE => 'evidenceCode';

use constant XREFTYPE => 'xrefType';

use constant SEVERITY => 'severity';

use constant REFQUERYID => 'refQueryID';

use constant REFELEMENT => 'refElement';
}
1;
