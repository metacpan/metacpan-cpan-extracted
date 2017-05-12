#!/usr/bin/perl -w 

# Tests whether or not the system can generate a tarball snapshot

use Test::More;
use Archive::Tar;
use File::Path;
use File::Spec::Functions qw(rel2abs catdir);

# for my $key (sort {$a cmp $b} keys %ENV) {
#     diag("$key: $ENV{$key}");
# }

my @Mod_Files = qw(XML/Simple.pm XML/SAX.pm XML/NamespaceSupport.pm);
plan tests => 4;

mkpath rel2abs "t/rootdir";
END { rmtree rel2abs "t/rootdir" }

# test the packager's ability to build the modules
system( "$^X -Iblib/lib bin/megadistro --clean --force --build-only --modlist=t/test.list --rootdir=t/rootdir" );
my ( $year, $month, $day ) = (localtime)[5,4,3];
my $date = sprintf "%02d%02d%02d", $year + 1900, $month + 1, $day;
my $tarball = catdir(rel2abs('t/rootdir'),"megadistro-$date.tar.gz");
ok( -e $tarball, "build src" );

my $tar = Archive::Tar->new;
$tar->read($tarball, 1) || diag $tar->error;
my @files = $tar->list_files;
# diag("Files: @files");

foreach my $file (@Mod_Files) {
    ok( grep(m{\Q$file\E$}, @files), "file is in tarball" );
}
