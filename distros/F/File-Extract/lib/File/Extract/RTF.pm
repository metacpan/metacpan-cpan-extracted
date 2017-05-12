# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/RTF.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::RTF;
use strict;
use base qw(File::Extract::Base);
use RTF::Lexer qw(PTEXT ENBIN ENHEX CSYMB);

sub mime_type { 'application/rtf' }
sub extract
{
    my $self  = shift;
    my $file  = shift;

    my $p = RTF::Lexer->new(in => $file);

    my $text;
    my $token = '';
    do {
        $token = $p->get_token;

        if ($token->[0] == ENHEX) {
            $text .= pack("H2", $token->[1]);
        } elsif ($token->[0] == CSYMB && $token->[1] =~ /^\s+$/) {
            $text .= $token->[1];
        } elsif ($token->[0] == PTEXT || $token->[0] == ENBIN) {
            $text .= $token->[1];
        }
    } until $p->is_stop_token($token);

    return File::Extract::Result->new(
        text      => eval { $self->recode($text) } || $text,
        filename  => $file,
        mime_type => $self->mime_type,
    );
}

1;

__END__

=head1 NAME

File::Extract::RTF - Extract Text From RTF Files

=head1 SEE ALSO

L<File::Extract|File::Extract>
L<File::Extract::Base|File::Extract::Base>
L<RTF::Lexer>

=cut

