###############################################################################
#UTF.pm
#Last Change: 2008-12-08
#Copyright (c) 2008 Marc-Seabstian "Maluku" Lucksch
#Version 0.21
####################
#This file is part of the Plasma project, a parser library for an all-purpose
#ASCII file format. More information can be found on the project web site
#at http://plasma.sf.net/ .
#
#UTF.pm is published under the terms of the MIT license, which basically 
#means "Do with it whatever you want". For more information, see the license.txt
#file that should be enclosed with plasma distributions. A copy of the license
#is (at the time of this writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################

package Games::Freelancer::UTF;
use Exporter;
{
	no warnings qw/portable/; #Why is this so hard... :(
	local $^W=0; #Grrr @ Tie::InsertOrderHash;
	require Tie::InsertOrderHash;
}
use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION = 1.001;

=head1 NAME

Games::Freelancer::UTF - Perl extension for working with Microsoft UTF Files used in the Game Freelancer.

=head1 Synopsis

	use Games::Freelancer::UTF;
	open FILE,"model.cmp"; #or .utf, .3db, .txm, .mat, .ale, .vms, .dfm or maybe some more
	binmode FILE;
	my $content = do {local $/; <FILE>};
	close FILE;
	my $tree=UTFread($content);
	$code = UTFwriteUTF($tree);
	open FILE, ">out.cmp"
	binmode FILE;
	print FILE, $code;
	close FILE;


=head1 DESCRIPTION

This Module provides the ability to decode UTF files for the Mircrosoft game "Freelancer"

Those are named UTF files because of their header.

They are just trees that are encoded in binary, there might be a possibility that these files are used somewhere else, too.

In "Freelancer" they are used for models, meshes, materials, textures, effects and a lot more.

You can even use this to save hashes of hashes, but I highly recommend using something else, like L<Storable> for this.

=head1 WARNING

The read routines return a tied InsertOrderHash, so just keep the reference you got and work with it instead of using

	my %mysuperhash = %{UTFread($crypted)}
	%mysuperhash{NewEntry} = "Data"
	# Now the order is destroyed
	# This is better:
	my $tree=UTFread($crypted);
	$tree->{NewEntry} = "Data"
	

I have no idea how important the order of the elements is for Freelancer, but better keep it this way.
Of course all subhashes are also tied
	#Bad code example
	$tree->{copyme}={%{$tree}};
	#Good code:
	tie my %newhash,'Tie::InsertOrderHash';
	%newhash=(%{$tree}) #Copy tree, preserves order, at least last time I tested
	$tree->{copyme}=\%newhash;
	#not this:
	$tree->{copyme}={%newhash}; #Looses tiedness too.

=head1 FUNCTIONS

=cut

# Perl-Port by Maluku (fl@maluku.de)
our @ISA=qw/Exporter/;
our @EXPORT=qw/UTFread UTFwrite/;
our @EXPORT_OK=qw/UTFread UTFwrite/;

my $datas;
my $strings;
my $pointer;
my %strings;
my %datas;
my %offsets;


=head2 $tree = UTFread ($data);

Reads an UTF file content into a tied tree:

	use Games::Freelancer::UTF;
	use Data::Dumper;
	open FILE,"model.cmp";
	binmode FILE;
	my $content = do {local $/; <FILE>};
	close FILE;
	my $tree=UTFread($content);
	print Data::Dumper->Dump([$tree]);

=cut

sub UTFread {
	my $d = UTFreadUTF(@_);
	return $d;
}


=head2 $data = UTFwrite ($tree);

Reads an UTF file content into a tied tree:

	use Games::Freelancer::UTF;
	open FILE,"model.cmp";
	binmode FILE;
	my $content = do {local $/; <FILE>};
	close FILE;
	my $tree=UTFread($content);
	#... Do something with $tree ..., for example moving a hardpoint:
	foreach my $entr (grep /\.3db/,keys %{$tree->{"\\"}}) {
		foreach (keys %{$tree->{"\\"}->{$entr}->{Hardpoints}->{"Fixed"}}) {
			#moves all fixed hardpoints along (0.2,0.2,0.2):
			$tree->{"\\"}->{$entr}->{Hardpoints}->{"Fixed"}->{$_}->{Position}=pack("f*",map {$_+0.2} unpack("f*",$tree->{"\\"}->{$entr}->{Hardpoints}->{"Fixed"}->{$_}->{Position})); 
		}
	}
	# Now write it down.
	open FILE,">model2.cmp";
	binmode FILE;
	print FILE UTFwrite($tree);
	close FILE;
