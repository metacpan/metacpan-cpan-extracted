package JIRA::REST::Class::Project::Component;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a component of a JIRA project as an object.

__PACKAGE__->mk_data_ro_accessors( qw( id isAssigneeTypeValid name self ) );

1;

#pod =accessor B<id>
#pod
#pod The ID of the project category.
#pod
#pod =accessor B<isAssigneeTypeValid>
#pod
#pod A boolean indicating whether the assignee type is valid.
#pod
#pod =accessor B<name>
#pod
#pod The name of the project category.
#pod
#pod =accessor B<self>
#pod
#pod Returns the JIRA REST API URL of the project category.
#pod
#pod =for stopwords isAssigneeTypeValid
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik isAssigneeTypeValid

=head1 NAME

JIRA::REST::Class::Project::Component - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a component of a JIRA project as an object.

=head1 VERSION

version 0.10

=head1 READ-ONLY ACCESSORS

=head2 B<id>

The ID of the project category.

=head2 B<isAssigneeTypeValid>

A boolean indicating whether the assignee type is valid.

=head2 B<name>

The name of the project category.

=head2 B<self>

Returns the JIRA REST API URL of the project category.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
