package File::Mode;
use strict;
use Exporter;
use Carp;

use vars qw/$VERSION/;
$VERSION = 0.05;

#--------------------------  File::Mode Ver 0.05 ---------------------#
#---------------------  ©2000 Idan Robbins aka Aqutiv ----------------#

#I was thinking... If they invented comments, why not use them?
#So there you go, here's a comment. And you know what? I actually like comments.
#Yeah, that's it. Much better, fills in some empty spaces like this.
#What could have been here without these comments. ah? 
#
#Shit, I've nothing left to say... Ah, well. See ya in the next version. :)

#--------------------- New Object ---------------------#
sub new {
    my $which = shift;
    my $class = ref($which) || $which;
    return bless {},$class;
}

#-------------- Unix file mode to Number Mode ---------#
sub UnixToOct {
    my $self = shift;
    my $mod  = shift || "-" x 6; 
    my $NoType = shift || 0;
    my $type = undef;	    
    my $skipchar = 0;
    my $OctMod = 0;

    #The common format that is used for file modes. (i.e the mode that 'ls -l' unix commands gives)
    if ($mod =~ /^([d\-]?)([r\-][w\-][x\-]){3}$/) {
		
	#Determine whether it is a file or a directory. (stays undefined if none)	
	if (!$1) { $skipchar = 1;}
	elsif (substr($mod, 0, 1) eq "d") {$type = "DIR";}
	else {$type = "FILE";}

	$mod =~ s/^.// unless $skipchar; #get rid of the first character for easy handling.

	my($ownermod)  = substr($mod, 0, 3);
       	my($groupmod)  = substr($mod, 3, 3); 
	my($publicmod) = substr($mod, 6, 3); 
      
	my($dig1) = $self->GetNum($ownermod);
	my($dig2) = $self->GetNum($groupmod);
	my($dig3) = $self->GetNum($publicmod);
	
	$OctMod = 0 . $dig1 . $dig2 . $dig3;


   }
   
   else { 
        #Uncomment if you want the module to be strict, otherwise will return an empty list. 
   	#croak "Wrong format for Unix file mode"; 
        return ();
   }	

   if(!$type || $NoType) { return $OctMod}	
   else {return $OctMod, $type}
   

}

#-------------- Numeric Mode to Unix Standart ---------#
sub OctToUnix {
    my $self = shift;
    my $mod  = shift || "000"; 
    my($UnixMod) = 0;	

    #Makes sure that the number is made of 3 digits (or 4, with an option 0 at start) and each one of them is 7 or smaller. 
    #For example, 755 and 0755 will both match.    
    if (($mod =~ /^0?\d{3}$/) && ($mod !~ /[89]/)) {
	
	#A tricky method to get each one of the digits, don't you think? 
	#It also takes care of the optional 4 digits. ;)
	my($ownermod)  = int($mod / 100); #first
       	my($groupmod)  = int($mod % 100 / 10); #middle
	my($publicmod) = int($mod % 10); #last
      
	my($str1) = $self->GetString($ownermod);
	my($str2) = $self->GetString($groupmod);
	my($str3) = $self->GetString($publicmod);
	
	$UnixMod = $str1 . $str2 . $str3;
	
   }
   #Uncomment if you want the module to be strict. Otherwise, returns 0.
   #else { 
   #	croak "Illegal octal file mode"; 
   #}	

   return $UnixMod;

}
#--------------------- String to Digit Conversion ---------------------#
sub GetNum {

my $self = shift;
my $ModValue = shift || "-" x 3; 

$ModValue =~ tr/\-a-z/01/; #Converts the string to a binary value.

#Convert from binary into an octal digit.
$ModValue = oct( unpack("N", pack("B32", substr("0" x 32 . $ModValue, -32))) );
#Took me awhile to figure this out... Ok, I admit, Grabbed it out of the perldocs...
#But it still took me some time to find it. ;)

return $ModValue;

}

#--------------------- Digit to (short) String Conversion ---------------------#
sub GetString {

my $self = shift;
my $ModDig = shift || 0;

#Convert to a binary value:
my($ModValue) = unpack('B*', $ModDig);
$ModValue =~ s/^.*(\d{3})$/$1/; #Remove useless digits.

#Binary to unix file mode convertion.
$ModValue =~ tr/0/\-/; 
$ModValue =~ s/^1/r/; 
$ModValue =~ s/^(.)1(.)$/$1w$2/; 
$ModValue =~ s/1$/x/; 

return $ModValue;

}

