package Dir::Split;

use strict;
use warnings;
use base qw(Exporter);

use Carp qw(croak);
use File::Basename ();
use File::Copy ();
use File::Find ();
use File::Path ();
use File::Spec ();
use SelfLoader;

our ($VERSION,
     @EXPORT,

     $NOACTION,                # return values
     $ACTION,
     $EXISTS,
     $FAILURE,
     $ADJUST,

     $UNLINK,                  # external options
     $TRAVERSE,
     $TRAVERSE_UNLINK,
     $TRAVERSE_RMDIR,
     $TRAVERSE_RMDIR_SOURCE,

     @exists,                  # external data
     %failure,
     %track);

$VERSION = '0.80';

@EXPORT = qw(
    $NOACTION
    $ACTION
    $EXISTS
    $FAILURE
    $ADJUST
);

$NOACTION =    0;
$ACTION   =    1;
$EXISTS   =   -1;
$FAILURE  =   -2;
$ADJUST   = -255;

sub new
{
    my ($self, @opt) = @_;
    my $class = ref($self) || $self;

    my %blessed;
    %{$blessed{OPT}} = @opt;

    return bless(\%blessed, $class);
}

sub split_dir
{
    my $self = shift;

    $self->_sanity_input;
    $self->_gather_files;

    my $RetVal = $NOACTION;

    if ($self->{files}) {
        $RetVal = $ACTION;

        $self->_sort_files if $self->{OPT}{mode} eq 'num';
        $self->_suffix;
        $self->_move;

        $self->_traversed_rmdir
          if $TRAVERSE && $TRAVERSE_RMDIR && $TRAVERSE_UNLINK;

        $RetVal = $EXISTS  if @exists;
        $RetVal = $FAILURE if %failure;
    }

    return $RetVal;
}

sub _sanity_input
{
    my $self = shift;

    if ($UNLINK && ($TRAVERSE || $TRAVERSE_UNLINK ||
        $TRAVERSE_RMDIR || $TRAVERSE_RMDIR_SOURCE)) {
        croak '$UNLINK and $TRAVERSE_* may not be combined';
    }

    my %generic = (
        mode        =>       '^(?:num|char)$',
        source      =>              'defined',
        target      =>              'defined',
        verbose     =>               '^[01]$',
        override    =>               '^[01]$',
        identifier  =>                  '\w+',
        separator   =>              'defined',
        length      =>                  '> 0',
    );

    my %num = (
        file_limit  =>                  '> 0',
        file_sort   =>               '^[+-]$',
        continue    =>               '^[01]$',
    );

    my %char = (
        case        =>    '^(?:lower|upper)$',
    );

    $self->_validate_input(\%generic);

    $self->{OPT}{mode} eq 'num'
      ? $self->_validate_input(\%num)
      : $self->_validate_input(\%char);
}

sub _validate_input
{
    my ($self, $args) = @_;

    while (my ($arg, $prove) = each %$args) {
        my $condition = "\$self->{OPT}{\$arg}";

        if ($prove ne 'defined' && $prove !~ /\d+$/) {
            $condition .= " =~ /$prove/";
        }
        no warnings 'uninitialized';
        my $match = eval "sub { $condition }"
          or die "Couldn't compile $condition: $@";

        croak "Option '$arg' not defined or invalid"
          unless &$match;
    }
}

sub _gather_files
{
    my $self = shift;

    if ($TRAVERSE) {
        $self->_traverse(\@{$self->{dirs}}, \@{$self->{files}});
    }
    else {
        $self->_read_dir(\@{$self->{files}}, $self->{OPT}{source});

        # Leave directories behind as we are in ``flat", non-traversal mode.
        @{$self->{files}} = grep { !-d File::Spec->catfile($self->{OPT}{source}, $_) } @{$self->{files}};
    }
    $track{source}{files} = @{$self->{files}};
}

sub _sort_files
{
    my $self = shift;

    my $cmp =
      $TRAVERSE
        ? $self->{OPT}{file_sort} eq '+'
          ? 'lc File::Basename::basename($a) cmp lc File::Basename::basename($b)'
          : 'lc File::Basename::basename($b) cmp lc File::Basename::basename($a)'
        : $self->{OPT}{file_sort} eq '+'
          ? 'lc $a cmp lc $b'
          : 'lc $b cmp lc $a';

    @{$self->{files}} = sort { eval $cmp } @{$self->{files}};
}

sub _suffix
{
    my $self = shift;

    if ($self->{OPT}{mode} eq 'num') {
        $self->_suffix_num_contin if $self->{continue};
        $self->_suffix_num_sum_up;
    }
    else {
        $self->_suffix_char;
    }
}

