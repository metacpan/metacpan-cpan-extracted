###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;


package Kook::Commands;
use Exporter 'import';
our @EXPORT_OK = qw(sys sys_f echo echo_n cp cp_p cp_r cp_pr mkdir mkdir_p rm rm_r rm_f rm_rf rmdir mv store store_p cd edit);
use Data::Dumper;
use File::Basename;     # basename()
use File::Path;         # mkpath(), rmtree()
use Cwd;                # getcwd()

use Kook::Config;
use Kook::Misc ('_report_cmd');
use Kook::Util ('read_file', 'write_file', 'has_metachar', 'flatten', 'glob2');


sub _msg {
    my ($msg) = @_;
    return $Kook::Config::MESSAGE_PROMPT . $msg . "\n";
}

sub _pr {
    my ($command) = @_;
    #print _msg($command);
    print $Kook::Config::COMMAND_PROMPT, $command, "\n";
}

sub _prepare {
    my ($cmd, @filenames) = @_;
    _report_cmd("$cmd " . join(' ', @filenames)) if $cmd;
    my @arr;
    #my @fnames = map { has_metachar($_) ? ((@arr = glob2($_)) ? @arr : $_) : $_ } @filenames;
    my @fnames = map { (@arr = glob2($_)) ? @arr : $_ } flatten(@filenames);
    return @fnames;
}

sub _touch {
    my ($src, $dst) = @_;
    my $mtime = (stat $src)[9];
    utime $mtime, $mtime, $dst;
}


## invoke os-depend command. if command failed then die.
## ex.
##   sys("gcc -o hello hello.o");
sub sys {
    my $command = shift @_;
    _pr($command) if $Kook::Config::VERBOSE;
    return 0      if $Kook::Config::NOEXEC;
    my $status = system($command);
    $status == 0  or die "*** command failed (status=$status).\n";
    return $status;
}

## similar to sys() but never die even when os-command failed.
sub sys_f {
    my $command = shift @_;
    _pr($command) if $Kook::Config::VERBOSE;
    return 0      if $Kook::Config::NOEXEC;
    return system($command);
}


## print argument
sub echo {
    _echo("echo", "echo", 0, @_);
}

## similar to echo() but not print newline
sub echo_n {
    _echo("echo", "echo", 1, @_);
}

sub _echo {
    my ($func, $cmd, $n, @filenames) = @_;
    @filenames = _prepare $cmd, @filenames;
    return if $Kook::Config::NOEXEC;
    my $i = 0;
    for (@filenames) {
        print " " if $i++;
        print $_;
    }
    print "\n" unless $n;
}


## copy files or directories
sub cp {
    _cp('cp',    'cp',     0, 0, @_);
}

sub cp_p {
    _cp('cp_p',  'cp -p',  1, 0, @_);
}

sub cp_r {
    _cp('cp_r',  'cp -r',  0, 1, @_);
}

sub cp_pr {
    _cp('cp_pr', 'cp -pr', 1, 1, @_);
}

sub _cp {
    my ($func, $cmd, $p, $r, @filenames) = @_;
    @filenames = _prepare $cmd, @filenames;
    return if $Kook::Config::NOEXEC;
    my $n = @filenames;
    $n >= 2  or die "func: at least two file or directory names are required.";
    my $dst = pop @filenames;
    #if ($n == 2) {
    #    -e $src  or "$func: $src: no such file or directory.";
    #    if (-d $src) {
    #        $r  or "$func: $src: no such file or directory.";
    #        _copy_dir_to_dir($src, $dst, $func, $cmd, $p);
    #    }
    #    elsif (-d $dst) {
    #        _copy_file_to_dir($src, $dst, $func, $cmd, $p);
    #    }
    #    else {
    #        _copy_file_to_file($src, $dst, $func, $cmd, $p);
    #    }
    #}
    #else {    # $n > 2
    #    -e $dst  or "$func: $dst: directory not found.";
    #    -d $dst  or "$func: $dst: not a directory.";
    #    for my $src (@filenames) {
    #        -e $src  or die "$func: $src: no such file or directory.";
    #        if (-d $src) {
    #            $r  or die "$func: $src: cannot copy directory (use 'cp_r' instead).";
    #            _copy_dir_to_dir($src, $dst, $func, $cmd, $p);
    #        }
    #        else {
    #            _copy_file_to_dir($src, $dst, $func, $cmd, $p);
    #        }
    #    }
    #}
    if ($n == 2) {
        my $src = $filenames[0];
        ! (-d $src && -f $dst)  or die "$func: $src: cannot copy directory to file.\n";
    }
    else {   # $n > 2
        -e $dst  or die "$func: $dst: directory not found.\n";
        -d $dst  or die "$func: $dst: not a directory.\n";
    }
    my $to_dir = -d $dst;
    for my $src (@filenames) {
        -e $src  or die "$func: $src: no such file or directory.\n";
        if (-d $src) {
            $r  or die "$func: $src: cannot copy directory (use 'cp_r' instead).\n";
            _copy_dir_to_dir($src, $dst, $func, $p);
        }
        elsif ($to_dir) {
            _copy_file_to_dir($src, $dst, $func, $p);
        }
        else {
            _copy_file_to_file($src, $dst, $func, $p);
        }
    }
}

