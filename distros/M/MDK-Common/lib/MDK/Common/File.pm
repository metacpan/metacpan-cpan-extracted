package MDK::Common::File;

=head1 NAME

MDK::Common::File - miscellaneous file/filename manipulation functions

=head1 SYNOPSIS

    use MDK::Common::File qw(:all);

=head1 EXPORTS

=over

=item dirname(FILENAME)

=item basename(FILENAME)

returns the dirname/basename of the file name

=item cat_(FILES)

returns the files contents: in scalar context it returns a single string, in
array context it returns the lines.

If no file is found, undef is returned

=item cat_or_die(FILENAME)

same as C<cat_> but dies when something goes wrong

=item cat_utf8(FILES)

same as C(<cat_>) but reads utf8 encoded strings

=item cat_utf8_or_die(FILES)

same as C(<cat_or_die>) but reads utf8 encoded strings

=item cat__(FILEHANDLE REF)

returns the file content: in scalar context it returns a single string, in
array context it returns the lines

=item output(FILENAME, LIST)

creates a file and outputs the list (if the file exists, it is clobbered)

=item output_utf8(FILENAME, LIST)

same as C(<output>) but writes utf8 encoded strings

=item secured_output(FILENAME, LIST)

likes output() but prevents insecured usage (it dies if somebody try
to exploit the race window between unlink() and creat())

=item append_to_file(FILENAME, LIST)

add the LIST at the end of the file

=item output_p(FILENAME, LIST)

just like C<output> but creates directories if needed

=item output_with_perm(FILENAME, PERMISSION, LIST)

same as C<output_p> but sets FILENAME permission to PERMISSION (using chmod)

=item mkdir_p(DIRNAME)

creates the directory (make parent directories as needed)

=item rm_rf(FILES)

remove the files (including sub-directories)

=item cp_f(FILES, DEST)

just like "cp -f"

=item cp_af(FILES, DEST)

just like "cp -af"

=item cp_afx(FILES, DEST)

just like "cp -afx"

=item linkf(SOURCE, DESTINATION)

=item symlinkf(SOURCE, DESTINATION)

=item renamef(SOURCE, DESTINATION)

same as link/symlink/rename but removes the destination file first

=item touch(FILENAME)

ensure the file exists, set the modification time to current time

=item all(DIRNAME)

returns all the file in directory (except "." and "..")

=item all_files_rec(DIRNAME)

returns all the files in directory and the sub-directories (except "." and "..")

=item glob_(STRING)

simple version of C<glob>: doesn't handle wildcards in directory (eg:
*/foo.c), nor special constructs (eg: [0-9] or {a,b})

=item substInFile { CODE } FILENAME

executes the code for each line of the file. You can know the end of the file
is reached using C<eof>

=item expand_symlinks(FILENAME)

expand the symlinks in the absolute filename:
C<expand_symlinks("/etc/X11/X")> gives "/usr/bin/Xorg"

=item openFileMaybeCompressed(FILENAME)

opens the file and returns the file handle. If the file is not found, tries to
gunzip the file + .gz

=item catMaybeCompressed(FILENAME)

cat_ alike. If the file is not found, tries to gunzip the file + .gz

=back

=head1 SEE ALSO

L<MDK::Common>

=cut

