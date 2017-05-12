# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/MP3.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::MP3;
use strict;
use base qw(File::Extract::Base);
use MP3::Info qw(get_mp3tag);

sub mime_type { 'audio/mpeg' }
sub extract
{
    my $self = shift;
    my $file = shift;

    my $hash   = get_mp3tag($file);
    my %p;

    while (my($field, $value) = each %$hash) {
        next unless $value;
        $p{lc $field} = $value;
    }

    my $r = File::Extract::Result->new(
        metadata  => %p,
        filename  => $file,
        mime_type => $self->mime_type,
    );
    return $r;
}

1;

__END__

=head1 NAME

File::Extract::MP3 - Extract Text From MP3 Files

=head1 SEE ALSO

L<File::Extract|File::Extract>
L<File::Extract::Base|File::Extract::Base>
L<MP3::Info>

=cut