sub _suffix_num_contin
{
    my $self = shift;

    my @dirs;
    $self->_read_dir(\@dirs, $self->{OPT}{target});

    # Leave files behind as we need to evaluate names of subdirs.
    @dirs = grep { -d File::Spec->catfile($self->{OPT}{target}, $_) } @dirs;

    $self->{suffix} = 0;

    # Search for the highest numerical suffix of given identifier.
    foreach my $dir (@dirs) {
        my ($ident_cmp, $suff_cmp) = $dir =~ /(.+) \Q$self->{OPT}{separator}\E (.*)/ox;

        if ($self->{OPT}{identifier} eq $ident_cmp && $suff_cmp =~ /[0-9]/o) {
            $self->{suffix} = $suff_cmp if ($suff_cmp > $self->{suffix});
        }
    }
}

sub _suffix_num_sum_up
{
    my $self = shift;

    # In case, no previous suffix has been found,
    # set to 1, otherwise increment.
    $self->{suffix}++;

    if (length $self->{suffix} < $self->{OPT}{length}) {
        $self->{suffix} = sprintf("%0.$self->{OPT}{length}".'d', $self->{suffix});
    }
}

sub _suffix_char
{
    my $self = shift;

    while (my $file = shift @{$self->{files}}) {
        my $suffix = $TRAVERSE
          ? File::Basename::basename($file)
          : $file;

        $suffix =~ s/\s//g;
        $suffix = substr($suffix, 0, $self->{OPT}{length});

        if ($suffix =~ /\w/) {
            $suffix = $self->{OPT}{case} eq 'lower'
              ? lc $suffix : uc $suffix;
        }
        push @{$self->{file_suffix}{$suffix}}, $file;
    }
}

sub _move
{
    my $self = shift;

    $track{target}{dirs}  = 0;
    $track{target}{files} = 0;

    if ($self->{OPT}{mode} eq 'num') {
        $self->_move_num;
    }
    else {
        $self->_move_char;
    }
}

sub _move_num
{
    my $self = shift;

    for (; @{$self->{files}}; $self->{suffix}++) {
        $self->{target_path}  = $self->_mkpath;
        %{$self->{duplicate}} = ();

        for (my $copied = 0; $copied < $self->{OPT}{file_limit} && @{$self->{files}}; $copied++) {
            $self->{file} = shift @{$self->{files}};
            $self->_copy_unlink;
            $self->{duplicate}{File::Basename::basename($self->{file})}++;
        }
    }
}

sub _move_char
{
    my $self = shift;

    foreach my $suffix (sort keys %{$self->{file_suffix}}) {
        $self->{suffix}       = $suffix;
        $self->{target_path}  = $self->_mkpath;
        %{$self->{duplicate}} = ();

        while ($self->{file} = shift @{$self->{file_suffix}{$suffix}}) {
            $self->_copy_unlink;
            $self->{duplicate}{File::Basename::basename($self->{file})}++;
        }
    }
}

sub _mkpath
{
    my $self = shift;

    my $target_path = File::Spec->catfile
      ($self->{OPT}{target}, "$self->{OPT}{identifier}$self->{OPT}{separator}$self->{suffix}");

    return $target_path if -e $target_path;

    if (File::Path::mkpath($target_path, $self->{OPT}{verbose})) {
        $track{target}{dirs}++;
    }
    else {
        croak "Dir $target_path couldn't be created: $!";
    }

    return $target_path;
}

sub _copy_unlink
{
    my $self = shift;

    if ($TRAVERSE) {
        $self->{source_file} = $self->{file};
        $self->{target_file} = File::Spec->catfile($self->{target_path}, File::Basename::basename($self->{file}));
    }
    else {
        $self->{source_file} = File::Spec->catfile($self->{OPT}{source}, $self->{file});
        $self->{target_file} = File::Spec->catfile($self->{target_path}, $self->{file});
    }

    $self->{target_file} .= "_$self->{duplicate}{File::Basename::basename($self->{file})}"
      if $self->{duplicate}{File::Basename::basename($self->{file})};

    if ($self->_copy) {
        $track{target}{files}++;
        $self->_unlink;
    }
}

sub _copy
{
    my $self = shift;

    if ($self->_exists_and_not_override) {
        push @exists, $self->{target_file};
        return 0;
    }

    if (!(File::Copy::copy $self->{source_file}, $self->{target_file})) {
        push @{$failure{copy}}, $self->{target_file};
        return 0;
    }
    else {
        return 1;
    }
}

sub _unlink
{
    my $self = shift;

    if (!$UNLINK && !$TRAVERSE) {
        return;
    }
    elsif ($TRAVERSE) {
        return unless $TRAVERSE_UNLINK;
    }
    unless (unlink $self->{source_file}) {
        push @{$failure{unlink}}, $self->{source_file};
    }
}

sub _exists_and_not_override
{
    my $self = shift;

    return (-e $self->{target_file} && !$self->{OPT}{override})
      ? 1 : 0;
}

