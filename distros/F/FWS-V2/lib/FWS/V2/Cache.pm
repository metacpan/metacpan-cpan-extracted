package FWS::V2::Cache;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Cache - Framework Sites version 2 data caching

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

	use FWS::V2;
	
	my $fws = FWS::V2->new();


	my $cacheData = $fws->cacheValue( 'someData' ) || &{ sub {
	    my $value = 'This is a testineeg!';
	    #
	    # do something...
	    #
	    return $fws->saveCache( key => 'someData', expire => 1, value => $value );
	} };

	print $cacheData;
	
	$fws->deleteCache( key => 'someData' );
	
    $fws->flushCache();


=head1 DESCRIPTION

FWS version 2 cache methods are used as a portable non-environment specific cache library to the FWS data model. For maximum compatibility it uses the file FWSCache directory under the sites fileSecurePath directory to store its data and is compatible with NFS or other distributed file systems.

=head1 METHODS

=head2 saveCache

Save data to cache passing they key, value and expire (in minutes).  The return will be the string passed as value.

    #
    # Save my data to cache and hang on to it for 5 minutes before getting a new a new one
	# but return the current one if my 5 minutes isn't up
    #
    $someValue	= $fws->saveCache( key => 'someData', value => $someValue, expire => 5 );

=cut

sub saveCache {
    my ( $self, %paramHash ) = @_;

	#
	# set default expire if not passed
	#
	$paramHash{expire} ||= 60;

    #
    # make the dir for the cache
    #
	my $cacheDir = $self->{fileSecurePath} . "/cache/" . $self->safeFile( $paramHash{key} ) ;
    $self->makeDir( $cacheDir );

	#
	# set cache file based on expire date
	#
	my $newFile = $cacheDir . '/' . ( time() + ( $paramHash{expire} * 60 ) );
	
	#
	# set the file name as the exp epoch with its content
	#
	my $expireEpoch = ( time() + ( $paramHash{expire} * 60 ) );
    open ( my $CFILE, ">", $newFile );
	print $CFILE $expireEpoch."\n";
    print $CFILE $paramHash{value};
	close $CFILE;
	
	#
	# Move it to the live value, or if we have something nasty from file locking happen
	# what ever is there will be good in those rare cases
	#
    rename $newFile, $cacheDir.'/value';

	#
	# return what we were givin
	#
	return $paramHash{value};
}


=head2 deleteCache

Remove a key from cache.   For optmization, this does not look up the key, only blindly remove it.

    #
    # We no longer need somData lets get rid of it
    #
    $fws->deleteCache( key => 'someData' );

=cut