#----------------------- File plus Mode Directory Listing ---------------------#
sub FileList {

my $self = shift;
my $HashRef = shift || croak "No hash refeference specified for method FileList";
my $Directory = shift || "./";
my $NoDir = shift || 0;
my $mode = 000;
my $error = 0;
my $file = '';

croak qq{Not a hash reference for method FileList} unless ref($HashRef) eq "HASH"; 

opendir(DIR, $Directory) or $error = 1;
my @files = readdir(DIR);
closedir(DIR);

foreach $file (@files) {

	$mode = (stat("$Directory/$file"))[2]; 
	$mode = sprintf "%04o", $mode & 07777;

	$mode = $self->OctToUnix($mode); 
	
	#Determine Directories
	if ((-d $file) && !$NoDir) {$mode = "d" . $mode} 
	elsif (!$NoDir) {$mode = "-" . $mode}

	$HashRef->{$file} = "$mode";

}

if ($error) {return 0}
else {return 1}

}

1;
__END__

#-------------------- Perldoc Text (perldoc File::Mode)------------------#

=head1 NAME

B<File::Mode> - A perl module to handle, convert, and list unix file modes in various formats.

=head1 DESCRIPTION

File::Mode is a simple perl library meant to handle file modes and convert 
them to the wanted format, as well as read the files in a directory with their modes
in a human readable format (eg. -rwxrwxrwx). 

=head1 SYNOPSIS

  use File::Mode;
  my $Fmode   =  File::Mode->new();
  my $unixmod =  $Fmode->OctToUnix( NUMBER );
  my ($mod, $type) =  $Fmode->UnixToOct( STRING, [notype] ); 
  $Fmode->FileList( \%hash, DIR PATH, ["NODIR"] ); 	

=head1 METHODS

B<OctToUnix>( NUMBER )

This method converts a numeric file mode to its unix standart equilivant,
(i.e The file modes you get when you do 'ls -l'.) Since it's not possible to determine 
if it's a file or a directory, it returns a string that is only 6 chars, for example: 

        print $Fmode->OctToUnix(0777) or die("Illegal Number.\n");

Will print out the string: rwxrwxrwx. which means Read, Write, and eXecute for all usrs.
(refer to your unix/linux manual for more info.) Will return 0 if the format is wrong. 
(eg, one of the digits is greater then 7, or the number has more then 3 digits. optionally 4, 
if starts with 0).


B<UnixToOct>( STRING, [notype] )

This complex method converts a standart unix file mode string into its numeric equilivant,
(i.e the file mode that you use when you do CHMOD.) It returns either a scalar of the octal 
number, if the string is in a format of 6 chars (e.g rwxrwxrwx), which means that it'l not 
be able to determine if it's a file or a directory. Or a list of two items, the first is 
the number, and the second is the type (DIR or FILE), if the string is in a format of 7 chars. 
(e.g drwxr-xr-x which is a directory). If the second argument is true, 
will never return the type. Will return an empty list if the format is wrong.
Full Example:

	use File::Mode;
	$Fmode = File::Mode->new();

	print "Type a unix standart file mode\
        to convert into a its numeric value:\n";
	chomp($mod = <STDIN>);
        
	@mod = $Fmode->UnixToOct($mod) or die "Wrong Format.\n";
	print "@mod\n";

If the user has entered "rwxr-xr-x", will print "0755". 
if he has entered "-rwxrwxr-x" will print "0755 FILE".
if he has entered "hello" will quit (die) and print "Wrong format."

B<FileList>( \%hash, DIR STRING, [nodir] )

This method takes 2 arguments and an optional third. The first must be an hash referense
that will store a list of files in a specified directory as the keys, and their 
file modes / permissions in a unix standart format, as the values. The second argument is 
the directory to look in, if none specified, the current directory will be used as a default. 
(altough, It's always a better practice to specify it.) The third argument is rethar useless, 
but well, you never know. If you set it to "NODIR" (or any other true value, for that matter), 
The file modes will be in a format of 6 characters and will not mention wheter each file is 
actually a directory or not. 
Here's an example, you may use it freely:

	use File::Mode;

	$Fmode = File::Mode->new();

	$Fmode->FileList(\%modes, "./") or die "Can't open dir, $!.\n";

	foreach $file (sort keys %modes) {
	print "$modes{$file}\t$file\n";
	}
	
This might remind you the 'ls -l' unix command a bit.

=head1 TO DO

Ask people to test the module for me and tell me what they think.

=head1 AUTHOR

Idan Robbins <aqutiv@softhome.net>

=head1 SEE ALSO

chmod(), perl(1).

=cut