sub _read_dir
{
    my ($self, $items, $dir) = @_;

    opendir(my $dir_fh, $dir)
      or croak "Couldn't open dir $dir: $!";

    @$items = grep !/^(?:\.|\.\.)$/, readdir($dir_fh);

    closedir($dir_fh)
      or croak "Couldn't close dir $dir: $!";
}

1;
__DATA__

sub _traverse
{
    local ($self, $dirs, $files) = @_;

    my %opts = (
        wanted       =>    $self->can('_eval_files'),
        postprocess  =>    $self->can('_eval_dirs'),
    );

    File::Find::finddepth(\%opts, $self->{OPT}{source});
}

sub _eval_files
{
    my $self = shift;
    push @$files, $File::Find::name if -f $File::Find::name;
}

sub _eval_dirs
{
    my $self = shift;
    push @$dirs, $File::Find::dir;
}

sub _traversed_rmdir
{
    my $self = shift;

    if ($TRAVERSE_RMDIR && $TRAVERSE_UNLINK) {
        foreach my $dir (@{$self->{dirs}}) {
            next if $dir eq $self->{OPT}{source} && !$TRAVERSE_RMDIR_SOURCE;
            File::Path::rmtree($dir, 1, 1);
        }
    }
}

__END__

=head1 NAME

Dir::Split - Split files of a directory to subdirectories

=head1 SYNOPSIS

 use Dir::Split;

 # example arguments
 $dir = Dir::Split->new(
     mode    =>    'num',

     source  =>    '/source',
     target  =>    '/target',

     verbose     =>        1,
     override    =>        0,

     identifier  =>    'sub',
     file_limit  =>        2,
     file_sort   =>      '+',

     separator   =>      '-',
     continue    =>        1,
     length      =>        5,
 );

 $retval = $dir->split_dir;

=head1 DESCRIPTION

C<Dir::Split> moves files to either numbered or characteristic subdirectories.

=head2 numeric splitting

Numeric splitting is an attempt to gather files from a source directory and
split them to numbered subdirectories within a target directory. Its purpose is
to automate the archiving of a great amount of files, that are likely to be indexed
by numbers.

=head2 characteristic splitting

Characteristic splitting allows indexing by using leading characters of filenames.
While numeric splitting is being characterised by dividing file amounts, characteristic
splitting tries to keep up the contentual recognition of data.

=cut

=head1 CONSTRUCTOR

=head2 new

Creates a new C<Dir::Split> object.

 # example arguments
 $dir = Dir::Split->new(
     mode    =>    'num',

     source  =>    '/source',
     target  =>    '/target',

     verbose     =>        1,
     override    =>        0,

     identifier  =>    'sub',
     file_limit  =>        2,
     file_sort   =>      '+',

     separator   =>      '-',
     continue    =>        1,
     length      =>        5,
 );

 $dir = Dir::Split->new(%args);

=head1 METHODS

=head2 split_dir

Splits files to subdirectories.

 $retval = $dir->split_dir;

Checking the return value will provide further insight, what action split_dir() has
taken. See (OPTIONS / debug) on how to become aware of errors.

=head3 Return Values

  1 / $ACTION           Files splitted

  0 / $NOACTION         No action

 -1 / $EXISTS           Files exist
                        (see OPTIONS / debug)

 -2 / $FAILURE          Failure
                        (see OPTIONS / debug)

=head1 ARGUMENTS

=head2 numeric

Split files to subdirectories with a numeric suffix.

 %args = (
     mode    =>    'num',

     source  =>    '/source',
     target  =>    '/target',

     verbose     =>        1,
     override    =>        0,

     identifier  =>    'sub',
     file_limit  =>        2,
     file_sort   =>      '+',

     separator   =>      '-',
     continue    =>        1,
     length      =>        5,
 );

=over 4

=item * C<mode>

I<num> for numeric.

=item * C<source>

source directory.

=item * C<target>

target directory.

=item * C<verbose>

if enabled, mkpath will output the paths on creating subdirectories.

 MODES
   1  enabled
   0  disabled

=item * C<override>

overriding of existing files.

 MODES
   1  enabled
   0  disabled

=item * C<identifier>

prefix of each subdirectory created.

=item * C<file_limit>

limit of files per subdirectory.

=item * C<file_sort>

sort order of files.

 MODES
   +  ascending
   -  descending

=item * C<separator>

suffix separator.

=item * C<continue>

numbering continuation.

 MODES
   1  enabled
   0  disabled    (will start at 1)

If numbering continuation is enabled, and numbered subdirectories are found
within target directory which match the given identifier and separator,
then the suffix numbering will be continued. Disabling numbering continuation
may interfere with existing files / directories.

=item * C<length>

character length of the suffix.

This option will have no effect, if its smaller in length than the 
current length of the highest suffix number.

