use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Fatal;
use Probe::Perl ();
use EBook::EPUB::Check;

chomp( my $java_version = qx(java -version 2>&1) );

diag("\n\n");
diag("------------ Java INFO ------------\n");
diag("$java_version\n");
diag("------------ END OF Java INFO -----\n");
diag("\n");

my $report = epubcheck('epub/valid.epub')->report;
plan skip_all => $report if $report =~ /Error occurred during initialization of VM/i;

subtest 'valid epub file' => sub {
    my $result = epubcheck('epub/valid.epub');
    ok($result->is_valid);
    like($result->report, qr/No errors or warnings detected/i);
    note($result->report);
};

subtest 'invalid epub file' => sub {
    my $result = epubcheck('epub/invalid.epub');
    ok( ! $result->is_valid );
    like($result->report, qr/Check finished with warnings or errors/i);
    note($result->report);
};

subtest 'epub file not found' => sub {
    my $result;
    warning_is { $result = epubcheck('epub/hoge.epub'); } 'epub file not found';
    ok( ! $result->is_valid );
    is($result->report, '');
};

subtest 'jar file not found' => sub {
    like(exception { epubcheck('epub/valid.epub', 'hoge') }, qr/jar file not found/);
};

subtest 'valid jar file path' => sub {
    my $result = epubcheck('epub/valid.epub', $EBook::EPUB::Check::JAR);
    ok($result->is_valid);
    like($result->report, qr/No errors or warnings detected/i);
    note($result->report);
};

subtest 'emtpy epub file path' => sub {
    my $result;
    warning_is { $result = epubcheck(''); } 'epub file not found';
    ok( ! $result->is_valid );
    is($result->report, '');
};

subtest 'undefined epub file path' => sub {
    my $result;
    warning_is { $result = epubcheck(undef); } 'epub file not found';
    ok( ! $result->is_valid );
    is($result->report, '');
};

subtest 'command line interface' => sub {
    my $perl = Probe::Perl->find_perl_interpreter;

    my $out1 = qx($perl script/epubcheck epub/valid.epub 2>&1);
    like($out1, qr/No errors or warnings detected/i);

    my $out2 = qx($perl script/epubcheck -out output.xml epub/valid.epub 2>&1);
    like($out2, qr/Assessment XML document was saved in: output.xml/i);
};

done_testing;
