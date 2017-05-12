#! /usr/bin/perl -w
#
# stringsx.pl
#
# (C) 2011 jnw@cpan.org
# Distribute under MIT or any GPL license.
#
# A simplified strings tool, similar to the tool that 
# comes with gnu binutils, but with the following differences
#
# * no -e switch. We support all encodings simultaneously
# * '\0' characters are stripped, and have no effect, unless
#   multiple '\0' charachters occur in a row.
# * adjustable fuzzyness: 3 chars in a row with their 8th bit
#   set are accepted, control chars except '\t', '\n', '\r'
#   always cut a string. 
# * Strings need not be '\0' terminated.
# * no support for file sections. We always scan the entire file.
#
# Implemented in both perl and C. Compile the C version, if you 
# find significant speed issues with the perl version.
#
# 2011-11-01, jnw@cpan.org
# 2012-08-23, jw, no more string termination with \f

my $infile = shift;
unless (defined $infile)
  {
    die "Usage: $0 file\n";
  }

my $fd = STDIN;
if ($infile ne '-')
  {
    open $fd, "<", $infile or die "open $infile failed: $!\n";
  }

my $minlen = 10;
my $badcut = 3*1;	# 3 chars of badness 1, or similar

my $ch;
my $badcount = 0;
my $printing = 0;
my $queuelen = 0;
my $nulseen = 0;
my $queuebuf = '';

while (defined($ch = getc($fd)))
  {
    my $badness = 0;
    my $oc = ord($ch);
    if ($oc == 0)
      {
 	$nulseen++;	# a nul every second char is just fine.
 	if ($nulseen > 1) { $badness = $badcut+1; }
      }
    else
      {
 	$nulseen = 0;
 	if ($oc > 127)                     { $badness = 1; }	     # latin1 or utf8 byte
	elsif ($oc < 32 && $ch ne "\t" && 
 	       $ch ne "\n" && $ch ne "\r") { $badness = $badcut+1; } #  control char.
        else 				   { $badness = 0; }	     # good char
      }

# 
    $badcount += $badness;

    if (!$printing && !$badness)
      {
        $queuebuf .= $ch if $oc; 	# always skip \0 bytes

        if (length($queuebuf) >= $minlen) 
          {
	    print $queuebuf;
            $queuebuf = '';
            $printing = 1;
          }
        next;
      }

    if ($printing)
      {
        if (!$badness && $oc)
          {
            if (length($queuebuf))
              {
	        print $queuebuf;
		$queuebuf = '';
      	      }
            $badcount = 0;
            print $ch;
          }
        else
          {
            $queuebuf .= $ch if $oc; 	# always skip \0 bytes
            if ($badcount >= $badcut) 
              { 
      	        $queuebuf = '';
                $printing = 0;
      	  	$badcount = 0;
      	  	# print "\n\f";		# next string. \f here confuses less.
      	  	print "\n";		# next string.
      	      }
          }
      }
  }
close $fd;