use File::Sync qw(fsync);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(dirname basename cat_ cat_utf8 cat_or_die cat_utf8_or_die cat__ output output_p output_with_perm append_to_file linkf symlinkf renamef mkdir_p rm_rf cp_f cp_af cp_afx touch all all_files_rec glob_ substInFile expand_symlinks openFileMaybeCompressed catMaybeCompressed);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub dirname { local $_ = shift; s|[^/]*/*\s*$||; s|(.)/*$|$1|; $_ || '.' }
sub basename { local $_ = shift; s|/*\s*$||; s|.*/||; $_ }
sub cat_ { my @l = map { my $F; open($F, '<', $_) ? <$F> : () } @_; wantarray() ? @l : join '', @l }
sub cat_utf8 { my @l = map { my $F; open($F, '<:utf8', $_) ? <$F> : () } @_; wantarray() ? @l : join '', @l }
sub cat_or_die { open(my $F, '<', $_[0]) or die "can't read file $_[0]: $!\n"; my @l = <$F>; wantarray() ? @l : join '', @l }
sub cat_utf8_or_die { open(my $F, '<:utf8', $_[0]) or die "can't read file $_[0]: $!\n"; my @l = <$F>; wantarray() ? @l : join '', @l }
sub cat__ { my ($f) = @_; my @l = <$f>; wantarray() ? @l : join '', @l }
sub output { my $f = shift; open(my $F, ">$f") or die "output in file $f failed: $!\n"; print $F $_ foreach @_; fsync($F); 1 }
sub output_utf8 { my $f = shift; open(my $F, '>:utf8', $f) or die "output in file $f failed: $!\n"; print $F $_ foreach @_; fsync($F); 1 }
sub append_to_file { my $f = shift; open(my $F, ">>$f") or die "append to file $f failed: $!\n"; print $F $_ foreach @_; fsync($F); 1 }
sub output_p { my $f = shift; mkdir_p(dirname($f)); output($f, @_) }
sub output_with_perm { my ($f, $perm, @l) = @_; mkdir_p(dirname($f)); output($f, @l); chmod $perm, $f }
sub linkf    { unlink $_[1]; link    $_[0], $_[1] }
sub symlinkf { unlink $_[1]; symlink $_[0], $_[1] }
sub renamef  { unlink $_[1]; rename  $_[0], $_[1] }

sub secured_output { 
    my ($f, @l) = @_;
    require POSIX;
    unlink($f); 
    sysopen(my $F, $f, POSIX::O_CREAT() | POSIX::O_EXCL() | POSIX::O_RDWR()) or die "secure output in file $f failed: $! $@\n";
    print $F $_ foreach @l; 
    1;
} 

sub mkdir_p {
    my ($dir) = @_;
    if (-d $dir) {
	# nothing to do
    } elsif (-e $dir) {
	die "mkdir: error creating directory $dir: $dir is a file and i won't delete it\n";
    } else {
	mkdir_p(dirname($dir));
	mkdir($dir, 0755) or die "mkdir: error creating directory $dir: $!\n";
    }
    1;
}

sub rm_rf {
    foreach (@_) {
	if (!-l $_ && -d $_) {
	    rm_rf(glob_($_));
	    rmdir($_) or die "can't remove directory $_: $!\n";
	} else { 
	    unlink $_ or die "rm of $_ failed: $!\n";
	}
    }
    1;
}

sub cp_with_option {
    my $option = shift @_;
    my $keep_special = $option =~ /a/;

    my $dest = pop @_;

    @_ or return;
    @_ == 1 || -d $dest or die "cp: copying multiple files, but last argument ($dest) is not a directory\n";

    foreach my $src (@_) {
	my $dest = $dest;
	-d $dest and $dest .= '/' . basename($src);

	unlink $dest;

	if (-l $src && $keep_special) {
	    unless (symlink(readlink($src) || die("readlink failed: $!"), $dest)) {
		warn "symlink: can't create symlink $dest: $!\n";
	    }
	} elsif (-d $src) {
	    -d $dest or mkdir $dest, (stat($src))[2] or die "mkdir: can't create directory $dest: $!\n";
	    cp_with_option($option, glob_($src), $dest);
	} elsif ((-b $src || -c $src || -S $src || -p $src) && $keep_special) {
	    my @stat = stat($src);
	    require MDK::Common::System;
	    MDK::Common::System::syscall_('mknod', $dest, $stat[2], $stat[6]) or die "mknod failed (dev $dest): $!";
	} else {
	    open(my $F, $src) or die "can't open $src for reading: $!\n";
	    open(my $G, "> $dest") or die "can't cp to file $dest: $!\n";
	    local $_; while (<$F>) { print $G $_ }
	    chmod((stat($src))[2], $dest);
	}
    }
    1;
}

