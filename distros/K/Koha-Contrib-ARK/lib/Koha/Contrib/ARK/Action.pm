package Koha::Contrib::ARK::Action;
# ABSTRACT: ARK Action roles
$Koha::Contrib::ARK::Action::VERSION = '1.0.3';
use Moose::Role;
use Modern::Perl;

requires 'action';

has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


sub action {
    my $self = shift;

    say "action on ARK";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Action - ARK Action roles

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 ark

L<Koha::Contrib::ARK> object.

=head1 METHODS

=head2 action($biblionumber, $record)

Do something with Koha biblio record.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
