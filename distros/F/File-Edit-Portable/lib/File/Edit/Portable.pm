package File::Edit::Portable;
use 5.008;
use strict;
use warnings;

local $SIG{__WARN__} = sub { confess(shift); };
our $VERSION = '1.26';

use Carp qw(confess croak);
use Exporter;
use Fcntl qw(:flock);
use File::Find::Rule;
use File::Temp;
use POSIX qw(uname);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    recsep
    platform_recsep
);

sub new {
    return bless {}, shift;
}
sub read {
    my $self = shift;
    my ($file, $testing);

    if ($_[0] eq 'file'){
        $self->_config(@_);
    }
    else {
        $file = shift;
        $testing = shift if @_;
        $self->_config(file => $file, testing => $testing);
    }

    $file = $self->{file};
    $testing = $self->{testing};

    if (! $file){
        confess "read() requires a file name sent in!";
    }

    $self->recsep($file);
    $self->{files}{$file}{is_read} = 1;
    $self->{files}{$file}{recsep} = $self->{recsep};
    $self->{reads}{count} = keys %{ $self->{files} };

    my $fh;

    if (! wantarray){
        $fh = $self->_handle($file);
        return $fh;
    }
    else {
        $fh = $self->_binmode_handle($file);
        my @contents = <$fh>;
        close $fh or confess "read() can't close file $file!: $!";

        if (! $testing){
            for (@contents){
                $_ = $self->_strip_ends($_);
            }
        }
        return @contents;
    }
}
sub write {
    my $self = shift;
    my %p = @_;
    $self->_config(%p);

    if (! $self->{file}){
        confess "write() requires a file to be passed in!";
    }

    my $reads_count = $self->{reads}{count} || 0;

    if ($reads_count > 1 && ! $p{file}){
        confess "\nif calling write() with more than one read() open, you must " .
                "send in a file name with the 'file' parameter so we know " .
                "which file to write. You currently have the following files " .
                "open: " . join(' ', keys %{ $self->{files} }) . "\n";
    }
    if (! $self->{contents}){
        confess "write() requires 'contents' param sent in";
    }

    my $file = $self->{file}; # needed for cleanup of open file list

    if (! $self->{files}{$file}{is_read}){
        $self->{files}{$file}{recsep} = $self->recsep($file);
    }

    $self->{file} = $self->{copy} if $self->{copy};

    my $wfh = $self->_binmode_handle($self->{file}, 'w');

    # certain FreeBSD versions on amd64 don't work
    # with flock()

    my @os = uname();

    unless ($os[0] eq 'FreeBSD' && $os[-1] eq 'amd64'){
        flock $wfh, LOCK_EX;
    }

    my $recsep = defined $self->{custom_recsep}
        ? $self->{custom_recsep}
        : $self->{files}{$file}{recsep};

    my $contents = $self->{contents};

    if (ref($contents) eq 'GLOB' || ref($contents) eq 'File::Temp') {
        {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = shift; };

            seek $contents, 0, 0;

            if ($warn) {
                confess "\nthe file handle you're passing into write() as ".
                    "the contents param has already been closed\n";
            }
        };

        while (<$contents>){
            $_ = $self->_strip_ends($_);
            print $wfh $_ . $recsep;
        }
        close $contents;
    }
    else {
        for (@$contents){
            $_ = $self->_strip_ends($_);
            print $wfh $_ . $recsep;
        }
    }

    close $wfh;
    delete $self->{files}{$file}; # cleanup open list
    $self->{reads}{count} = 0 if keys %{ $self->{files} } == 0;

    return 1;
}
sub splice {
    my $self = shift;
    $self->_config(@_);

    my $file = $self->{file};
    my $copy = $self->{copy};
    my $insert = $self->{insert};
    my $limit = defined $self->{limit} ? $self->{limit} : 1;

    if (! $insert){
        confess "splice() requires insert => [aref] param";
    }

    my ($line, $find) = ($self->{line}, $self->{find});

    if (! defined $line && ! defined $find){
        confess
          "splice() requires either the 'line' or 'find' parameter sent in.";
    }

    if (defined $line && defined $find){
        warn
          "splice() can't search for both line and find. Operating on 'line'.";
    }

    my @contents = $self->read($file);

    if (defined $line){
        if ($line !~ /^[0-9]+$/){
            confess "splice() requires its 'line' param to contain only an " .
                  "integer. You supplied: $line\n";
        }
        splice @contents, $line, 0, @$insert;
    }

    if (defined $find && ! defined $line){
        $find = qr{$find} if ! ref $find ne 'Regexp';

        my $i = 0;
        my $inserts = 0;

        for (@contents){
            $i++;
            if (/$find/){
                $inserts++;
                splice @contents, $i, 0, @$insert;
                if ($limit){
                    last if $inserts == $limit;
                }
            }
        }
    }

    $self->write(contents => \@contents, copy => $copy);

    return @contents;
}
sub dir {
    my $self = shift;
    $self->_config(@_);

    my $recsep = $self->{custom_recsep};

    my @types;

    if ($self->{types}){
        @types = @{ $self->{types} };
    }
    else {
        @types = qw(*);
    }

    my $find = File::Find::Rule->new;

    $find->maxdepth($self->{maxdepth}) if $self->{maxdepth};
    $find->file;
    $find->name(@types);

    my @files = $find->in($self->{dir});

    return @files if $self->{list};

    for my $file (@files){

        my $fh = $self->read($file);
        my $wfh = $self->tempfile;

        while(<$fh>){
            print $wfh $_;
        }
        close $fh;

        $self->write(
            file => $file,
            contents => $wfh,
            recsep => defined $recsep
                ? $recsep
                : $self->platform_recsep,
        );
    }

    return @files;
}
sub recsep {
    my $self = ref $_[0] eq __PACKAGE__
        ? shift
        : __PACKAGE__->new;

    my $file = shift;
    my $want = shift;

    my $fh;
    eval {
        $fh = $self->_binmode_handle($file);
    };

    if ($@ || -z $fh){

        # we've got an empty file...
        # we'll set recsep to the local platform's

        $self->{recsep} = $self->platform_recsep;

        return $want
            ? $self->_convert_recsep($self->{recsep}, $want)
            : $self->{recsep};
    }

    seek $fh, 0, 0;

    my $recsep_regex = $self->_recsep_regex;

    if (<$fh> =~ /$recsep_regex/){
        $self->{recsep} = $1;
    }

    close $fh or confess "recsep() can't close file $file!: $!";

    return $want
        ? $self->_convert_recsep($self->{recsep}, $want)
        : $self->{recsep};
}
sub platform_recsep {
    my $self = ref $_[0] eq __PACKAGE__
        ? shift
        : __PACKAGE__->new;

    my $want = shift;

    # for platform_recsep(), we need the file open in ASCII mode,
    # so we can't use _binmode_handle() or File::Temp

    my $file = $self->_temp_filename;

    open my $wfh, '>', $file
      or confess
        "platform_recsep() can't open temp file $file for writing!: $!";

    print $wfh "abc\n";

    close $wfh
      or confess "platform_recsep() can't close write temp file $file: $!";

    my $fh = $self->_binmode_handle($file);

    my $recsep_regex = $self->_recsep_regex;

    if (<$fh> =~ /$recsep_regex/){
        $self->{platform_recsep} = $1;
    }

    close $fh
      or confess "platform_recsep() can't close temp file $file after run: $!";

    unlink $file or confess "Can't unlink temp file '$file': $!";

    return $want
        ? $self->_convert_recsep($self->{platform_recsep}, $want)
        : $self->{platform_recsep};
}
sub tempfile {
    # returns a temporary file handle in write mode

    my $wfh = File::Temp->new(UNLINK => 1);
    return $wfh;
}
sub _config {
    # configures self with incoming params

    my $self = shift;
    my %p = @_;

    $self->{custom_recsep} = $p{recsep};
    delete $p{recsep};

    my @params = qw(
                    testing copy types list maxdepth
                    insert line find limit
                   );

    for (@params){
        delete $self->{$_};
    }

    for (keys %p){
        $self->{$_} = $p{$_};
    }
}
sub _handle {
    # returns a handle with platform's record separator

    my $self = shift;
    my $file = shift;

    my $fh;

    if ($self->recsep($file, 'hex') ne $self->platform_recsep('hex')){

        $fh = $self->_binmode_handle($file);
        my $temp_wfh = $self->tempfile;
        binmode $temp_wfh, ':raw';

        my $temp_filename = $temp_wfh->filename;

        while (<$fh>){
            $_ = $self->_platform_replace($_);
            print $temp_wfh $_;
        }

        close $fh or confess "can't close file $file: $!";
        close $temp_wfh or confess "can't close file $temp_filename: $!";

        my $ret_fh = $self->_binmode_handle($temp_filename);

        return $ret_fh;
    }
    else {
        $fh = $self->_binmode_handle($file);
        return $fh;
    }
}
sub _binmode_handle {
    # returns a handle opened with binmode :raw

    my $self = shift;
    my $file = shift;
    my $mode = shift || 'r';

    my $fh;

    if ($mode =~ /^w/){
        open $fh, '>', $file
          or confess "_binmode_handle() can't open file $file for writing!: $!";
    }
    else {
        open $fh, '<', $file
          or confess "_binmode_handle() can't open file $file for reading!: $!";
    }

    binmode $fh, ':raw';

    return $fh;
}
sub _convert_recsep {
    # converts recsep to either hex or OS name (ie. type)

    my ($self, $sep, $want) = @_;

    $sep = unpack "H*", $sep;
    $sep =~ s/0/\\0/g;

    return $sep if $want eq 'hex';

    my %seps = (
        '\0a'    => 'nix',
        '\0d\0a' => 'win',
        '\0d'    => 'mac',
    );

    return $seps{$sep} || 'unknown';
}
sub _recsep_regex {
    # returns a regex object representing all recseps
    return qr/([\n\x{0B}\f\r\x{85}]{1,2})/;
}
sub _platform_replace {
    # replace recseps in a string with the platform recsep

    my ($self, $str) = @_;
    my $re = $self->_recsep_regex;
    $str =~ s/$re/$self->platform_recsep/ge;
    return $str;
}
sub _strip_ends {
    # strip all line endings from string

    my ($self, $str) = @_;
    my $re = $self->_recsep_regex;
    $str =~ s/$re//g;
    return $str;
}
sub _temp_filename {
    # return the name of a temporary file

    my $temp_fh = File::Temp->new(UNLINK => 1);
    my $filename = $temp_fh->filename;
    return $filename;
}
sub _vim_placeholder { return 1; }; # for folding

