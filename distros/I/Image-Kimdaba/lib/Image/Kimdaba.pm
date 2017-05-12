# Copyright 2005 Jean-Michel Fayard jmfayard_at_gmail.com
# Put into the public domain.
#

package Image::Kimdaba; 
use strict;
use warnings;
use XML::Parser;
use Carp;

=head1 NAME

Image::Kimdaba - Parser for the KDE Image Database

See here : http://ktown.kde.org/kimdaba

=head1 SYNOPSIS 

	use Image::Kimdaba;
	use English qw( -no_match_vars ) ;
	
	my @ListOfPictures;
	
	my $folder=getRootFolder();
	parseDB( "$folder" );
	
	print "Your actual Kimdaba settings are :\n";
	while( my ($attr, $value) = each %kimdabaconfig)
	{
	    print "\t$attr => $value\n";
	}
	print "\n";
	
	my $nb1= scalar keys %imageattributes;
	my $nb2= scalar keys %imageoptions;
	print "Following options were present in your $nb1 pictures :\n";
	while( my ($option,$r_values) = each %alloptions )
	{
	    my $nb = scalar @$r_values;
	    print "\t$nb $option\n";
	}
	print "\n";
	
	local $, = "\n" ; # print bla,bla prints "bla\nbla"
	
	print "\n\n== NO Keywords  (ten first) ==\n";
	@ListOfPictures=matchAnyOption( "Keywords" => [] );
	print sort(@ListOfPictures[0..9]);
	
	print "\n\n== Holiday  ==\n";
	@ListOfPictures=matchAnyOption( "Keywords" => [ "holiday" ] );
	print sort(@ListOfPictures);
	
	print "\n\n== ANNE HELENE ==\n";
	@ListOfPictures=matchAnyOption( "Persons" => [ "Anne Helene" ] );
	print sort(@ListOfPictures);
	
	print "\n\n== ANY OF (JESPER, ANNE HELEN) ==\n";

	@ListOfPictures=matchAnyOption( "Persons" => [ "Jesper" , "Anne Helene" ] );
	print sort(@ListOfPictures);
	
	print "\n\n== ALL OF (JESPER, ANNE HELEN) ==\n";
	@ListOfPictures=matchAllOptions( "Persons" => [ "Jesper" , "Anne Helene" ] );
	print sort(@ListOfPictures);
	
	print "\n\n== PERSONS=Jesper, Locations=Mallorca ==\n";
	@ListOfPictures=matchAllOptions( 
		"Persons" => [ "Jesper" ],
		"Locations" => [ "Mallorca" ]
		);
	print sort(@ListOfPictures);
	
	
	
	$, = "" ; # print bla,bla prints "blabla"
	
	print "\n\n==Print all infos known about specific pictures\n";
	print "\n\n== Drag&Drop pictures from Kimdaba  ==\n";
	@ListOfPictures=letMeDraganddropPictures();
	printImage( $_ ) foreach @ListOfPictures;
	

=head1 DESCRIPTION

From the website : http://ktown.kde.org/kimdaba

KimDaBa or KDE Image Database is a tool which you can use to easily sort your
images. It provides many functionnalities to sort them and find them easily. 

=head2 Datastructures

The infos available in the database are directly translated in following perl datastructures.
(See the index.xml file to see how it looks like)
 
note :  the reading of man perllol is highly recommended

=head3 C<%imageattributes>	

HASH OF (url of the picture, REF. HASH OF (attribute, value) )

Now and in the rest of the document, B<url> is given locally from the root directory,
 such as "Folder1/Subfolder/img001.jpg",
it's neither file:/home/user/Images/Folder1/Subfolder1/img001.jpg nor http://www.google.com/images/logo.gif

An B<HASH> corresponding to this B<url> could be 

	(
	monthFrom=>"1",
	dayFrom=>"18",
	hourFrom=>"19",
	yearTo=>"0",
	monthTo=>"0",
	md5sum=>"7f120e3cfb698ce0d7bb6e4e454c1a8b",
	minuteFrom=>"29",
	file=>"2005-01-09-Gif/img_0290.jpg",
	label=>"img_0290",
	angle=>"0",
	dayTo=>"0",
	secondFrom=>"46",
	yearFrom=>"2005",
	description=>""
 	)

=head3 C<%imageoptions>

HASH of (url, REF. HASH OF (optoin, REF. LIST OF value) )

C<url> is given locally from the root directory, such as "Folder1/Subfolder/img001.jpg"

