package Directory::Iterator;

use 5.006002;
use strict;
use warnings;

our @ISA;
our $VERSION = '1.001';

BEGIN {

    eval {
	require Directory::Iterator::XS;
	@ISA = 'Directory::Iterator::XS';
    };
    if ($@) {
	require Directory::Iterator::PP;
	@ISA = 'Directory::Iterator::PP';
    }
}

sub new {
	my ($class, $dir, %options) = @_;
	my $self = $class->SUPER::new( $dir );
	while (my ($method,$arg) = each %options) {
		$self->$method($arg);
	}
	return $self;
}
1;
__END__
=head1 NAME

Directory::Iterator - Simple, efficient recursive directory listing

=head1 SYNOPSIS

  use Directory::Iterator;

  my $it = Directory::Iterator->new($dir, %opts);
  while (my $file = <$it>) {
    print "$file\n";
  }

=head1 DESCRIPTION

This is a simple, efficient way to get a recursive list of all files under a
specified directory.

It implements a typical iterator interface, making it simple to convert code
that processes a list of files to use this instead.  The directory is read
as the list is consumed, so memory overhead is minimal.

This module loads the appropriate backend; either L<Directory::Iterator::PP>
or L<Directory::Iterator::XS>.  With the pure-perl backend, the speed is
equivalent to L<File::Find>; the XS backend is a few times faster,
particularly on systems which implement _DIRENT_HAVE_D_TYPE (mainly Linux and
BSD).

As a bit of syntactic sugar, the module also implements a constructor which
forwards options to the backend; i.e.

 my $list = Directory::Iterator->new($dir, show_dotfiles=>1);

Is equivalent to 

 my $list = Directory::Iterator->new($dir);
 $list->show_dotfiles(1);

=head2 METHODS

Currently, both back ends support the following options:

=over

=item B<next>()

Advance to the next file and return its name; returns undef after all names
have been read.  This is the underlying method for the I<<>> operator.

=item B<get>()

Return the latest file name without advance to the next file; returns undef
after all names have been read.  This is the underlying method for the I<"">
operator.

=item B<prune>()

Close the directory that is currently being read, so no more files from it
will be returned.

As currently implemented, it's possible that some subdirectories could've
been queued before the first file was seen, so it's not guaranteed that a
single call to prune will always suffice. Its purpose is simply to be more
efficient than continuing to read files from an unwanted directory.

To skip over a subdirectory with a single call, use B<show_directories> and
B<prune_directory>.

=item B<show_dotfiles>(I<ARG>) 

If I<ARG> is true, hidden files & directories, those with names that begin
with a I<.> will be processed as regular files.  By default, such files are
skipped.

=back

=item B<show_directories>(I<ARG>) 

If I<ARG> is true, directories will be returned from the list, in addition
to being queued to process their files.

=item B<is_directory>

Returns true if the most recently returned file entry is a directory; used
to enable quickly differentiating directories form plain files.

=item B<prune_directory>

Removes the most recently queued directory, and returns the name of the
removed directory.  This allows the module to quickly skip over
subdirectories entirely, without ever opening them.

=item B<recursive>(I<ARG>) 

If I<ARG> is false, just look in the top-level directory; don't queue
subdirectories for processing.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Directory::Iterator::PP>

L<Directory::Iterator::XS>

L<File::Find>

=head1 AUTHOR

Steve Sanbeg

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steve Sanbeg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
