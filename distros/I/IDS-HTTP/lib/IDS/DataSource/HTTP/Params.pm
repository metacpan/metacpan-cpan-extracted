#
# Parameters and defaults for the HTTP parser; no actual code here
#

package IDS::DataSource::HTTP::Params;
$IDS::DataSource::HTTP::Params::VERSION = "1.0";

require Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw (%params %param_options);
our @EXPORT_OK = qw (%params %param_options);

%params = (
    # general parameters
    # source			# filled in by IDS::DataSource::HTTP::read_session,
    				# it is the source of data,
    				# used when producing error/warn msgs
    "msg_fh" => undef,		# Where warning messages go; nowhere if undef
    "return_warnings" => 1,	# Warnings are tokens
    "print_warnings" => 0,	# Print warning messages (to msg_fh)
    "verbose" => 0,		# Print extra information; larger means more
    
    # what to return as tokens
    "with_values" => 1,         # whether to put values in the parsed http
    "lc_only" => 1, 	        # whether to map all of the http to lower case
    "file_types_only" => 1,     # return only file types, not names

    # various data validation options
    "recognize_hostnames" => 1, # return simply if a hostname is valid or not
    "recognize_ipaddr" => 1,    # return simply if an addr is valid or not
    "lookup_hosts" => 0,        # lookup hosts and addrs to ensure DNS entries?
    "recognize_dates" => 1,     # return simply if a date is valid or not
    "handle_PHPSESSID" => 1,	# validate PHP Session ID to avoid hash
    "handle_EntityTag" => 1,	# validate Entity Tags to avoid hashes
    "recognize_qvalues" => 1,	# validate qvalue; otherwise, return value
    "email_user_length_only" => 0, # only return the email address length, 
                  		# not value
);

# for command-line argument processing with GetOpt::Long
%param_options = (
    "values"              => \$params{"with_values"},
    "lc"                  => \$params{"lc_only"},
    "file_types_only"     => \$params{"file_types_only"},
    "verbose=i"           => \$params{"verbose"},
    "return_warnings"	  => \$params{"return_warnings"},
    "print_warnings"	  => \$params{"print_warnings"},
    "recognize_hostnames" => \$params{"recognize_hostnames"}, 
    "recognize_ipaddr"    => \$params{"recognize_ipaddr"},    
    "lookup_hosts"        => \$params{"lookup_hosts"},        
    "recognize_dates"     => \$params{"recognize_dates"},     
    "handle_PHPSESSID"    => \$params{"handle_PHPSESSID"},	
    "handle_EntityTag"    => \$params{"handle_EntityTag"},	
    "recognize_qvalues"   => \$params{"recognize_qvalues"},	
    "email_user_length_only" => \$params{"email_user_length_only"},
);

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the reponse depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Algorithm>, L<IDS::DataSource>

=cut

1;
