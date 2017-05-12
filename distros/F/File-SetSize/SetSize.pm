package File::SetSize;

use File::Copy;
use strict;
use vars qw(@ISA @EXPORT $VERSION);
require Exporter;

@ISA = qw(Exporter);

# %EXPORT_TAGS = ( 'all' => [ qw(   ) ] );

# @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw( setsize );

$VERSION = "0.2";

my @NEW_FILE = ();
my $file_name = "";
my $sizekeep = "";
my $size = "";
my $tmp = "";
my $size_limet = 50000; # array limit
my $remove_amount = 0;
my $size_after = 0;
my $type = "";


sub setsize {
 
             ($file_name, $sizekeep) = @_ ;

             if ( $file_name eq "" ) { 
                                       print "\n * No file *\n\n"; 
                                       return 1;
                                     }
             if ( $sizekeep eq "" ) {
                                         print "\n * No Size *\n\n";
                                         return 1;
                                    }

             if (not -e $file_name)  {
                                       print "\n * Can't find \"$file_name\" *\n\n";
                                       return 1;
                                     }
             if (-d $file_name) {
                                       print "\n * File is a directory *\n\n";
                                       return 1;
                                }
             if (-z $file_name )  {
                                       print "$file_name is 0 size, can't go into negitve space\n\n";
                                  }
                            

            ($size) = (stat($file_name)) [7];


          if ( $size > $sizekeep ) { $remove_amount = ( $size - $sizekeep ) }
          else {  
                 print "\n * File is already smaller than what you want it is $size Bytes *\n\n"; 
                 return 1;
               }

                if ( $size < $size_limet ) {
                                            
                                            open(INFILE, "$file_name") or die "Error : Can not open $file_name";
                                            seek (INFILE, $remove_amount, 0);
                                   
                                            while (<INFILE>) {  push @NEW_FILE, $_ }
                                            close(INFILE);
 
                                            open (INFILE, ">$file_name");
                                            print INFILE "@NEW_FILE";
                                            close(INFILE);

                }
                else {
                $tmp = "$file_name.tmp" ;

                open(INFILE, "$file_name") or die "Error : Can not open $file_name";
                seek (INFILE, $remove_amount, 0);

                open(TEMPFILE, ">$tmp");
                while (<INFILE>) { 
                                
                                   print TEMPFILE $_ ;
                               
                                  }
                close(TEMPFILE);
                close(INFILE);
                print "$tmp .. $file_name\n";
                copy("$tmp", "$file_name") or die "move failed: $!";
                unlink($tmp);
                }


                ($size_after) = (stat($file_name)) [7];
                print "$file_name type $type, was $size, set to $size_after bytes\n";


};


1;


__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SetSize - Perl extension for reducing files from the top down

=head1 SYNOPSIS

  use File::SetSize;



=head1 DESCRIPTION

A very simple module to keep a file at set size by removing lines from the start of the file until 
the file is at the desired size. Ment created for apache logs.


usage

use File::SetSize;

$file_name = "/usr/local/apache/logs/access_log";
$keepatsize = 500; # in bytes

SetSize($file_name,$keepatsize);

=head1 AUTHOR

campbell paterson  cam8chris@fastmail.com.au

=head1 SEE ALSO

perl(1).

=cut
