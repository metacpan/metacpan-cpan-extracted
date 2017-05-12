package Metaweb::Result;

use strict;
use warnings;

=head1 NAME

Metaweb::Result - Result set from a Metaweb query

=head1 SYNOPSIS

    my $mw = Metaweb->new($args);
    $mw->login();

    my $result = $mw->query($name, $query_hash);
    # $result isa Metaweb::Result

    use Data::Dumper;
    print Dumper $result;

=head1 DESCRIPTION

This class doesn't do much of anything yet.  It just gives you an object
you can treat as a hashref.

=head2 new()

Simple constructor.  Takes a result as a perl data structure and
basically just turns it into a Metaweb::Result object.

=cut

sub new {
    my ($class, $result) = @_;
    my $self = { content => $result };
    bless $self, $class;
    return $self;
}

=head1 SEE ALSO

L<Metaweb>

=cut

1;
