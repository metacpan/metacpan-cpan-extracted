=head1 NAME

Term::GetKey - A perl module for quick easy simple key control

=head1 SYNOPSIS

perl Version 5.6.0 or higher is required because it uses the module warnings:

use Term::GetKey;

Term::ReadKey is used to change the terminal settings.

=head1 DESCRIPTION

This module changes the settings of Term::ReadKey using the `\' as a toggle key. qtty() makes a single character request to Term::ReadKey which is esential for the functionality of this module. `|' toggles the case of the output character to UPPERCase lowercase or off.  qtty() and keypasswd() and query() use chomp on all input.

use Term::Getkey;

my $ch;#$ch can be any scalar variable

$ch = qtty();#single character good for menus.
The methods in this module are dynamically loded so you do not need the full prefix Term::GetKey-> prefix to call a method.

status();

will announce the key strokes the module uses.

The Term::ReadKey reserve words: 

	ReadKey ReadMode ReadLine GetTerminalSize SetTerminalSize

	GetSpeed GetControlChars SetControlChars

are still available and functional.

qtty() keypasswd() query() status() setkeymode()

keymode()  setannounce() announcestatus() setcase() casestatus() Kmstatus() is the list of methods that do not require the full system path and module name before the method name.

When you press `|' or `\' and then a `\\n' depending on the settings you cycle
through the settings of Term::ReadKey. The keys effected by Term::GetKey->qtty are disabled in noecho mode. When Term::GetKey is in (cbreak, raw or ultra-raw) modes the `\n' or enter key is not required.

=head1 The following methods are called by qtty()

setanounce() 	`~'

setcase()			`|'

setkeymode()			`\\' the backslash key
Terminat your program with	'`' the grav accent key. warnings is used so the line number is announced so you know that Term::Getkey terminated your module fore you.

keypasswd() calls qtty to create a password. This saves a call to stty - echo and stty echo.

my $opt_passwd;

$opt_passwd = keypasswd();

query() calls setcase() 	`|'

If you wish to have a `|' as the only character on the line: `\|' will cause query() to remove the `\\' and `|' will be sent as the string.

The announcements are not disabled when you call qtty() or query() if they are waiting for a request and you press '|' or '\\'. You can disable the announcements with a call to set_announce(). The functions setcase() setkeymode() casestatus() and Kmstatus return the current value or the changed value of their called method.

=head1 keymode Settings

0 Restore original settings.  1 Change to normal mode.
2 Change to cooked mode with echo off.  (Good for passwords) strings are uneffected
3 Change to cbreak mode.  4 Change to raw mode.
5 Change to ultra-raw mode.  (LF to CR/LF translation turned off) 

=head1 GetKey announces the synonyms:

restore
normal
noecho
cbreak
raw
ultra-raw

The Default for qtty() is cbreak.

qtty() handles each key individually. It returns to the `normal' mode after each key has been pressed so that you can continue with your programming allowing you flexability. When case conversion is activated with the `|' or called via a program it takes priority over your current case settings.  It saves your current setting and sets itself so that other programs run normally. The default setting for its case conversion is off (no translation). You can toggle or query the settings with the following calls:

status();

my $myval;
$myval = casestatus();

$myval = Kmstatus();

#change the case of the key requested and announce the setting

my $keymodeval;
setcase();

#or

$readval = setcase();

query();#handles lines of text.

my$opt_passwd = keypasswd();

my $textline = query();

The characters returned are set to the case setting that you set with `|'.

announcestatus announces the status of the verbosity.

The status of Term::GetKey is available by pressing `=' the equals key.

setannounce toggles the setting verbosity. The calls to the keystrokes mentioned above are only present with a call to qtty() All the Term::GetKey commands except '\\' are disabled when Term::GetKey is in noecho mode.

