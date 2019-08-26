package File::Format::CRD::Reader;

use warnings;
use strict;

use 5.008;

use Carp;

use Encode;

use Fcntl qw(SEEK_SET);

=head1 NAME

File::Format::CRD::Reader - read Windows .CRD files.

=head1 VERSION

Version 0.0.4

=cut

use vars qw($VERSION);

$VERSION = '0.0.4';

=head1 SYNOPSIS

    use File::Format::CRD::Reader;

    my $reader = File::Format::CRD::Reader->new({ filename => $filename});

    while (my $card = $reader->get_next_card({encoding => "windows-1255"}))
    {
        print "Title = " , $card->{'title'}, "\nBody = <<<\n",
            $card->{'body'}, "\n>>>\n\n";
    }

=head1 METHODS

=head2 File::Format::CRD::Reader->new({filename => $filename});

Open CRD file $filename for reading.

=cut

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _read_from
{
    my ($self, $pos, $count) = @_;

    if (!seek($self->{_fh}, $pos, SEEK_SET))
    {
        Carp::confess("Cannot seek to $pos.");
    }

    my $buffer = "";
    if (read($self->{_fh}, $buffer, $count) != $count)
    {
        Carp::confess("Could not read $count bytes.");
    }

    return $buffer;
}

sub _read_short
{
    my $self = shift;
    my $pos = shift;

    my $buffer = $self->_read_from($pos, 2);

    return unpack("v", $buffer);
}

sub _read_long
{
    my $self = shift;
    my $pos = shift;

    return unpack("V", $self->_read_from($pos, 4));
}

sub _init
{
    my ($self, $args) = @_;

    my $filename = $args->{'filename'};

    open my $in, "<", $filename
        or Carp::confess "Could not open '$filename'";

    binmode ($in);

    $self->{_fh} = $in;

    my $magic = $self->_read_from(0, 3);

    if ($magic ne "MGC")
    {
        Carp::confess("Could not find magic number in file.");
    }

    my $n_cards = $self->_read_short(3);

    $self->{_num_cards} = $n_cards;

    $self->{_card_idx} = 0;

    return;
}

=head2 $self->get_num_cards()

Get the number of cards.

=cut

sub get_num_cards
{
    return shift->{_num_cards};
}

sub DESTROY
{
    my $self = shift;

    $self->finish();

    return;
}

=head2 $self->finish()

Clean up and finish. Can no longer read cards after that.

=cut

sub finish
{
    my $self = shift;

    if (exists($self->{_fh}))
    {
        close($self->{_fh});

        delete($self->{_fh});
    }

    return;
}

=head2 $self->get_next_card({encoding => "windows-1255"})

Get the next card. Returns undef or the empty list at the end of the file,
and a hash-ref like that upon success:

    {
        'title' => "My Card",
        'body' => "Body of card\nHello",
    }

The encoding parameter C<'encoding'> can be used to decode the card using a
certain encoding.

=cut

sub get_next_card
{
    my $self = shift;
    my $args = shift || {};

    my $encoding = $args->{'encoding'};

    my $card_idx = $self->{_card_idx};

    if ($card_idx == $self->get_num_cards())
    {
        return;
    }

    my $loc = 11 + $card_idx * 52;

    my $textloc = $self->_read_long($loc);

    if (! ($textloc >= 57))
    {
        Carp::confess("textloc is too small");
    }

    my $transform = sub {
        my $text = shift;

        if (defined($encoding))
        {
            return decode($encoding, $text);
        }
        else
        {
            return $text;
        }
    };

    my $title = $self->_read_from($loc+5, 52-5);

    my $ret = { 'title' => $transform->($title) };

    my $textlen = $self->_read_short($textloc+2);

    my $text = $self->_read_from($textloc+4, $textlen);

    $ret->{'body'} = $transform->($text);
    ++($self->{_card_idx});

    return $ret;
}


=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-format-crd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Format-CRD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Format::CRD::Reader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Format-CRD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Format-CRD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Format-CRD>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Format-CRD/>

=back

=head1 ACKNOWLEDGEMENTS

This module is based on L<http://ihaa.com/english/crd2html.html> by
ihaa.com.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of File::Format::CRD::Reader
