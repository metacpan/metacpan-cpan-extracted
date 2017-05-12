package IO::File::AtomicChange;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(IO::File);
use Carp;
use File::Temp qw(:mktemp);
use File::Copy;
use File::Sync;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->_temp_file("");
    $self->_target_file("");
    $self->_backup_dir("");
    $self->open(@_) if @_;
    $self;
}

sub _accessor {
    my($self, $tag, $val) = @_;
    ${*$self}{$tag} = $val if $val;
    return ${*$self}{$tag};
}
sub _temp_file   { return shift->_accessor("io_file_atomicchange_temp", @_) }
sub _target_file { return shift->_accessor("io_file_atomicchange_path", @_) }
sub _backup_dir  { return shift->_accessor("io_file_atomicchange_back", @_) }

sub DESTROY {
    carp "[CAUTION] disposed object without closing file handle." unless $_[0]->_closed;
}

sub open {
    my ($self, $path, $mode, $opt) = @_;
    ref($self) or $self = $self->new;

    # Because we do rename(2) atomically, temporary file must be in same
    # partion with target file.
    my $temp = mktemp("${path}.XXXXXX");
    $self->_temp_file($temp);
    $self->_target_file($path);

    copy_preserving_attr($path, $temp) if -f $path;
    if (exists $opt->{backup_dir}) {
        unless (-d $opt->{backup_dir}) {
            croak "no such directory: $opt->{backup_dir}";
        }
        $self->_backup_dir($opt->{backup_dir});
    }

    $self->SUPER::open($temp, $mode) ? $self : undef;
}

sub _closed {
    my $self = shift;
    my $tag = "io_file_atomicchange_closed";

    my $oldval = ${*$self}{$tag};
    ${*$self}{$tag} = shift if @_;
    return $oldval;
}

sub close {
    my ($self, $die) = @_;
    File::Sync::fsync($self) or croak "fsync: $!";
    unless ($self->_closed(1)) {
        if ($self->SUPER::close()) {

            $self->backup if ($self->_backup_dir && -f $self->_target_file);

            rename($self->_temp_file, $self->_target_file)
                or ($die ? croak "close (rename) atomic file: $!\n" : return);
        } else {
            $die ? croak "close atomic file: $!\n" : return;
        }
    }
    1;
}

sub copy_modown_to_temp {
    my($self) = @_;

    my($mode, $uid, $gid) = (stat($self->_target_file))[2,4,5];
    chown $uid, $gid, $self->_temp_file;
    chmod $mode,      $self->_temp_file;
}

sub backup {
    my($self) = @_;

    require Path::Class;
    require POSIX;
    require Time::HiRes;

    my $basename = Path::Class::file($self->_target_file)->basename;

    my $backup_file;
    my $n = 0;
    while ($n < 7) {
        $backup_file = sprintf("%s/%s_%s.%d_%d%s",
                               $self->_backup_dir,
                               $basename,
                               POSIX::strftime("%Y-%m-%d_%H%M%S",localtime()),
                               (Time::HiRes::gettimeofday())[1],
                               $$,
                               ($n == 0 ? "" : ".$n"),
                              );
        last unless -f $backup_file;
        $n++;
    }
    croak "already exists backup file: $backup_file" if -f $backup_file;

    copy_preserving_attr($self->_target_file, $backup_file);
}


sub delete {
    my $self = shift;
    unless ($self->_closed(1)) {
        $self->SUPER::close();
        return unlink($self->_temp_file);
    }
    1;
}

sub detach {
    my $self = shift;
    $self->SUPER::close() unless ($self->_closed(1));
    1;
}

sub copy_preserving_attr {
    my($from, $to) = @_;

    File::Copy::copy($from, $to) or croak $!;

    my($mode, $uid, $gid, $atime, $mtime) = (stat($from))[2,4,5,8,9];
    chown $uid, $gid, $to;
    chmod $mode,      $to;
    utime $atime, $mtime, $to;
    1;
}


1;
__END__

=encoding utf-8

=begin html

<a href="https://travis-ci.org/hirose31/IO-File-AtomicChange"><img src="https://travis-ci.org/hirose31/IO-File-AtomicChange.png?branch=master" alt="Build Status" /></a>
<a href="https://coveralls.io/r/hirose31/IO-File-AtomicChange?branch=master"><img src="https://coveralls.io/repos/hirose31/IO-File-AtomicChange/badge.png?branch=master" alt="Coverage Status" /></a>

=end html

=head1 NAME

IO::File::AtomicChange - change content of a file atomically

=head1 SYNOPSIS

truncate and write to temporary file. When you call $fh->close, replace
target file with temporary file preserved permission and owner (if
possible).

    use IO::File::AtomicChange;
    
    my $fh = IO::File::AtomicChange->new("foo.conf", "w");
    $fh->print("# create new file\n");
    $fh->print("foo\n");
    $fh->print("bar\n");
    $fh->close; # MUST CALL close EXPLICITLY

If you specify "backup_dir", save original file into backup directory (like
"/var/backup/foo.conf_YYYY-MM-DD_HHMMSS_PID") before replace.

    my $fh = IO::File::AtomicChange->new("foo.conf", "a",
                                         { backup_dir => "/var/backup/" });
    $fh->print("# append\n");
    $fh->print("baz\n");
    $fh->print("qux\n");
    $fh->close; # MUST CALL close EXPLICITLY

=head1 DESCRIPTION

IO::File::AtomicChange is intended for people who need to update files
reliably and atomically.

For example, in the case of generating a configuration file, you should be
careful about aborting generator program or be loaded by other program
in halfway writing.

IO::File::AtomicChange free you from such a painful situation and boring code.

=head1 INTERNAL

    * open
      1. fix filename of temporary file by mktemp.
      2. if target file already exists, copy target file to temporary file preserving permission and owner.
      3. open temporary file and return its file handle.
    
    * write
      1. write date into temporary file.
    
    * close
      1. close temporary file.
      2. if target file exists and specified "backup_dir" option, copy target file into backup directory preserving permission and owner, mtime.
      3. rename temporary file to target file.

=head1 CAVEATS

You must call "$fh->close" explicitly when commit changes.

Currently, "close $fh" or "undef $fh" don't affect target file. So if you
exit without calling "$fh->close", CHANGES ARE DISCARDED.

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 THANKS TO

kazuho gave me many shrewd advice.

=head1 REPOSITORY

L<https://github.com/hirose31/IO-File-AtomicChange>

  git clone git://github.com/hirose31/IO-File-AtomicChange.git

patches and collaborators are welcome.

=head1 SEE ALSO

L<IO::File>, L<IO::AtomicFile>, L<File::AtomicWrite>

=head1 COPYRIGHT & LICENSE

Copyright HIROSE Masaaki 2009-

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=begin comment

=head0 SPECIAL THANKS TO

typester recommended brand new style "SEE ALSO" section.

=head0 IMHO

* IO::AtomicFile
  * same name of temporary file.
    several processes update a one file, temporary file is mangled.
  * close in DESTROY block.
    leave halfway writing when die in writing  process.
      $fh->print("begin write\n");
      $fh->print(generate_contents()); # call die in generate_contents()
      $fh->print("EOF");               # this is not written...

* File::AtomicWrite
  * shared $tmp_fh globally?

=end comment

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# cperl-close-paren-offset: -4
# cperl-indent-parens-as-block: t
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
