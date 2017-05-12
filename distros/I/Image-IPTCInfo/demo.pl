#!/usr/bin/perl

use Image::IPTCInfo;

chdir('demo_images');

my @files = ('burger_van.jpg', 'dog.jpg');

foreach my $filename (@files)
{
	# Create new IPTCInfo object for the file
	my $info = new Image::IPTCInfo($filename);

	# With this you can get a list of keywords...
	my $keywordsRef = $info->Keywords();

	# ...and specific attributes
	print "file      : $filename\n";
	print "caption   : " . $info->Attribute('caption/abstract') . "\n";
	foreach $keyword (@$keywordsRef)
	{
		print "  keyword : $keyword\n";
	}

	# Create some mappings and extra data for messing
	# with XML and SQL exports.
	my %mappings = (
		'caption/abstract'	=> 'caption',
		'by-line'			=> 'byline',
		'city'				=> 'city',
		'province/state'	=> 'state');
	
	my %extra = ('extra1'   => 'value1',
				 'filename' => $filename);

	print "\n------------------------------\n\n";
	
	# Demo XML export, with and without extra stuff
	print "xml follows:\n\n";
	print $info->ExportXML('photo');
	
	print "\nxml with extra stuff follows:\n\n";
	print $info->ExportXML('photo-with-extra', \%extra);

	print "\n------------------------------\n\n";
	
	# Demo SQL export, with and without extra stuff
	print "sql follows:\n\n";
	print $info->ExportSQL('photos', \%mappings);

	print "\n\nsql with extra stuff follows:\n\n";
	print $info->ExportSQL('morephotos', \%mappings, \%extra);

	print "\n\n------------------------------\n\n";
}

print "all done!\n\n";

exit;

