package Mail::Exchange::ObjectTypes;
# From MS-OXCPRPT V20120630 2.2.1.7

=head1 NAME

Mail::Exchange::ObjectTypes - enum functions for the various kinds of
objects that may be stored in a PidTagObjectType property

=head1 SYNOPSIS
    use Mail::Exchange::ObjectTypes;

Including this module allows you to use names like otMailUser or
otAttachment for the various object types defined in [MS-OXCPRPT]
section 2.2.1.7.

=head1 REFERENCES

[MS-OXCPRPT] Property and Stream Object Protocol specification
http://msdn.microsoft.com/en-us/library/cc425503(v=exchg.80).aspx
on Sep 30, 2012
=cut

use strict;
use warnings;
use 5.008;

use Exporter;
use Encode;

use vars qw($VERSION @ISA @EXPORT);
@ISA=qw(Exporter);
$VERSION = "0.01";

@EXPORT=qw(otStoreObject otAddressBookObject otAddressBookContainer
	otMessageObject otMailUser otAttachment otDistributionList
	);

sub otStoreObject		{return 0x0001 ;}
sub otAddressBookObject		{return 0x0002 ;}
sub otAddressBookContainer	{return 0x0004 ;}
sub otMessageObject		{return 0x0005 ;}
sub otMailUser			{return 0x0006 ;}
sub otAttachment		{return 0x0007 ;}
sub otDistributionList		{return 0x0008 ;}

1;