sub _copy_file_to_file {
    my ($src, $dst, $func, $p) = @_;
    open(my $in,  '<', $src)  or die "$func: $src: $!";
    open(my $out, '>', $dst)  or die "$func: $dst: $!";
    my ($buf, $size) = (undef, 2*1024*1024);
    print $out $buf while (read $in, $buf, $size);
    close($in);
    close($out);
    _touch($src, $dst) if $p;
}

sub _copy_file_to_dir {
    my ($src, $dst, $func, $p) = @_;
    _copy_file_to_file($src, $dst . '/' . basename($src), $func, $p);
}

sub _copy_dir_to_dir {
    my ($src, $dst, $func, $p) = @_;
    $dst = $dst . '/' . basename($src) if -d $dst;
    ! -e $dst  or die "$func: $dst: already exists.\n";
    mkdir($dst)  or die "$func: $dst: $!";
    opendir(my $DIR, $src)  or die "$func: $src: $!";
    my @entries = readdir($DIR);
    closedir($DIR);
    for my $e (@entries) {
        next if $e eq '.' || $e eq '..';
        my $fpath = "$src/$e";
        -d $fpath ? _copy_dir_to_dir($fpath, $dst, $func, $p)
                  : _copy_file_to_dir($fpath, $dst, $func, $p);
    }
    _touch($src, $dst) if $p;
}


## create directory
sub mkdir {
    _mkdir('mkdir', 'mkdir', 0, @_);
}

sub mkdir_p {
    _mkdir('mkdir_p', 'mkdir -p', 1, @_);
}

sub _mkdir {
    my ($func, $cmd, $p, @dirnames) = @_;
    @dirnames = _prepare($cmd, @dirnames);
    return if $Kook::Config::NOEXEC;
    @dirnames  or die "$func: directory name required.\n";
    if ($p) {
        for my $dname (@dirnames) {
            -d $dname and next;
            -e $dname and die "$func: $dname: already exists.\n";
            mkpath($dname)  or die "$func: $dname: $!\n";
        }
    }
    else {
        for my $dname (@dirnames) {
            -e $dname and die "$func: $dname: already exists.\n";
            CORE::mkdir($dname)  or die "$func: $dname: $!\n";
        }
    }
}


## remove files or directories
## ex.
##   rm_rf "*/*.o", "doc/*.html", "tmp";
sub rm {
    _rm('rm', 'rm', 0, 0, @_);
}

sub rm_r {
    _rm('rm_r', 'rm -r', 1, 0, @_);
}

sub rm_f {
    _rm('rm_f', 'rm -f', 0, 1, @_);
}

sub rm_rf {
    _rm('rm_rf', 'rm -rf', 1, 1, @_);
}

sub _rm {
    my ($func, $cmd, $r, $f, @filenames) = @_;
    @filenames = _prepare($cmd, @filenames);
    return if $Kook::Config::NOEXEC;
    @filenames  or die "$func: directory name required.\n";
    for my $fname (@filenames) {
        if (-d $fname) {
            $r  or die "$func: $fname: can't remove directory (try 'rm_r' instead).\n";
            rmtree($fname)  or die "$func: $fname: $!";
        }
        elsif (-e $fname) {
            unlink($fname)  or die "$func: $fname: $!";
        }
        else {
            $f  or die "$func: $fname: not found.\n";
        }
    }
}


## remove directory
sub rmdir {
    _rmdir('rmdir', 'rmdir', @_);
}

sub _rmdir {
    my ($func, $cmd, @dirnames) = @_;
    @dirnames = _prepare($cmd, @dirnames);
    return if $Kook::Config::NOEXEC;
    @dirnames  or die "$func: directory name required.\n";
    for my $dname (@dirnames) {
        -e $dname  or die "$func: $dname: not found.\n";
        -d $dname  or die "$func: $dname: not a directory.";
        CORE::rmdir($dname)  or die "$func: $dname: $!\n";
    }
}


