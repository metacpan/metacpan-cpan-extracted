#!/usr/bin/perl -w

# JAlbum config :
# Tab main >>
#	Image directory : Kimdaba's root folder
# Tab advanced >> 
#	ignore pattern : ThumbNails|CategoryImages|index.xml


use strict;
use Image::Kimdaba;
use English qw( -no_match_vars ) ;

my @ListOfPictures;

my $folder=getRootFolder();
parseDB( "$folder" );

## Looks like there is no way to start JAlbum with a specified set of pictures

##@ListOfPictures=matchAnyOption( "Keywords" => [ "jalbum" ] );
##my $nb=scalar @ListOfPictures;
##
##print <<END
##This script will create comments used by the JAlbum software : http://jalbum.net/
##for the $nb pictures with the "jalbum" keyword.
##
##END
##;
##if ($nb == 0) {
##	print "$nb pictures found...\nSet the \"jalbum\" keyword first\n";
##	exit( 1 );
##}

my %dirs;
for (keys %imageattributes) {
	no warnings;
	if ( m#^(.*)/(.*)# ) {
	    push @{ $dirs{$1} }, $_;
	} else {
	    push @{ $dirs{"."} }, $_;
	}
}
while( my ($dir,$r_urls) = each %dirs ) 
{
    my $nb=0;
    chdir "$folder/$dir" ;
    open (C, "> comments.properties" ) || die "Cannot write comment file $!";	# JAlbum comment file
    print "Directory '$dir' ... ";

    for my $url (@$r_urls) {
	next unless (-r "$folder/$url" );
	next unless exists $imageattributes{$url};

#print "\t$url...\n";
	$nb++;

	(my $relativename = $url) =~ s#.*/## ;
	print C "$relativename=";

	my %attrs=%{ $imageattributes{$url} };
	my $date=print_date( %attrs );
	print C $date;

	my %options=();
	if( exists $imageoptions{$url} ) {
	    %options=%{ $imageoptions{$url} };
	}; 
	while( my ($key, $r_values) = each( %options ) )
	{
	    print C "<b>$key: </b> ", join('; ', @$r_values ) , "<br/>\\\n";
	}

	unless ( $attrs{"description"} eq "" ) {
	    my $desc = $attrs{'description'} ;
	    print C "<b>Description: </b>$desc<br/>\\\n";
	}
	print C "\n";
    }
    print " $nb pictures found > $dir/comments.properties\n";
    close( C );
}

sub print_date {
    my %attrs=@_;
    my $res;
    my $minutes;
    
    if ( ($attrs{"yearFrom"} eq "") or ($attrs{"yearFrom"} eq "1970" ) ) {
	return "";
    }
    $res = "<b>Date: </b> $attrs{'yearFrom'}-$attrs{'monthFrom'}-$attrs{'dayFrom'} ";
    
    my ($hour,$minute,$second) =( $attrs{'hourFrom'}, $attrs{'minuteFrom'}, $attrs{'secondFrom'} );
    $hour=0 if ($hour eq "");
    $minute=0 if ($minute eq "");
    $second=0 if ($second eq "");
    $minutes="$hour:$minute:$second" ;
    $res .= " $minutes " unless ($minutes eq "0:0:0" );
	
    if ( ($attrs{"yearTo"} eq "") or ($attrs{"yearTo"} eq "0" ) ) {
	$res .= "<br/>\\\n";
	return $res;
    }

    $res .= " to $attrs{'yearTo'}-$attrs{'monthTo'}-$attrs{'dayTo'} ";
    
    ($hour,$minute,$second) =( $attrs{'hourTo'}, $attrs{'minuteTo'}, $attrs{'secondTo'} );
    {
	no warnings;
	$hour=0 if ($hour eq "");
    $hour=0 if ($hour eq "");
    $minute=0 if ($minute eq "");
    $second=0 if ($second eq "");
	$minute=0 if ($minute eq "");
	$second=0 if ($second eq "");
    }
    $minutes="$hour:$minute:$second" ;
    $res .= " $minutes " unless ($minutes eq "0:0:0" );
	
    $res .= "<br/>\\\n";
    return $res;

}
