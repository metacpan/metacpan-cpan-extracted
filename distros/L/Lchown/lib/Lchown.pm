package Lchown;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT    = qw(lchown);
@EXPORT_OK = qw(lchown LCHOWN_AVAILABLE);

$VERSION = '1.01';

require XSLoader;
XSLoader::load('Lchown', $VERSION);

sub LCHOWN_AVAILABLE () {
    defined lchown(0,0) ? 1 : 0;
}

1;

__END__

=head1 NAME

Lchown - use the lchown(2) system call from Perl

=head1 SYNOPSIS

  use Lchown;

  lchown $uid, $gid, 'foo' or die "lchown: $!";

  my $count = lchown $uid, $gid, @filenames;

  # or
  
  use Lchown qw(lchown LCHOWN_AVAILABLE);

  warn "this system lacks the lchown system call\n" unless LCHOWN_AVAILABLE;

  ...

  # or
  
  use Lchown ();

  warn "this won't work\n" unless Lchown::LCHOWN_AVAILABLE;
  Lchown::lchown $uid, $gid, 'foo' or die "lchown: $!";

=head1 DESCRIPTION

Provides a perl interface to the C<lchown()> system call, on platforms that
support it.

=head1 DEFAULT EXPORTS

The following symbols are exported be default:

=over

=item lchown (LIST)

Like the C<chown> builtin, but using the C<lchown()> system call so that
symlinks will not be followed.  Returns the number of files successfully
changed.

On systems without the C<lchown()> system call, C<lchown> always returns
C<undef> and sets C<errno> to C<ENOSYS> (Function not implemented).

=back

=head1 ADDITIONAL EXPORTS

The following symbols are available for export but are not exported by
default:

=over 

=item LCHOWN_AVAILABLE ()

Returns true on platforms with the C<lchown()> system call, and false on
platforms without.

=back

=head1 SEE ALSO

L<perlfunc/chown>, L<lchown(2)>

=head1 AUTHOR

Nick Cleaton E<lt>nick@cleaton.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2009 Nick Cleaton, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