## rename or move files or directories
## ex.
##    mv "src/*/*.pl", "test/*.pl", "dist";
sub mv {
    _mv('mv', 'mv', @_);
}

sub _mv {
    my ($func, $cmd, @filenames) = @_;
    @filenames = _prepare($cmd, @filenames);
    return if $Kook::Config::NOEXEC;
    my $n = @filenames;
    if ($n < 2) {
        die "$func: at least two file or directory names are required.\n";
    }
    elsif ($n == 2) {
        my ($src, $dst) = @filenames;
        if    (! -e $src) { die "$func: $src: not found.\n";       }
        elsif (! -e $dst) { rename($src, $dst)                     or die "$func: $!"; } # any to new
        elsif (-d $dst)   { rename($src, $dst.'/'.basename($src))  or die "$func: $!"; } # any to dir
        elsif (-d $src)   { die "$func: $dst: not a directory.\n";                     } # dir to file
        else              { rename($src, $dst)                     or die "$func: $!"; } # file to file
    }
    else {
        my $dst = pop @filenames;
        -e $dst  or die "$func: $dst: directory not found.\n";
        -d $dst  or die "$func: $dst: not a directory.\n";
        for my $src (@filenames) {
            -e $src  or die "$func: $src: not found.\n";
        }
        for my $src (@filenames) {
            rename($src, $dst.'/'.basename($src))  or die "$func: $!";
        }
    }
}


## copy files to directory with keeping file path
## ex.
##   $dir = "dist/project-1.2.3";
##   mkdir_p $dir;
##   store "README", "src", "test", "doc", $dir;
sub store {
    _store('store', 'store', 0, @_);
}

sub store_p {
    _store('store_p', 'store -p', 1, @_);
}

sub _store {
    my ($func, $cmd, $p, @filenames) = @_;
    my @fnames = _prepare($cmd, @filenames);
    return if $Kook::Config::NOEXEC;
    my $n = @fnames;
    $n >= 2  or die "$func: at least two file or directory names are required.\n";
    my $basedir = pop @fnames;
    -e $basedir  or die "$func: $basedir: directory not found.\n";
    -d $basedir  or die "$func: $basedir: not a directory.\n";
    for my $src (@fnames) {
        -e $src  or die "$func: $src: not found.\n";
    }
    for my $src (@fnames) {
        my $dst = $basedir.'/'.$src;
        if (-d $src) {
            mkpath($dst)  or die "$func: $!" unless -d $dst;
        }
        else {
            my $dirname = dirname($dst);
            mkpath($dirname)  or die "$func: $!" unless -d $dirname;
            _copy_file_to_file($src, $dst);
            _touch($src, $dst) if $p;
        }
    }
}


## change directory
## ex.
##   cd "dist";
##   cd "dist", sub { rm "*.o" };
sub cd {
    _cd('cd', 'cd', @_);
}

sub _cd {
    my ($func, $cmd, $dir, $closure) = @_;
    my @dirs = _prepare($cmd, $dir);
    $dir = $dirs[0]  or die "$func: directory name required.\n";
    -e $dir  or die "$func: $dir: directory not found.\n";
    -d $dir  or die "$func: $dir: not a directory.\n";
    my $cwd = getcwd();
    CORE::chdir($dir)  or die "$func: $!";
    if ($closure) {
        ref($closure) eq "CODE"  or die "$func: 2nd argument should be closure.\n";
        $_ = $dir;
        $closure->();
        _report_cmd("$cmd -  # back to $cwd");
        CORE::chdir $cwd  or die "$func: $!";
    }
}


## edit files
## ex.
##   edit "dist/src/*/*.pl", sub { s/\$RELEASE\$/1.2.3/g; $_ };
sub edit {      # or sub edit (&@) { ...
    #my ($closure, @filenames) = @_;
    my $closure = pop @_;
    ref($closure) eq 'CODE'  or die "edit(): last argument should be closure.\n";
    my (@filenames) = @_;
    my @fnames = _prepare('edit', @filenames);
    return if $Kook::Config::NOEXEC;
    my $errmsg = "edit(): closure should return non-empty string but %s returned.\n";
    for my $fname (@fnames) {
        next unless -f $fname;
        $_ = read_file($fname);
        my $s = &{$closure}();
        defined($s)     or die sprintf($errmsg, 'undef');
        length($s) > 0  or die sprintf($errmsg, 'empty string');
        "$s" ne "0"     or die sprintf($errmsg, 'zero');
        my $is_number = $s =~ /\A\d+(\.\d+)?\Z/ && Dumper($s) !~ /['"]/;
        ! $is_number    or die sprintf($errmsg, $s);
        write_file($fname, $s);
    }
}



1;
