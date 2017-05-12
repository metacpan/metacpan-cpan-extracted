use strict;
use warnings;
use Lingua::JA::Expand;

print "Yahoo API appIDを入力してください（2011年4月以降、有料版でないとうまく動作しなくなりました) : ";
my $appid = <STDIN>;
chomp $appid;

die("Yahoo API appIDが入力されていません") if !$appid;

my %conf = (
    yahoo_api_appid   => $appid,
    yahoo_api_premium => 1,
);

loop();

sub loop {
    print "Input keyword: ";
    my $keyword = <STDIN>;
    my $exp     = Lingua::JA::Expand->new(%conf);
    my $result  = $exp->expand($keyword);
	exit if !$result;
    print "-" x 100, "\n";
    for ( sort { $result->{$b} <=> $result->{$a} } keys %$result ) {
        print sprintf( "%0.5f", $result->{$_} ), "\t", $_, "\n";
    }
    print "\n";
    loop();
}