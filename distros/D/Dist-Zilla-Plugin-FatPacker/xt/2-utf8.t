use strict;
use warnings;
use utf8;
use Encode 'decode';
use Test::More;
use Path::Class;
use Unicode::Collate;

my $utf8 = "我想写的东西在中国傻了。";

my $dir = Path::Class::tempdir(CLEANUP => 1);
copy_dist_files_into_dir($dir, $utf8);
chdir $dir;

my $status = system 'dzil build >/dev/null 2>/dev/null';
is $status << 0, 0, 'zero exit status';

my $dist_dir = $dir->subdir('UTF8-Script-0.07');
ok -d $dist_dir,
    'dist dir';

my $packed_script_file = $dist_dir->file('bin/script.pl');
my $output   = safe_pipe_command(':utf8', 'perl', $packed_script_file);
my $collator = Unicode::Collate->new;
ok $collator->eq($output, $utf8), 'utf8 string is unmodified after fatpacking';


done_testing();


sub copy_dist_files_into_dir {
    my $dir  = shift;
    my $utf8 = shift;

    foreach my $subdir (qw(t lib/UTF8 bin)) {
        $dir->subdir($subdir)->mkpath;
    }

    $dir->file('dist.ini')->spew(dist_ini());
    $dir->file('lib/UTF8/Script.pm')->spew(script_pm());
    $dir->file('bin/script.pl')->spew(iomode => '>:utf8', script($utf8));
}

sub dist_ini { <<'DIST_INI' }
name    = UTF8-Script
version = 0.07
author  = CPAN Tester
license = Perl_5
copyright_holder = CPAN Tester

[@Classic]

[FatPacker]
script = bin/script.pl
DIST_INI

sub script_pm { <<'SCRIPT_PM' }
package UTF8::Script;
# ABSTRACT: UTF8 Script
1;
SCRIPT_PM

sub script { <<"SCRIPT" }
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open qw/:std :utf8/;

print "$_[0]";
SCRIPT

sub safe_pipe_command {
    my ($binmode, @cmd) = @_;

    open(my($pipe), '-|', @cmd) or die "can't run command @cmd: $!";
    binmode($pipe, $binmode);
    my $output = join('', <$pipe>);
    close($pipe);

    return $output;
}