=cut

sub UTFwrite {
	return UTFwriteUTF(@_);
}

=head1 INTERNAL FUNCTIONS (use with care)

=head2 get (SOURCE, OFFSET, LENTGH)

Extracts a string of LENGTH at OFFSET of the SOURCE.

Used for general file reading.

=cut

#Internal functions:

#$chars = get ($string,$offset,$amount);
#returns $amount (or less) chars of $string starting from $offset.
#Also increases $offset.


sub get {
	my $off=$_[1];
	$_[1]+=$_[2];
	return substr($_[0],$off,$_[2]);
}

=head2 string (OFFSET)

Extracts a string \0 delimited string at OFFSET out of the stringlibrary of the file.

Used for key names

=cut

#my $string = string($offset)
#Returns a string of stringlib, which is a compilation of \0 strings starting a $offset.
#Returns string without the trailing \0.

sub string {
	if ($_[0] >= length $strings) { #THIS IS AN ERROR IN THE UTF FILE
		warnings::warnif("Requested a string from outside of the string lib, this is an error in the file or something the parser doesn't know about.");	
		return "" ; 
	}
	my $shift=index($strings,"\0",$_[0]) - $_[0];
	return substr($strings,$_[0],$shift);
}

=head2 data (OFFSET, LENGTH)

Extracts data from an OFFSET with specific LENGTH out of the datalibrary of the file.

Used for data nodes

=cut

#my $data=data($start,$length);
#Returns a string of the datalib, which is just a bunch of data, starting at $start with a length of $length.

sub data {
	if ($_[0] >= length $datas) {#THIS IS AN ERROR IN THE UTF FILE
		warnings::warnif("Requested data from outside of the data lib, this is an error in the file or something the parser doesn't know about.");	
		return "" ;
	}
	return substr($datas,$_[0],$_[1]);
}


=head2 UTFreadUTFrek( TREE, NODEID )

Parses a node with NODEID out of the binary TREE, then calls itself with all the childnodes and siblingnodes

=cut

#Parses a UTF node recursive:
#node
#{
#	dword sibling_offset
#	dword string_offset
#	dword flags
#	dword zero (seems to be always zero, meaning unknown)
#	dword child_offset
#	dword allocated_size
#	dword size1
#	dword size2
#	dword time1
#	dword time2
#	dword time3
#} = 44 bytes



sub UTFreadUTFrek {
	no warnings 'recursion';
	local $_;
	my $tree=shift;
	my $i=shift;
	if ($offsets{$i}++) {
		warnings::warnif("Somehow the file managed to request the same node again, this is ignored");
		return {};
	}
	if ($i > length($tree)-44) {
		warnings::warnif("Requested a node from outside of the TREE, this is an error in the file or something the parser doesn't know about.");
		return {};
	}
	tie my %data => 'Tie::InsertOrderHash';
	my ($silb, $name, $flags, $z, $childoffset, $alloc, $size, $size2, $time1, $time2, $time3) = unpack("VVVVVVVVVVV", substr($tree,$i));
	# Now we must use all the stuff here or warning will annoy us:
	($time1, $time2, $time3) = ($time1, $time2, $time3);
	$size=$size2 if ($size2 < $size);
	if ($flags & 0x10 and not $flags & 0x80) {
		$data{string($name)}=UTFreadUTFrek($tree,$childoffset);
	}
	else {
		$data{string($name)}=data($childoffset,$size);
	}
	if ($silb) {
		my $data=UTFreadUTFrek($tree,$silb);
		#print $data,"->$i-->$silb\n";
		%data=(%data,%{$data});
	}
	return \%data;

}

=head2 packString (STRING)

Saves a STRING to the stringlib and returns an offset. Tests if the string already exists.

