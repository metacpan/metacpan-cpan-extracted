package Bundle::Link_Controller;
$REVISION=q$Revision: 1.10 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

Bundle::Link_Controller - List of perl modules needed for LinkController.

=head1 SYNOPSIS

    perl -MCPAN -e shell
    ...
    install Bundle::Link_Controller

=head1 DESCRIPTION

This is a bundle module which installs all of the perl modules needed
by the LinkController software.

The first section of the contents forces installation of modules which
are required by the rest Data::Dumper is double installed to force it
to be there before libnet.

=head2 packages

This is the list of rpms that satisfy the dependencies in the contents
section. 

=over 4 

Data::Dumper 0       - required by libnet
MD5 0                - required by libwww-perl
Net::FTP 0           - required by libwww-perl
CDB_File 0.86         - there are bugs in version 0.83

=item perl-CGI-modules

this should probably be got rid of since it doesn't seem standard..

CGI::Carp 0
CGI::Form 0
CGI::Request 0

=item perl-CGI-Response

CGI::Response 0

=item perl-Data-Dumper - standard in new perl

Data::Dumper 0

=item perl-Getopt-Mixed

Getopt::Mixed 1.006

=item perl-HTML-Parser

HTML::LinkExtor 0

=item perl-HTML-Tree

HTML::Parse 0

=item perl-HTML-Stream

HTML::Stream 0

=item perl-libwww-perl

HTTP::Date 0
HTTP::Response 0
HTTP::Status 0
LWP::Debug 0
LWP::MediaTypes 0
LWP::RobotUA 0
LWP::UserAgent 0

=item perl-MLDBM

MLDBM 1.22           - earlier versions are database incompatible

=item perl-URI

URI 0

=back

=head1 CONTENTS

Data::Dumper 0       - required by libnet
MD5 0                - required by libwww-perl
Net::FTP 0           - required by libwww-perl

CDB_File 0.86         - earlier versions than 0.6 don't have multiget inbuilt
#                      - earlier versions than 0.86 have important bugs

CGI::Carp 0
CGI::Form 0
CGI::Request 0
CGI::Response 0
Data::Dumper 0
Getopt::Mixed 1.006
HTML::Tagset 0        - this may have been separated from another module??
HTML::LinkExtor 0
HTML::Parse 0
HTML::Stream 0
HTTP::Date 0
HTTP::Response 0
HTTP::Status 0
Net::Telnet 0         - used by adaptive tester to try really hard on broken links.
MIME::Base64          - for authentication in LWP
LWP::Debug 0
LWP::MediaTypes 0
LWP::RobotUA 0
LWP::UserAgent 0
MLDBM 1.22           - earlier versions are database incompatible
URI 0
Search::Binary 0

=head1 INCLUDED MODULES

The following modules are included in the LinkController distribution
and do not need to be installed separately.

	CDB_File::BiIndex 0.026
	CDB_File::BiIndex::Generator 0
	CDB_File::Generator 0.018
	WWW::Link 0
	WWW::Link::Repair 0
	WWW::Link::Repair::DirectSubstitutor 0
	WWW::Link::Reporter 0
	WWW::Link::Reporter::HTML 0
	WWW::Link::Reporter::RepairForm 0
	WWW::Link::Reporter::Text 0
	WWW::Link::Selector 0
	WWW::Link::Test 0
	Schedule::SoftTime 0
	Test_Link 0

=head2 Outdated

The following are included for now in the distribution but are
outdated as far as normal dependency on them goes.

	BiIndex 0

=head1 STANDARD

The following modules are needed for the software, but are in the
standard distribution of perl5.005.

        Data::Dumper 0
	CGI::Carp 0
	Carp 0
	Cwd 0
	DB_File 0
	English 0
	Fcntl 0
	File::Copy 0
	File::Find 0
	IO::File 0

=head1 SEE ALSO

=cut

