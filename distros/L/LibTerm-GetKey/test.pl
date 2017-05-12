#use strict vars;

#use Term::ReadKey qw( ReadMode ReadKey );
#use Term::GetKey qw( ReadMode ReadKey );
#my $x;
#my $case_val;
#my $case_status;
#ReadMode 3;
#print "Read 1\n";
#$x = ReadKey(0);
#print "X=$x\n";
#print "Read 2\n";
#$x = ReadKey(0);
#print "X=$x\n";
#ReadMode 0;
#__END__;

#BEGIN {@INC = ("/home/kjahds/perl5/perl5.000/lib/auto","/home/kjahds/perl5/perl5.000/lib"); }
use Term::ReadKey;
use Term::GetKey;
use Fcntl;

status();

if ($^O =~ /Win32/i) {
	sysopen(IN,'CONIN$',O_RDWR) or die "Unable to open console input:$!";
	sysopen(OUT,'CONOUT$',O_RDWR) or die "Unable to open console output:$!";
} else {
	open(IN,"</dev/tty");
	*OUT = *IN;}
*IN=*IN; # Make single-use warning go away
$|=1;

print "Now on to the tests!\n";

#print join(",",GetTerminalSize(\IN)),"\n";
#print join(",",GetTerminalSize("IN")),"\n";
#print join(",",GetTerminalSize(*IN)),"\n";
#print join(",",GetTerminalSize(\*IN)),"\n";
#__END__;

sub makenicelist {
	my(@list) = @_;
	my($i,$result);
	$result="";
	for($i=0;$i<@list;$i++) {
		$result .= ", " if $i>0;
		$result .= "and " if $i==@list-1 and @list>1;
		$result .= $list[$i];
	}
	$result;
}

sub makenice {
	my($char) = $_[0];
	if(ord($char)<32) { $char = "^" . pack("c",ord($char)+64) }
	elsif(ord($char)>126) { $char = ord($char) }
	$char;
}

sub makeunnice {
	my($char) = $_[0];
	$char =~ s/^\^(.)$/pack("c",ord($1)-64)/eg;
	$char =~ s/(\d{1,3})/pack("c",$1+0)/eg;
	$char;
}

if( &Term::ReadKey::termoptions() == 1) {
	print "Term::ReadKey is using TERMIOS, as opposed to TERMIO or SGTTY.\n";
} elsif( &Term::ReadKey::termoptions() == 2) {
	print "Term::ReadKey is using TERMIO, as opposed to TERMIOS or SGTTY.\n";
} elsif( &Term::ReadKey::termoptions() == 3) {
	print "Term::ReadKey is using SGTTY, as opposed to TERMIOS or TERMIO.\n";
} elsif( &Term::ReadKey::termoptions() == 4) {
	print "Term::ReadKey is trying to make do with stty; facilites may be limited.\n";
} elsif( &Term::ReadKey::termoptions() == 5) {
	print "Term::ReadKey is using Win32 functions.\n";
} else {
	print "Term::ReadKey could not find any way to manipulate the terminal.\n";
}
push(@modes,"O_NODELAY") if &Term::ReadKey::blockoptions() & 1;
push(@modes,"poll()") if &Term::ReadKey::blockoptions() & 2;
push(@modes,"select()") if &Term::ReadKey::blockoptions() & 4;
push(@modes,"Win32") if &Term::ReadKey::blockoptions() & 8;

if(&Term::ReadKey::blockoptions()==0)
{
	print "No methods found to implement non-blocking reads.\n";
	print " (If your computer supports poll(), you might like to read through ReadKey.xs)\n";
} else {
	print "Non-blocking reads possible via ",makenicelist(@modes),".\n";
	print $modes[0]." will be used. " if @modes>0;
	print $modes[1]." will be used for timed reads." if @modes>1 and $modes[0] eq "O_NODELAY";
	print "\n"}
@size = GetTerminalSize(OUT);

if(!@size) {
	print "GetTerminalSize was incapable of finding the size of your terminal.";
} else {
	print "Using GetTerminalSize, it appears that your terminal is\n";
	print "$size[0] characters wide by $size[1] high.\n"}

if(GetSpeed) {
	print "You are connected at ",join("/",GetSpeed)," baud.\n";
} else {
	print "GetSpeed couldn't tell your connection baud rate.\n"}
print "\n";
%chars = GetControlChars(IN);
%origchars = %chars;

for $c (keys %chars) { $chars{$c} = makenice($chars{$c}) }
print "Control chars = (",join(', ',map("$_ => $chars{$_}",keys %chars)),")\n";
SetControlChars(%origchars, IN);
#SetControlChars("FOOFOO"=>"Q");
#SetControlChars("INTERRUPT"=>"\x5");
END { ReadMode 0, IN; } # Just if something goes weird
$x= "";
print "And now for the interactive tests.
\nYou may try the different settings of $x = qtty()\n";
$case_val = 0;
print "Type a character, terminate with the enter key:";
for (;;){
$x = qtty();
print $x;
last if ($x eq "\n" || $x eq "")}#end for
print "This is ReadMode 1. It's guarranteed to give you cooked input. All the
signals and editing characters may be used as usual.
\nYou may enter some text here: ";
$t = query();

print "\nYou entered `$t'.\n";

print "\nThis is ReadMode 2. It's just like #1, but echo is turned off. Great\n";
print "for passwords.\n";
print "\nYou may enter some invisible text here: ";
$t = keypasswd();
print "\nYou entered `$t'.\n";

