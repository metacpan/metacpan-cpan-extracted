use 5.010001;
use ExtUtils::MakeMaker;
use FindBin qw($Bin);
use File::Copy;

My_WriteMakefile(
    NAME              => 'HTTP::UA::Parser',
    VERSION_FROM      => 'lib/HTTP/UA/Parser.pm',
    ABSTRACT_FROM  => 'lib/HTTP/UA/Parser.pm',
    EXE_FILES    => ['script/ua_parser'],
    PREREQ_PM         => {
        'LWP::UserAgent' => 0,
        'YAML::Tiny' => 0
    },
    LICENSE        => 'perl',
    AUTHOR         => 'Mamod Mehyar <mamod.mehyar@gmail.com>',
    META_MERGE => {
        resources => {
            repository => 'git://github.com/ua-parser/uap-perl.git',
            bugtracker => 'https://github.com/ua-parser/uap-perl/issues',
        }
    }
);

sub My_WriteMakefile {
    my %params=@_;
    my $regexes = './uap-core/regexes.yaml';
    my $regexes2 = $Bin.'/regexes.yaml';
    my $dest = $Bin.'/lib/HTTP/UA/Parser';
    if (-e $regexes) {
        copy($regexes, $dest) or die "File cannot be copied.";
    } elsif (-e $regexes2) {
        copy($regexes2, $dest) or die "File cannot be copied.";
    } else {
        print "Can't locate regexes.yaml file\n";
        print "We will try to fetch it from a remote server\n";
        my $regexContent = getRegexes();
        open my $file,'>',$regexes2 or die "can't open file $!";
        print $file $regexContent;
        close $file;
        copy($regexes2, $dest) or die "File cannot be copied.";
        print "regexes.yaml downloaded successfully\n";
    }

    WriteMakefile(%params);
}

##also update in script/ua_parser if changed here
sub getRegexes {
    my $response;
    my $stream;
    my $url = 'https://raw.githubusercontent.com/ua-parser/uap-core/master/regexes.yaml';

    ## trying curl
    print "Trying curl\n";
    open $stream, "-|", "curl $url";
    while(<$stream>) { $response .= "$_" };

    ##trying wget
    if (!$response){
        print "Trying wget\n";
        open $stream, "-|", "wget $url";
        while(<$stream>) { $response .= "$_" };
    }

    ##trying lwp-request
    if (!$response){
        print "Trying lwp-request\n";
        open $stream, "-|", "lwp-request $url";
        while(<$stream>) { $response .= "$_" };
    }

    return $response if $response;
    print "Trying to fetch using LWP::UserAgent\n";
    eval "use LWP::UserAgent";
    if ($@){
        print "We couldn't locate LWP::UserAgent Module\n";
        print "LWP::UserAgent required to fetch regexes.yaml from server\n";
        print "Please install it or get regexes.yaml file manually from\n";
        print "$url\n";
        print "and place it in the root folder of this distro\n";
        print "then run Makefile.PL again\n";
        exit;
    }
    my $ua = LWP::UserAgent->new;
    $ua->timeout(5);
    $ua->env_proxy();
    $response = $ua->get($url);
    if ($response->is_success) {
        return $response->content;
    } else {
        print "Request aborted\n";
        exit;
    }
}