An C<HASH> corresponding to this C<url> could be 

	(
 	Keywords => 	[ "holiday"	],
	Locations =>	[ "Mallorca"	],
	Persons =>	[ "Anne Helene", "Jesper" ]
	)

=head3 C<%alloptions>

HASH of (option, REF. LIST of values)

Could be something like :

 	(
	Keywords =>	[ "beers", "holiday", "new wave", "silo falls over", "Anne Helene's 30 years birthday" ]m
	Locations =>	...,
	Persons	=>	...,
	OtherCategory => ...
	)

=head3 C<%membergroups>

membergroups are called categories depending on your version of Kimdaba.

HASH : (Locations => REF (HASH : USA => [ Chicago, Los Angeles ] ) )

Beware, you can have loops between membergroups.

=head3 C<%kimdabaconfig>

HASH of (attributes, values) 

Fast all KimDaBa settings are stored in the index.xml file, as attribute of the "KimDaBA/config" XML element.
So using this hash you can access many of the user preferences, for example it could be something like :

	( 
	viewSortTye=>>"0",
	passwd=>"",
	ensureImageWindowsOnScreen=>"1",
	viewerCacheSize=>"25",
	albumCategory=>"",
	showDrawings=>"1",
	htmlBaseURL=>"file:///home2/jmfayard/public_html",
	previewSize=>"256",
	thumbSize=>"64",
	displayLabels=>"1",
	launchViewerFullScreen=>"0",
	windowWidth-0=>"800",
	autoShowThumbnailView=>"0",
	showInfoBox=>"1",
	windowWidth-1=>"800",
	slideShowWidth_1280=>"600",
	viewerHeight_1280=>"450",
	fromDate=>"2005-01-01",
	htmlDestURL=>"file:///home2/jmfayard/public_html",
	trustTimeStamps=>"0",
	windowHeight-0=>"600",
	thumbNailBackgroundColor=>"#000000",
	windowHeight-1=>"600",
	slideShowInterval=>"5",
	toDate=>"2006-01-01",
	exclude=>"1",
	infoBoxPosition=>"6",
	locked=>"0",
	showDate=>"1",
	imageDirectory=>"/tmp/kimdaba-demo-jmfayard",
	searchForImagesOnStartup=>"1",
	autoSave=>"5",
	version=>"1",
	viewerWidth_1280=>"600",
	launchSlideShowFullScreen=>"0",
	showDescription=>"1",
	maxImages=>"100",
	useEXIFComments=>"1",
	useEXIFRotate=>"1",
	showTime=>"1",
	htmlBaseDir=>"/home2/jmfayard/public_html",
	slideShowHeight_1280=>"450",
	)



=head2 Fonctions

=cut

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION     = 0.5;
    @ISA         = qw(Exporter);
    @EXPORT      = qw(	%alloptions 	%kimdabaconfig	    	%membergroups
			%imageoptions	%imageattributes
			&printImage 		&getRootFolder		&parseDB 		
			&matchAllOptions    	&matchAnyOption		&letMeDraganddropPictures
			&askForPictures		
			&makeKimFile	    );
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
#@EXPORT_OK   = qw(%imageoptions %imageattributes);
}
our @EXPORT_OK;

# exported package globals go here
our %imageattributes;
our %imageoptions;
our %alloptions;
our %kimdabaconfig;
our %membergroups;

# non-exported package globals go here

# initialize package globals, first exported ones
%imageattributes=();
%imageoptions=();
%alloptions=();
%kimdabaconfig=();
%membergroups=();

# then the others (which are still accessible as $Some::Module::stuff)

# all file-scoped lexicals must be created before
# the functions below that use them.

# file-private lexicals go here
my $option="" ;
my $image="";	    # image element that we currently handle
my $optionname="";	    # currently handle option with name $option for image $image
my @values=();	    # currently found values
my %alloptionshashed;
my $folder;	    # I need it for askForPictures



=head3 C<&letMeDraganddropPictures()>

	print "\n\n== Drag&Drop pictures from Kimdaba  ==\n";
	@ListOfPictures = &letMeDraganddropPictures();

Wait until the user drag and drop pictures from Kimdaba and Konqueror
and return a list of url.

=cut

