# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/PDF.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::PDF;
use strict;
use base qw(File::Extract::Base);
use CAM::PDF;
use File::Extract::Result;

sub mime_type { 'application/pdf' }
sub extract
{
    my $self = shift;
    my $file = shift;

    my $doc  = CAM::PDF->new($file);
    my $text = '';

    foreach my $p (1..$doc->numPages()) {
        $text .= $doc->getPageText($p);
    }

    return File::Extract::Result->new(
        text      => eval { $self->recode($text) } || $text,
        filename  => $file,
        mime_type => $self->mime_type
    );
}

1;

__END__

=head1 NAME

File::Extract::PDF - Extract Text From PDF

=cut