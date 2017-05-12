package JIRA::REST::Class::Issue::LinkType;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA link type as an object.

__PACKAGE__->mk_data_ro_accessors( qw( id name inward outward self ) );

1;

#pod =accessor B<id>
#pod
#pod The id of the link type.
#pod
#pod =accessor B<name>
#pod
#pod The name of the link type.
#pod
#pod =accessor B<inward>
#pod
#pod The text for the inward name of the link type.
#pod
#pod =accessor B<outward>
#pod
#pod The text for the outward name of the link type.
#pod
#pod =accessor B<self>
#pod
#pod The full URL for the JIRA REST API call for the link type.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik

=head1 NAME

JIRA::REST::Class::Issue::LinkType - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA link type as an object.

=head1 VERSION

version 0.10

=head1 READ-ONLY ACCESSORS

=head2 B<id>

The id of the link type.

=head2 B<name>

The name of the link type.

=head2 B<inward>

The text for the inward name of the link type.

=head2 B<outward>

The text for the outward name of the link type.

=head2 B<self>

The full URL for the JIRA REST API call for the link type.

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