sub deleteCache {
    my ( $self, %paramHash ) = @_;
	
	my $cacheDir = $self->{fileSecurePath} . "/cache/" . $self->safeFile( $paramHash{key} );

	my @fileArray = @{$self->fileArray( directory => $cacheDir ) };
    for my $i (0 .. $#fileArray) { unlink $fileArray[$i]{fullFile} }

	rmdir $cacheDir;

	return;
}


=head2 flushCache

If anything is in cache currently, after this call it won't be!

    #
    # Remove all cache keys
    #
    $fws->flushCache();

=cut

sub flushCache {
    my ( $self ) = @_;

	my $cacheDir = $self->{fileSecurePath} . "/cache" ;

    #
    # pull the directory into an array
    #
    opendir( DIR, $cacheDir );
    my @getDir = grep(!/^\.\.?$/,readdir( DIR ));
    closedir( DIR );

	#
	# eat each cache in the dir
	#
    foreach my $dirFile (@getDir) { if (-d $cacheDir.'/'.$dirFile) { $self->deleteCache( key => $dirFile ) } }

    $self->runScript( 'postFlushCache' );
    
    $self->FWSLog( 'Cache Flushed' );
	
	return;
}


=head2 flushWebCache

Removes all files located in your web cache.  These are the files that are your combined js, and css files created on the fly when pages are rendered.    When pages are loaded after this is ran, it will start to repopulate the cache with newly created web cache files.

    #
    # Remove all web cache files
    #
    $fws->flushWebCache();

=cut

sub flushWebCache {
    my ( $self ) = @_;

    my @fileArray = @{$self->fileArray( directory => $self->{filePath} . '/fws/cache' )};
    for my $i ( 0 .. $#fileArray ) { unlink $fileArray[$i]{fullFile} }

    $self->runScript( 'postFlushWebCache' );
    
    $self->FWSLog( 'Web Cache Flushed' );

    return;
}


=head2 cacheValue

Return the cache value.   If the cache value does not exist, it will return blank in same way that formValue, siteValue and userValue.

    #
    # will return the cache value.   This or a blank string if it is not set, or blank
    #
    print $fws->caheValue( 'someData' );

=cut

sub cacheValue {
    my ( $self, $key ) = @_;

	#
    # set cache file based on expire date
    # set the value to blank to start
    #
	my $cacheDir    = $self->{fileSecurePath} . "/cache/" . $self->safeFile( $key );
    my $newFile     = $cacheDir . '/value';
	my $value;

	#
	# if the cache file does not exist then return the blank
	#
	if ( !-e $newFile ) { return $value }

	#
	# open the file and get the first line
	#
    open ( my $VFILE, "<", $newFile );
    chomp ( my $timeStamp = <$VFILE> );

	#
	# if we are still within timestamp lets return it
	#
	if ( $timeStamp > time() ) { while ( <$VFILE> ) { $value .= $_ } }
	
	#
	# Return the value and close the file
	#
    close $VFILE;
    return $value;
}


=head2 setPageCache

Used internally to craete combined head css and js cached files so they can be used on the page.

=cut

sub setPageCache {
    my ( $self, %paramHash ) = @_;

    use Digest::MD5  qw(md5_hex);

    #
    # PH for settables
    #
    my $pageHead;
    my $pageFoot;
    my $cacheFileName = $self->{siteId} . '-';

    #
    # make it unique depending on flags passed
    #
    if ( $paramHash{jqueryOnly} ) { $cacheFileName .= 'jqueryOnly-' }

    #
    # figure out what the js/css name is
    #
    if ( $self->{tinyMCEEnable} ) { $cacheFileName .= $self->{tinyMCEPath} . '-' }

    #
    # add the jquery
    #
    my %jqueryHash = %{$self->{_jqueryHash}};
    foreach my $jqueryLibrary ( sort {$jqueryHash{$a} <=> $jqueryHash{$b} } keys %jqueryHash ) {
        $cacheFileName .= $jqueryLibrary . '-';
    }

    #
    # load js from elements and pages
    #
    my %jsHash = %{$self->{_jsHash}};
    foreach my $jsFile ( sort {$jsHash{$a} <=> $jsHash{$b} } keys %jsHash ) {
        $jsFile =~ s/\//-/sg;
        $cacheFileName .= $jsFile . '-';
    }

    #
    # load js from elements and pages
    #
    my %cssHash = %{$self->{_cssHash}};
    foreach my $cssFile ( sort {$cssHash{$a} <=> $cssHash{$b} } keys %cssHash ) {
        $cssFile =~ s/\//-/sg;
        $cacheFileName .= $cssFile . '-';
    }

    #
    # turn it into a unique short file
    #
    my $fileName    = md5_hex( $cacheFileName );
    my $cacheFile   = $self->{filePath} . "/fws/cache/" . $fileName;
    my $cacheWeb    = $self->{fileFWSPath} . "/cache/" . $fileName;

    if ( $cacheFileName ) {
        if ( !-e $cacheFile . ".js" ) {

            #
            # make the dir if it doesn't exist
            #
            $self->makeDir( $self->{filePath} . "/fws/cache" );

            #
            # open files to print to
            #
            open ( my $CSS, ">", $cacheFile . ".css" )  || $self->FWSLog( "Could not write to file: " . $cacheFile . ".css" );
            open ( my $JS, ">", $cacheFile . ".js" )    || $self->FWSLog( "Could not write to file: " . $cacheFile . ".js" );

            print $JS "// FWS Generated JS Cache File - " .     $self->formatDate( format => "dateTime" ) . "\n";
            print $CSS "/* FWS Generated CSS Cache File - " .   $self->formatDate( format => "dateTime" ) . " */\n";

            #
            # if jquery is used or tiny mce we need these
            #
            if ( keys %jqueryHash || $self->{tinyMCEEnable} ) {
                print $JS "var scriptName = \"" .   $self->{scriptName}   . "\";\n";
                print $JS "var siteId = \"" .       $self->{siteId}       . "\";\n";
                print $JS "var secureDomain = \"" . $self->{secureDomain} . "\";\n";
                print $JS "var globalFiles = \"" .  $self->{fileFWSPath}  . "\";\n";
                print $JS "var domain = \"" .       $self->{domain}       . "\";\n";

                my $fwsJS = $self->{filePath} . "/fws/fws-" . $self->{FWSVersion} . ".min.js";
                if ( -e $fwsJS ) {
                    open ( my $FILE, "<", $fwsJS ) || $self->FWSLog( "Could not read file: " . $fwsJS );
                    print $JS "\n\n// fws-" . $self->{FWSVersion} . ".min.js\n\n";
                    while ( my $line = <$FILE> ) { print $JS $line }
                    close $FILE;
                }

                my $fwsCSS = $self->{filePath} . "/fws/fws-" . $self->{FWSVersion} . ".css";
                if ( -e $fwsCSS ) {
                    open ( my $FILE, "<", $fwsCSS ) || $self->FWSLog( "Could not read file:  " .  $fwsCSS );
                    print $CSS "\n\n/* fws-" . $self->{FWSVersion} . ".css */\n\n";
                    while ( my $line = <$FILE> ) { print $CSS $line }
                    close $FILE;
                }
            }

            if ( $self->{bootstrapEnable} ) {
                my $bootstrapCSS = $self->{filePath} . "/fws/bootstrap-2.3.2/css/bootstrap.min.css";
                if ( -e $bootstrapCSS ) {
                    open ( my $FILE, "<", $bootstrapCSS ) || $self->FWSLog( "Could not read file:  " .  $bootstrapCSS );
                    print $CSS "\n\n/* boostrap.min.css */\n\n";
                    while ( my $line = <$FILE> ) { print $CSS $line }
                    close $FILE;
                }
            }


            #
            # add tiny mce.  lets do it first because it seems that if it loads after jquery dialog you might be able to dialog before you can render edit tools
            #
            if ( $self->{tinyMCEEnable} && !$paramHash{jqueryOnly} ) {
                print $JS $self->tinyMCEHead();

                my $tinyMCEInit = $self->{filePath} . "/fws/" . $self->{tinyMCEPath} . "/tiny_mce_init.js";
                if ( -e $tinyMCEInit ) {
                    open ( my $FILE, "<", $tinyMCEInit ) || $self->FWSLog( "Can not open file:" .  $tinyMCEInit );
                    print $JS "\n\n// /fws/" . $self->{tinyMCEPath} . "/tiny_mce_init.js\n\n";
                    while ( my $line = <$FILE> ) { print $JS $line }
                    close $FILE;
                }
            }

            #
            # all the jquery libraries
            #
            foreach my $jqueryLibrary (sort {$jqueryHash{$a} <=> $jqueryHash{$b} } keys %jqueryHash) {
                my $fileName = $self->{filePath} . "/fws/jquery/jquery." . $jqueryLibrary . ".min.js";
                if ( -e $fileName ) {
                    open ( my $FILE, "<", $fileName ) || $self->FWSLog( "Can not open file:" .  $fileName );
                    print $JS "\n\n// jquery." . $jqueryLibrary . ".min.js\n\n";
                    while ( my $line = <$FILE> ) { print $JS $line }
                    close $FILE;
                }

                $fileName =  $self->{filePath} . "/fws/jquery/jquery." . $jqueryLibrary . ".css";
                if ( -e $fileName ) {
                    open ( my $FILE, "<", $fileName ) || $self->FWSLog( "Can not open file:" .  $fileName );
                    print $CSS "\n\n/* jquery." . $jqueryLibrary . ".css */\n\n";
                    while ( my $line = <$FILE> ) { print $CSS $line }
                    close $FILE;
                }
            }

            #
            #
            #
            if ( !$paramHash{jqueryOnly} ) {
                #
                # load css from elements, pages and templates
                #
                my %cssHash = %{$self->{_cssHash}};
                foreach my $fileName ( sort {$cssHash{$a} <=> $cssHash{$b} } keys %cssHash ) {
                    
                    #
                    # If the full file is there, thats our favorite!
                    #
                    my $fullFileName = $self->{filePath} . "/" . $fileName . ".css";

                    # 
                    # fail over to no version name if its not there on the next version of FWS this will just only use non versioned one
                    #
                    if ( !-e $fullFileName ) {
                        $fullFileName =~ s/-[0-9\.]+.*/\.css/sg;
                    }

                    if (-e $fullFileName) {
                        open ( my $FILE, "<", $fullFileName ) || $self->FWSLog( "Can not open file:" .  $fullFileName );
                        print $CSS "\n\n/* " . $fileName . ".css */\n\n";
                        while ( my $line = <$FILE> ) { print $CSS $line }
                        close $FILE;
                    }
                }

                #
                # load js from elements and pages
                #
                my %jsHash = %{$self->{_jsHash}};
                foreach my $fileName ( sort {$jsHash{$a} <=> $jsHash{$b} } keys %jsHash ) {
                    
                    #
                    # full versioned file is our favorite, lets try that first
                    #
                    my $fullFileName = $self->{filePath} . "/" . $fileName . ".js";
                    
                    # 
                    # fail over to no version name if its not there on the next version of FWS this will just only use non versioned one
                    #
                    if ( !-e $fullFileName ) {
                        $fullFileName =~ s/-[0-9\.]+.*/\.js/sg;
                    }

                    if (-e $fullFileName) {
                        open ( my $FILE, "<", $fullFileName ) || $self->FWSLog( "Can not open file:" .  $fullFileName );
                        print $JS "\n\n// " . $fileName . ".js\n\n";
                        while ( my $line = <$FILE> ) { print $JS $line }
                        close $FILE;
                    }
                }
            }

            #
            # close up shop, we done
            #
            close $CSS;
            close $JS;
        }
        
        $pageFoot .= "<script type=\"text/javascript\" src=\"" . $cacheWeb . ".js\"></script>\n";

        if ( $self->{tinyMCEEnable}  && !$paramHash{jqueryOnly} ) {
            $pageFoot = "<script type=\"text/javascript\" src=\"" . $self->{fileFWSPath} . "/" . $self->{tinyMCEPath} . "/tiny_mce.js\"></script>\n" . $pageFoot;
        }


        #
        # if we are flaged for boostrap, add it!
        #
        if ( $self->{bootstrapEnable} ) {
            $pageFoot = "\n<script src=\"" . $self->{fileWebPath} . "/fws/bootstrap-2.3.2/js/bootstrap.min.js\"></script>\n" . $pageFoot;
        }



        if ( keys %jqueryHash && !$self->{loadJQueryInHead} ) {
            $pageFoot = "<script type=\"text/javascript\" src=\"" . $self->{fileFWSPath} . "/jquery/jquery-1.7.1.min.js\"></script>\n" . $pageFoot;
        }
            
        if ( !$paramHash{noCSS} ) { $pageHead .= "<link rel=\"stylesheet\" type=\"text/css\" href=\"" . $cacheWeb . ".css\"/>\n" }
    }


    #
    # set them to be used in templatese
    #
    $self->siteValue( 'pageHead', $pageHead .  $self->siteValue( 'pageHead' ) );
    $self->siteValue( 'pageFoot', $pageFoot .  $self->siteValue( 'pageFoot' ) );

    return $pageHead . $pageFoot;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Cache


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-V2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-V2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-V2>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-V2/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Cache
