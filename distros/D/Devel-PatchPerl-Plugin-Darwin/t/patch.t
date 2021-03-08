use Test::More;
use File::Temp;
use File::Fetch;
use File::Path;
use Archive::Tar;
use Devel::PatchPerl;
use Devel::PatchPerl::Hints qw[hint_file];

$ENV{PERL5_PATCHPERL_PLUGIN} = 'Darwin';
my @versions = ('5.6.2', '5.8.9', '5.10.1', '5.11.1', '5.12.5', '5.14.4', '5.16.3', '5.18.4',
		'5.20.3', '5.22.4', '5.24.4', '5.26.3', '5.28.3', '5.30.3', '5.32.1');
my $os = $^O;

for my $v (@versions) {
    my $stderr;
    open my $stdtmp, '>&', STDERR;
    close STDERR;
    open STDERR, '>', \$stderr;

    my $temp = File::Temp->newdir();
    my $url = "http://www.cpan.org/src/5.0/perl-$v.tar.gz";
    my $ff = File::Fetch->new(uri => $url);
    my $targz = $ff->fetch( to => $temp->dirname ) or die $ff->error();
    my $tar = Archive::Tar->new($targz) or die;
    $tar->setcwd($temp->dirname);
    $tar->extract or die;
    my $srcdir = $temp->dirname . "/perl-$v";
    my $result = Devel::PatchPerl->patch_source($v, $srcdir);

    close STDERR;
    open STDERR, '>&', $stdtmp;
    close $stdtmp;

    my ($file, $data) = hint_file($os);

    is($result, 1, "$v: test result");
    is($stderr, "Patching 'hints/$file'\n", "$v: stderr");
}

done_testing();
