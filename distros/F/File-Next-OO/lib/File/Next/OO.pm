package File::Next::OO;

$VERSION = '0.04';
use File::Next 0.38;

#use warnings;
use strict;

BEGIN {

  sub new {
    shift if ref $_[1] eq 'HASH';
    my $i = File::Next::files(@_);
    return wantarray ? do { my @t; while( my $f = $i->() ){ push @t, $f } @t } : $i;
  }

  *files = *new;
  *name  = *File::Next::name;
  *dir   = *File::Next::dir;

  sub dirs {
    shift if ref $_[1] eq 'HASH';
    my $i = File::Next::dirs(@_);
    return wantarray ? do { my @t; while( my $f = $i->() ){ push @t, $f } @t } : $i;
  }

}

1;
__END__

=head1 NAME

File::Next::OO - File-finding iterator Wrapper for C<File::Next::files> function


=head1 VERSION

This document describes File::Next::OO version 0.04


=head1 SYNOPSIS

File::Next::OO is just a wrapper around C<File::Next::files> function. 
But it is easy to remember and less typing. 

Call it always with object notation. Not mixed as in File::Next itself.


    use File::Next::OO;

    my $iter = File::Next::OO->new( '/tmp', '/var' );

    while ( my $file = $iter->() ) {
      ..
    }

  use File::Next::OO;
  my $files = File::Next::OO->new(
    { file_filter => sub { -f $File::Next::OO::name and /\.mp3$/ } },
    "/tmp"
  );

  while ( my $file = $files->() ) {
    print $file, $/;
  }


  # in array context return a list of all matches
  my @files = File::Next::OO->new( "/tmp" );

  # new and files are aliased use files if you like
  my @files = File::Next::OO->files( "/tmp" );
    

  # and the same with dirs
  my @dirs = File::Next::OO->dirs('/tmp');

  # or in peaces
  my $dirs = File::Next::OO->dirs( '/tmp' );
  while( my $dir = $dirs->() ){
    print $dir, "\n";
  }

=head1 DESCRIPTION

=head2 new

new takes a list of directories and optional a hashref with params.
For all the details see File::Next::files documentation

=head3 file_filter -> \&file_filter

The file_filter lets you check to see if it's really a file you
want to get back.  If the file_filter returns a true value, the
file will be returned; if false, it will be skipped.

The file_filter function takes no arguments but rather does its work through
a collection of variables.

=over 4

=item * C<$_> is the current filename within that directory

=item * C<$File::Next::dir> is the current directory name

=item * C<$File::Next::name> is the complete pathname to the file

=item * C<$File::Next::OO::dir> alias for C<$File::Next::dir>

=item * C<$File::Next::OO::name> alias for C<$File::Next::name>

=back

These are analogous to the same variables in L<File::Find>.

    my $iter = File::Find::files( { file_filter => sub { /\.txt$/ } }, '/tmp' );

By default, the I<file_filter> is C<sub {1}>, or "all files".

=head3 descend_filter => \&descend_filter

The descend_filter lets you check to see if the iterator should
descend into a given directory.  Maybe you want to skip F<CVS> and
F<.svn> directories.

    my $descend_filter = sub { $_ ne "CVS" && $_ ne ".svn" }

The descend_filter function takes no arguments but rather does its work through
a collection of variables.

=over 4

=item * C<$_> is the current filename of the directory

=item * C<$File::Next::dir> is the complete directory name

=item * C<$File::Next::OO::dir> alias for C<$File::Next::dir>

=back

The descend filter is NOT applied to any directory names specified
in the constructor.  For example,

    my $iter = File::Find::OO->files( { descend_filter => sub{0} }, '/tmp' );

always descends into I</tmp>, as you would expect.

By default, the I<descend_filter> is C<sub {1}>, or "always descend".

=head3 error_handler => \&error_handler

If I<error_handler> is set, then any errors will be sent through
it.  By default, this value is C<CORE::die>.


=head2 files 

files is a alias for new it is just a matter of taste

=head2 dirs

takes a list of directories and optional a hashref with params.
For all the details see File::Next::dirs documentation

In scalar context a iterator is returned, that walks directories. Each call to the iterator returns another directory.

In list context a list with all dirs is returned.


=head1 CONFIGURATION AND ENVIRONMENT

File::Next::OO requires no configuration files or environment variables.

=head1 DEPENDENCIES

this module relies on C<File::Next> 0.38 and is only a syntax wrapper around it.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-file-next-oo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Boris Zentner  C<< <bzm@2bz.de> >>

=head1 THANKS

The testcases and documentation is mostly stolen from
Andy Lester's incredible L<File::Next> module.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Boris Zentner C<< <bzm@2bz.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