In noecaho mode, qtty() only has `\\' active. query() has case conversion disabled. 

=head1 Case and announcement values:

setcase() casestatus() Kmstatus() setkeymode() return values only when announce mode is disabled with the default.

Off 0
UPPERCASE and announcements active 1
lowercase 2

Characters can be converted by Term::GetKey no matter what the capslock or case of the character sent by the terminal.

=cut


#this module requires perl version 5.6.0 or better

package Term::GetKey;
use Carp;
use warnings;
my $tmp = 0;
eval{
    require Term::ReadKey};
$tmp++ if $@;
if ($tmp){
    die "Term::ReadKey is required along with perl version 5.6.0 or better.\n";}

else {
    use Term::ReadKey}
my $version = "1.02";

BEGIN 
{
    use Exporter   ();
    require AutoLoader;
    require DynaLoader;

    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS); #new in v5.6
    $VERSION    =  1.00;

    @ISA = (Exporter, AutoLoader, DynaLoader);

    @EXPORT=qw(
	       ReadKey ReadMode ReadLine GetTerminalSize SetTerminalSize
	       GetSpeed GetControlChars SetControlChars
	       keypasswd qtty query setcase  casestatus setkeymode
	       announcestatus setannounce status Kmstatus
	       );

    @EXPORT_OK   = qw($xy $case_val $tty_val $announce_val);
}#end BEGIN

    our @EXPORT_OK;
my $xy   = '';
my $case_val = 0;
$DB::emacs = $DB::emacs;	# To peacify -w
my $announce_val = 0;
my $announce_tmp = $announce_val;
my $case = "GetKey set to";
my $console;
my $tty_val = 3;

# function declorations:

sub status;
sub setcase;   
sub setannounce;
sub keypasswd;
sub announcestatus;
sub casestatus;
sub Kmstatus;
sub setkeymode;
sub qtty;
sub query;

END {close(TTY); }     # module clean-up code here (global destructor)

if (-e "/dev/tty") {
    $console = "/dev/tty";
} elsif (-e "con" or $^O eq 'MSWin32') {
    $console = "con";
} else {
    $console = "sys\$command";    }

if (($^O eq 'amigaos') || ($^O eq 'beos') || ($^O eq 'epoc')) {
    $console = undef;    }

elsif ($^O eq 'os2') {

    if ($DB::emacs) {
	$console = undef;
    } else {
	$console = "/dev/con";      }
}

$consoleOUT = $console;
$console = "&STDIN" unless defined $console;

if (!defined $consoleOUT) {
    $consoleOUT = defined fileno(STDERR) ? "&STDERR" : "&STDOUT";
}

open(TTY, "<$console");

sub qtty
{#single character request using Term::ReadKey
     ReadMode "restore" if $tty_val == 0;
     ReadMode "normal" if $tty_val == 1;
     ReadMode "noecho" if $tty_val == 2;
     ReadMode "cbreak" if $tty_val == 3;
     ReadMode "raw" if $tty_val == 4;
     ReadMode "ultra-raw" if $tty_val == 5;
     $xy = ReadKey 0, *TTY;
     ReadMode "normal";#we needd the normal state to return the key
	 chomp $xy;
     $announce_val = 1;
     print "\n" if ($xy eq '\n' || $tty_val == 3);

     if ($xy eq '\\'){
	 $tty_val = setkeymode();
	 qtty() if $tty_val < 3;
	 qtty();

     }else {

	 if ($tty_val != 2){
	     $xy=uc($xy) if $case_val == 1;
	     $xy=lc($xy) if $tty_val == 2; #do not translate in noecho
		 print"$xy\n" if ( $case_val);

	     if ($xy eq '|'){
		 setcase();
		 $announce_val = $announce_tmp;
		 qtty() if $tty_val < 3;
		 qtty();
	     } elsif ($xy eq '+'){
		 my $qtty_call = caller();
		 print"$qtty_call\n";
		 qtty();
	     } elsif ($xy eq '~'){
		 setannounce();
		 $announce_val = $announce_tmp;
		 qtty() if $tty_val < 3;
		 qtty();
	     } elsif ($xy eq '='){
		 status();
		 $announce_val = $announce_tmp;
		 qtty() if $tty_val < 3;
		 qtty();
	     }
	     $announce_val = $announce_tmp;
	     croak("\nThank you for using $0: ") if $xy eq '`';
	 }#end else
	 }#end if

	 $announce_val = $announce_tmp;
     $xy;
}#end qtty

    sub Kmstatus
{#setting of Term::GetKey keymode

     if ($tty_val == 1){
	 print "$case normal:\n" if $announce_val;
     } elsif ($tty_val == 2){
	 print "$case noecho:\n" if $announce_val;
     } elsif ($tty_val == 3){
	 print "$case cbreak:\n" if $announce_val;
     } elsif ($tty_val == 4){
	 print "$case raw:\n" if $announce_val;
     } elsif ($tty_val == 5){
	 print "$case ultra-raw:\n" if $announce_val;
     } else{

	 print "$case restore:\n" if $announce_val;
     }

     $tty_val;
}#end Kmstatus

    sub setkeymode
{#change setting of Term::ReadKey keymode

     if ($tty_val == 0){
	 $tty_val=1;
	 Kmstatus();
     } elsif ($tty_val == 1){
	 $tty_val = 2;
	 Kmstatus();
     } elsif ($tty_val == 2){
	 $tty_val = 3;
	 Kmstatus();
     } elsif ($tty_val == 3){
	 $tty_val = 4;
	 Kmstatus();
     } elsif ($tty_val == 4){
	 $tty_val = 5;
	 Kmstatus();
     }else{
	 $tty_val = 0;
	 Kmstatus();
     }

     $tty_val;
}#end set keymode

    sub setannounce
{#alter the setting verbosity announce is the default

     if ($announce_tmp == 1){
	 $announce_val = $announce_tmp = 0;
	 announcestatus();

     }else{

	 $announce_val = $announce_tmp = 1;
	 announcestatus();
     }

     return($announce_tmp,$announce_val);
}#end setannounce

    sub announcestatus
{#announce the setting of active announce on the default

     if ($announce_tmp == 0){
	 print "$ case announcement disabled: " if $announce_val == 0;

     }else{

	 print "$case announcement active: " if $announce_val == 1;
     }#end else

	 $announce_tmp;
}#end announcestatus

    sub query
{#input line
     chomp($xy=<STDIN>);
     $announce_val = 1;

     	if ($tty_val >= 2){
	 print "\n";
	} else{

		if ($xy eq '|'){
		setcase();
query();
	    }

			     if (length($xy)){

		 if ($xy =~ /\D/){
		     $xy = uc($xy) if $case_val == 1;
		     $xy = lc($xy) if $case_val == 2;
		 }#end if
		     $xy  = ~ s/\\// if ($xy eq '\\|');
	     }#end if
	     }#end else
		 print "$xy\n" if $case_val;
		 $announce_val = $announce_tmp;
     $xy;
}#end query


    sub status
{#GetKey status
     $announce_val = 1;
     casestatus();
     announcestatus();
     Kmstatus();
     print qq~Term::GetKey.pm $version. Commands from `$0'
	 when asked for a single character response when using qtty():
	 '`'  quit the program                  '\~'  toggle GetKey announcement
       '|'  toggle case conversion            '\\' toggle the ReadKey settings
       '='  read this announcement            '+'  list the caller function
    ~;
    $announce_val = $announce_tmp;
}#end status

    sub casestatus
{#announce the setting of active case off the default

     if ($case_val == 2){
	 print "$case lowercase: " if $announce_val;
     } elsif ($case_val == 0){
	 print "$case case conversion disabled: " if $announce_val;
     }else{
	 print "$case UPPERCASE: " if $announce_val;
     }#end else

	 $case_val;
}#end casestatus

    sub setcase
{#alter the setting of case conversion off is the default

     if ($case_val == 1){
	 $case_val = 2;
	 casestatus();
     } elsif ($case_val == 2){
	 $case_val = 0;
	 casestatus();
     }else{
	 $case_val = 1;
	 casestatus();
     }

     $case_val;
}#end setcase

    sub keypasswd
{#get a password
     my $xz;
		 my $qtty_call = caller();
     my $xx = $tty_val;

     $tty_val = 2 if $qtty_call!~ /query/;

     for(;;){
	 $xy = qtty();
	 last if $xy eq "";
	 $xz .= "$xy";
     }#end for
	 $tty_val = $xx;
     print "\n";
     $xz;
}#end keypasswd


    1;

__END__;

package Term::GetKey; #so AutoSplit is happy
