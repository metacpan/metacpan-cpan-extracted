package File::Find::ProjectCycleMigration;

use 5.008004;
use strict;
use File::Find;
use File::Path;
use File::Copy;
use File::Spec;
use Data::Dumper;
use Time::Local;

require Exporter;
 
our @ISA = qw(Exporter);
our @EXPORT = qw(FindReplace);
our $VERSION = '0.01';

sub FindReplace{
    my $config = shift;
    my ($cycle_year,$srcdir) = ($config->{year}, $config->{srcdir});
    unless(($cycle_year =~/^\d\d\d\d$/) || (-d $srcdir)){
        separator(80,'*');
        unless(($cycle_year =~/^\d\d\d\d$/))
        {
            textFormat(80, "Please enter correct year the given year must be a 4 digit numeric number.\n");
        }
        unless(-d $srcdir){
            textFormat(80,"The given path does not exist please give absolute path.");
        }
        separator(80,'*');
        die &Usage;
    }
    my $nextyear = $cycle_year + 1;

    # The directory to be search on.
    my @directories = File::Spec->splitdir($srcdir);
    my $lastpath    = pop @directories;              # Get the last directory to be search on
    $lastpath = pop @directories if $lastpath eq ''; # If the user gave a / at end of the path then we need to pop twice to skip the ''

    # Creating the absolute path for the directory to be search on.
    my $folderPath = File::Spec->catdir( @directories, $lastpath );

    # Creeating the backup directory .
    my $backupFolderPath = File::Spec->catdir( @directories, $lastpath . '_bkp' );   
    my $logFilePath = File::Spec->catdir( @directories, $lastpath . '_log' );   

    my $grepregex  = '[a-zA-Z]+' . $cycle_year . '[^a-zA-Z0-9\_\,]'; #Creating a regex for searching the pattern ie. the year (we can customized it as per the requirement)               
    my $grepoutput = `egrep -rhn '$grepregex' $folderPath`;    # egrep should be quicker than going file by file and looking for patterns in file using perl only.
    my @op = ( $grepoutput =~ /([a-zA-Z]{4,}$cycle_year)[\/\:-]/g ); # We got the patterns that look like stuff we need to replace along with stupid stuff that egrep tries to churn out.
    my %findReplaceH;
    foreach my $string (@op) {                                 # We build a hash to make things easier and removes the duplicate keys ie. search pattern.
        my $replacementstring = $string;
        $replacementstring =~ s/$cycle_year/$nextyear/;
        $findReplaceH{$string} = $replacementstring if ( $string =~ /[a-zA-Z]{4,}$cycle_year/ ); # Replace when there are at least 4 more alphanumeric char associated with year.
    }
    $findReplaceH{$cycle_year} = $nextyear;
    mkdir $logFilePath unless(-e $logFilePath);

    my $logFile = "$logFilePath/FindReplace.log";
    open( FILE, ">>$logFile" ) || die "cann't open the $!\n";
    my ( $seconds, $minutes, $hours, $day_of_month, $month, $year, $wday, $yday, $isdst ) = gmtime(time);
    $year  = $year + 1900;
    $month = $month + 1;
    my $date_string = "$hours:$minutes:$seconds - $day_of_month/$month/$year";
    print FILE "Here we are going to keep logs - TIME : $date_string\n";
    close FILE;

    my $input;
    while ((lc($input) ne 'yes' ) && ( scalar(keys%findReplaceH))) {
        separator(80,'*');
        textFormat(80, "Replacement List-");print "\n";
        textFormat(80, "Right side values are the possible replacement of Left side pattern(given year  associated with some alphanumeric characters) find in the directory and sub dir-ectory So possible replacements are-");  
        print "\n";
        while(my($key,$val)=(each %findReplaceH)){
            printf ("%35s",$key); print " => " ; printf("%-50s", $val); print "\n" ;
        }
        separator(80,'*');
        textFormat(150,  "Current Config Settings-");print "\n";
        textFormat(80, "'Current Directory' is the directory where script starts search operation for   replacement also script automatically backs up the current code in 'Back-up Dir-ectory' and for logs it creates a 'Log Directory' at one level above the 'Current Directory'");
        print "\n";
        textFormat(150, "Current Directory : $folderPath");
        textFormat(150, "Back-up Directory : $backupFolderPath");
        textFormat(150, "Log Directory \t  : $logFile");
        separator(80,'*');
        textFormat(80, "README-");
        textFormat(80,"i. If you want to proceed with above Replacement List/Current Config Settings      then type YES otherwise NO to quit ...");
        textFormat(80,"ii. If you want to remove any key => value pair from Replacement List then type    the key(Case Sensitive) on terminal. e.g. type key name (left side element)  'foo2011' to remove key-value pair from 'Replacement List'- 'foo2011 => foo2012'");
        print "\t";
        $input = <STDIN>;
        $input =~ s/^\s+|\s+$//g;

        if ( $input =~ /^yes$/i ) {
            textFormat(80,"Here we go with current Replacement List/Config Settings...");
        }
        elsif ( $input =~ /^no$/i ) {
            textFormat(80,"Please check your Current Config Settings in the script.");
            separator(80, '*');
            exit;
        }
        else{
            $input =~ s/^\s|\s+$//g;
            unless(grep $_ eq $input, keys%findReplaceH){
                textFormat(80,"Please pass only YES/NO option or a valid key name from Replacement List to     remove key-value pair from search result."); 
            }
            delete( $findReplaceH{$input} );
        }
    }
    if(scalar(keys%findReplaceH) == 0){
        textFormat(80,"No search result found for the given year.");
        separator(80, '*');
        exit;
    }    

    # This closure will rename all directory recursively as per given in hash keys/values
    finddepth(
        sub {
            return unless -d;
            return if ( $_ eq '.' || $_ eq '..' );
            return if ( $_ =~ /.svn|\.svn/ );
            my $new = $_;
            foreach my $key1 ( keys %findReplaceH ) {
                my $pattern = quotemeta($key1);
                if ( $new =~ /$pattern/ ) {
                    $new =~ s/$pattern/$findReplaceH{$key1}/;
                }
            }
            if ( $_ eq $new ) {
                return;
            }
            my $currentDir = $File::Find::dir;
            $currentDir .= "/" . $_;
            my $renamedDir = $File::Find::dir;
            $renamedDir .= "/" . $new;

            rename $_, $new or warn "Error while renaming $_ to $new in $File::Find::dir: $!";
            open( FILE, ">>$logFile" ) || die "cann't open the $!\n";
            print FILE "Current Directory: $currentDir :: Renamed Directory: $renamedDir\n";
            close FILE;
        }, $folderPath
    );

    # $useRegexQ has values 1 or 0. If 1, interprets the pairs in %findReplaceH to be regex.
    my $useRegexQ = 0;
    $folderPath       =~ s/\/$//;
    $backupFolderPath =~ s/\/$//;
    $folderPath       =~ m/\/(\w+)$/;
    my $previousDir = $`;
    my $lastDir     = $1;
    my $backupRoot  = $backupFolderPath . '/' . $1;

    my $refchangedFiles       = [];
    my $totalFileChangedCount = 0;

    sub fileFilterQ ($) {
        my $fileName = $_[0];
        next if ( $fileName =~ /(svn|\.svn)/ig );

        if ( -f $fileName ) {
			#print "processing files:  $fileName\n";
            return 1;
        }
    }

    # go through each file, accumulate a hash.
    sub processFile {
        my $currentFile     = $File::Find::name;
        my $currentDir      = $File::Find::dir;
        my $previousDir     = $`;
        my $lastDir         = $1;
        my $currentFileName = $_;
        if ( not fileFilterQ($currentFile) ) {
            # fileFilterQ It returns true in case of file, false in case of  dir, not a text file.
            return 1;
        }
        # open file. Read in the whole file.
        if( not( open FILE, "<$currentFile" ) ) {
            die("Error opening file: $!");
        }
        my $wholeFileString;
        { local $/ = undef; $wholeFileString = <FILE>; };
        if ( not( close(FILE) ) ) { die("Error closing file: $!"); }

        # do the replacement.
        my $replaceCount = 0;
        foreach my $key1 ( keys %findReplaceH ) {
            my $pattern = ( $useRegexQ ? $key1 : quotemeta($key1) );
            $replaceCount = $replaceCount + ( $wholeFileString =~ s/$pattern/$findReplaceH{$key1}/g );
        }
        if ( $replaceCount > 0 ) {    # replacement has happened
            push( @$refchangedFiles, $currentFile );
            $totalFileChangedCount++;

            # do backup make a directory in the backup path, make a backup copy.
            my $pathAdd = $currentDir;
            $pathAdd =~ s[$folderPath][];
            mkpath( "$backupRoot/$pathAdd", 0, 0777 );
            copy( $currentFile, "$backupRoot/$pathAdd/$currentFileName" ) or die "error: file copying file failed on $currentFile\n$!";

            # write to the original and  get the file mode.
            my ( $mode, $uid, $gid ) = ( stat($currentFile) )[ 2, 4, 5 ];

            # write out a new file.
            if ( not( open OUTFILE, ">$currentFile" ) ) { die("Error opening file: $!"); }
            print OUTFILE $wholeFileString;
            if ( not( close(OUTFILE) ) ) { die("Error closing file: $!"); }

            # set the file mode.
            chmod( $mode, $currentFile );
            chown( $uid, $gid, $currentFile );

            open( FILE, ">>$logFile" ) || die "cann't open the $!\n";
            print FILE "---------------------------------------------\n";
            print FILE "$replaceCount replacements made at\n";
            print FILE "$currentFile\n";
            close FILE;
        }
    }
    find( \&processFile, $folderPath );
    open( FILE, ">>$logFile" ) || die "cann't open the $!\n";
    print FILE "--------------------------------------------\n";
    print FILE "Total changed files -> $totalFileChangedCount\n";

    if ( scalar @$refchangedFiles > 0 ) {
        print FILE "\nFollowing files are changed:\n";
        print FILE Dumper($refchangedFiles);
    }
    close FILE;
}
sub Usage {
        print<<'EOF';
        Usage:  
            #!/usr/bin/perl
            use File::Find::ProjectCycleMigration;
            my $config = {year=>2011, srcdir=>'/home/uid/foo/project2011'};
            FindReplace($config);
            
        File::Find::ProjectCycleMigration is to convert a project from one cycle to next. The Script scans
        the code in provided path <srcdir> and auto generates a list of possible replacements
        required for moving the code to the next cycle.
          Once you run the script from command line it shows you the list of possible
        replacements in your specified folder and prompts you to confirm or selectively
        remove some of the auto generated list of replacements. enter a name of a
        replacement key to remove it from the list of replacements or type yes or no to
        continue or abort.

        --year=<year>    replace <year> with 4-digits of current cycle year.
                       For example if you are moving the code base from 2011 to 2012 cycle
                       replace <year> with 2011.
                       Required
	    --srcdir=<srcdir> replace <srcdir> with the absolute path of the directory where the replacement
                       should be made. Also script automatically backs up the current code in 'Back-up Directory' 
		               and for logs it creates a 'Log Directory' at one level above the 'Current Directory'.
                       Required
EOF
}
sub separator{
    my ($length, $symbol) = @_;
        print "\t";foreach(1..$length){print $symbol}; print "\n";
}
sub textFormat{
    my ($limit, $text) = @_;
    my $ln = length($text);
    my $sp=0;
    while($ln>0){print "\t",  (substr($text,$sp, $limit)) . "\n"; $sp += $limit;$ln -=$limit;}
}    

