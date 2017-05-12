package Lufs::Local;

use strict;

use Fcntl;

sub init {
    my $self = shift;
	$self->{config} = shift;
}

sub mount { 1 }

sub umount { 1 }

sub readdir {
    my $self = shift;
    my $dir = shift;
    my $ref = shift;
    unless (-d $dir) { return 0 }
    chdir($dir) or return 0;
    unless (opendir(DIR,$dir)) { return 0 }
    my @d = readdir(DIR);
    closedir(DIR);
    shift(@d);shift(@d);
    push @{$ref}, @d;
    return 1;
}

#     ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
#      $atime,$mtime,$ctime,$blksize,$blocks)

sub stat {
    my $self = shift;
    my $file = shift;
    my $ref = shift;
    unless (-e $file) { return 0 }
    my @s = (-l $file) ? CORE::lstat($file) : CORE::stat($file) or return 0;
    $ref->{f_ino} = $s[1];
    $ref->{f_mode} = $s[2];
    $ref->{f_nlink} = $s[3];
    $ref->{f_uid} = $s[4];
    $ref->{f_gid} = $s[5];
    $ref->{f_rdev} = $s[6];
    $ref->{f_size} = $s[7];
    $ref->{f_atime} = $s[8];
    $ref->{f_mtime} = $s[9];
    $ref->{f_ctime} = $s[10];
    $ref->{f_blksize} = $s[11];
    $ref->{f_blocks} = $s[12];
    return 1;
}
 
sub mkdir {
    my $self = shift;
    my $dir = shift;
    my $mode = shift;
    if (mkdir($dir,$mode)) { return 1 }
    else { return 0 }
}

sub open {
    my $self = shift;
    my $file = shift;
    my $mode = shift;
    if (sysopen(FH,$file,$mode)) {
        close FH;
        return 1;
    }
    return 0;
}

sub release {
    my $self = shift;
    my $file = shift;
    return 1;
}

sub unlink { 
    my $self = shift;
    my $file = shift;
    CORE::unlink($file);
}

sub rmdir { 
    my $self = shift;
    my $file = shift;
    CORE::rmdir($file);
}

sub read { 
    my $self = shift;
    my $file = shift;
    my $offset = shift;
    my $count = shift;
    CORE::open(FH,$file) or return -1;
    sysseek(FH,$offset,0) or return 0;
    my $cnt = sysread(FH,$_[0],$count);
    close(FH);
    return $cnt;
}

sub write {
    my $self = shift;
    my $file = shift;
    my ($offset, $count, $buf) = @_;
    CORE::sysopen(FH,$file,1) or return -1;
    CORE::seek(FH,$offset,0);
    CORE::print(FH $buf);
    CORE::close(FH);
    return $count;
}

sub link {
    my $self = shift;
    CORE::link($_[0],$_[1]);
}

sub symlink {
    my $self = shift;
    CORE::symlink($_[0],$_[1]);
}

sub readlink {
    my $self = shift;
    my $link = shift;
    if ($_[0] = CORE::readlink($link)) {
        $_[0] =~ s{^/}{};
        return 1;
    }
    else {
        return 0;
    }
}

sub setattr {
    my $self = shift;
    my $file = shift;
    my $attr = shift;
    unless (-e $file) { return 0 }
    my @s = CORE::stat($file) or return 0;
    if ($s[6]!=$attr->{f_size} && -f $file) { truncate($file,$attr->{f_size}) or return 0 }
    if ($s[2]!=$attr->{f_mode}) { chmod($attr->{f_mode},$file) or return 0 }
    if ($s[7]!=$attr->{f_atime} or $s[8]!=$attr->{f_mtime}) { utime($attr->{f_atime},$attr->{f_mtime},$file) or return 0 }
    return 1;
}

sub create {
    my $self = shift;
    my ($file,$mode) = @_;
    sysopen(FH,$file, O_RDWR | O_EXCL | O_CREAT) or return 0;
    close(FH);
	chmod($mode & 0777, $file);
    return 1;
}

sub rename {
    my $self = shift;
    CORE::rename(shift,shift);
}

1;
__END__

=head1 NAME

Lufs::Local - Transparent local filesystem

Raoul Zwart, E<lt>rlzwart@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Raoul Zwart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