sub letMeDraganddropPictures
{
    my @res=();
    my $line=<STDIN>;
    chomp $line;
    # for pictures having a "'" in their filename
    $line=~s#'\\''#\\#g;
    my @a = ( $line =~ m/'[^']+'/g );
    
    my $folder2 = $kimdabaconfig{"imageDirectory"}; 
    foreach (@a) 
    {	# Change '/autre/Photos/USA/2004-08-09_Monument_Valley/Monument_Valley_05.JPG'
	# in			USA/2004-08-09_Monument_Valley/Monument_Valley_05.JPG
	s#$folder##;
	s#$folder2##;		# in case where $folder="." or similar
	s#(file:)?/+##;
	s#^'## ; 
	s#'$## ; 
	s#\\#'#g; 
	push @res, $_;
    }

# Now check which urls are really correct :
    @res	=grep {  exists $imageoptions{$_} } @res;
    return @res;
}


##########

=head3 C<< &matchAllOptions(HASH of (option => REF List of values)) >>

Returns a list of urls. See the example in the synopsis.

=head3 C<< &matchAnyOption(HASH of (option => REF List of values)) >>

Returns a list of urls. See the example in the synopsis.

=cut

sub matchAllOptions
{
    return @{ matchOptions( 1, @_) };
}
sub matchAnyOption
{
    return @{ matchOptions( 0, @_) };
}

sub matchOptions
{
    my ($matchall, %request)=@_;
    my @urlsfound=();
    my @checkoptions=keys %request;
URL:    for my $url (keys %imageattributes) 
    {
	my %options = ();
	%options= %{ $imageoptions{$url} } if (exists $imageoptions{$url} );
OPTION:	for my $option ( @checkoptions )		     
	{
	    unless (exists $options{$option} ) {
		if ( scalar @{ $request{$option} } == 0 ) {
		    next OPTION;
		} else {
		    next URL;
		}
	    }
			

	    my @values_image   =@{ $options{$option} };		    # (Anne Helen)
	    my @values_searched=@{ $request{$option} };		    # (Jesper, Anne Helen)
	    for my $req (@values_searched)		    
	    {
		my $res = scalar grep { $_ eq $req } @values_image;
		if ( ($res == 0) && ($matchall) ) {
		    next URL;
		} elsif ( ($res!=0) && (!$matchall) ) {		    # if trouvé, here
		    next OPTION;
		}
	    }
		
	    # If we went this far, this means that we...
	    if ($matchall) {
		next OPTION; # ... found a value corresponding to each of the options
	    } else {
		next URL;    # ... never found a value corresponding to one of the options
	    }
	}
	push @urlsfound, $url;
	
    }
    return [ @urlsfound ];	
}

=head3 C<&getRootFolder()>

	my $folder=getRootFolder();
	parseDB( "$folder" );

Returns the absolute path of the root directory.
You should run the demo, keep the files, and use /tmp/kimdaba-demo-$USER
when you are experimenting.
Thanks to this function, the root directory can 
- passed as first argument on the command line ($ kim_script /tmp/kimdaba-demo-$USER )
- or will be asked to the user

=head3 C<&parseDB( $folder )>

Readonly access to most information available in the index.xml file.
To modify a database, see B<&makeKimFile()>

=cut

sub getRootFolder
{
    no warnings;
    ($folder) = grep { -d } @main::ARGV;
    $folder = "~/Images"    unless (-d $folder );
    $folder = $ENV{PWD}	    unless (-d $folder );
    until ( (-d "$folder") && (-r "$folder/index.xml") )
    {
        print "In which folder are your pictures stored ?\n";
        chomp( $folder=<STDIN>);
    }
    return $folder;
}

=head3 C<&printImage( url )>

	printImage( $url );

Interesting to debug. Its code also shows how to access the hashes %imageattributes and %imageoptions :

	sub printImage {
	    my ($file)= @_;
	
	    print "=== $file ===\n" ;
	    print "Attributes : ";
	    my %attributes = %{ $imageattributes{$file} } ;
	    while( my ($attr, $value) = each( %attributes ) )
	    {
		print " $attr=>$value ; ";
	    }
	    print "\n";
		
	    my %options = %{ $imageoptions{$file} };
	    print "Options: \n" ;
	    while( my ($key, $r_values) = each( %options ) )
	    {
		print "\t$key ==> ", join('; ', @$r_values ) , "\n";
	    }
	    print "\n";
	}

=cut

sub printImage {
    my ($file)= @_;

    print "=== $file ===\n" ;
    print "Attributes : ";
    my %attributes = %{ $imageattributes{$file} } ;
    while( my ($attr, $value) = each( %attributes ) )
#    for my $attr ( keys %{ $imageattributes{$file} } )
    {
	print " $attr=>$value ; ";
    }
    print "\n";
	
    my %options = %{ $imageoptions{$file} };
    print "Options: \n" ;
#    for my $key ( sort keys %options ) 
    while( my ($key, $r_values) = each( %options ) )
    {
	print "\t$key ==> ", join('; ', @$r_values ) , "\n";
    }
    print "\n";
}




