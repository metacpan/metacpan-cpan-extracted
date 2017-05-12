package File::Temp::Trace;

=head1 NAME

File::Temp::Trace - Trace the creation of temporary files

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=begin readme

=head1 REQUIREMENTS

The following packages are required:

  Attribute::Handlers
  Carp
  File::Path
  File::Spec
  File::Temp
  overload
  Scalar::Util
  self

=end readme

=head1 SYNPOSIS

    package MyPkg;

    use File::Temp::Trace;

    my $tmp = File::Temp::Trace->tempdir();

    print STDERR "New temporary directory ${tmp} created.";

    sub create_file : skip_temp_log {
	my ($tmp, $ext) = @_;
	return $tmp->tempfile( suffix => $ext );
    }

    sub create_text {
	my ($tmp, $ext) = @_;
	return create_file($tmp, '.txt');
    }

    my $fh = create_text($tmp);

    # $fh->filename will be named "MyPkg-create_text-XXXXXXXX.txt",
    # where XXXXXXXX is a unique string.

=head1 DESCRIPTION

This module allows you to trace the creation of temporary files. By
default, these files are all created in the same directory, and their
names are prefixed by the name of the function or method that created
them.

You can optionally log the creation of temporary files with a stack
trace as well.

=cut

use strict;
use warnings;

use self;

use overload
    '""' => \&dir;

use Attribute::Handlers;
use Carp qw( longmess );
use File::Path qw( make_path );
use File::Spec;
use File::Temp ();
use Scalar::Util qw( refaddr );

BEGIN {
    %File::Temp::Trace::SkipName = ( );
}

sub UNIVERSAL::skip_temp_log : ATTR(CODE) {
  my ($pkg, $sym, $ref, $attr, $data) = @_;
  $File::Temp::Trace::SkipName{substr($$sym,1)} = $data;
}

my %LogFiles = ( );

sub _name_to_template {
    my ($name) = @_;
    $name =~ s/\:\:/-/g;
    $name = "UNKNOWN", if (($name eq "") || ($name eq "(eval)"));
    return "${name}-XXXXXXXX";
}

=for readme stop

Methods are documented below:

=head2 tempdir

  $tmp = File::Temp::Trace->tempdir(%options);

Creates a new temporary directory and returns a blessed reference to
the name of that temporary directory.

The following options may be used:

=over

=item cleanup

Delete the directory and contents once the object is
destroyed. True by default.

=item template

A template for the name of directory. By default, it is
C<File-Temp-Trace-XXXXXXXX>, where C<XXXXXXXX> is a unique string.

The template name must end with at least C<XXXX>.

=item dir

The parent directory of the temporary directory. By default, it is in
the system temporary directory.

=item log

Create a log file that gives the time that a temporary file was
created, and a L<Carp::longmess> stack trace of the calling methods
that created it.

Note that if L</cleanup> is true, then the log file will be deleted
when the object is destroyed.

=back

=cut

sub tempdir {
    my $class = shift || __PACKAGE__;

    my %opts = @args;

    my %ftopts = ( CLEANUP => 1, TEMPLATE => _name_to_template(__PACKAGE__), TMPDIR => 1 );
    foreach my $o (qw( cleanup template tmpdir dir )) {
	$ftopts{ uc($o) } = $opts{$o}, if (exists $opts{$o});
    }

    $self = \ File::Temp->newdir($ftopts{TEMPLATE}, %ftopts);
    bless $self, $class;

    if ($opts{log}) {
	$LogFiles{ refaddr $self } = File::Temp->new( TEMPLATE => _name_to_template(__PACKAGE__), DIR => $self->dir, SUFFIX => ".log", UNLINK => 0 );
    }

    return $self;
}

=head2 dir

  $path = $tmp->dir;

The pathname of the temporary directory created by L</tempdir>.

Note that the object is overloaded to return the pathname on
stringification.

=cut

sub dir {
    return ${$self};
}

