package MailBot::UI::Spool;

#use MailBot::Internet;
use Mail::Internet;
use MailBot::Config;
use MailBot::UI::OneMsg;

@ISA = qw( MailBot::UI::OneMsg );
use strict;

sub d
{
    &MailBot::Util::debug(@_);
}

# j prevent 'From rolf' from showing up

sub waitForSpool
{
    my $self = shift;
    
    my $config = MailBot::Config::current;

    my $localSpool = $config -> getLocalSpool;
    (-e $localSpool) and return $localSpool;

    my $mailSpool = $config -> getMailSpool;
    #(-r $mailSpool) or die "cannot read spoolfile $mailSpool";
    #(-w $mailSpool) or die "cannot write to spoolfile $mailSpool";

    $ENV{MAIL} = $mailSpool;

    my $sleep = $config -> getIniVal('load','sleep.spool',30);

    while (1)
    {
	my @stat = stat($mailSpool);
	my $size = $stat[7];
	if ($size > 1)
	{
	    my $cmd = $config -> getIniVal('spool','get');
	    $cmd =~ s/\$localSpool/$localSpool/g;
	    my $mailStatus = `$cmd`;
	    #my $mailStatus = `/bin/echo 's * $localSpool' | /usr/bin/Mail -n`;
	    if ($? << 8)
	    {
		if ($mailStatus =~ /no mail for/i)
		{
		    sleep $sleep;
		    next;
		}
		die "Mail command returned nonzero: $mailStatus";
	    }
	    # print STDERR "status: $mailStatus";

	    return $localSpool;
	}
	sleep $sleep;
    }    
}

sub vGetMessage
{
    my $self = shift;

    my $spool = $self -> waitForSpool;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size) = stat($spool);
    $size > 400000 and die "spool too long";

    open(SPOOL,$spool) or die "could not open spool: $!";
    flock(SPOOL,2);  # exclusive lock

    my @message = ();
    my $line = <SPOOL>;
    $line =~ /^From / or die "$spool is not a mail spool";
    push(@message,$line);
    while ($line = <SPOOL>)
    {
	last if $line =~ /^From /;
	push(@message,$line);
    }

    if (defined $line)
    {
	my $spoolNew = "$spool.new";
	open(SPOOL_NEW,">$spoolNew") or die "could not create $spoolNew: $!";
	print SPOOL_NEW $line;
	while ($line = <SPOOL>)
	{
	    print SPOOL_NEW $line;
	}
	close(SPOOL_NEW) or die "could not write to $spoolNew: $!";
	# chmod($mode,$spoolNew) or die "could not chmod $spoolNew: $!";
	# chown($uid,$gid,$spoolNew) or die "could not chown $spoolNew: $!";
	rename($spoolNew,$spool) or
	    die "could not rename $spool to $spoolNew: $!";
    }
    else
    {
	unlink($spool) or die "could not delete $spool: $!";
    }

    my $message = new Mail::Internet(@message);

    $self -> analyzeMessage($message);
}
