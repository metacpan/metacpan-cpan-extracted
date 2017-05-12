package JIRA::REST::Class::Issue::Status::Category;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the category of an issue's status.

__PACKAGE__->mk_data_ro_accessors( qw/ name colorName id key self / );

1;

#pod =accessor id
#pod
#pod The id of the status category.
#pod
#pod =accessor key
#pod
#pod The key of the status category.
#pod
#pod =accessor name
#pod
#pod The name of the status category.
#pod
#pod =accessor colorName
#pod
#pod The color name of the status category.
#pod
#pod =accessor self
#pod
#pod The full URL for the JIRA REST API call for the status category.
#pod
#pod =for stopwords colorName
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik colorName

=head1 NAME

JIRA::REST::Class::Issue::Status::Category - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the category of an issue's status.

=head1 VERSION

version 0.10

=head1 READ-ONLY ACCESSORS

=head2 id

The id of the status category.

=head2 key

The key of the status category.

=head2 name

The name of the status category.

=head2 colorName

The color name of the status category.

=head2 self

The full URL for the JIRA REST API call for the status category.

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
