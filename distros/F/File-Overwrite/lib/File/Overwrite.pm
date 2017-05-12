use strict;
use warnings;

package File::Overwrite;

use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(overwrite overwrite_and_unlink); 
$VERSION = '1.2';

=head1 NAME

File::Overwrite - overwrite the contents of a file and optionally unlink it

=head1 SYNOPSIS

    use File::Overwrite qw(overwrite);
    
    # haha, now no-one will know I stole it
    overwrite('sekrit_formular.txt');
    unlink('sekrit_formular.txt');

=head1 DESCRIPTION

This module provides a few simple functions for overwriting data files.  This
will protect against the simplest forms of file recovery.

=head1 SECURITY

This module makes all kinds of assumptions about your system - how the disks
work, how the filesystem works, and so on.  Even if it does overwrite the
actual disk blocks containing the original data, this will not necessarily
protect you against someone with sufficient equipment and/or determination.  If
you want to stop forensic recovery of the data, don't put it on a computer in
the first place.  If you have already put it on a computer, I recommend
melting all your disks.

=cut

=head1 FUNCTIONS

All of the following functions can be exported if you wish.  However, none are
exported by default.  All take a filename as their only parameter (any subsequent
params are ignored) and die if that file can't be fiddled with.  In case of failure,
the file may be left fractionally fiddled.

=over 4

=item overwrite

Overwrites the file.

=cut

sub overwrite {
    my $file = shift();
    _overwrite(with => 'X', file => $file);
}

=item overwrite_and_unlink

Overwrites and unlinks the file.

=cut

sub overwrite_and_unlink {
    my $file = shift();
    overwrite($file);
    _unlink($file);
}

# =item overwrite_and_delete
#
# Overwrites the file and then tries to find and unlink all links to it
#
# =cut
#
# sub overwrite_and_delete {
#     my $file = shift();
#     overwrite($file);
#     foreach my $link (_find_links($file)) { _unlink($link); }
# }

sub _overwrite {
    my %params = @_;
    my $file = $params{file};
    my $with = $params{with};
    my $bytes = -s $file;

    open(my $fh, '+<', $file) || die("Couldn't open $file: $!");
    seek($fh, 0, 0);
    for(; $bytes; $bytes--) {
      print $fh $with || die("Couldn't overwrite $file: $!");
    }
    close($fh) || die("Couldn't close $file: $!");
}

sub _unlink {
    my $file = shift;
    die("Couldn't unlink $file") unless(unlink($file) == 1);
}

=back

=head1 BUGS

None known.  Please report any that you find using L<http://rt.cpan.org/>.

You should be aware, however, that the tests are only rudimentary.  There
is no portable way of determining whether a file's data really is overwritten
so I don't try very hard.

On Win32 you can't delete files that are open.  This is a bug in the
operating system, not in this module.

=head1 FEEDBACK

I like to know who's using my code.  All comments, including constructive
criticism, are welcome.  Please email me.

=head1 THANKS TO

Daniel Muey, for reporting some bugs and misfeatures,
see L<http://rt.cpan.org/Public/Bug/Display.html?id=50067>.

=head1 SEE ALSO

L<http://www.perlmonks.com/?node_id=525657>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2008 David Cantrell E<lt>david@cantrell.org.ukE<gt>

This module was written in response to a post by 'fluffyvoidwarrior'
on perlmonks.

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
