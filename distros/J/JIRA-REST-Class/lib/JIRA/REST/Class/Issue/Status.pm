package JIRA::REST::Class::Issue::Status;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the status of a JIRA issue as an object.

__PACKAGE__->mk_ro_accessors( qw/ category / );
__PACKAGE__->mk_data_ro_accessors( qw/ description iconUrl id name self / );
__PACKAGE__->mk_contextual_ro_accessors( qw/ transitions / );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    $self->{category} = $self->make_object(
        'statuscat',
        {
            data => $self->data->{statusCategory}
        }
    );

    return;
}

1;

#pod =method B<description>
#pod
#pod Returns the description of the status.
#pod
#pod =method B<iconUrl>
#pod
#pod Returns the URL of the icon the status.
#pod
#pod =method B<id>
#pod
#pod Returns the id of the status.
#pod
#pod =method B<name>
#pod
#pod Returns the name of the status.
#pod
#pod =method B<self>
#pod
#pod Returns the JIRA REST API URL of the status.
#pod
#pod =method B<category>
#pod
#pod Returns the category of the status as a
#pod L<JIRA::REST::Class::Issue::Status::Category|JIRA::REST::Class::Issue::Status::Category>
#pod object.
#pod
#pod =for stopwords iconUrl
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik iconUrl

=head1 NAME

JIRA::REST::Class::Issue::Status - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the status of a JIRA issue as an object.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<description>

Returns the description of the status.

=head2 B<iconUrl>

Returns the URL of the icon the status.

=head2 B<id>

Returns the id of the status.

=head2 B<name>

Returns the name of the status.

=head2 B<self>

Returns the JIRA REST API URL of the status.

=head2 B<category>

Returns the category of the status as a
L<JIRA::REST::Class::Issue::Status::Category|JIRA::REST::Class::Issue::Status::Category>
object.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue::Status::Category|JIRA::REST::Class::Issue::Status::Category>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