##### <Parsing of the database goes here> ######
sub parseDB ($)  
{
    my ($folder)=@_;
    my $p1 = new XML::Parser(
	Style => 'Subs'
    );
    croak "Can not find KimDaBa's database"
	unless (-r "$folder/index.xml");
    $p1->parsefile( "$folder/index.xml");
}
sub member {
    my ( $p, $el, %attrs ) = @_ ;
    my ($groupname,$member) = 
	( $attrs{"group-name"}, $attrs{"member"} );
    # index.xml format has changed at Fri Dec 3
    my $category=$attrs{"option-group"} if ( exists $attrs{"option-group"}  );
    $category=$attrs{"category"} if ( exists $attrs{"category"}  );
	
    if (! exists( $membergroups{$category} ) ) {
	$membergroups{$category} = {
	    $groupname => [ $member ]
	};
	    
    } elsif (! exists( $membergroups{$category}{$groupname} ) ) {
	$membergroups{$category}{$groupname} =  [ $member ]  ;
    } else {
	my $r_list =  $membergroups{$category}{$groupname};
	push @$r_list, $member;
    }
}

sub config {
    my ( $p, $el, %attrs ) = @_ ;
    %kimdabaconfig=%attrs;
}
sub image {
    my ( $p, $el, %attrs ) = @_ ;
    $image = $attrs{"file"} ;
    $imageattributes{$image} = \%attrs;
}
sub image_ {
    my ( $p, $el ) = @_;
    $image = "";
}
	
sub options {
    my ( $p, $el, %attrs ) = @_ ;
    return  if ($image eq "") ;	# We are in KimDaBa>config>SearchInfo>Options>Option
				# or in KimDaBa>Options
    $imageoptions{$image} = {} ;
}    
sub option {
    my ( $p, $el, %attrs ) = @_ ;
    return  if ($image eq "") ;	# We are in KimDaBa>config>SearchInfo>Options>Option
				# or in KimDaBa>Options
    $optionname=$attrs{"name"};	
    @values=();
}
sub option_ {
    my ( $p, $el ) = @_;
    if ($image eq "") {
	$optionname="";
	return;
    }
    $imageoptions{$image}->{$optionname} = [ @values ];
    $alloptionshashed{$optionname} = {} 
	unless( exists $alloptionshashed{$optionname} );
    for my $value (@values) {
	$alloptionshashed{$optionname}{$value}=1;
    }
    $optionname="";
}

sub value {
    my ( $p, $el, %attrs ) = @_ ;
    return if ( $optionname eq "" ) ;
    push @values, $attrs{"value"};
}
sub KimDaBa_ {
# %alloptionshashed is hash of hash for efficiency reasons, but we want to return
# a more clean hash of list.
    my $nb= scalar %alloptionshashed;
    for (keys %alloptionshashed) {
	$alloptions{ $_ } = [ keys %{ $alloptionshashed{$_} } ];
    }
}
##### <Parsing of the database ends here> ######




=head3 C<&makeKimFile( $destdir, $name, @list )>

Instead of modifying directly the database (which could easily be dangerous
for your data), you write a kimdaba export file (*.kim)
then you use the import fonction in kimdaba (no dangerous, you are in control)

A .kim file is a zip archive containning an index.xml file, and
a Thumbnail directory. You just have to create the index.xml file 
(say in '/tmp') then you call :

  C<makeKimFile( "/tmp", "perl_output.kim", @ListOfPictures );>

where 

	/tmp/index.xml 		is the file created by you
	/tmp/perl_output.kim	is the resulting kimdaba import ile
	@ListOfPictures		is a list of urls present in /tmp/index.xml

Not that the KimDaBa import feature has some limitations.

