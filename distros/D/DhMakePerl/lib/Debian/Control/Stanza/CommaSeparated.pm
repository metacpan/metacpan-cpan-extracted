package Debian::Control::Stanza::CommaSeparated;

=head1 NAME

Debian::Control::Stanza::CommaSeparated - comma separated debian/control field abstraction

=cut

use strict;
use warnings;

our $VERSION = '0.66';

use Array::Unique;
use Text::ParseWords qw(quotewords);

use overload '""' => \&as_string;

=head1 SYNOPSIS

    my $f = Debian::Control::Stanza::CommaSeparated->new(
        'Joe M <joem@there.not>');
    $f->add('"Smith, Agent" <asmith@hasyou.not>, Joe M <joem@there.not>');
    print $f->as_string;
        # 'Joe M <joem@there.not>, "Smith, Agent" <asmith@hasyou.not>'
    print "$f";     # the same
    $f->sort;

=head1 DESCRIPTION

Debian::Control::Stanza::CommaSeparated abstracts handling of comma-separated
list of values, often found in F<debian/control> file fields like I<Uploaders>.
Note that the various dependency fields in F<debian/control> also use
comma-separated values, but the L<Debian::Dependencies> class is more suitable
for these as it is for example also capable of finding overlapping dependency
declarations.

=head1 CONSTRUCTOR

=over

=item new (initial values)

The initial values list is parsed and may contain strings that are in fact
comma-separated lists. These are split appropriately using L<Text::ParseWords>'
I<quotewords> routine.

=back

=cut

sub new {
    my $self = bless [], shift;

    tie @$self, 'Array::Unique';

    $self->add(@_) if @_;

    $self;
}

=head1 METHODS

=over

=item as_string

Returns text representation of the list. A simple join of the elements by C<, >.

The same function is used for overloading the stringification operation.

=cut

sub as_string
{
    return join( ', ', @{ $_[0] } );
}

sub _parse {
    my $self = shift;

    my @output;

    for (@_) {
        my @items = quotewords( qr/\s*,\s*/, 1, $_ );
        push @output, @items;
    }

    return @output;
}

=item add I<@items>

Adds the given items to the list. Items that are already present are not added,
keeping the list unique.

=cut

sub add {
    my ( $self, @items ) = @_;

    push @$self, $self->_parse(@items);
}

=item sort

A handy method for sorting the list.

=cut

sub sort {
    my $self = shift;

    @$self = sort @$self;
}

=back

=cut

1;
