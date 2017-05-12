package Fey::SQL::Pg::Insert;
BEGIN {
  $Fey::SQL::Pg::Insert::VERSION = '0.005';
}
# ABSTRACT: Generate PostgreSQL specific INSERT statements
use Moose;
use namespace::autoclean;

use Moose;
use MooseX::StrictConstructor;

extends 'Fey::SQL::Insert';
with 'Fey::SQL::Pg::Role::Returning';

around sql => sub {
    my $orig = shift;
    my ($self, $dbh) = @_;
    return ( join ' ',
             $self->$orig($dbh),
             $self->returning_clause($dbh)
           );
};


__PACKAGE__->meta->make_immutable;
1;



__END__
=pod

=encoding utf-8

=head1 NAME

Fey::SQL::Pg::Insert - Generate PostgreSQL specific INSERT statements

=head1 DESCRIPTION

Specific PostgreSQL extensions to C<INSERT> statements.

=head1 EXTENSIONS

=head2 INSERT ... RETURNING

Allows you to perform a C<SELECT> like query on newly inserted rows
(which can be helpful for retrieving automatically generated row IDs).

Specify columns to be returned by using C<returning>. This takes the
same input as C<select> in L<Fey::SQL::Select>.

=head1 AUTHOR

Oliver Charles <oliver.g.charles@googlemail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

