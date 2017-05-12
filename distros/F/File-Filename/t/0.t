use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::Filename 'get_filename_segments';
use File::Filename::Convention 'get_filename_hash';
my @filenames = (
'122106-VERIZON 17577-005761-@API.pdf',
'122705-CHRYSLER FINANCIAL-004689-@API.pdf',
'122705-CITICORP VENDOR FINANCE INC-004691-@API.pdf',
'122705-COMMONWEALTH DIGITAL OFFICE-004701-@API.pdf',
'122705-FEDERAL EXPRESS-004700-@API.pdf',
'122705-GUARDIAN REALTY MANAGEMENT INC-004693-@API.pdf',
'122705-MARLEN ASSOCIATES LP LOCK BOX-004694-@API.pdf',
'122705-PENN PARKING-004704-@API.pdf',
'122705-PRENTISS PROPERTIES-004695-@API.pdf',
'122705-TIDEWATER COMPANIES-004705-@API.pdf',
'122705-TOYOTA FINANCIAL SERVICES-004696-@API.pdf',
'122705-WELLS FARGO FINANCIAL LEASING-004697-@API.pdf',
'122705-WMATA WASHINGTON METROPOLITAN-004698-@API.pdf',
'122706-BRANDYWINE WISCONSIN LLC-005779-@API.pdf',
'122706-GUARDIAN REALTY MANAGEMENT INC-005776-@API.pdf',
'122706-JBG NICHOLSON LANE EAST LLC-005778-@API.pdf',
'122706-TOYOTA FINANCIAL SERVICES-005780-@API.pdf',
'122706-TOYOTA FINANCIAL SERVICES-005781-@API.pdf',
'122706-WMATA WASHINGTON METROPOLITAN-005782-@API.pdf',
'122805-RGS TITLE LLC-004706-@API.pdf',
'122806-2004 BRADLEY FOOD AND BEVERAGE-005789-@API.pdf',
'122806-ABSTRACT ASSOCIATES INC-005785-@API.pdf',
'122806-ALTOGETHER-005786-@API.pdf',
'122806-ANNE LESAGE-005787-@API.pdf',
'122806-ATLANTIC SERVICES GROUP-005788-more bogus-@APX.pdf',
'122806-CLERK OF THE CIRCUIT COURT-005790-@API.pdf',
'122806-CLERK OF THE COURT MONTGOMERY-005791-@API.pdf',
'/dirs/here/122806-COMMONWEALTH DIGITAL OFFICE-005784-@API.pdf',
);


my @filenames_bad = (

'122705-J & M DELIVERY INC-004703-@API.pdf',
'082305-PENN PARKING-004309-@AP-000.pbm',
'082305-PENN PARKING-004309-@AP-001.pbm',
'082305-PENN PARKING-004309-@AP-002.pbm',
'082305-PENN PARKING-004309-@AP-003.pbm',
'101206-CDW DIRECT LLC-005533-@AP.pdf.ocr',
'122705-V & F COFFEE INC-004702-@API.pdf',
'122705-V F COFFEE INC-004702API.pdf',
'122705V F COFFEE INC-004702-APX.pdf',


);

### File Filename

for (@filenames){
	print "$_ : ";
	my $s = get_filename_segments($_);
	map { print "[$_]"} @$s;
	print "\n";
	ok(scalar @$s,"got code and hash") or die($_);
}





#opendir(DIR,$ENV{HOME});
#map { 
#		my $segments = get_filename_segments($_); 
#		## $_
#		## $segments
#} grep { !/^\.+$/ } readdir DIR;
#closedir DIR;

### File Filename Convention

my $filenaming_convention_fields= [
	['date','vendor','checknum',[ code => 'API' ],'ext'],	
	['date','vendor','checknum', 'extra', [ code => 'APX' ],'ext'],	
	['date','vendor',[code=>'NOCHECKNUM'],'ext'],	
	['name','code','ext'],	
];



my $filenaming_convention_matchsubs = {
   date => sub { $_[0]=~/\d{6,8}$/ },
	code => sub { $_[0]=~/^AP[CVIA]*$|^TAX$|^REC$|^EWK$|TWK$|APX$|NOCHECKNUM$/ },	
	checknum => sub { $_[0]=~/^\d+$/ },
};


for (@filenames){
	my $hash = get_filename_hash($_,$filenaming_convention_fields, $filenaming_convention_matchsubs);
	ok($hash->{code},'got hash and code' ) or do{
		### $hash	
		die($_);

	}
	
}	



### tests bad
for (@filenames_bad){
	my $badfilename = $_;

   warn "\n---\n should not be able to get_filename_hash() for $badfilename\n\n";

   my $hash = get_filename_hash( $badfilename,$filenaming_convention_fields, $filenaming_convention_matchsubs);
   

   unless( ok( ! defined $hash, 'get_filename_hash()')) {
      ### $hash
      die("why getting hash for : $badfilename ?");
   }

	
}



