package Markapl::Helpers;
use strict;
use Markapl;

use Exporter::Lite;
our $VERSION = "0.01";
our @EXPORT = qw(THs TDs ths tds heads cells linklist);

sub linklist {
    my @link = @_;
    ul {
        while(@link) {
            my $label = shift @link;
            my $url = shift @link;
            li {
                a(href => $url) { $label };
            }
        }
    }
}

sub heads {
    my @heads = @_;
    row { for (@heads) { th { $_ } } }
}

sub cells {
    my @cells = @_;
    row { for (@cells) { cell { $_ } } }
}

*THs = \&heads;
*ths = \&heads;
*TDs = \&cells;
*tds = \&cells;

1;

=head1 NAME

Markapl::Helpers - Practical helper methods

=head1 DESCRIPTION

This module exports several useful functions that are meant to be used
inside templates.

=head1 FUNCTIONS

=over 4

=item linklist($label1 => $url1, $label2 => $url2, ...)

Take pairs of labels and urls, return a structure like this:

    <ul>
      <li><a href="$url1">$label1</a></li>
      <li><a href="$url2">$label2</a></li>
      ...
    </ul>

=item cells($item1, $item2, ...)

Wrap C<< <td></td> >> tag around each item in the argument list.
Useful when showing tabular data. For example:

    table {
        while(my @data = $dbh->fetchrow_array) {
          cells(@data);
        }
    }

=item heads($item1, $item2, ...)

Similar to C<cells>, but output seris of C<< <th></th> >> tag instead.
For example:

    table {
        heads( qw(Name Age Gender Height Weight) );
        while(my @data = $dbh->fetchrow_array) {
          cells(@data);
        }
    }

=back

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