1;
__END__

=head1 NAME

File::Edit::Portable - Read and write files while keeping the original line-endings intact, no matter the platform.

=for html
<a href="http://travis-ci.org/stevieb9/file-edit-portable"><img src="https://secure.travis-ci.org/stevieb9/file-edit-portable.png"/>
<a href='https://coveralls.io/github/stevieb9/file-edit-portable?branch=master'><img src='https://coveralls.io/repos/stevieb9/file-edit-portable/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use File::Edit::Portable;

    my $rw = File::Edit::Portable->new;

    # read a file, replacing original file's line endings with
    # that of the local platform's default

    my $fh = $rw->read('file.txt');

    # edit file in a loop, and re-write it with its original line endings

    my $fh = $rw->read('file.txt');
    my $wfh = $rw->tempfile;

    while (<$fh>){
        ...
        print $wfh $_;
    }

    $rw->write(contents => $wfh);

    # get an array of the file's contents, with line endings stripped off

    my @contents = $rw->read('file.txt');

    # write out a file using original file's record separator, into a new file,
    # preserving the original

    $rw->write(contents => \@contents, copy => 'file2.txt');

    # replace original file's record separator with a new (custom) one

    $rw->write(recsep => "\r\n", contents => \@contents);

    # rewrite all files in a directory recursively with local
    # platform's default record separator

    $rw->dir(dir => '/path/to/files');

    # insert new data into a file after a specified line number

    $rw->splice(file => 'file.txt', line => $num, insert => \@contents);

    # insert new data into a file after a found search term

    $rw->splice(file => 'file.txt', find => 'term', insert => \@contents);

    # get a file's record separator

    $rw->recsep('file.txt'); # string form
    $rw->recsep('file.txt', 'hex'); # hex form
    $rw->recsep('file.txt', 'type');  # line ending type (nix, win, mac, etc)

