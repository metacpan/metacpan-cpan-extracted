package Launcher::Cascade::FileReader::Seekable;

=head1 NAME

Launcher::Cascade::FileReader::Seekable - a filereader that memorizes its position between reads.

=head1 SYNOPSIS

    use Launcher::Cascade::FileReader::Seekable;

    my $f = new Launcher::Cascade::FileReader -path => ... ;

    my $fh1 = $f->open();
    my $line1 = <$fh1>; # first line
    $f->close();

    # later, in a nearby piece of code

    my $fh2 = $f->open(); # different filehandle
    my $line2 = <$fh2>; # next line


=head1 DESCRIPTION

Launcher::Cascade::FileReader::Seekable inherits from
Launcher::Cascade::FileReader but keeps in memory the position where it was at
when the filehandle is closed. Subsequent calls to open() will perform the
necessary operations to resume reading where it last stopped, be it when
reading a local file, or a remote file through ssh.

=cut

use strict;
use warnings;

use base qw( Launcher::Cascade::FileReader );

use IO::Handle;

=head2 Attributes

=over 4

=item B<position>

=back

=cut
Launcher::Cascade::make_accessors qw( position );

=head2 Methods

=cut

# _remote_cat: the command to launch remotely to read a file over ssh
# either return a regular 'cat' if one wants to start from the start, or a Perl
# one-liner to first seek the wanted position.
sub _remote_cat {

    my $self = shift;
    my $path = shift;

    my $pos = $self->position();

    if ( $pos ) {
	return qq#perl -e "open IN,q{<},pop;seek IN,pop,0;print while <IN>" $pos $path#
    }
    else {
	return $self->SUPER::_remote_cat($path);
    }
}

=over 4

=item B<close>

Stores the filehandle's position in the position() attribute, then closes the
filehandle.

=cut

sub close {

    my $self = shift;
    $self->position(tell($self->filehandle()) + ($self->host() ? $self->position() || 0 : 0));
    $self->SUPER::close();
}

=item B<open>

Opens the file (locally or remotely), seeks to the desired position() and
returns a filehandle.

=cut

sub open {

    my $self = shift;
    my $fh = $self->SUPER::open();

    if ( $self->position() && !$self->host() ) {
	seek $fh, $self->position(), 0;
    }
    return $fh;
}

=back

=head1 BUGS AND CAVEATS

=over 4

=item *

C<perl> has to be in a directory mentioned in the C<PATH> environment variable
on the remote host, because the C<seek> operation on remote files is performed
with a Perl one-liner.

=item *

The memorization of the position is performed only when closing the filehandle
through the close() method of Launcher::Cascade::FileReader::Seekable, not when
closing the filehandle directly:

    my $fh = $f->open();
    ... # do something with it

    $f->close();   # right: position() is updated
    close $fh;     # wrong: position() is *not* updated

=back

=head1 SEE ALSO

L<Launcher::Cascade::FileReader>

=head1 AUTHOR

Cédric Bouvier C<< <cbouvi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # end of Launcher::Cascade::FileReader::Seekable
