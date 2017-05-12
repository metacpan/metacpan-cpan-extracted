use strict;
use warnings;
use Test::More;
use Path::Class;

my $dir = Path::Class::tempdir(CLEANUP => 1);
copy_dist_files_into_dir($dir);
chdir $dir;

my $status = system 'dzil build >/dev/null 2>/dev/null';
is $status << 0, 0, 'zero exit status';

my $dist_dir = $dir->subdir('File-Munging-Script-0.42');
ok -d $dist_dir,
    'dist dir';

ok -f $dir->file('File-Munging-Script-0.42.tar.gz'),
    'dist tar.gz';

my $packed_script_file = $dist_dir->file('bin/file_munging.pl');
my $packed_version = `perl $packed_script_file`;
is $packed_version, '0.42', 'fatpacked libs included PkgVersion version';

done_testing;


sub copy_dist_files_into_dir {
    my $dir = shift;

    foreach my $subdir (qw(t lib/File/Munging bin)) {
        $dir->subdir($subdir)->mkpath;
    }

    $dir->file('dist.ini')->spew(dist_ini());
    $dir->file('lib/File/Munging/Script.pm')->spew(script_pm());
    $dir->file('bin/file_munging.pl')->spew(script());
}

sub dist_ini { <<'DIST_INI' }
name    = File-Munging-Script
version = 0.42
author  = CPAN Tester
license = Perl_5
copyright_holder = CPAN Tester

[@Classic]
[PkgVersion]

[FatPacker]
script = bin/file_munging.pl
DIST_INI

sub script_pm { <<'SCRIPT_PM' }
package File::Munging::Script;

# ABSTRACT: File Munging Script

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub run {
    my $self = shift;

    print "$VERSION";
}

1;
SCRIPT_PM

sub script { <<'NO_DEPS_PL' }
#!/usr/bin/env perl
use strict;
use warnings;
use File::Munging::Script;

File::Munging::Script->new->run;

NO_DEPS_PL
