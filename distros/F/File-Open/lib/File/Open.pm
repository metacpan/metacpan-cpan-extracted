package File::Open;

use strict;
use warnings;
BEGIN { warnings->import(FATAL => 'layer') if $] >= 5.008; }

our $VERSION = '1.0102';

use File::Basename qw(basename);
use Carp qw(croak);
use Fcntl ();
use Errno ();
use Exporter (); BEGIN { our @ISA = 'Exporter'; }

our @EXPORT_OK = qw(
    fopen    fopen_nothrow
    fsysopen fsysopen_nothrow
    fopendir fopendir_nothrow
);

sub _mode {
    map { $_ => $_[0] } @_
}

my %modemap = (
    _mode(qw[<   r ]),
    _mode(qw[>   w ]),
    _mode(qw[>>  a ]),
    _mode(qw[+<  r+]),
    _mode(qw[+>  w+]),
    _mode(qw[+>> a+]),
);

sub _open {
    my ($func, $file, $mode, $layers) = @_;
    @_ < 2 and croak "Not enough arguments for $func";
    @_ > 4 and croak "Too many arguments for $func";
    $mode = '<' if !defined $mode;

    my $binary = $mode =~ s/(?<=.)b//;
    my $emode = $modemap{$mode} or croak "Unknown $func() mode '$mode'";

    if ($file =~ /\0/) {
        $! = Errno::ENOENT() if exists &Errno::ENOENT;
        return undef;
    }

    unless (defined $layers) {
        # grab our caller's 'use open' settings
        my $hints = (caller 1)[10];
        my $key = $emode =~ />/ ? 'open>' : 'open<';
        $layers = $hints->{$key};
    }

    open my $fh, $emode . (defined $layers ? " $layers" : ''), $file or return undef;
    binmode $fh if $binary;
    $fh
}

sub fopen_nothrow {
    _open('fopen_nothrow', @_)
}

my $prog = basename $0;

sub fopen {
    _open('fopen', @_) || die "$prog: $_[0]: $!\n"
}

sub _sysopen {
    my ($func, $file, $mode, $flags) = @_;
    @_ < 3 and croak "Not enough arguments for $func";
    @_ > 4 and croak "Too many arguments for $func";

    my $emode =
        $mode eq 'r'  ? Fcntl::O_RDONLY() :
        $mode eq 'w'  ? Fcntl::O_WRONLY() :
        $mode eq 'rw' ? Fcntl::O_RDWR()   :
        croak "Unknown $func() mode '$mode'"
    ;
    $flags = {} if !defined $flags;

    my $perms = 0;

    for my $k (keys %$flags) {
        my $v = !!$flags->{$k};
        $emode |=
            $k eq 'creat' ?
                defined $flags->{$k} ? do {
                    $perms = $flags->{$k};
                    Fcntl::O_CREAT()
                } :
                0
            :
            $k eq 'append'    ? $v && Fcntl::O_APPEND()    :
            $k eq 'async'     ? $v && Fcntl::O_ASYNC()     :
            $k eq 'direct'    ? $v && Fcntl::O_DIRECT()    :
            $k eq 'directory' ? $v && Fcntl::O_DIRECTORY() :
            $k eq 'excl'      ? $v && Fcntl::O_EXCL()      :
            $k eq 'noatime'   ? $v && Fcntl::O_NOATIME()   :
            $k eq 'noctty'    ? $v && Fcntl::O_NOCTTY()    :
            $k eq 'nofollow'  ? $v && Fcntl::O_NOFOLLOW()  :
            $k eq 'nonblock'  ? $v && Fcntl::O_NONBLOCK()  :
            $k eq 'sync'      ? $v && Fcntl::O_SYNC()      :
            $k eq 'trunc'     ? $v && Fcntl::O_TRUNC()     :
            croak "Unknown $func() flag '$k'"
        ;
    }

    if ($file =~ /\0/) {
        $! = Errno::ENOENT() if exists &Errno::ENOENT;
        return undef;
    }

    sysopen my $fh, $file, $emode, $perms or return undef;
    $fh
}

sub fsysopen_nothrow {
    _sysopen('fsysopen_nothrow', @_)
}

sub fsysopen {
    _sysopen('fsysopen', @_) || die "$prog: $_[0]: $!\n"
}

