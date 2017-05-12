package File::Path::Stderr;

use 5.005;  # yes, really

use strict;
#use warnings;

use File::Path ();

require Exporter;
@File::Path::Stderr::ISA = qw(Exporter);
@File::Path::Stderr::EXPORT = qw(mkpath rmpath);
@File::Path::Stderr::EXPORT_OK = qw(make_path remove_tree);
$File::Path::Stderr::VERSION = "2.00";

=head1 NAME

File::Path::Stderr - like File::Path but print to STDERR

=head1 SYNOPSIS

   use File::Path::Stderr qw(make_path remove_tree);

   make_path('foo/bar/baz', '/zug/zwang');
   make_path('foo/bar/baz', '/zug/zwang', {
       verbose => 1,
       mode => 0711,
   });

   remove_tree('foo/bar/baz', '/zug/zwang');
   remove_tree('foo/bar/baz', '/zug/zwang', {
       verbose => 1,
       error  => \my $err_list,
   });

   # legacy (interface promoted before v2.00)
   mkpath('/foo/bar/baz');
   mkpath('/foo/bar/baz', 1, 0711);
   mkpath(['/foo/bar/baz', 'blurfl/quux'], 1, 0711);
   rmtree('foo/bar/baz', 1, 1);
   rmtree(['foo/bar/baz', 'blurfl/quux'], 1, 1);

   # legacy (interface promoted before v2.06)
   mkpath('foo/bar/baz', '/zug/zwang', { verbose => 1, mode => 0711 });
   rmtree('foo/bar/baz', '/zug/zwang', { verbose => 1, mode => 0711 });

=head1 DESCRIPTION

This is a very, very simple wrapper around B<File::Path>.  All
exported functions function exactly the same as they do in B<File::Path>
except rather than printing activity reports to the currently selected
filehandle (which is normally STDOUT) the messages about what B<File::Path>
is doing are printed to STDERR.

=head2 Functions

The following functions from File::Path are currently supported:

=over

=item mkpath

=item rmpath

=item make_path

=item remove_tree

=back

By default, if you don't request a particular import list,
C<mkpath> and C<rmpath> will be exported by default.

=cut

sub File::Path::Stderr::End::DESTORY {
  my $self = shift;
  return $self->();
}

sub _with_stdderr(&) {
  # remember what file handle was selected
  my $old = select();

  # select STDERR instead
  select(STDERR);

  # after we've returned (but before the next statement)
  # switch the file handle back to what it was before
  my $run_on_destroy = bless sub { select($old) }, "File::Path::Stderr::End";

  # run the passed codeblock
  return $_[0]->();
}

sub mkpath      { return _with_stderr { File::Path::mkpath(@_); } }
sub rmpath      { return _with_stderr { File::Path::rmpath(@_); } }
sub make_path   { return _with_stderr { File::Path::make_path(@_); } }
sub remove_tree { return _with_stderr { File::Path::remove_tree(@_); } }

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copryright Mark Fowler 2003, 2012.  All Rights Reserved.

Most of the SYNOPSIS stolen directly from File::Path.
File::Path copyright (C) Charles Bailey, Tim Bunce and David
Landgren 1995-2009. All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File::Path::Stderr>.

Alternatively, you can simply fork this project on github and
send me pull requests.  Please see
L<http://github.com/2shortplanks/File-Path-Stderr>

=head1 SEE ALSO

L<File::Path>

=cut

1;
