# -*- perl -*-
# test that AutoCategorize can be used in a program that 
# uses Log::Log4perl also

BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
    unlink <out.07*>;
}

use Test::More (tests => 48);

use_ok ( Log::Log4perl );	 # qw(:easy);
use_ok ( myLogger );

sub legacy {
    my $logger = Log::Log4perl::get_logger ("main");
    $logger->error("this is err");
    $logger->warn("this is warn");
    $logger->debug("this is debug");
}

foreach (1..20) {
    myLogger->warn($_);
    myLogger->info($_);
    legacy();
}

my ($stdout,$cover);
{
    local $/ = undef;
    my $fh;
    open ($fh, "out.07_coexist");
    $stdout = <$fh>;
    open ($fh, "out.07_coexist.cover");
    $cover = <$fh>;
}

ok ($stdout, "got something on stdout");

foreach my $i (1..20) {
    like ($stdout, qr/main.main.warn.\d+: $i/ms, "found main.main.warn: $i");
    like ($stdout, qr/main.main.info.\d+: $i/ms, "found main.main.info: $i");
}


like ($stdout, qr/(main: this is err)/ms, "found legacy usage of \$logger->error()");
like ($stdout, qr/(main: this is warn)/ms, "found legacy usage of \$logger->info()");

@found = ($stdout =~ m/(main: this is err)/msg);
ok(@found == 20, "found 20 occurrences of '$1'");

@found = ($stdout =~ m/(main: this is warn)/msg);
ok(@found == 20, "found 20 occurrences of '$1'");

@found = ($stdout =~ m/(main: this is debug)/msg);
ok(@found == 0, "found 0 occurrences of 'this is debug', suppressed by config");


__END__