sub _opendir {
    my ($func, $dir) = @_;
    @_ < 2 and croak "Not enough arguments for $func";
    @_ > 2 and croak "Too many arguments for $func";

    if ($dir =~ /\0/) {
        $! = Errno::ENOENT() if exists &Errno::ENOENT;
        return undef;
    }

    opendir my $dh, $dir or return undef;
    $dh
}

sub fopendir_nothrow {
    _opendir('fopendir_nothrow', @_)
}

sub fopendir {
    _opendir('fopendir', @_) || die "$prog: $_[0]: $!\n"
}

'ok'

__END__

=head1 NAME

File::Open - wrap open/sysopen/opendir and give them a nice and simple interface

=head1 SYNOPSIS

 use File::Open qw(
     fopen    fopen_nothrow
     fsysopen fsysopen_nothrow
     fopendir fopendir_nothrow
 );

 my $fh = fopen $file;
 my $fh = fopen $file, $mode;
 my $fh = fopen $file, $mode, $layers;

 my $fh = fopen_nothrow $file or die "$0: $file: $!\n";
 my $fh = fopen_nothrow $file, $mode or die "$0: $file: $!\n";
 my $fh = fopen_nothrow $file, $mode, $layers or die "$0: $file: $!\n";

 my $fh = fsysopen $file, $mode;
 my $fh = fsysopen $file, $mode, \%flags;

 my $fh = fsysopen_nothrow $file, $mode or die "$0: $file: $!\n";
 my $fh = fsysopen_nothrow $file, $mode, \%flags or die "$0: $file: $!\n";

 my $dh = fopendir $dir;

 my $dh = fopendir_nothrow $dir or die "$0: $dir: $!\n";

=head1 EXAMPLES

 sub slurp {
   local $/;
   readline $_[0]
 }
 
 my $contents = slurp fopen 'input.txt';

 print { fopen 'output.txt', 'w' } "hello, world!\n";
 fopen('output.txt', 'a')->print("mtfnpy\n");  # handles are IO::Handle objects

 my $lock_file = 'my.lock';
 my $lock_fh = fsysopen $lock_file, 'w', { creat => 0644 };
 flock $lock_fh, LOCK_EX or die "$0: $lock_file: $!\n";

 my @entries = readdir fopendir '.';

=head1 DESCRIPTION

This module provides convenience wrappers around
L<C<open>|perlfunc/open FILEHANDLE,EXPR> and
L<C<sysopen>|perlfunc/sysopen FILEHANDLE,FILENAME,MODE>
for opening simple files and a wrapper around
L<C<opendir>|perlfunc/opendir DIRHANDLE,EXPR> for opening directories. Nothing
is exported by default; you have to specify every function you want to import
explicitly.

=head2 Functions

=over

=item fopen FILE

=item fopen FILE, MODE

=item fopen FILE, MODE, LAYERS

Opens FILE and returns a filehandle. If the open fails, it throws an exception
of the form C<"$program: $filename: $!\n">.

MODE is a string specifying how the file should be opened. The following values
are supported:

=over

=item C<'r'>, C<'E<lt>'>

Open the file for reading.

=item C<'w'>, C<'E<gt>'>

Open the file for writing. If the file exists, wipe out its contents and make
it empty; if it doesn't exist, create it.

=item C<'a'>, C<'E<gt>E<gt>'>

Open the file for appending. If the file doesn't exist, create it. All writes
will go to the end of the file.

=item C<'r+'>, C<'+E<lt>'>

Open the file for reading (like C<'r'>) but also allow writes.

=item C<'w+'>, C<'+E<gt>'>

Open the file for writing (like C<'w'>) but also allow reads.

=item C<'a+'>, C<'+E<gt>E<gt>'>

Open the file for appending (like C<'a'>) but also allow reads.

=back

In addition you can append a C<'b'> to each of the mode strings listed above.
This will cause L<C<binmode>|perlfunc/binmode FILEHANDLE, LAYER> to be called
on the filehandle.

If you don't specify a MODE, it defaults to C<'r'>.

If you pass LAYERS, C<fopen> will combine it with the open mode in the
underlying L<C<open>|perlfunc/open FILEHANDLE,EXPR> call. This gives you
greater control than the simple C<'b'> in MODE (which is equivalent to passing
C<:raw> as LAYERS). For example, to read from a UTF-8 file:

  my $fh = fopen $file, 'r', ':encoding(UTF-8)';
  # does
  #   open my $fh, '<:encoding(UTF-8)', $file
  # under the covers
 
  while (my $line = readline $fh) {
      ...
  }

