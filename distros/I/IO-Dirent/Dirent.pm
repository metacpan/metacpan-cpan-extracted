package IO::Dirent;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw( DT_UNKNOWN
		 DT_FIFO
		 DT_CHR
		 DT_DIR
		 DT_BLK
		 DT_REG
		 DT_LNK
		 DT_SOCK
		 DT_WHT
	       );
@EXPORT = qw( readdirent nextdirent );
%EXPORT_TAGS = ('ALL' => [@EXPORT, @EXPORT_OK]);
$VERSION = '0.05';

use constant DT_UNKNOWN =>   0;
use constant DT_FIFO    =>   1;    ## named pipe (fifo)
use constant DT_CHR     =>   2;    ## character special
use constant DT_DIR     =>   4;    ## directory
use constant DT_BLK     =>   6;    ## block special
use constant DT_REG     =>   8;    ## regular
use constant DT_LNK     =>  10;    ## symbolic link
use constant DT_SOCK    =>  12;    ## socket
use constant DT_WHT     =>  14;    ## whiteout

bootstrap IO::Dirent $VERSION;

1;
__END__

=head1 NAME

IO::Dirent - Access to dirent structs returned by readdir

=head1 SYNOPSIS

  use IO::Dirent;

  ## slurp-style
  opendir DIR, "/usr/local/foo";
  my @entries = readdirent(DIR);
  closedir DIR;

  print $entries[0]->{name}, "\n";
  print $entries[0]->{type}, "\n";
  print $entries[0]->{inode}, "\n";

  ## using the enumerator
  opendir DIR, "/etc";
  while( my $entry = nextdirent(DIR) ) {
    print $entry->{name} . "\n";
  }
  closedir DIR;

=head1 DESCRIPTION

B<readdirent> returns a list of hashrefs. Each hashref contains the
name of the directory entry, its inode for the filesystem it resides
on and its type (if available). If the file type or inode are not
available, it won't be there!

B<nextdirent> returns the next dirent as a hashref, allowing you to
iterate over directory entries one by one. This may be helpful in
low-memory situations or where you have enormous directories.

B<IO::Dirent> exports the following symbols by default:

    readdirent

    nextdirent

The following tags may be exported to your namespace:

    ALL

which includes B<readdirent>, B<nextdirent> and the following symbols:

    DT_UNKNOWN
    DT_FIFO
    DT_CHR
    DT_DIR
    DT_BLK
    DT_REG
    DT_LNK
    DT_SOCK
    DT_WHT

These symbols can be used to test the file type returned by
B<readdirent> in the following manner:

    for my $entry ( readdirent(DIR) ) {
        next unless $entry->{'type'} == DT_LNK;

        print $entry->{'name'} . " is a symbolic link.\n";
    }

For platforms that do not implement file type in its dirent struct,
B<readdirent> will return a hashref with a single key/value of 'name'
and the filename (effectively the same as readdir). This is subject
to change, if I can implement some of the to do items below.

=head1 CAVEATS

This was written on FreeBSD and OS X which implement a robust (but
somewhat non-standard) dirent struct and which includes a file type
entry. I have plans to make this module more portable and useful by
doing a stat on each directory entry to find the file type and inode
number when the dirent.h does not implement it otherwise.

Improvements and additional ports are welcome.

=head1 TO DO

=over 4

=item *

For platforms that do not implement a dirent struct with file type,
do a stat on the entry and populate the structure anyway.

=item *

Do some memory profiling (I'm not sure if I have any leaks or not).

=back

=head1 COPYRIGHT

Copyright 2002, 2011 Scott Wiersdorf.

This library is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License.

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Thanks to Nick Ing-Simmons for his help on the perl-xs mailing list.

=head1 SEE ALSO

dirent(5), L<perlxstut>, L<perlxs>, L<perlguts>, L<perlapi>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