1;

__END__

=head1 NAME

File::Find::ProjectCycleMigration - Perl extension for Prjoect Cycle Migration

=head1 SYNOPSIS

  use File::Find::ProjectCycleMigration;
  my $config = {year=>2011, srcdir=>'/home/uid/foo/project2011'};
  FindReplace($config);
  
=head1 DESCRIPTION
	File::Find::ProjectCycleMigration is to convert a project from one cycle to next. The Script scans
        the code in provided path <srcdir> and auto generates a list of possible replacements
        required for moving the code to the next cycle.
          Once you run the script from command line it shows you the list of possible
        replacements in your specified folder and prompts you to confirm or selectively
        remove some of the auto generated list of replacements. enter a name of a
        replacement key to remove it from the list of replacements or type yes or no to
        continue or abort.

        --year=<year>  Replace <year> with 4-digits of current cycle year.
                       For example if you are moving the code base from 2011 to 2012 cycle
                       replace <year> with 2011.
                       * It is Required

        --srcdir=<srcdir> Replace <srcdir> with the absolute path of the directory where the replacement
                       should be made. Also script automatically backs up the current code in 'Back-up Directory' 
        		       and for logs it creates a 'Log Directory' at one level above the 'Current Directory'.
		               * It is Required
=head2 EXPORT

None by default.

=head1 AUTHOR

Neeraj Srivastava, E<lt>neer1979@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Neeraj Srivastava

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