See L<PerlIO> and L<Encode::Supported> for a list of available layers and
encoding names, respectively.

If you don't pass LAYERS, C<fopen> will use the default layers set via
C<use open ...>, if any (see L<open>). Default layers aren't supported on old
perls (i.e. anything before 5.10.0); on those you'll have to pass an explicit
LAYERS argument if you want to use encodings.

=item fopen_nothrow FILE

=item fopen_nothrow FILE, MODE

=item fopen_nothrow FILE, MODE, LAYERS

Works exactly like L<fopen|/"fopen FILE"> but if the open fails it simply
returns C<undef>.

=item fsysopen FILE, MODE

=item fsysopen FILE, MODE, FLAGS

Uses the more low-level interface of
L<C<sysopen>|perlfunc/sysopen FILEHANDLE,FILENAME,MODE> to open FILE.
If it succeeds, it returns a filehandle; if it fails, it throws an exception of
the form C<"$program: $filename: $!\n">.

MODE must be C<'r'>, C<'w'>, or C<'rw'> to open the file for reading, writing,
or both reading and writing, respectively (this corresponds to the open flags
C<O_RDONLY>, C<O_WRONLY>, and C<O_RDWR>).

You can pass additional flags in FLAGS, which must be a hash reference. The
hash keys are strings (specifying the flag) and the values are booleans
(indicating whether the flag should be off (default) or on) - with one
exception. The exception is the C<'creat'> flag; if set, its value must be a
number that specifies the permissions of the newly created file. See
L<perlfunc/umask EXPR> for details.

The following flags are recognized:

=over

=item C<'append'> - sets C<O_APPEND>

=item C<'async'> - sets C<O_ASYNC>

=item C<'creat'> - sets C<O_CREAT> and specifies file permissions

=item C<'direct'> - sets C<O_DIRECT>

=item C<'directory'> - sets C<O_DIRECTORY>

=item C<'excl'> - sets C<O_EXCL>

=item C<'noatime'> - sets C<O_NOATIME>

=item C<'noctty'> - sets C<O_NOCTTY>

=item C<'nofollow'> - sets C<O_NOFOLLOW>

=item C<'nonblock'> - sets C<O_NONBLOCK>

=item C<'sync'> - sets C<O_SYNC>

=item C<'trunc'> - sets C<O_TRUNC>

=back

See L<Fcntl> and L<open(2)> for the meaning of these flags. Some of them may
not exist on your system; in that case you'll get a runtime exception when you
try to specify a non-existent flag.

=item fsysopen_nothrow FILE, MODE

=item fsysopen_nothrow FILE, MODE, FLAGS

Works exactly like L<C<fsysopen>|/fsysopen FILE, MODE> but if the sysopen fails
it simply returns C<undef>.

=item fopendir DIR

=back

=head2 Methods

The returned filehandles behave like L<IO::Handle> objects (actually
L<IO::File> objects, which is a subclass of L<IO::Handle>). However, on perl
versions before 5.14.0 you have to C<use IO::Handle;> manually before you can
call any methods on them. (Current perl versions will do this for you
automatically but it doesn't hurt to load L<IO::Handle> anyway.)

Here is a toy example that copies all lines from one file to another, using
method calls instead of functions:

  use File::Open qw(fopen);
  use IO::Handle;  # not needed on 5.14+
 
  my $fh_in  = fopen $file_in,  'r';
  my $fh_out = fopen $file_out, 'w';
 
  while (defined(my $line = $fh_in->getline)) {
      $fh_out->print($line) or die "$0: $file_out: $!\n";
  }
 
  $fh_out->close or die "$0: $file_out: $!\n";
  $fh_in->close;

=head1 SEE ALSO

L<perlfunc/open FILEHANDLE,EXPR>,
L<perlfunc/binmode FILEHANDLE, LAYER>,
L<perlfunc/sysopen FILEHANDLE,FILENAME,MODE>,
L<perlfunc/opendir DIRHANDLE,EXPR>,
L<perlopentut>,
L<IO::Handle>,
L<Fcntl>,
L<open(2)>

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011, 2013, 2016 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
