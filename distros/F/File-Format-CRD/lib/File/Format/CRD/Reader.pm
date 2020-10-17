package File::Format::CRD::Reader;
$File::Format::CRD::Reader::VERSION = '0.2.2';
use warnings;
use strict;

use 5.008;

use Carp;

use Encode;

use Fcntl qw(SEEK_SET);



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



1; # End of File::Format::CRD::Reader

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Format::CRD::Reader - read Windows .CRD files.

=head1 VERSION

version 0.2.2

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

=head2 $self->get_num_cards()

Get the number of cards.

=head2 $self->finish()

Clean up and finish. Can no longer read cards after that.

=head2 $self->get_next_card({encoding => "windows-1255"})

Get the next card. Returns undef or the empty list at the end of the file,
and a hash-ref like that upon success:

    {
        'title' => "My Card",
        'body' => "Body of card\nHello",
    }

The encoding parameter C<'encoding'> can be used to decode the card using a
certain encoding.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 ACKNOWLEDGEMENTS

This module is based on L<http://ihaa.com/english/crd2html.html> by
ihaa.com.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Shlomi Fish.

This program is distributed under the MIT (Expat) License:
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

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/File-Format-CRD>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Format-CRD>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/File-Format-CRD>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/F/File-Format-CRD>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=File-Format-CRD>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=File::Format::CRD>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-file-format-crd at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=File-Format-CRD>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-file-format-crd>

  git clone git://github.com/shlomif/perl-file-format-crd.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-file-format-crd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