Used for writing Nodenames (keys)

=cut

#$offset = packString($string)

#Packs a string and returns the offset.
#Also adds the string to the stringlib
sub packString {
	my $string = shift;
	if (exists $strings{$string}) {
		return $strings{$string};
	}
	else {
		$strings{$string} = length($strings);
		$strings.=$string."\0";
		return $strings{$string};
	}

}

=head2 packData (DATA)

Saves a string with DATA to the datalib and returns an offset. Tests if the data already exists.

Used for writing nodedata (values)

=cut

#$offset = packData($data)

#Packs a piece of data and returns the offset.
#Also adds the data to the datalib
sub packData {
	my $data = shift;
	if (exists $datas{$data}) {
		return $datas{$data};
	}
	else {
		$datas{$data} = length($datas);
		#$datas.=$data."\0";
		$datas.=$data;
		return $datas{$data};
	}

}

#Writes UTF nodes recursive.

=head2 UTFwriteUTFrek (DATA, NAME, SIBLING)

Writes hashref or a scalar into the tree.

SIBLING is true if there is a next sibling node (different output on nodes without a next one)

Calls itself again for each entry of a hashref. (Writes the children)

=cut

sub UTFwriteUTFrek {
	no warnings 'recursion';
	local $_;
	my $tree=shift;
	my $name=shift;
	my $silb=shift;
	$pointer+=44;
	my $start=$pointer;
	croak "Can't pack other then scalar or Hashrefs" if ref $tree and ref $tree ne "HASH";
	return pack ("VVVVVVVVVVV",$silb?$pointer:0, packString($name), 0x80, 0, packData($tree), length($tree), length($tree), length($tree), 0, 0, 0) unless ref $tree;
	my $code="";
	my @list = keys(%$tree);
	#print "name = $name, pointer = $pointer, data = ".(ref ($tree) || "scalar")."\n";
	foreach (0 .. $#list) {
		$code.=UTFwriteUTFrek($tree->{$list[$_]},$list[$_],($_!=$#list));
	}
	#print "name = $name, pointer = $pointer, data = ".(ref ($tree) || "scalar")."\n";
	return pack ("VVVVVVVVVVV",$silb?$pointer:0, packString($name), 0x10, 0, $start, 0,0,0,0,0,0).$code;
}


#header
#{
#	dword "UTF "
#	dword 0x101
#	dword tree_segment_offset
#	dword size_of_tree_segment
#	dword header_offset? (0) ##I think its here also a First element of the treeoffset
#	dword size_of_header (44) ##I think it is more a size of entry
#	dword string_segment_offset
#	dword space_allocated_for_string_segment
#	dword size_of_string_segment_actually_used
#	dword data_segment_offset
#	dword unknown (seems to be zero most of the times) #Possible first entry of data segment (after deletion of an entry)
#} = 44 bytes

#Reads the UTF header, extracts data and string libraries and starts parsing the nodes

=head2 UTFreadUTF ( DATA )

Extracts and parses an UTF header from the scalar DATA.

Splits the file in TREE, STRINGLIB and DATALIB according to the header and then calls UTFreadUTFrek on the TREE.

=cut

sub UTFreadUTF{
	my $code=shift;
	my $i=0;
	%offsets = ();
	if (substr($code,$i,4) eq "UTF ") {
		$i+=4;
		my ($ver,$treeoffset,$treesize,$treefirst,$treeelemsize,$stringoffset,$stringspace,$stringsize,$dataoffset,$datafirst)=unpack("VVVVVVVVVV",get($code,$i,40));
		# We don't use those now, not sure what they are for anyway
		$datafirst = 0 unless $datafirst;
		$treefirst = 0 unless $treefirst;
		$treeelemsize = 0 unless $treeelemsize;
		# We don't need this one either, do we?
		$stringsize = 0 unless $stringsize;
		# Splitting the parts
		$strings=substr($code,$stringoffset,$stringspace);
		$datas=substr($code,$dataoffset);
		my $tree=substr($code,$treeoffset,$treesize);
		return UTFreadUTFrek($tree,0);
	}
	else {
		croak "NOT a UTF File";
	}
	
}

#Writes an UTF file with header and nodes.

=head2 UTFwriteUTF (TREE(HASHREF) )

Calls UTFwriteUTFrek and then return the header, TREE, STRINGLIB and DATALIB 

=cut 

sub UTFwriteUTF{
	my $tree=shift;
	my $i=0;
	$strings="";
	$datas="";
	my $code = "";
	%strings = ();
	%datas = ();
	$pointer=0;
	my @list = keys(%$tree);
	foreach (0 .. $#list) {
		$code.=UTFwriteUTFrek($tree->{$list[$_]},$list[$_],($_!=$#list));
	}
	my $string=$strings;
	$string.="\0" for(length($strings) .. (int(length($strings)/32)+1)*32); #Just some fun stuff.
	return "UTF ".pack("VVVVVVVVVV",0x101,44+12,length($code),0,44,44+12+length($code),length($string),length($strings),44+12+length($code)+length($string),0)."000000000000".$code.$string.$datas;
	
}

1;

__END__

=head1 Example tree

This is an example of deparsed tree of a very basic model (.cmp) a friend of mine made, there are however other types of UTF files.

Every UTF file seems to have a root node called \.

	$tree = {
	    '\\' => {
	        'VMeshLibrary' => {
	            'jc_defender.lod0.vms' => { #Contains the model data
	                'VMeshData' => 'Some Vmeshdata' #Removed by me because you can't see anything useful here and its large.
	            }
	        },
	        'Cmpnd' => {
	            'Root' => {
	                'File name' => 'jc_defender.3db ', #Links the frist model
	                'Index' => '        ', #Index 0
	                'Object name' => 'Root ' #Name of that model.
	            }
	        },
	        'jc_defender.3db' => { #A model, a file can have multiple .3db (model) files in them
	            'Hardpoints' => { #The game lets you mount things on this Points
	                'Fixed' => { #Not rotatebale
	                    'HpEngine01' => {
	                        #These are just packed vectors, can be easily decoded using unpack("f*",this)
	                        'Orientation' => '  €?              €?              €?',
	                        'Position' => '    IK¿×A' #also a vector: unpack("f*",this)
	                    },
	                }
	                'Revolute' => { #For weapons mostly, follow the cursor.
	                    'HpWeapon01' => {
	                        'Axis' => '      €?    ', #also a vector: unpack("f*",this)
	                        'Max' => '’†>    ', #an angle in radians: unpack("f*",this)
	                        'Min' => '’†¾    ',
	                        'Orientation' => 'Z|¿âÐ1¾   €âÐ1>Z|¿           €  €?', #also a vector: unpack("f*",this)
	                        'Position' => '­L€?Œø®>¿+±À' #also a vector: unpack("f*",this)
	                    },
	                    'HpWeapon02' => {
	                        'Axis' => '      €?    ',
	                        'Max' => '’†>    ',
	                        'Min' => '’†¾    ',
	                        'Orientation' => 'Z|¿âÐ1>    âÐ1¾Z|¿              €?', 
	                        'Position' => 'r¿Œø®>¿+±À'
	                    }
	                }
	            },
	            'MultiLevel' => {
	                'Level0' => {
	                    'VMeshPart' => {
	                        #This contains a reference to the VMeshdata up there
	                        'VMeshRef' => '<   Úý  x  n   ¯Ë@ÄËÀ“°š?d÷¤¿-¬Aï7Á `Ž:m$½€ð¢½ä,A'
	                    }
	                }
	            }
	        }
	    }
	};

I cut out the VMesh part which is just binary data, but it can be read using L<Games::Freelancer::VMesh>

=head1 SEE ALSO

L<Games::Freelancer::VMesh> for in UTF files included VMeshData and VMeshRef values.

L<Games::Freelancer::BINI> for another type of file used by Freelancer.

=head1 LICENSE

UTF.pm is published under the terms of the MIT license, which basically 
means "Do with it whatever you want". For more information, see the license.txt
file that should be enclosed with this distribution. A copy of the license
is (at the time of this writing) also available at
L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Marc "Maluku" Sebastian Lucksch
perl@marc-s.de

=cut

