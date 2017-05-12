use strict;
use warnings;
use Test::More;
use Gnuplot::Builder;
use lib "xt";
use testlib::XTUtil qw(check_process_finish);

foreach my $case (
    {label => "no arg", args => [], exp => qr{Gnuplot}},
    {label => "single arg", args => ["plot"], exp => qr{drawing plots}},
    {label => "multi args", args => ["plot", "using", "xticlabels"], exp => qr{tick labels}},
    {label => "no such help", args => ["hogehoge"], exp => qr{no help}},
) {
    note("--- ghelp: $case->{label}");
    my $message = ghelp(@{$case->{args}});
    like $message, $case->{exp}, "$case->{label}: error message seems OK";

    my @lines = split /^/, $message;
    foreach my $line (@lines[0..4]) {
        last if not defined $line;
        chomp $line;
        note($line);
    }
}

{
    note("--- example");
    is ghelp("style data"), ghelp("style", "data"), "multiple args are just joined by white spaces";
}

check_process_finish;

done_testing;