Example :

	use Image::Kimdaba;
	
	my @ListOfPictures;
	
	my $folder=getRootFolder();
	parseDB( "$folder" );
	
	print "\n\n== Drag&Drop pictures from Kimdaba  ==\n";
	@ListOfPictures=letMeDraganddropPictures();
	print join("\n", sort(@ListOfPictures));
	print "--\n";
	
	my $destdir="/tmp";
	open( EXPORT, "> ${destdir}/index.xml");
	print EXPORT <<FIN
	<?xml version="1.0" encoding="UTF-8"?>
	<KimDaBa-export location="external" >
	FIN
	;
	
	for my $url (@ListOfPictures)
	{
	    my $description="yeah! I changed the description";
	    my $md5sum="";
	    if (
		(exists $imageattributes{$url})
		&&
		(exists $imageattributes{$url}{'md5sum'})
		&&
		(! $imageattributes{$url}{'md5sum'} eq "")
	       )
	    {
		$md5sum="md5sum=\"$imageattributes{$url}{'md5sum'}\" ";
	    }
		
	    
	    my $value="Test Add Another Keyword";
	    print EXPORT <<FIN
	 <image description="$description" $md5sum file="$url" >
	  <options>
	   <option name="Keywords" >
	    <value value="Test Add a keyword" />
	    <value value="$value" />
	   </option>
	  </options>
	 </image>
	FIN
	    ;
	}
	
	print EXPORT <<FIN
	</KimDaBa-export>
	FIN
	;
	close( EXPORT );
	
	
	makeKimFile( $destdir, "perl_export.kim", @ListOfPictures);


=cut

sub makeKimFile
{
    my ($destdir,$name,@ListOfPictures)=@_;
    system( "rm -rf   ${destdir}/Thumbnails" );
    system( "mkdir -p ${destdir}/Thumbnails" );
    for my $url (@ListOfPictures)
    {
	next unless( -e "${folder}/${url}" );
#	( my $dest = $url) =~ s#(.*)/(.*)#\2#;
	my ($dirname,$basename) = ( $url =~ m#(.*)/(.*)# );
	my $thumb="${folder}/${dirname}/ThumbNails/"
		. "$kimdabaconfig{'thumbSize'}x$kimdabaconfig{'thumbSize'}"
		. "-$imageattributes{$url}{'angle'}"
		. "-$basename";
	if (-e $thumb) {
	    my $a=symlink $thumb, "${destdir}/Thumbnails/$basename";
	    next;
	}
	print "Creating thumbnail for $url...\n";
	$url=~s/'/'\\''/g;
	$basename=~s/'/'\\''/g;
	system(
"convert -size 128x128 '$folder/$url' -resize 128x128  '${destdir}/Thumbnails/$basename'"
);
    }
    chdir $destdir or croak "$!";
    unlink $name;
    system( "zip", "-r", $name, "index.xml", "Thumbnails" );
    print "KimDaBa export file created : ${destdir}/${name}\n";
}


1;  # don't forget to return a true value from the file




# Desactived for now, because it's rather pointless and adds a dependcy on Term::Readline

##sub askForPictures
##{
##    my @res;
##    print <<EOF
##Now specify a list of urls of pictures that this script will handle.
##You can write any perl code. Then Ctrl-D when you are done.
##Common examples:
##    # simple list
##    \@res=( "img004.jpg" , "img006.jpg" , "img010.jpg" );
##    # pictures not on disk
##    \@res=grep { ! -e "$folder/\$_" } keys \%imageoptions;
##    # pictures rotated in Kimdaba but not in the real life
##    @res=grep {  $imageattributes{$_}{"angle"}!=0 } keys %imageattributes;
##    # kimdaba's queries
##    \@res=matchAllOptions( "Persons" => [ "Jesper" , "Anne Helene" ] );
##    \@res=matchAllOptions( "Persons" => [ "Jesper" ], "Locations" => [ "Mallorca" ]);
##    \@res=matchAnyOption( "Keywords" => [ "ForMyScript" ] );
##
##EOF
##;
##  use Term::ReadLine;
##  my $term = new Term::ReadLine 'Kimdaba Query';
##  my $prompt = "Kim> ";
##  my $OUT = $term->OUT || \*STDOUT;
##    
##  while(1)
##  {
##      while ( defined (my $perlcode = $term->readline($prompt)) ) {
##	  my $res = eval ($perlcode);
##	  warn $@ if $@;
##	  print $OUT $res, "\n" unless $@;
##	  $term->addhistory($_) if /\S/;
##      }
##
### Now check which urls are really correct :
##    @res=grep { exists $imageoptions{$_} } @res;
##    print "Following pictures were found\n";
##    print join("\n",@res),"\n\n";
##    print "Continue with those picutres? [yes]/no : ";
##    $_=<STDIN>;
##    /no/ or last;
##    }
##    return @res;
##}

=head1 BUGS/CAVEATS/etc 

A lot ;-)

=head1 AUTHOR 

Jean-Michel Fayard ; jmfayard{at}moufrei.de

=head1 SEE ALSO 

B<perllol>
