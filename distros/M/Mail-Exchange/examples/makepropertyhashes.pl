#!/usr/bin/perl
#
# Helper script, called at the end of getdocumentation.sh - it reads the tag
# definitions from the HTML files that getdocumentation.sh fetched us, and
# creates the various definition files from them.

opendir(DIR, "tagdefs");
@files=readdir DIR;
closedir DIR;

mkdir("lib/Mail", 0777);
mkdir("lib/Mail/Exchange", 0777);

open(P2I, ">lib/Mail/Exchange/PidTagIDs.pm");
print P2I q [
# This file is autogenerated from Microsoft documentation. Don't edit!
package Mail::Exchange::PidTagIDs;
use Exporter;
use vars qw(@ISA @EXPORTER);
@ISA=qw(Exporter);
# @EXPORT at the bottom because this file is autogenerated

];

open(L2I, ">lib/Mail/Exchange/PidLidIDs.pm");
print L2I q [
# This file is autogenerated from Microsoft documentation. Don't edit!
# LIDs are stored as (lid<<16|type), so when using these, remember to
# shift the LID right by 16 bits to get the "real" lid.
package Mail::Exchange::PidLidIDs;
use Exporter;
use vars qw(@ISA @EXPORTER);
@ISA=qw(Exporter);
# @EXPORT at the bottom because this file is autogenerated

];

open(P2D, ">lib/Mail/Exchange/PidTagDefs.pm");
print P2D q [
# This file is autogenerated from Microsoft documentation. Don't edit!
package Mail::Exchange::PidTagDefs;
use Exporter;
use vars qw(@ISA @EXPORTER);
@ISA=qw(Exporter);
@EXPORT=qw(%PidTagDefs);

our %PidTagDefs=(
];

open(L2D, ">lib/Mail/Exchange/PidLidDefs.pm");
print L2D q [
# This file is autogenerated from Microsoft documentation. Don't edit!
package Mail::Exchange::PidLidDefs;
use Exporter;
use vars qw(@ISA @EXPORTER);
@ISA=qw(Exporter);
@EXPORT=qw(%PidLidDefs);

our %PidLidDefs=(
];

open(T2D, ">lib/Mail/Exchange/PropertyTypes.pm");
print T2D q [
# This file is autogenerated from Microsoft documentation. Don't edit!
package Mail::Exchange::PropertyTypes;
use Exporter;
use vars qw (@ISA @EXPORTER);
@ISA=qw(Exporter);
# @EXPORT at the bottom because this file is autogenerated

my %PropertyTypes=(

];


foreach $file (@files) {
	next unless $file =~ /^2\.\d+_/;

	%val=();
	open(IN, "<tagdefs/$file") or die "$file: $!";
	while (<IN>) {
		chomp;
		y/\r//d;
		next unless /<strong>(.*)<\/strong>(.*)/;
		$key=$1;
		$key="Canonical name:" if $key eq "Canonical Name:"; #2.875
		($val=$2)=~s/^\s+//;
		$val=~s/<a href=".*?">(.*?)<\/a>/\1/g;
		$val=~s/<.*?>//g;
		$val=~s/\s+$//;
		$val{$key}=$val;
		if ($key =~ /Ptyp/) {
			$key=~s/Data type:\s*//;
			$key=~s/,$//;	# doc. problem "PtypBoolean,"
			$val{'datatype'}=$key;
			$val=~s/^,\s+//;
			$val{'datatypeid'}=$val;
			$propertytype{"$key"}=$val;
			$propertytype{"$val"}="\"$key\"";
		}
	}
	close IN;

	$id=$longid="";
	$key="$val{'Canonical name:'}";

	if ($key =~ /PidTag/) {
		push(@pidtagexport, $key);
		$id=hex($val{'Property ID:'});
		$type=hex($val{"datatypeid"});
		$desc=$val{"Description:"};
		push @p2i, sprintf "sub $key { return 0x%04X%04X; }\n", $id, $type;
		push @p2d, sprintf "0x%04x => { type => 0x%04x, name => \"%s\" }, # %s\n",
			$id, $type, $key, $desc;
	} elsif ($key =~ /PidLid/) {
		push(@pidlidexport, $key);
		$id=hex($val{'Property long ID (LID):'});
		$type=hex($val{"datatypeid"});
		$desc=$val{"Description:"};
		$guid=$val{"Property set:"}; $guid=~s/.*\{(.*)\}.*/$1/;
		push @l2i, sprintf "sub $key { return 0x%04X%04X; }\n", $id, $type;
		push @l2d, sprintf "0x%04x => { type => 0x%04x, name => \"%s\", guid => \"%s\" }, # %s\n",
			$id, $type, $key, $guid, $desc;
	}
}

print P2I '@EXPORT=qw('.join(" ", @pidtagexport).q[);
].join("", sort @p2i).q[

1;
];

print L2I '@EXPORT=qw('.join(" ", @pidlidexport).q[);
].join("", sort @l2i).q[


1;
];

foreach $key (sort keys %propertytype) {
	print T2D qq(\t$key => $propertytype{$key},\n);
}
print T2D ");\n";
@t2dexport=();
foreach $key (sort keys %propertytype) {
	if (substr($key, 0, 4) eq "Ptyp") {
		print T2D qq(sub $key { return $propertytype{$key};}\n);
		push @t2dexport , $key;
	}
}
$t2dexport=join(" ", @t2dexport);
print T2D qq[
\@EXPORT=qw(%PropertyTypes $t2dexport);

1;
];

print P2D join("", sort @p2d).q[

);

1;
];

print L2D join("", sort @l2d).q[

);

1;
];

