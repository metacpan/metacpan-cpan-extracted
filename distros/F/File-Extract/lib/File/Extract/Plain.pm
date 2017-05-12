# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/Plain.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::Plain;
use strict;
use base qw(File::Extract::Base);

sub mime_type { 'text/plain' }
sub extract
{
    my $self = shift;
    my $file = shift;

    open(F, $file) or Carp::croak("Failed to open file $file: $!");
    local $/ = undef;
    my $text = scalar(<F>);
    my $r = File::Extract::Result->new(
        text      => eval { $self->recode($text) } || $text, 
        mime_type => $self->mime_type,
        filename  => $file,
    );
}

1;

__END__

=head1 NAME

File::Extract::Plain - Extract Text From Plain Text Files

=head1 SEE ALSO

L<File::Extract|File::Extract>
L<File::Extract::Base|File::Extract::Base>

=cut