sub cp_same_filesystem_with_options {
    my $rootdev = shift @_;
    my $option = shift @_;
    my $keep_special = $option =~ /a/;

    my $dest = pop @_;

    @_ or return;
    @_ == 1 || -d $dest or die "cp: copying multiple files, but last argument ($dest) is not a directory\n";

    foreach my $src (@_) {
        # detect original file system
        if ($rootdev == -1) {
            my @stat = stat($src);
            $rootdev = $stat[0];
        }

        my $dest = $dest;
        -d $dest and $dest .= '/' . basename($src);

        unlink $dest;

        if (-l $src && $keep_special) {
            unless (symlink(readlink($src) || die("readlink failed: $!"), $dest)) {
            warn "symlink: can't create symlink $dest: $!\n";
            }
        } elsif (-d $src) {
            -d $dest or mkdir $dest, (stat($src))[2] or die "mkdir: can't create directory $dest: $!\n";
            cp_same_filesystem_with_options($rootdev, $option, glob_($src), $dest);
        } elsif ((-b $src || -c $src || -S $src || -p $src) && $keep_special) {
            my @stat = stat($src);
            require MDK::Common::System;
            MDK::Common::System::syscall_('mknod', $dest, $stat[2], $stat[6]) or die "mknod failed (dev $dest): $!";
        } else {
            my @stat = stat($src);
            if ($stat[0] != $rootdev) {
                next;
            }
            open(my $F, $src) or die "can't open $src for reading: $!\n";
            open(my $G, "> $dest") or die "can't cp to file $dest: $!\n";
            local $_; while (<$F>) { print $G $_ }
            chmod((stat($src))[2], $dest);
        }
    }
    1;
}

sub cp_f  { cp_with_option('f', @_) }
sub cp_af { cp_with_option('af', @_) }
sub cp_afx { cp_same_filesystem_with_options(-1, 'af', @_) }

sub touch {
    my ($f) = @_;
    unless (-e $f) {
	my $F;
	open($F, ">$f");
    }
    my $now = time();
    utime $now, $now, $f;
}


sub all {
    my $d = shift;

    local *F;
    opendir F, $d or return;
    my @l = grep { $_ ne '.' && $_ ne '..' } readdir F;
    closedir F;

    @l;
}

sub all_files_rec {
    my ($d) = @_;

    map { $_, -d $_ ? all_files_rec($_) : () } map { "$d/$_" } all($d);
}

sub glob_ {
    my ($d, $f) = $_[0] =~ /\*/ ? (dirname($_[0]), basename($_[0])) : ($_[0], '*');

    $d =~ /\*/ and die "glob_: wildcard in directory not handled ($_[0])\n";
    ($f = quotemeta $f) =~ s/\\\*/.*/g;

    $d =~ m|/$| or $d .= '/';
    map { $d eq './' ? $_ : "$d$_" } grep { /^$f$/ } all($d);
}


sub substInFile(&@) {
    my ($f, $file) = @_;
    #FIXME we should follow symlinks, and fail in case of loop
    if (-l $file) {
        my $targetfile = readlink $file;
        $file = $targetfile;
    }
    if (-s $file) {
	local @ARGV = $file;
	local $^I = '.bak';
	local $_;
	while (<>) { 
	    $_ .= "\n" if eof && !/\n/;
	    &$f($_); 
	    print;
	}
	open(my $F, $file);
	fsync($F);
	unlink "$file$^I"; # remove old backup now that we have closed new file
    } else {
	#- special handling for zero-sized or nonexistent files
	#- because while (<>) will not do any iteration
	open(my $F, "+> $file") or return;
	#- "eof" without an argument uses the last file read
	my $dummy = <$F>;
	local $_ = '';
	&$f($_);
	print $F $_;
	fsync($F);
    }
}


sub concat_symlink {
    my ($f, $l) = @_;
    $l =~ m|^\.\./(/.*)| and return $1;

    $f =~ s|/$||;
    while ($l =~ s|^\.\./||) { 
	$f =~ s|/[^/]+$|| or die "concat_symlink: $f $l\n";
    }
    "$f/$l";
}
sub expand_symlinks {
    my ($first, @l) = split '/', $_[0];
    $first eq '' or die "expand_symlinks: $_[0] is relative\n";
    my ($f, $l);
    foreach (@l) {
	$f .= "/$_";
	$f = concat_symlink($f, "../$l") while $l = readlink $f;
    }
    $f;
}


sub openFileMaybeCompressed { 
    my ($f) = @_;
    -e $f || -e "$f.gz" or die "file $f not found";
    open(my $F, -e $f ? $f : "gzip -dc '$f.gz'|") or die "file $f is not readable";
    $F;
}
sub catMaybeCompressed { cat__(openFileMaybeCompressed($_[0])) }

1;
