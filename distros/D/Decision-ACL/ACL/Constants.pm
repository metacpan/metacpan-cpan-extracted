package Decision::ACL::Constants;

use strict;
use Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

@EXPORT = qw(ACL_RULE_UNCONCERNED 
				ACL_RULE_CONCERNED
				ACL_RULE_DENY
				ACL_RULE_ALLOW);
@EXPORT_OK = qw(ACL_RULE_UNCONCERNED 
				ACL_RULE_CONCERNED
				ACL_RULE_DENY
				ACL_RULE_ALLOW);
%EXPORT_TAGS = (rule => [qw(ACL_RULE_UNCONCERNED
							ACL_RULE_CONCERNED
							ACL_RULE_DENY
							ACL_RULE_ALLOW)]);

#Rule Status Constants
use constant ACL_RULE_UNCONCERNED => 0;
use constant ACL_RULE_CONCERNED => 1;
use constant ACL_RULE_DENY => 2;
use constant ACL_RULE_ALLOW => 3;

666;