=head1 DESCRIPTION

The default behaviour of C<perl> is to read and write files using the Operating
System's (OS) default record separator (line ending). If you open a file on an
OS where the record separators are that of another OS, things can and do break.

This module will read in a file, keep track of the file's current record
separators regardless of the OS, and save them for later writing. It can return
either a file handle (in scalar context) that has had its line endings replaced
with that of the local OS platform, or an array of the file's contents
(in list context) with line endings stripped off. You can then modify this
array and send it back in for writing to the same file or a new file, where the
original file's line endings will be re-appended (or a custom ending if you so
choose).

Uses are for dynamically reading/writing files while on one Operating System,
but you don't know whether the record separators are platform-standard. Shared
storage between multpile platforms are a good use case. This module affords you
the ability to not have to check each file, and is very useful in looping over
a directory where various files may have been written by different platforms.

=head1 EXPORT

None by default. See L<EXPORT_OK>

=head1 EXPORT_OK

C<recsep()>, C<platform_recsep()>

=head1 METHODS

=head2 C<new>

Returns a new C<File::Edit::Portable> object.

=head2 C<read('file.txt')>

In scalar context, will return a read-only file handle to a copy of the file
that has had its line endings replaced with those of the local OS platform's
record separator.

In list context, will return an array, where each element is a line from the
file, with all line endings stripped off.

