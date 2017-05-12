use Config;
open OUTPUT, ">$ARGV[0]" or die "$ARGV[0]: $!\n";
select OUTPUT;

print << "!GROK!THIS!";
$Config{'startperl'}

my \$config_file = '/usr/local/mpopd/mpopd.conf';
!GROK!THIS!
print << '!GROK!THIS!';

# mpopdstats v1.01
# (c) Mark Tiramani 1998-2001
# mpopd utility for parsing a user's mail log file and
# printing basic reports on their pop3 usage.

$user_log_dir = "/var/log" if !-d "$user_log_dir";

if ($mailpath && !$switch) {$user_log_dir = $mailpath;}

if (!$ARGV[0]) {
        print "\nUsage: \# mpopdstats <username>\n\n";
        exit(0);
}
elsif (!-f "$user_log_dir/$ARGV[0]_log") {
        print "\nNo user-log found for: $ARGV[0]\n\n";
        exit(0);
}

open MPOPLOG, "$user_log_dir/$ARGV[0]_log";

$_ = <MPOPLOG>;
($fdate,$connect) = split /\t/,$_;
++$cnt;

while (<MPOPLOG>) {
        if (/^RETRieved\t/) {
                ($retr,$bytes,$date) = split /\t/, $_;
                $totalbytes += $bytes;
        }
        ++$cnt if /CONNECTION OPENED/;
}

close MPOPLOG;

$totalbytes = &CommasInNumber($totalbytes);

print "\nmpop stats for $ARGV[0]\n\nfrom: $fdate\tto: $date\n\n";
print "Total connects:\t\t$cnt\n\n";
print "Total bytes sent:\t$totalbytes\n\n";

############################################################

sub CommasInNumber {
    ($n) = @_;
        ($in,$dec) = split /\./, $n;
        while ($in =~ s/(\d+)(\d{3})/$1/g) {
                $nn = $nn.",".$2;
        }
        #$dec = "00" unless $dec;
        $num = $in.$nn; #.".".$dec;
    $num;
}
!GROK!THIS!
