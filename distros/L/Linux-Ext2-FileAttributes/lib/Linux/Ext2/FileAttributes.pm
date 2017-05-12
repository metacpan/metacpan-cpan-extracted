=head1 NAME

Linux::Ext2::FileAttributes - Access to Ext2/3 filesystem extended attributes

=head1 SYNOPSIS

  use Linux::Ext2::FileAttributes;

  my $logfile    = '/var/log/notreal';
  my $unchanging = '/etc/motd';

  # set immutable flag on $unchanging
  set_immutable( $unchanging );

  # set append flag on $logfile
  set_append_only( $logfile );

  # check if a file is immutable
  print "[$unchanging] is immutable\n" if is_immutable( $unchanging );

=head1 DESCRIPTION

Linux::Ext2::FileAttributes provides access to the Ext2 and Ext3
filesystem extended attributes from within perl.

This module is pure perl and doesn't require or use the external L<chattr>
or L<lsattr> binaries which can save a lot of load when doing filesystem
traversal and modification

=cut


package Linux::Ext2::FileAttributes;
use strict;
use warnings;

# The first constant is from http://www.netadmintools.com/html/2ioctl_list.man.html
# Hard coding these removes the dependency on h2ph

use constant EXT2_IOC_GETFLAGS => 0x80046601;
use constant EXT2_IOC_SETFLAGS => 0x40046602;
use constant EXT2_IMMUTABLE_FL => 16;
use constant EXT2_APPEND_FL    => 32;

require Exporter;
use vars qw(@EXPORT @ISA $VERSION);

#--------------------------------#

@ISA = qw(Exporter);
@EXPORT = qw(
             is_immutable    clear_immutable    set_immutable
             is_append_only  clear_append_only  set_append_only
            );

$VERSION = '0.01';


#--------------------------------#

my %constants = (
  immutable   => EXT2_IMMUTABLE_FL,
  append_only => EXT2_APPEND_FL,
);

=head1 FUNCTIONS

By default this module exports:
             is_immutable    clear_immutable    set_immutable
             is_append_only  clear_append_only  set_append_only

=over 4

=item set_immutable

This function takes a filename and attempts to set its immutable flag.

If this flag is set on a file, even root cannot change the files content
without first removing the flag.

=item is_immutable

This function takes a filename and returns true if the immutable flag is
set and false if it isn't.

=item clear_immutable

This function takes a filename and removes the immutable flag if it
is present.

=item set_append_only

This function takes a filename and attempts to set its appendable flag.

If this flag is set on a file then its contents can be added to but not
removed unless the flag is first removed.

=item is_append_only

This function takes a filename and returns true if the immutable flag is
set and false if it isn't.

=item clear_append_only

This function takes a filename and removes the appendable flag if it
is present.

=back

=cut

# generate get, set and clear methods for each value in
# %constants (above)

for my $name (keys %constants) {
  my $is_sub = sub {
    my $file = shift;
    my $flags = _get_ext2_attributes($file);
    return unless defined $flags;
    return $flags & $constants{ $name };
  };

  my $set_sub = sub {
    my $file = shift;
    my $flags = _get_ext2_attributes($file);
    return unless defined $flags;
    return _set_ext2_attributes($file, $flags | $constants{ $name });
  };

  my $clear_sub = sub {
    my $file = shift;
    my $flags = _get_ext2_attributes($file);
    return unless defined $flags;
    return _set_ext2_attributes($file, $flags & ~$constants{ $name } );
  };

  no strict 'refs';
  *{__PACKAGE__ . '::is_' . $name } = $is_sub;
  *{__PACKAGE__ . '::set_' . $name } = $set_sub;
  *{__PACKAGE__ . '::clear_' . $name } = $clear_sub;
}

#--------------------------------#

# TODO
# export in an expert tag in 0.2
# also export the hash of constants above.

sub _get_ext2_attributes {
  my $file = shift;
  open my $fh, $file
    or return;
  my $res = pack 'i', 0;
  return unless defined ioctl($fh, EXT2_IOC_GETFLAGS, $res);
  $res = unpack 'i', $res;
}

sub _set_ext2_attributes {
  my $file = shift;
  my $flags = shift;
  open my $fh, $file
    or return;
  my $flag = pack 'i', $flags;
  return unless defined ioctl($fh, EXT2_IOC_SETFLAGS, $flag);
}

# export as expert tag ########################




#--------------------------------l

# END OF MODULE CODE

1;

#--------------------------------#


=head1 DEPENDENCIES

Linux::Ext2::FileAttributes has no external dependencies.

=head1 TESTS

As Linux::Ext2::FileAttributes is something of a niche module, which
requires an Ext2/Ext3 file system and root powers to run, I've placed
some test longer scripts in the examples directory to both show how to
us it and provide another set of tests for detecting regressions.

=head1 SEE ALSO

Filesys::Ext2 provides a different interface to some of the same
information. That module wraps the command line tools (lsattr and
chattr) rather than speaking directly to the ioctl.

L<http://search.cpan.org/~jpierce/Filesys-Ext2-0.20/Ext2.pm>

Native Ext2 commands:

L<chattr>, L<lsattr>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2008 Dean Wilson.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dean Wilson <dean.wilson@gmail.com>

=head1 ACKNOWLEDGEMENTS

Richard Clamp did the heavy lifting on this module and taught me a
fair chunk about using ioctls in perl while doing it. The cool stuff's
his. The errors are mine.

=cut