In both cases, we save the line endings that were found in the original file
(which is used when C<write()> is called, by default).



=head2 C<write>

Writes the data back to the original file, or alternately a new file. Returns 1
on success. If you inadvertantly append newlines to the new elements of the
contents array, we'll strip them off before appending the real newlines.

Parameters:

C<file =E<gt> 'file.txt'>

Not needed if you've used C<read()> to open the file. However, if you have
multiple C<read()>s open, C<write()> will die without the 'file' param, as it
won't know which file you're wanting to write.

C<copy =E<gt> 'file2.txt'>

Set this if you want to write to an alternate (new) file, rather than the
original.

C<contents =E<gt> $filehandle> or C<contents =E<gt> \@contents>

Mandatory - either an array with one line per element, or a file handle (file
handle is far less memory-intensive).

C<recsep =E<gt> "\r\n">

Optional - a double-quoted string of any characters you want to write as the
line ending (record separator). This value will override what was found in the
C<read()> call. Common ones are C<"\r\n"> for Windows, C<"\n"> for Unix and
C<"\r"> for Mac. Use a call to C<platform_recsep()> as the value to use the
local platforms default separator.

=head2 C<splice>

Inserts new data into a file after a specified line number or search term.

Parameters:

C<file =E<gt> 'file.txt'>

Mandatory.

C<insert =E<gt> \@contents>

Mandatory - an array reference containing the contents to merge into the file.

C<copy =E<gt> 'file2.txt'>

Optional - we'll read from C<file>, but we'll write to this new file.

C<line =E<gt> Integer>

Optional - Merge the contents on the line following the one specified here.

C<find =E<gt> 'search term'>

Optional - Merge the contents into the file on the line following the first
find of the search term. The search term is put into C<qr>, so single quotes
are recommended, and all regex patterns are honoured. Note that we also accept
a pre-created C<qr//> Regexp object directly (as opposed to a string).

C<limit =E<gt> Integer>

Optional - When splicing with the 'find' param, set this to the number of finds
to insert after. Default is stop after the first find. Set to 0 will insert
after all finds.

NOTE: Although both are optional, at least one of C<line> or C<find> must be
sent in. If both are sent in, we'll warn, and operate on the line number and
skip the find parameter.

Returns an array of the modified file contents.


=head2 C<dir>

Rewrites the line endings in some or all files within a directory structure
recursively. By default, rewrites all files with the current platform's default
line ending. Returns an array of the names of the files found.

Parameters:

C<dir =E<gt> '/path/to/files'>

Mandatory.

C<types =E<gt> ['*.txt', '*.dat']>

Optional - Specify wildcard combinations for files to work on. We'll accept
anything that C<File::Find::Rule::name()> method does. If not supplied, we work
on all files.

C<maxdepth =E<gt> Integer>

Optional - Specify how many levels of recursion to do after entering the
directory. We'll do a full recurse through all sub-directories if this
parameter is not set.

C<recsep =E<gt> "\r\n">

Optional - If this parameter is not sent in, we'll replace the line endings
with that of the current platform we're operating on. Otherwise, we'll use the
double-quoted value sent in.

C<list =E<gt> 1>

Optional - If set to any true value, we'll return an array of the names of the
files found, but won't take any editing action on them.

Default is disabled.

=head2 C<recsep('file.txt', $want)>

Returns the record separator found within the file. If the file is empty, we'll
return the local platform's default record separator.

The optional C<$want> parameter can contain either 'hex' or 'type'. If 'hex' is
sent in, the record separator will be returned in hex form (eg: "\0d\0a" for
Windows). If 'type' is sent in, we'll return a short-form of the line-ending
type (eg: win, nix, mac, etc).

Note that this method can be imported into your namespace on demand if you
don't need the object functionality of the module.

=head2 C<platform_recsep($want)>

Returns the the current platform's (OS) record separator in string form.

The optional C<$want> parameter can contain either 'hex' or 'type'. If 'hex' is
sent in, the record separator will be returned in hex form (eg: "\0d\0a" for
Windows). If 'type' is sent in, we'll return a short-from of the line-ending
type (eg: win, nix, mac, etc).

Note that this method can be imported into your namespace on demand if you
don't need the object functionality of the module.

=head2 C<tempfile>

Returns a file handle in write mode to an empty temp file.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/stevieb9/file-edit-portable/issues>

=head1 REPOSITORY

L<https://github.com/stevieb9/file-edit-portable>

=head1 BUILD RESULTS (THIS VERSION)

CPAN Testers: L<http://matrix.cpantesters.org/?dist=File-Edit-Portable>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Edit::Portable

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


