#!/usr/bin/perl -w

use Guitar::Tuner;
use Term::ReadKey;


my $guitarstring=1; # Guitar String To Tune. 1=Heaviest 6=Lightest
my $playstr="EString"; # Guitar String Sample To Use.


system("clear");
print "$playstr\n";
print "\n";
print "Use Space Bar To Play String. \n";
print "UP / Down Arrow Keys For Volume. \n";
print "Use Left / Right Arrow Keys To Change Strings \n";
print "Press Escape Key To Exit.\n";


while() # Main While() Loop
{
ReadMode 3; # Will Trap One Character, Allows Control Characters

	while (not defined ($keypressed = ReadKey(-1)))
	{
         # Waiting For Keypress
	}

	if ($keypressed =~ //)  # Escape Key, Arrow Keys, Or Fn Key Pressed
	{
		$keypressed = ReadKey(-1); 
		$keypressed = ReadKey(-1);

		if ( ! $keypressed )
		{
			
			if ( $pidvar )
			{
				kill(15, $pidvar);
			}

			ReadMode 0; # Reset tty mode before exiting
			exit;
		}


		if ( $keypressed =~ "A" ) # Up Arrow
		{
			system("amixer -q -c 0 set Master 1.7dB+");
			next;
		}

		if ( $keypressed =~ "B" ) # Down Arrow
		{
			system("amixer -q -c 0 set Master 1.1dB-");
			next;
		}


		if ( $keypressed =~ "C" ) # Right Arrow
		{
			$guitarstring = $guitarstring + 1;
			if ( $guitarstring == 7)
			{
			$guitarstring=6;
			# print("$guitarstring\n"); # Debugging...
			}
			PlayIt($guitarstring);

		}

		if ( $keypressed =~ "D" ) # Left Arrow
		{
			$guitarstring = $guitarstring - 1;
			if ( $guitarstring == 0)
			{
			$guitarstring=1;
			# print("$guitarstring\n"); # Debugging...
			}
			PlayIt($guitarstring);
		}

		else  # Any Other Key That Contains Escape, Keep Going 
		{
			next;
		}
	}


	if ($keypressed =~ / /)  # Spacebar Pressed
	{
		PlayIt($guitarstring);
	}

# system("clear");
# print "Use Space Bar To Play String. \r";
}
## End Main While() Loop

ReadMode 0; # Reset tty mode before exiting
exit(42);




## Subroutine to Play Strings Below.
# Call Functions From Module Guitar::Tuner
sub PlayIt {

my $playstring = shift;
# print $playstring; # Debugging...

		if ($guitarstring == 1)
		{
			$playstr="EString";
		}

		if ($guitarstring == 2)
		{
			$playstr="AString";
		}

		if ($guitarstring == 3)
		{
			$playstr="DString";
		}

		if ($guitarstring == 4)
		{
			$playstr="GString";
		}

		if ($guitarstring == 5)
		{
			$playstr="BString";
		}

		if ($guitarstring == 6)
		{
			$playstr="eString";
		}


		# print "$pidvar\n";  # Debugging...
		if ( ! $pidvar  )
		{
			$pidvar = fork();
			if( $pidvar == 0 )
			{
				$pidvar=$$;
				my $oldpid=-1;
				my @stringtoplay=($oldpid, $playstr);
				my @returnarray=Tuner->PlayString(@stringtoplay) or die ;
			}
			# print "forked to $pidvar\n";  # Debugging...
		}

		else
		{
			$oldpid=$pidvar;
			$pidvar = fork();
			if( $pidvar == 0 )
			{
				# print " -->  $pidvar\n";    # Debugging...
				my @stringtoplay=($oldpid, $playstr);
				my @returnarray=Tuner->PlayString(@stringtoplay) or die;
				$pidvar=$$;
			}
		}
		
}
## End Of PlayString()
