# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/Result.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::Result;
use strict;

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = bless {%args}, $class;
    return $self;
}

sub _elem
{
    my $self  = shift;
    my $field = shift;
    my $old   = $self->{$field};
    if (@_) {
        $self->{$field} = shift;
    }
    return $old;
}
sub mime_type { shift->_elem('mime_type', @_) }
sub text      { shift->_elem('text', @_) }
sub metadata  { shift->_elem('metadata', @_) }
sub filename  { shift->_elem('filename', @_) }

1;

__END__

=head1 NAME

File::Extract::Result - Extraction Result Object

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head2 text

Get/set the extracted text.

=head2 filename

Get/set the filename which the text was extracted from.

=head2 mime_type

Get/set the MIME type of the file that the text was extracted from.

=head2 metadata

Get/set the metadata. This can be anything depending on the processor
that created this result.

=cut
