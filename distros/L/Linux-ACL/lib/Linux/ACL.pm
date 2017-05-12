package Linux::ACL;

use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(getfacl setfacl);
our $VERSION = '0.05';

require XSLoader;
XSLoader::load('Linux::ACL', $VERSION);

1;
=head1 NAME

Linux::ACL - Perl extension for reading and setting Access Control Lists for files by libacl linux library.

=head1 VERSION

Version 0.05

=cut




=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

  use Linux::ACL;
  ($acl, $default_acl) = getfacl("path/to/file");
  setfacl("path/to/file", $acl [, $default_acl]);

=head1 EXPORT

=over

=item setfacl($$;$)

Set the ACL of the file or directory named by C<$path> to that
specified by C<$acl>.  If C<$path> names a directory, then the optional
C<$default_acl> argument can also be passed to specify the default ACL
for the directory.  See L<"ACL structure"> for information on how the
C<$acl> and C<$default_acl> hashes should be constructed.

=item getfacl($)

Return a reference to a hash containing information about the file's
ACL.  If the file is a directory with a default ACL, then a list is
returned, with the first entry being a hash reference to the ACL, and
the second being a hash reference to the default ACL.  See L<"Accessing
ACL structures"> for information on how to access these hashes, and
L<"ACL structure"> for information on how these hashes are internally
constructed.

=back

=head1 RETURN VALUES

=over

=item setfacl

returns TRUE if successful and FALSE if unsuccessful.

=item getfacl

if successful, returns a list containing a reference to
the hash describing an acl, and, if there is a default acl, a
reference to the hash describing the default acl.  If unsuccessful,
C<getfacl> returns a null list.

=back

=head1 Examples

getfacl example

  use Linux::ACL;
  use Data::Dumper;
  my @a = getfacl("/tmp");
  print Dumper \@a;

prints:

  $VAR1 = [
          {
            'uperm' => {
                         'w' => 1,
                         'r' => 1,
                         'x' => 1
                       },
            'gperm' => {
                         'w' => 1,
                         'r' => 1,
                         'x' => 1
                       },
            'other' => {
                         'w' => 1,
                         'r' => 1,
                         'x' => 1
                       }
          }
        ];

setfacl example

  use Linux::ACL;
  setfacl("/mnt/testacl/d", {
  	uperm=>{r=>1,w=>1,x=>1},
  	gperm=>{r=>1,w=>1,x=>1},
  	other=>{r=>1,w=>0,x=>1},
  	mask=>{r=>1,w=>1,x=>1},
  	group=>{
  		123456=>{r=>1,w=>1,x=>1}
  	}
  }, {
  	uperm=>{r=>1,w=>1,x=>1},
  	gperm=>{r=>1,w=>1,x=>1},
  	other=>{r=>1,w=>1,x=>1},
  	mask=>{r=>1,w=>1,x=>1}
  });
  system("getfacl /mnt/testacl/d");

prints:

  $ getfacl d
  # file: d
  # owner: user
  # group: user
  user::rwx
  group::rwx
  group:123456:rwx
  mask::rwx
  other::r-x
  default:user::rwx
  default:group::rwx
  default:mask::rwx
  default:other::rwx

=head1 AUTHOR

Yuriy Nazarov, C<< <nazarov at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-linux-acl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Linux-ACL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Linux::ACL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Linux-ACL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Linux-ACL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Linux-ACL>

=item * Search CPAN

L<http://search.cpan.org/dist/Linux-ACL/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Yuriy Nazarov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut