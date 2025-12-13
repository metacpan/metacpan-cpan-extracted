package Dev::Util::File;

use Dev::Util::Syntax;
use Exporter qw(import);

use File::Temp;
use IO::Handle;

our $VERSION = version->declare("v2.19.29");

our %EXPORT_TAGS = (
                     fattr => [ qw(
                                    file_exists
                                    file_readable
                                    file_writable
                                    file_executable
                                    file_is_empty
                                    file_size_equals
                                    file_owner_effective
                                    file_owner_real
                                    file_is_setuid
                                    file_is_setgid
                                    file_is_sticky
                                    file_is_ascii
                                    file_is_binary
                                )
                              ],
                     ftypes => [ qw(
                                     file_is_plain
                                     file_is_symbolic_link
                                     file_is_pipe
                                     file_is_socket
                                     file_is_block
                                     file_is_character
                                 )
                               ],

                     dirs => [ qw(
                                   dir_exists
                                   dir_readable
                                   dir_writable
                                   dir_executable
                                   dir_suffix_slash
                               )
                             ],
                     misc => [ qw(
                                   mk_temp_dir
                                   mk_temp_file
                                   stat_date
                                   status_for
                                   read_list
                               )
                             ]

                   );

# add all the other ":class" tags to the ":all" class, deleting duplicates
{
    my %seen;
    push @{ $EXPORT_TAGS{ all } }, grep { !$seen{ $_ }++ } @{ $EXPORT_TAGS{ $_ } }
        foreach keys %EXPORT_TAGS;
}
Exporter::export_ok_tags('all');