=back

=head2 characteristic

Split files to subdirectories with a characteristic suffix. Files
are assigned to subdirectories which suffixes equal the specified,
leading character(s) of the filenames.

 %args = (
     mode    =>    'char',

     source  =>    '/source',
     target  =>    '/target',

     verbose     =>         1,
     override    =>         0,

     identifier  =>     'sub',

     separator   =>       '-',
     case        =>   'upper',
     length      =>         1,
 );

=over 4

=item * C<mode>

I<char> for characteristic.

=item * C<source>

source directory.

=item * C<target>

target directory.

=item * C<verbose>

if enabled, mkpath will output the pathes on creating
subdirectories.

 MODES
   1  enabled
   0  disabled

=item * C<override>

overriding of existing files.

 MODES
   1  enabled
   0  disabled

=item * C<identifier>

prefix of each subdirectory created.

=item * C<separator>

suffix separator.

=item * C<case>

lower / upper case of the suffix.

 MODES
   lower
   upper

=item * C<length>

character length of the suffix.

< 4 is highly recommended (26 (alphabet) ^ 3 == 17'576 suffix possibilites).
C<Dir::Split> will not prevent using suffix lengths greater than 3. Imagine
splitting 1'000 files and using a character length > 20. The file rate per
subdirectory will almost certainly approximate 1/1 - which equals 1'000
subdirectories.

Whitespaces in suffixes will be removed.

=back

=head1 OPTIONS

=head2 Tracking

C<%Dir::Split::track> keeps count of how many files the source and directories / files
the target consists of. It may be useful, if the amount of files that could not be transferred 
due to existing ones, has to be counted. Each time a new splitting is attempted, 
the track will be reseted.

 %Dir::Split::track = (
     source  =>    {  files  =>    512
     },
     target  =>    {  dirs   =>    128,
                      files  =>    512,
     },
 );

Above example: directory consisting of 512 files successfully splitted to 128 directories.

=head2 Debug

B<Existing>

If C<split_dir()> returns C<$EXISTS>, this implys that the B<override> option is disabled and
files weren't moved due to existing files within the target subdirectories; they will have
their paths appearing in C<@Dir::Split::exists>.

 file    @Dir::Split::exists    # Existing files, not attempted to
                                # be overwritten.

B<Failures>

If C<split_dir()> returns C<$FAILURE>, this most often implys that the B<override> option is enabled
and existing files could not be overwritten. Files that could not be copied / unlinked,
will have their paths appearing in the according keys in C<%Dir::Split::failure>.

 file    @{$Dir::Split::failure{copy}}      # Files that couldn't be copied,
                                            # most often on overriding failures.

         @{$Dir::Split::failure{unlink}}    # Files that could be copied but not unlinked,
                                            # rather seldom.

It is recommended to evaluate those arrays on C<$FAILURE>.

A C<@Dir::Split::exists> array may coexist.

=head2 Unlinking

Files in a flat source directory may be unlinked by setting:

 # Unlink files in flat source
 $Dir::Split::UNLINK = 1;

=head2 Traversing

Traversal processing of files may be activated by setting:

 # Traversal mode
 $Dir::Split::TRAVERSE = 1;

No depth limit e.g. all underlying directories / files will be evaluated.

B<Options>

 # Unlink files in source
 $Dir::Split::TRAVERSE_UNLINK = 1;

Unlinks files after they have been moved to their new locations.

 # Remove directories in source
 $Dir::Split::TRAVERSE_RMDIR = 1;

Removes the directories in source, after the files have been moved. In order to take effect,
this option requires the C<$Dir::Split::TRAVERSE_UNLINK> to be set.

 # Remove the source directory itself
 $Dir::Split::TRAVERSE_RMDIR_SOURCE = 1;

It is not recommended to turn on the latter options C<$Dir::Split::TRAVERSE_UNLINK>,
C<$Dir::Split::TRAVERSE_RMDIR> and C<$Dir::Split::TRAVERSE_RMDIR_SOURCE>,
unless one is aware of the consequences they imply.

=head1 EXAMPLES

Assuming the source directory contains these files:

 +- _123
 +- abcd
 +- efgh
 +- ijkl
 +- mnop

After splitting the source directory tree to the target, it would result in:

=head2 numeric splitting

 +- sub-00001
 +-- _123
 +-- abcd
 +- sub-00002
 +-- efgh
 +-- ijkl
 +- sub-00003
 +-- mnop

=head2 characteristic splitting

 +- sub-_
 +-- _123
 +- sub-a
 +-- abcd
 +- sub-e
 +-- efgh
 +- sub-i
 +-- ijkl
 +- sub-m
 +-- mnop

=head1 SEE ALSO

L<File::Basename>, L<File::Copy>, L<File::Find>, L<File::Path>, L<File::Spec>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
