package Dev::Util::Backup;

use Dev::Util::Syntax;
use Exporter qw(import);

use File::Copy;
use File::Spec;
use File::Basename;
use File::Find;
use IO::File;
use Archive::Tar;

our $VERSION = version->declare("v2.19.12");

our @EXPORT_OK = qw(
    backup
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

#where to save backup files
our $BACKUPDIR = '';

#should we preserve atime, mtime, and mode of the original
#file in all backups ?
our $PRESERVE_FILE_ATTRS = 1;

# Backup file or directory
sub backup {
    return -f $_[0] ? _backupfile(@_) : _backupdir(@_);
}

# Backup file -- takes file name and returns new file name
# This sub can DIE -- so use eval
sub _backupfile {
    my $filename = shift;

    croak "$filename is not a file\n" unless ( -e $filename );

    #backup file will have _yyyymmdd extention added to it
    my $newfile = _backup($filename);

    #preserve mode, atime, and utime of old file
    if ($PRESERVE_FILE_ATTRS) {
        my @stat = stat $filename;

        utime( $stat[8], $stat[9], $newfile );
        chmod $stat[2], $newfile;

        #preserve ownership if possible
        chown $stat[4], $stat[5], $newfile
            if ( $REAL_USER_ID == 0 || $REAL_USER_ID == $stat[4] );
    }

    return $newfile;
}

# Backup directory -- takes file name, optional compression level (2-9) and
#                     returns new archive file name
# This sub can DIE -- so use eval
sub _backupdir {
    my ( $dir, $level ) = @_;

    $level = 5 if ( !defined($level) || $level < 2 || $level > 9 );

    croak "$dir is not a directory\n" unless ( -d $dir );

    my @files;
    my $tar = Archive::Tar->new();

    # "promote" warnings from File::Find to errors
    local $SIG{ __WARN__ } = sub { croak $_[0] };

    #recursivelly add files to tar
    find(
           {  wanted   => sub { push( @files, $_ ) },
              no_chdir => 1
           },
           $dir
        );

    #save archive

    my $tmpout = IO::File->new_tmpfile() || croak "Failed to create tmpfile\n";
    binmode($tmpout);

    $tar->add_files(@files);
    $tar->write( $tmpout, $level );

    #backup file will have _yyyymmdd extention added to it
    return _backup( $dir, $tmpout );
}

# Perform file backup if necessary
# Arguments: $filename -- file/dir to backup
# Returns backup file name
sub _backup {
    my ( $filename, $fh ) = @_;

    my $input = $fh ? $fh : $filename;

    $filename =~ s/\/$//;    #remove trailing slash from paths

    my $ext   = -d $filename ? ".tar.gz" : "";
    my $mtime = ( stat $filename )[9];
    my ( $mday, $mon, $year ) = ( localtime($mtime) )[ 3 .. 5 ];

    if ( $BACKUPDIR ne '' ) {

        #backup in BUDIR directory relative to dirname
        my ( $name, $path ) = fileparse($filename);

        my $budir
            = $BACKUPDIR =~ /^\//
            ? $BACKUPDIR
            : File::Spec->catfile( $path, $BACKUPDIR );

        #try to create backup dir if it does not exist
        croak("Failed to create backup dir $BACKUPDIR\n")
            unless ( -d $budir || mkdir( $budir, 0750 ) );

        $filename = File::Spec->catfile( $budir, $name );
    }

    my $newfile    = q{};    # EMPTY_STR
    my $basefile   = q{};
    my $lastbackup = q{};
    my $count      = 0;

    $newfile = $basefile
        = sprintf( "%s_%d%02d%02d", $filename, $year + 1900, $mon + 1, $mday );

    #find next available backup -- keep appending _counter to
    #basefile name until available extention is found

    for ( $count = 0; -e "$newfile$ext"; $count++ ) {
        $newfile = $basefile . "_" . ( $count + 1 );
    }

    $newfile = $basefile;

    if ($count) {

        # more then 1 backup exists -- last backup has
        # count-1 extention (if count-1 == 0 -> exception: lastbackup=$basefile)
        $lastbackup = $count - 1 > 0 ? "${basefile}_" . ( $count - 1 ) : $basefile;
        $newfile .= "_$count";
    }

    if ( $lastbackup ne '' ) {

        # last backup exists -- check if current file
        # is different from backup
        _file_diff( $input, "$lastbackup$ext" ) || return "$lastbackup$ext";
    }

    #backup file
    seek( $input, 0, 0 ) if ( ref($input) );
    copy( $input, "$newfile$ext", 4096 ) || croak("$!\n");
    return "$newfile$ext";
}

# return true if files are different
# f1, f2 can either be file names or open file handles (by ref)
# NOTE: modifies filehandle position to 0
sub _file_diff {
    my ( $f1, $f2 ) = @_;

    my ( @files, $fh, $ref, $n1, $n2 );

    foreach ( $f1, $f2 ) {
        $ref = ref($_);
        $fh  = $ref ? $_ : IO::File->new( $_, "r" )
            or croak "Failed to create file: $!\n";

        push(
               @files,
               {  fh   => $fh,
                  ref  => $ref,
                  size => ( $fh->stat() )[7]
               }
            );
        seek( $fh, 0, 0 );
    }

    return 1 unless ( $files[0]->{ size } == $files[1]->{ size } );

    my ( $buf1, $buf2 );
    my $diff = 0;

    while (    !$diff
            && ( $n1 = read( $files[0]->{ fh }, $buf1, 4096 ) )
            && ( $n2 = read( $files[1]->{ fh }, $buf2, 4096 ) ) )
    {
        $diff = 1 if ( $n1 != $n2 || $buf1 ne $buf2 );
    }

    #close/restore filehandles
    foreach (@files) {
        if ( $_->{ ref } ) {
            seek( $_->{ fh }, 0, 0 );
        }
        else {
            $_->{ fh }->close();
        }
    }

    return $diff;
}

1;    # End of Dev::Util::OS

=pod

=encoding utf-8

=head1 NAME

Dev::Util::Backup - Simple backup functions for files and dirs

=head1 VERSION

Version v2.19.12

=head1 SYNOPSIS

The backup function will make a copy of a file or dir with the date of the file appended.
It returns the name of the new file.  Directories are backed up by C<tar> and C<gz>.

    use Dev::Util::Backup qw(backup);

    my $backup_file = backup('myfile');
    say $backup_file;

    my $backup_dir = backup('mydir/');
    say $backup_dir;

Will produce:

    myfile_20251025
    mydir_20251025.tar.gz

If the file has changed, calling C<backup('myfile')> again will create C<myfile_20251025_1>.
Each time C<backup> is called the appended counter will increase by 1 if C<myfile> has
changed since the last time it was called.

If the file has not changed, no new backup will be created.

=head2 Examples

The C<bu> program in the examples dir will take a list of files and dirs as args and make
backups of them using C<backup>.

=head1 EXPORT

    backup

=head1 SUBROUTINES

=head2 B<backup(FILE|DIR)>

Return the name of the backup file.

    my $backup_file = backup('myfile');
    my $backup_dir = backup('mydir/');


=head1 AUTHOR

Matt Martini, C<< <matt at imaginarywave.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dev-util at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::Backup

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util>

=item * Search CPAN

L<https://metacpan.org/release/Dev-Util>

=back

=head1 ACKNOWLEDGMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright © 2001-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007

=cut

__END__
