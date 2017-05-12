# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/HTML.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::HTML;
use strict;
use base qw(File::Extract::Base);
use HTML::TreeBuilder;

sub mime_type { 'text/html' }
sub extract
{
    my $self = shift;
    my $file = shift;

    my $text;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($file);

    $text = $tree->as_text;
    $tree->delete;

    my $r = File::Extract::Result->new(
        text      => eval { $self->recode($text) } || $text,
        filename  => $file,
        mime_type => $self->mime_type,
    );
    return $r;
}

1;

__END__

=head1 NAME

File::Extract::HTML - Extract Text From HTML Files

=head1 SEE ALSO

L<File::Extract|File::Extract>
L<File::Extract::Base|File::Extract::Base>
L<HTML::TreeBuilder|HTML::TreeBuilder>

=cut