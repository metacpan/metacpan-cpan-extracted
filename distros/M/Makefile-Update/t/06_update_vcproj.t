use strict;
use warnings;
use autodie;
use Test::More;

use Makefile::Update;
BEGIN { use_ok('Makefile::Update::VCProj'); }

my $sources = [qw(file1.cpp file2.cpp fileNew.cpp)];
my $headers = [qw(file1.h file2.h fileNew.h)];

open my $out, '>', \my $outstr;
update_vcproj(*DATA, $out, $sources, $headers);

note("Result: $outstr");

like($outstr, qr/file1\.cpp/, 'existing source file was preserved');
like($outstr, qr/fileNew\.cpp/m, 'new source file was added');
unlike($outstr, qr/fileOld\.cpp/, 'old source file was removed');
unlike($outstr, qr/file3\.h/, 'old header was removed');
like($outstr, qr/fileNew\.h/, 'new header was added');
like($outstr, qr/resource\.rc/, 'resource file was preserved');
like($outstr, qr/file\.other/, 'other file was preserved');

done_testing()

__DATA__
<?xml version="1.0" encoding="Windows-1252"?>
<VisualStudioProject
	ProjectType="Visual C++"
	Version="7.10"
	Name="base"
	ProjectGUID="{79F1691B-08C4-55BB-985E-FDDB0BC8753C}">
	<Platforms>
		<Platform
			Name="Win32"/>
	</Platforms>
	<Files>
		<Filter
			Name="Source Files"
			UniqueIdentifier="{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}">
			<File
				RelativePath="file1.cpp">
			</File>
			<File
				RelativePath="file2.cpp">
			</File>
			<File
				RelativePath="fileOld.cpp">
			</File>
			<File
				RelativePath="file3.cpp">
			</File>
			<File
				RelativePath="resource.rc">
			</File>
		</Filter>
		<Filter
			Name="Header Files"
			UniqueIdentifier="{yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy}">
			<File
				RelativePath="file1.h"
				>
			</File>
			<File
				RelativePath="file2.h"
				>
			</File>
			<File
				RelativePath="file3.h"
				>
			</File>
		</Filter>
		<Filter
			Name="Some Other Files"
			UniqueIdentifier="{zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz}">
            <File
                RelativePath="file.other"
                >
			</File>
		</Filter>
	</Files>
</VisualStudioProject>
