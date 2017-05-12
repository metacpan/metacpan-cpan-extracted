package File::Copy::Link;

use strict;
use warnings;
 
use Carp;
use File::Copy ();

require Exporter;
use base qw(Exporter);

our @EXPORT_OK = qw(copylink safecopylink);
our $VERSION = '0.06';

sub copylink {
    local $_ = @_ ? shift : $_;                 # default to $_ 
    croak "$_ not a link\n" unless -l;
    open my $fh, '<', $_ or croak "Can't open link $_: $!\n"; 
    unlink or croak "Can't unlink link $_: $!\n";
    my $ok = File::Copy::copy $fh, $_;
    croak "copy($fh $_) failed: $!\n" unless $ok;
    return $ok;
}

sub safecopylink {
    local $_ = @_ ? shift : $_;                 # default to $_ 
    croak "$_ not a link\n" unless -l;
    require File::Spec::Link;
    my $orig = File::Spec::Link->linked($_);
    croak "$_ link problem\n" unless defined $orig;
    unlink or croak "Can't unlink link $_: $!\n";
    my $ok = File::Copy::copy $orig, $_;
    croak "copy($orig $_) failed: $!\n" unless $ok;
    return $ok;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

File::Copy::Link - extension for replacing a link by a copy of the linked file

=head1 SYNOPSIS

  use File::Copy::Link;
  copylink 'file.lnk'; 

  use File::Copy::Link qw(safecopylink);
  safecopylink 'file.lnk'; 

=head1 DESCRIPTION

=over 4

=item C<copylink>

reads the filename linked to by the argument and replaced 
the link with a copy of the file.  It opens a filehandle to read from
the link, deletes the link, and then copies the filehandle back to the
link.

=item C<safecopylink>

does the same as C<copylink> but without the open-and-delete
manouvre.  Instead, it uses C<File::Spec::Link> to find the target of the
link and copies from there.

=back

This module is mostly a wrapper round C<File::Spec::Link::linked> and 
C<File::Copy::copy>, the functionality is available in a command line
script F<copylink>.
 
=head2 EXPORT

Nothing by default, can export C<copylink>, `C<safecopylink>.

=head1 SEE ALSO

copylink(1) File::Copy(3) File::Spec::Link(3)

=head1 AUTHOR

Robin Barker, <RMBarker@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2003, 2006, 2007, 2011, 2014 by Robin Barker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

$Id: Link.pm 342 2014-06-23 18:30:53Z robin $
