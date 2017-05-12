#! perl

BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
    unlink <out.04*>;
}

use Test::More (tests => 42);

use_ok(myLogger);

foreach (1..20) {
    myLogger->warn($_);
    myLogger->info($_);
}

my ($stdout,$cover);
{
    local $/ = undef;
    my $fh;
    open ($fh, "out.04_subclass");
    $stdout = <$fh>;
    open ($fh, "out.04_subclass.cover");
    $cover = <$fh>;
}

ok ($stdout, "got something on stdout");

foreach my $i (1..20) {
    like ($stdout, qr/main.main.warn.16: $i/ms, "found main.main.warn: $i");
    like ($stdout, qr/main.main.info.17: $i/ms, "found main.main.info: $i");
}

__END__