sub file_exists {
    my $file = shift;

    if ( -e $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_readable {
    my $file = shift;

    if ( -e -r $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_writable {
    my $file = shift;

    if ( -e -w $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_executable {
    my $file = shift;

    if ( -e -x $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_empty {
    my $file = shift;

    if ( -e -z $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_size_equals {
    my $file = shift;
    my $size = shift;

    unless ( file_exists($file) ) { return 0; }

    my $file_size = -s $file;
    if ( $file_size == $size ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_owner_effective {
    my $file = shift;

    if ( -e -o $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_owner_real {
    my $file = shift;

    if ( -e -O $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_setuid {
    my $file = shift;

    if ( -e -u $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_setgid {
    my $file = shift;

    if ( -e -g $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_sticky {
    my $file = shift;

    if ( -e -k $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_ascii {
    my $file = shift;

    if ( -e -T $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_binary {
    my $file = shift;

    if ( -e -B $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_plain {
    my $file = shift;

    if ( -e -f $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_symbolic_link {
    my $file = shift;

    if ( -e -l $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_pipe {
    my $file = shift;

    if ( -e -p $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_socket {
    my $file = shift;

    if ( -e -S $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_block {
    my $file = shift;

    if ( -e -b $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub file_is_character {
    my $file = shift;

    if ( -e -c $file ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub dir_exists {
    my $dir = shift;

    if ( -e -d $dir ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub dir_readable {
    my $dir = shift;

    if ( -e -d -r $dir ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub dir_writable {
    my $dir = shift;

    if ( -e -d -w $dir ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub dir_executable {
    my $dir = shift;

    if ( -e -d -x $dir ) {
        return 1;
    }
    else {
        return 0;
    }
    return;
}

sub dir_suffix_slash {

    # add a trailing slash to dir name if none exists
    my $dir = shift;

    $dir .= ( substr( $dir, -1, 1 ) eq '/' ) ? '' : '/';
    return $dir;
}

sub mk_temp_dir {
    my $dir = shift || '/tmp';
    my $temp_dir = File::Temp->newdir( DIR     => $dir,
                                       CLEANUP => 1 );

    return ($temp_dir);
}

sub mk_temp_file {
    my $temp_dir = shift || '/tmp';

    my $temp_file = File::Temp->new(
                                     DIR    => $temp_dir,
                                     SUFFIX => '.test',
                                     UNLINK => 0
                                   );
    $temp_file->autoflush();

    # print { $temp_file } 'super blood wolf moon' . "\n";

    return ($temp_file);
}

sub stat_date {
    my $file        = shift;
    my $dir_format  = shift || 0;
    my $date_format = shift || 'daily';
    my ( $date, $format );

    my $mtime = ( stat $file )[9];

    if ( $date_format eq 'monthly' ) {
        $format = $dir_format ? "%04d/%02d" : "%04d%02d";
        $date = sprintf(
                         $format,
                         sub { ( $_[5] + 1900, $_[4] + 1 ) }
                         ->( localtime($mtime) )
                       );
    }
    else {
        $format = $dir_format ? "%04d/%02d/%02d" : "%04d%02d%02d";
        $date = sprintf(
                         $format,
                         sub { ( $_[5] + 1900, $_[4] + 1, $_[3] ) }
                         ->( localtime($mtime) )
                       );
    }
    return $date;
}

sub status_for {
    my ($file) = @_;
    Readonly my @STAT_FIELDS =>
        qw( dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks );

    # The hash to be returned...
    my %stat_hash = ( file => $file );

    # Load each stat datum into an appropriately named entry of the hash...
    @stat_hash{ @STAT_FIELDS } = stat $file;

    return \%stat_hash;
}

sub read_list {
    my $input_file = shift;
    my $sep        = shift || "\n";

    $sep = undef if ( !wantarray );
    local $INPUT_RECORD_SEPARATOR = $sep;

    my ( $line, @list );

    open( my $input, '<', $input_file )
        or die "can't open file, $input_file $!\n";
    LINE:
    while ( defined( $line = <$input> ) ) {
        chomp($line);
        next LINE if ( $line =~ m|^$| );    # remove blank lines
        next LINE if ( $line =~ m|^#| );    # remove comments
        push @list, $line;
    }
    close($input);

    return wantarray ? @list : $list[0];
}

1;    # End of Dev::Util::File

=pod

=encoding utf-8

=head1 NAME

Dev::Util::File - General utility functions for files and directories.

=head1 VERSION

Version v2.19.29

=head1 SYNOPSIS

Dev::Util::File - provides functions to assist working with files and dirs, menus and prompts.

    use Dev::Util::File;

    my $fexists   = file_exists('/path/to/somefile');
    my $canreadf  = file_readable('/path/to/somefile');
    my $canwritef = file_writable('/path/to/somefile');
    my $canexecf  = file_executable('/path/to/somefile');

    my $isemptyfile = file_is_empty('/path/to/somefile');
    my $fileissize = file_size_equals('/path/to/somefile', $number_of_bytes);

    my $isplainfile = file_is_plain('/path/to/somefile');
    my $issymlink = file_is_symbolic_link('/path/to/somefile');
    ...

    my $dexists  = dir_exists('/path/to/somedir');
    my $canreadd  = dir_readable('/path/to/somedir');
    my $canwrited = dir_writable('/path/to/somedir');

    my $slash_added_dir = dir_suffix_slash('/dir/path/no/slash');

    my $td = mk_temp_dir();
    my $tf = mk_temp_file($td);

    my $file_date     = stat_date( $test_file, 0, 'daily' );    # 20240221
    my $file_date     = stat_date( $test_file, 1, 'monthly' );  # 2024/02

    my $mtime =  status_for($file)->{mtime}

    my $scalar_list = read_list(FILE);
    my @array_list  = read_list(FILE);

=head1 EXPORT_TAGS

=over 4

=item B<:fattr>

=over 8

=item file_exists

=item file_readable

=item file_writable

=item file_executable

=item file_is_empty

=item file_size_equals

=item file_owner_effective

=item file_owner_real

=item file_is_setuid

=item file_is_setgid

=item file_is_sticky

=item file_is_ascii

=item file_is_binary

=back

=item B<:ftypes>

=over 8

=item file_is_plain

=item file_is_symbolic_link

=item file_is_pipe

=item file_is_socket

=item file_is_block

=item file_is_character

=back

=item B<:dirs>

=over 8

=item dir_exists

=item dir_readable

=item dir_writable

=item dir_executable

=item dir_suffix_slash

=back

=item B<:misc>

=over 8

=item mk_temp_dir

=item mk_temp_file


=item stat_date

=item status_for

=item read_list

=back

=back

=head1 SUBROUTINES

=head2 B<file_exists(FILE)>

Tests for file existence.  Returns true if the file exists, false if it does not.

B<All of the subroutines return 1 for true and 0 for false.>

C<FILE> a string or variable pointing to a file.

    my $fexists  = file_exists('/path/to/somefile');

=head2 B<file_readable(FILE)>

Tests for file existence and is readable.  Returns true if file is readable, false if not.

    my $canreadf  = file_readable('/path/to/somefile');

=head2 B<file_writable(FILE)>

Tests for file existence and is writable. Returns true if file is writable, false if not.

    my $canwritef = file_writable('/path/to/somefile');

=head2 B<file_executable(FILE)>

Tests for file existence and is executable.  Returns true if file is executable, false if not.

    my $canexecf  = file_executable('/path/to/somefile');

=head2 B<file_is_empty(FILE)>

Check if the file is zero sized. Returns true if file is zero bytes, false if not.

    my $isemptyfile = file_is_empty('/path/to/somefile');

=head2 B<file_size_equals(FILE, BYTES)>

Check if the file size equals given size. Returns true if file is the given number of bytes, false if not.

C<BYTES> The number of bytes to test for.

    my $fileissize = file_size_equals('/path/to/somefile', $number_of_bytes);

=head2 B<file_owner_effective(FILE)>

Check if the file is owned by the effective uid. Returns true if file is owned by the effective user, false if not.

    my $effectiveuserowns = file_owner_effective('/path/to/somefile');

=head2 B<file_owner_real(FILE)>

Check if the file is owned by the real uid. Returns true if file is owned by the real user, false if not.

    my $realuserowns = file_owner_real('/path/to/somefile');

=head2 B<file_is_setuid(FILE)>

Check if the file has setuid bit set.  Returns true if file is setuid, for example: C<.r-Sr--r-->

    my $isfilesuid = file_is_setuid('/path/to/somefile');

=head2 B<file_is_setgid(FILE)>

Check if the file has setgid bit set.  Returns true if file is setgid, for example: C<.r--r-Sr-->

    my $isfileguid = file_is_setgid('/path/to/somefile');

=head2 B<file_is_sticky(FILE)>

Check if the file has sticky bit set.  Returns true if file is sticky, for example: C<.r--r--r-T>

    my $isfilesticky = file_is_sticky('/path/to/somefile');

=head2 B<file_is_ascii(FILE)>

Check if the file is an ASCII or UTF-8 text file (heuristic guess).  Returns true if file is ascii, false if binary.

    my $isfileascii = file_is_ascii('/path/to/somefile');

=head2 B<file_is_binary(FILE)>

Check if the file is a "binary" file (opposite of C<file_is_ascii>). Returns true if file is binary, false if ascii.

    my $isfilebinary = file_is_binary('/path/to/somefile');

=head2 B<file_is_plain(FILE)>

Tests that file is a regular file.  Returns true if file is a plain file, false if not.

    my $isplainfile = file_is_plain('/path/to/somefile');

=head2 B<file_is_symbolic_link(FILE)>

Tests that file is a symbolic link.  Returns true if file is a symbolic link, for example: C<lr--r--r-->

    my $issymlink = file_is_symbolic_link('/path/to/somefile');

=head2 B<file_is_pipe(FILE)>

Tests that file is a named pipe. Returns true if file is a pipe, for example: C<|rw-rw-rw->

    my $ispipe = file_is_pipe('/path/to/somefile');

=head2 B<file_is_socket(FILE)>

Tests that file is a socket. Returns true if file is a socket, for example: C<srw------->

    my $issocket = file_is_socket('/path/to/somefile');

=head2 B<file_is_block(FILE)>

Tests that file is a block special file. Returns true if file is a block file, for example: C<brw-r----->

    my $isblock = file_is_block('/path/to/somefile');

=head2 B<file_is_character(FILE)>

Tests that file is a block character file. Returns true if file is a block character file, for example: C<crw-r----->

    my $ischarf = file_is_character('/path/to/somefile');

=head2 B<dir_exists(DIR)>

Tests for dir existence.  Returns true if the directory exists, false if not.

C<DIR> a string or variable pointing to a directory.

    my $dexists  = dir_exists('/path/to/somedir');

=head2 B<dir_readable(DIR)>

Tests for dir existence and is readable. Returns true if the directory is readable, false if not.

    my $canreadd  = dir_readable('/path/to/somedir');

=head2 B<dir_writable(DIR)>

Tests for dir existence and is writable. Returns true if the directory is writable, false if not.

    my $canwrited = dir_writable('/path/to/somedir');

=head2 B<dir_executable(DIR)>

Tests for dir existence and is executable. Returns true if the directory is executable, false if not.

    my $canenterdir = dir_executable('/path/to/somedir');

=head2 B<dir_suffix_slash(DIR)>

Ensures a dir ends in a slash by adding one if necessary.

    my $slash_added_dir = dir_suffix_slash('/dir/path/no/slash');

=head2 B<mk_temp_dir(DIR)>

Create a temporary directory in the supplied parent dir. F</tmp> is the default if no dir given.

C<DIR> a string or variable pointing to a directory.

    my $td = mk_temp_dir();

=head2 B<mk_temp_file(DIR)>

Create a temporary file in the supplied dir. F</tmp> is the default if no dir given.

    my $tf = mk_temp_file($td);

=head2 B<stat_date(FILE, DIR_FORMAT, DATE_FORMAT)>

Return the stat date of a file

C<DIR_FORMAT> Style of date, include slashes? 0: YYYYMMDD, 1: YYYY/MM/DD 

C<DATE_FORMAT> Granularity of date: daily: YYYYMMDD, monthly: YYYY/MM 

    my $file_date     = stat_date( $test_file, 0, 'daily' );    # 20240221
    my $file_date     = stat_date( $test_file, 1, 'monthly' );  # 2024/02

       format: YYYYMMDD,
    or format: YYYY/MM/DD if dir_format is true
    or format: YYYYMM or YYYY/MM if date_type is monthly

=head2 B<status_for>

Return hash_ref of file stat info.

    my $stat_info_ref = status_for($file);
    my $mtime = $stat_info_ref->{mtime};

Available keys:

    dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks

=head2 B<read_list>

Read a list from an input file return an array of lines if called in list context.
If called by scalar context it will slurp the whole file and return it as a scalar.
Comments (begins with #) and blank lines are skipped.

    my $scalar_list = read_list(FILE);
    my @array_list  = read_list(FILE);

B<Note>: The API for this function is maintained to support the existing code base that uses it.
It would probably be better to use C<Perl6::Slurp> or C<File::Slurper> for new code.

=head1 AUTHOR

Matt Martini, C<< <matt at imaginarywave.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dev-util at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::File

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util>

=item * Search CPAN

L<https://metacpan.org/release/Dev-Util>

=back

=head1 ACKNOWLEDGMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright © 2019-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007

=cut

__END__
