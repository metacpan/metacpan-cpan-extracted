package Geo::TigerLine::Record;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';


=pod

=head1 NAME

Geo::TigerLine::Record - Superclass for all TIGER/Line record classes.

=head1 SYNOPSIS

  package Geo::TigerLine::Record::42;
  use base qw(Geo::TigerLine::Record);

  $record = __PACKAGE__->new(\%fields);


=head1 DESCRIPTION

From this class all the specific TIGER/Line record classes inherit.
It provides some of the basic methods common to all records.

You shouldn't be here.

=head2 Methods

=over 4

=item B<new>

    $record = __PACKAGE__->new(\%fields);

A simple constructor.  Each field is passed through its accessor and
sanity checked.

=cut

#'#
sub new {
    my($proto, $fields) = @_;
    my($class) = ref $proto || $proto;

    my $self = [];
    bless $self, $class;

    while( my($k,$v) = each %$fields ) {
        $self->$k($v);
    }

    warn "inside ", __PACKAGE__, "->new = $self\n";

    return $self;
}

=pod

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>

=cut

1;
