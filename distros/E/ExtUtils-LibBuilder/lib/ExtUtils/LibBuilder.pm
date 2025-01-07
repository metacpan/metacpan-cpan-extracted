package ExtUtils::LibBuilder;

use warnings;
use strict;

our $VERSION = '0.09';
our $DEBUG   = 0;

use base 'ExtUtils::CBuilder';

use File::Spec;
use File::Temp qw/tempdir/;

=head1 NAME

ExtUtils::LibBuilder - A tool to build C libraries.

=head1 SYNOPSIS

    use ExtUtils::LibBuilder;
    my $libbuilder = ExtUtils::LibBuilder->new( %options );

=head1 METHODS

Supports all the method from ExtUtils::CBuilder. The following three
methods were adapted to be used in standalone C libraries.

=head2 new

This method creates a new ExtUtils::LibBuilder object. While it
supports all C<ExtUtils::CBuilder> methods some might work slightly
differently (namely the two below).

You can supply to the constructor any option recognized by
C<ExtUtils::CBuilder> constructor. None of them will be used by
C<LibBuilder>.

=head2 link

   $libbuilder -> link( objects     => [ "foo.o", "bar.o" ],
                        module_name => "foobar",
                        lib_file    => "libfoobar$libbuilder->{libext}");

Options to the link method are the same as the C<CBuilder>
counterpart. Note that the result is a standalone C Library and not a
bundle to be loaded by Perl.

Also, note that you can use the C<libext> key to retrieve from the
object the common library extension on the running system (including
the dot).

=head2 link_executable

  $libbuilder->link_executable( objects => ["main.o"],
                                extra_linker_flags => "-L. -lfoobar",
                                exe_file => "foobarcmd$libbuilder->{exeext}");

The C<link_executable> needs, as C<extra_linker_flags> options, the
name of the library and the search path. Future versions might include
better handling on the library files.

Also, note that you can use the C<exeext> key to retrieve from the
object the common executable extension on the running system
(including the dot).

=cut

sub new {
    my $class = shift;
    my %options = @_;

    my $self = bless ExtUtils::CBuilder->new(%options) => $class;
    # $self->{quiet} = 1;

    $self->{libext} = $^O eq "darwin" ? ".dylib" : ( $^O =~ /win/i ? ".dll" : ".so");
    $self->{exeext} = $^O =~ /win32/i ? ".exe" : "";

    $DEBUG && print STDERR "\nTesting Linux\n\n";
    return $self if $^O !~ /darwin|win32/i && $self->_try;

    $DEBUG && print STDERR "\nTesting Darwin\n\n";
    $self->{config}{lddlflags} =~ s/-bundle/-dynamiclib/;
    return $self if $^O !~ /win32/i && $self->_try;

    $DEBUG && print STDERR "\nTesting Win32\n\n";
    *link = sub {
        my ($self, %options) = @_;
        my $LD = $self->{config}{ld};
        $options{objects} = [$options{objects}] unless ref $options{objects};
        system($LD, "-shared", "-o",
               $options{lib_file},
               @{$options{objects}});
    };
    *link_executable = sub {
        my ($self, %options) = @_;
        my $LD = $self->{config}{ld};
        my @CFLAGS = split /\s+/, $options{extra_linker_flags};
        $options{objects} = [$options{objects}] unless ref $options{objects};
        system($LD, "-o",
               $options{exe_file},
               @CFLAGS,
               @{$options{objects}});
    };
    return $self if $self->_try;

    $DEBUG && print STDERR "\nNothing...\n\n";
    return undef;
}

sub _try {
    my ($self) = @_;
    my $tmp = tempdir CLEANUP => 1;
    _write_files($tmp);

    my @csources = map { File::Spec->catfile($tmp, $_) } qw'library.c test.c';
    my @cobjects = map { $self->compile( source => $_) } @csources;

    my $libfile = File::Spec->catfile($tmp => "libfoo$self->{libext}");
    my $exefile = File::Spec->catfile($tmp => "foo$self->{exeext}");

    $self->link( objects     => [$cobjects[0]],
                 module_name => "foo",
                 lib_file    => $libfile );

    return 0 unless -f $libfile;

    $self->link_executable( exe_file           => $exefile,
                            extra_linker_flags => "-L$tmp -lfoo",
                            objects => [$cobjects[1]]);

    return 0 unless -f $exefile && -x _;
    return 1;
}

=head1 AUTHOR

Alberto Simoes, C<< <ambs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-extutils-libbuilder at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExtUtils-LibBuilder>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ExtUtils::LibBuilder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-LibBuilder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ExtUtils-LibBuilder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ExtUtils-LibBuilder>

=item * Search CPAN

L<http://search.cpan.org/dist/ExtUtils-LibBuilder/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Alberto Simoes.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


sub _write_files {
    my $outpath = shift;
    my $fh;
    seek DATA, 0, 0;
    while(<DATA>) {
        if (m!^==\[(.*?)\]==!) {
	    my $fname = $1;
            $fname = File::Spec->catfile($outpath, $fname);
            open $fh, ">$fname" or die "Can't create temporary file $fname\n";
        } elsif ($fh) {
            print $fh $_;
        }
    }
}

1; # End of ExtUtils::LibBuilder


__DATA__
==[library.c]==
  int answer(void) {
      return 42;
  }
==[test.c]==
#include <stdio.h>
extern int answer(void);
int main() {
    int a = answer();
    printf("%d\n", a);
    return 0;
}


