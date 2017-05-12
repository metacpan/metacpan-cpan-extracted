package JIRA::REST::Class::Query;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA query as an object.  Attempts to return an array of all results from the query.

#pod =method B<issue_count>
#pod
#pod A count of the number of issues matched by the query.
#pod
#pod =cut

sub issue_count { return shift->data->{total} }

#pod =method B<issues>
#pod
#pod Returns a list of L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue>
#pod objects matching the query.
#pod
#pod =cut

sub issues {
    my $self   = shift;
    my @issues = map {  #
        $self->make_object( 'issue', { data => $_ } );
    } @{ $self->data->{issues} };
    return @issues;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik

=head1 NAME

JIRA::REST::Class::Query - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA query as an object.  Attempts to return an array of all results from the query.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<issue_count>

A count of the number of issues matched by the query.

=head2 B<issues>

Returns a list of L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue>
objects matching the query.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
