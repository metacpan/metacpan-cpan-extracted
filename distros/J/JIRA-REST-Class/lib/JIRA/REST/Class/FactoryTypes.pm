package JIRA::REST::Class::FactoryTypes;
use parent qw( Exporter );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

#ABSTRACT: The module that exports the list of object types in the L<JIRA::REST::Class|JIRA::REST::Class> module to L<JIRA::REST::Class::Factory|JIRA::REST::Class::Factory> and the testing code.

#pod =head1 DESCRIPTION
#pod
#pod The sole purpose of this module is to have a single point of modification
#pod for the hash that defines short names for the object types.
#pod
#pod =cut

our @EXPORT_OK = qw( %TYPES );

#pod =head2 %TYPES
#pod
#pod A hash where the keys map to the full names of the classes of objects in the
#pod L<JIRA::REST::Class|JIRA::REST::Class> package.
#pod
#pod =cut

our %TYPES = (
    class        => 'JIRA::REST::Class',
    factory      => 'JIRA::REST::Class::Factory',
    abstract     => 'JIRA::REST::Class::Abstract',
    issue        => 'JIRA::REST::Class::Issue',
    changelog    => 'JIRA::REST::Class::Issue::Changelog',
    change       => 'JIRA::REST::Class::Issue::Changelog::Change',
    changeitem   => 'JIRA::REST::Class::Issue::Changelog::Change::Item',
    comment      => 'JIRA::REST::Class::Issue::Comment',
    linktype     => 'JIRA::REST::Class::Issue::LinkType',
    status       => 'JIRA::REST::Class::Issue::Status',
    statuscat    => 'JIRA::REST::Class::Issue::Status::Category',
    timetracking => 'JIRA::REST::Class::Issue::TimeTracking',
    transitions  => 'JIRA::REST::Class::Issue::Transitions',
    transition   => 'JIRA::REST::Class::Issue::Transitions::Transition',
    issuetype    => 'JIRA::REST::Class::Issue::Type',
    worklog      => 'JIRA::REST::Class::Issue::Worklog',
    workitem     => 'JIRA::REST::Class::Issue::Worklog::Item',
    project      => 'JIRA::REST::Class::Project',
    projectcat   => 'JIRA::REST::Class::Project::Category',
    projectcomp  => 'JIRA::REST::Class::Project::Component',
    projectvers  => 'JIRA::REST::Class::Project::Version',
    iterator     => 'JIRA::REST::Class::Iterator',
    sprint       => 'JIRA::REST::Class::Sprint',
    query        => 'JIRA::REST::Class::Query',
    user         => 'JIRA::REST::Class::User',
);

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik

=head1 NAME

JIRA::REST::Class::FactoryTypes - The module that exports the list of object types in the L<JIRA::REST::Class|JIRA::REST::Class> module to L<JIRA::REST::Class::Factory|JIRA::REST::Class::Factory> and the testing code.

=head1 VERSION

version 0.10

=head1 DESCRIPTION

The sole purpose of this module is to have a single point of modification
for the hash that defines short names for the object types.

=head2 %TYPES

A hash where the keys map to the full names of the classes of objects in the
L<JIRA::REST::Class|JIRA::REST::Class> package.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Factory|JIRA::REST::Class::Factory>

=item * L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue>

=item * L<JIRA::REST::Class::Issue::Changelog|JIRA::REST::Class::Issue::Changelog>

=item * L<JIRA::REST::Class::Issue::Changelog::Change|JIRA::REST::Class::Issue::Changelog::Change>

=item * L<JIRA::REST::Class::Issue::Changelog::Change::Item|JIRA::REST::Class::Issue::Changelog::Change::Item>

=item * L<JIRA::REST::Class::Issue::Comment|JIRA::REST::Class::Issue::Comment>

=item * L<JIRA::REST::Class::Issue::LinkType|JIRA::REST::Class::Issue::LinkType>

=item * L<JIRA::REST::Class::Issue::Status|JIRA::REST::Class::Issue::Status>

=item * L<JIRA::REST::Class::Issue::Status::Category|JIRA::REST::Class::Issue::Status::Category>

=item * L<JIRA::REST::Class::Issue::TimeTracking|JIRA::REST::Class::Issue::TimeTracking>

=item * L<JIRA::REST::Class::Issue::Transitions|JIRA::REST::Class::Issue::Transitions>

=item * L<JIRA::REST::Class::Issue::Transitions::Transition|JIRA::REST::Class::Issue::Transitions::Transition>

=item * L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type>

=item * L<JIRA::REST::Class::Issue::Worklog|JIRA::REST::Class::Issue::Worklog>

=item * L<JIRA::REST::Class::Issue::Worklog::Item|JIRA::REST::Class::Issue::Worklog::Item>

=item * L<JIRA::REST::Class::Iterator|JIRA::REST::Class::Iterator>

=item * L<JIRA::REST::Class::Project|JIRA::REST::Class::Project>

=item * L<JIRA::REST::Class::Project::Category|JIRA::REST::Class::Project::Category>

=item * L<JIRA::REST::Class::Project::Component|JIRA::REST::Class::Project::Component>

=item * L<JIRA::REST::Class::Project::Version|JIRA::REST::Class::Project::Version>

=item * L<JIRA::REST::Class::Query|JIRA::REST::Class::Query>

=item * L<JIRA::REST::Class::Sprint|JIRA::REST::Class::Sprint>

=item * L<JIRA::REST::Class::User|JIRA::REST::Class::User>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
