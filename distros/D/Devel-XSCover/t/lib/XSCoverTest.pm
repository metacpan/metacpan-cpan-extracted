package XSCoverTest;

use 5.020;
use strict;
use warnings;

use File::Copy ();
use File::Find ();
use File::Path ();
use File::Spec ();
use File::Temp ();

our $VERSION = '0.01';

sub spike_dir { File::Spec->catdir('xt', 'spike') }

sub copy_spike {
    my $spike = spike_dir();
    my $dir   = File::Temp->newdir;
    File::Find::find({
        no_chdir => 1,
        wanted   => sub {
            (my $rel = File::Spec->abs2rel($_, $spike)) =~ s{\\}{/}g;
            return if $rel eq '.';
            if (-d $_) {
                $File::Find::prune = 1 if $rel =~ /^(?:blib|cover_db)/;
                return;
            }
            return if $rel =~ /\.(?:o|gcno|gcda|gcov|bs|c)\z/ && $rel ne 'src/helper.c';
            return if $rel eq 'baseline.txt' || $rel =~ /^(?:Makefile$|MYMETA|pm_to_blib)/;
            my $to = File::Spec->catfile($dir, $rel);
            my ($vol, $d) = File::Spec->splitpath($to);
            File::Path::make_path(File::Spec->catpath($vol, $d, ''));
            File::Copy::copy($_, $to) or die "copy $_: $!";
        },
    }, $spike);
    return $dir;
}

sub fake_script {
    my ($dir, $name, $body) = @_;
    my $path = File::Spec->catfile($dir, $name);
    open my $fh, '>', $path or die "$path: $!";
    print $fh "#!/bin/sh\n$body\n";
    close $fh;
    chmod 0755, $path;
    return $path;
}

1;

sub cover_script {
    require Config;
    my ($cover) = grep { -f $_ } map { File::Spec->catfile($_, 'cover') }
        grep { defined && length } @Config::Config{qw(installsitescript installsitebin installscript)}, File::Spec->path;
    return $cover;
}

sub report_db {
    require Cwd;
    require Devel::XSCover::Gcov;
    require Devel::XSCover::XS;
    require Devel::XSCover::DB;
    my $dir = 't/fixtures/spike';
    my $tmp = File::Temp->newdir;
    my $db  = Cwd::abs_path("$tmp");
    my $reader = Devel::XSCover::Gcov->new(dir => $dir, silent => 1, generated => ['Spike.c']);
    my @objects;
    for my $name (qw(Spike.gcov.txt helper.gcov.txt)) {
        my $f = File::Spec->catfile(qw(t fixtures gcov llvm), $name);
        open my $fh, '<', $f or die "$f: $!";
        my $text = do { local $/; <$fh> };
        close $fh;
        my ($kept, $aside) = $reader->filter($reader->parse($text));
        push @objects, { object => $name, files => $kept, generated => $aside };
    }
    my @maps   = Devel::XSCover::XS->new(dir => $dir)->read;
    my $writer = Devel::XSCover::DB->new(dir => $dir, db => $db, silent => 1);
    $writer->write($writer->entries($writer->merge(@objects), @maps));
    my $perl_tmp = File::Temp->newdir;
    my $perl = Cwd::abs_path("$perl_tmp");
    File::Path::make_path(File::Spec->catdir($perl, 'lib'));
    File::Copy::copy(File::Spec->catfile(qw(t fixtures perl Spike.pm)), File::Spec->catfile($perl, 'lib', 'Spike.pm')) or die "copy: $!";
    File::Copy::copy(File::Spec->catfile(qw(t fixtures perl run.pl)), File::Spec->catfile($perl, 'run.pl')) or die "copy: $!";
    my $here = Cwd::getcwd();
    chdir $dir or die;
    {
        delete local @ENV{qw(HARNESS_PERL_SWITCHES PERL5OPT)};
        system($^X, "-MDevel::Cover=-db,$db,-silent,1,-ignore,run\\.pl", "-I$perl/lib", "$perl/run.pl") == 0 or die "the Perl fixture failed: $?";
    }
    chdir $here;
    return ($tmp, $db, $dir, $perl_tmp, $perl);
}

sub run_cover {
    my ($db, $dir, @args) = @_;
    require Cwd;
    my $cover = cover_script() or return;
    my $here  = Cwd::getcwd();
    my $lib   = Cwd::abs_path(-d 'blib/lib' ? 'blib/lib' : 'lib');
    chdir $dir or die;
    local $ENV{DEVEL_COVER_SELF}    = 1;
    local $ENV{DEVEL_COVER_OPTIONS} = "-dir,$here,+select,/Devel/Cover/Report/XSCover,+ignore,.";
    local $ENV{PERL5OPT} = "$ENV{PERL5OPT} -MDevel::Cover::Report::XSCover" if ($ENV{PERL5OPT} // '') =~ /Devel::Cover/;
    my $out = `"$^X" "-I$lib" "$cover" @{[ map { qq{"$_"} } @args ]} "$db" 2>&1`;
    chdir $here;
    return $out;
}

sub run_report {
    my ($db, $dir, @extra) = @_;
    return run_cover($db, $dir, '-nogcov', '-silent', '-report', 'XSCover', @extra);
}