=head2 logfile

  $fh = $tmp->logfile;

Returns the filehandle of the log file, or C<undef> if the C<log>
option was not specified in the constructor.

=cut

sub logfile {
    return $LogFiles{ refaddr $self };
}

=head2 file

  $fh = $tmp->file(%options);

Creates a new temporary file in L</dir>, and returns a filehandle.

Note that unlike the corresponding method in L<File::Temp>, it does
not also return a filename.  To obtain a filename, use

  $fh->filename

The file is created using L<File::Temp>, so other methods from
L<File::Temp> may be used to query or manipulate the file.

The name of the file is of the form C<CALLER-XXXXXXXX> (plus any
suffix, if given as an option---see below), where C<CALLER> is the
name of the function of method that called L</file> and C<XXXXXXXX> is
a unique string.  This helps with debugging by making it easier to
identify which temporary file in L</dir> was created by a particular
method.

In the case where a single method or function is used to create a
particular type of file, and is called by several other methods or
functions, it can be tagged with the C<skip_temp_log> attribute, so that
the name of the caller will come from further down the call stack. For
example,

  sub create_file : skip_temp_log {
    ...
  }

  sub fun_a {
    create_file(...);
  }

  sub fun_b {
    create_file(...);
  }

In this case, the two temporary files will be labelled with C<fun_a>
and C<fun_b> rather than both with C<create_file>.

The following options may be used.

=over

=item unlink

If set to true, delete the file when the filehandle is destroyed. This
is set disabled by default, since the parent temporary directory is
normally set to be deleted.

=item suffix

The suffix (or extension) of the file.

=item exlock

The exclusive lock flag. True by default.

=item log

Create a separate log file when this file is created. The log file has
the same filename as the this file, plug the C<.log> suffix.

(In theory this is unsafe, as it does not ensure that a file with the
same name exists, though such a case in unlikely.)

=item dir

Create a subdirectory in the L</dir> directory, if it does not already
exist, and put the temporary file in there.

=back

=head2 tempfile

  $fh = tempfile(%options);

This is an alias of L</file>.

=cut

sub tempfile {
    my $level = 1;
    my @frame = ( );
    my $name;
    do {
	@frame = caller($level++);
	$name   = $frame[3] || "";
    } while ($name && (exists $File::Temp::Trace::SkipName{$name}));

    my %opts = @args;

    my %ftopts = ( UNLINK => 0, TEMPLATE => _name_to_template($name), DIR => $self->dir, EXLOCK => 1 );
    foreach my $o (qw( unlink suffix exlock )) {
	$ftopts{ uc($o) } = $opts{$o}, if (exists $opts{$o});
    }

    if (exists $opts{dir}) {
	$ftopts{DIR} = File::Spec->catfile(File::Spec->splitdir($self->dir), File::Spec->splitdir($opts{dir}));
	make_path($ftopts{DIR});
    }

    my $fh = File::Temp->new(%ftopts);
    if ((my $lh = $self->logfile) || ($opts{log})) {
	my $ts  = sprintf("[%s]", (scalar gmtime()));
	my $msg = sprintf("%s File %s created%s", $ts, $fh->filename, longmess());
	$msg =~ s/\n(.)/\n$ts $1/g;

	if ($lh) { print $lh $msg; }
	if ($opts{log}) {
	    open my $fhlh, sprintf(">%s.log", $fh->filename);
	    print $fhlh $msg;
	    close $fhlh;
	}
    }
    return $fh;
}

=begin readme

=head1 REVISION HISTORY

=for readme include file=Changes type=text

=end readme

=for readme continue

=head1 SEE ALSO

L<File::Temp>

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo@cpan.org> >>

=for readme stop

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-temp-trace@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Temp-Trace>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Temp::Trace

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Temp-Trace>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Temp-Trace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Temp-Trace>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Temp-Trace/>

=item * GitHub

L<https://github.com/robrwo/File-Temp-Trace>

=back

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

