package MailBot::Config;

use MailBot::IniConf;

use Carp;
use strict;

my $gRoot = "/tmp/mailbot";
my $gCurrentConfig;

sub setRoot
{
    my $self = shift;
    my $rootDir = shift;

    $gRoot = $rootDir;

    $gCurrentConfig = new MailBot::Config($gRoot);
}

sub current
{
    $gCurrentConfig or croak "have not yet set root";
    $gCurrentConfig;
}

sub getRoot
{
    $gRoot;
}

sub getIni
{
    my $ini = shift -> {INI};
    croak "unloaded inifile" if ! defined $ini;
    $ini;
}

sub getMaxSize
{
    shift -> getIniVal("load","maxsize",500000);
}

sub getEnvelopeVal
{
    my $self = shift;
    my $condition = shift;
    my $param = shift;

    my $lower = lc $condition;
    $lower =~ s/ /_/g;
    my $section = "envelope.$lower";

    # check if we should use default
    my @aSection = $self -> getIni -> Sections;
    grep($_ eq $section,@aSection) or
	$section = "envelope.";

    $self -> getIniVal($section,$param);
}

sub getIniVal
{
    my $ini = shift -> getIni;
    my ($section,$param,$default) = @_;
    my $val = scalar($ini -> val($section,$param));
    return $val if defined $val;
    $default;
}

sub getSplitSize
{
    shift -> getIniVal('smtp','split_size');
}

sub getSplitMultiplier
{
    shift -> getIniVal('smtp','split_multiplier');
}

sub neverSend
{
    shift -> getIniVal('smtp','never_send');
}

sub new
{
    my $type = shift;
    my $root = shift;

    my $self = {
	INTERACTIVE => 0
    };

    my $mailBotConfigFile = "$root/config/mailbot.config";
    my $iniConf = new MailBot::IniConf -file => $mailBotConfigFile;
    $$self{INI} = $iniConf;

    bless($self,$type);

    $self;
}

sub isInteractive
{
    my $self = shift;
    $self -> {INTERACTIVE};
}

sub getLocalSpool
{
    my $spoolDir = shift -> getDir('spool');

    my $progName = $0;
    $progName =~ s/.+\///;
    $progName =~ s/\.pl$//;
    return "$spoolDir/rfc822.in.$progName";
}

sub getMailSpool
{
    shift -> {SPOOL};
}

sub setMailSpool
{
    my $self = shift;
    $self -> {SPOOL} = shift;
}

sub setInteractive
{
    my $self = shift;
    $self -> {INTERACTIVE} = 1;
}

sub isCGI
{
    my $self = shift;
    $self -> {CGI};
}

sub setCGI
{
    my $self = shift;
    $self -> {CGI} = 1;
}

sub getBody
{
    shift -> {BODY};
}

sub getBounceAddr
{
    my $ini = shift -> {INI};
    return undef if ! defined $ini;
    $ini -> val('address','bounce');
}

sub setBody
{
    my $self = shift;
    $self -> {BODY} = shift;
}

sub getSubject
{
    shift -> {SUBJECT};
}

sub setSubject
{
    my $self = shift;
    $self -> {SUBJECT} = shift;
}

sub getDir
{
    my $self = shift;
    my $dirName = shift;
    
    my $path = "$gRoot/$dirName";
    if (! -d $path)
    {
	mkdir($path,0777) or die "could not mkdir $path: $!";
    }
    $path;
}

sub getSaveDir
{
    shift -> getDir('save');
}

sub getQuotaDir
{
    shift -> getDir('quota');
}

sub getPubDir
{
    "$gRoot/pub";
}

sub getLogDir
{
    shift -> getDir('log');
}

sub log
{
    my $self = shift;
    my $string = join('',@_);
    chomp($string);
    $string =~ s/\n/\\n/g;

    my $logDir = $self -> getLogDir();
    my $logFile = "$logDir/log";

    my $logString = scalar(localtime()) . ": " . $string . "\n";

    if (open(LOG,">>$logFile"))
    {
	print LOG $logString;
	close(LOG);
    }
    else
    {
	print STDERR $logString;
    }
}

1;
