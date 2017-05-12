package JIRA::REST::Class::Project::Version;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

use Readonly 2.04;

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a version of a JIRA project as an object.

Readonly my @ACCESSORS => qw( archived id name projectId released self );

__PACKAGE__->mk_data_ro_accessors( @ACCESSORS );

#pod =head1 DESCRIPTION
#pod
#pod This object represents a version of JIRA project as an object.  It is
#pod overloaded so it returns the C<name> of the project version when
#pod stringified, the C<id> of the project version when it is used in a numeric
#pod context, and the value of the C<released> field if is used in a boolean
#pod context.  If two of these objects are compared I<as strings>, the C<name> of
#pod the project versions will be used for the comparison, while numeric
#pod comparison will compare the C<id>s of the project versions.
#pod
#pod =cut

#<<<
use overload
    '""'   => sub { shift->name    },
    '0+'   => sub { shift->id      },
    'bool' => sub { shift->released },
    '<=>'  => sub {
        my($A, $B) = @_;
        my $AA = ref $A ? $A->id : $A;
        my $BB = ref $B ? $B->id : $B;
        $AA <=> $BB
    },
    'cmp'  => sub {
        my($A, $B) = @_;
        my $AA = ref $A ? $A->name : $A;
        my $BB = ref $B ? $B->name : $B;
        $AA cmp $BB
    };
#>>>

1;

#pod =accessor B<archived>
#pod
#pod A boolean indicating whether the version is archived.
#pod
#pod =accessor B<id>
#pod
#pod The id of the project version.
#pod
#pod =accessor B<name>
#pod
#pod The name of the project version.
#pod
#pod =accessor B<projectId>
#pod
#pod The ID of the project this is a version of.
#pod
#pod =accessor B<released>
#pod
#pod A boolean indicating whether the version is released.
#pod
#pod =accessor B<self>
#pod
#pod Returns the JIRA REST API URL of the project version.
#pod
#pod =for stopwords projectId
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik projectId

=head1 NAME

JIRA::REST::Class::Project::Version - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a version of a JIRA project as an object.

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This object represents a version of JIRA project as an object.  It is
overloaded so it returns the C<name> of the project version when
stringified, the C<id> of the project version when it is used in a numeric
context, and the value of the C<released> field if is used in a boolean
context.  If two of these objects are compared I<as strings>, the C<name> of
the project versions will be used for the comparison, while numeric
comparison will compare the C<id>s of the project versions.

=head1 READ-ONLY ACCESSORS

=head2 B<archived>

A boolean indicating whether the version is archived.

=head2 B<id>

The id of the project version.

=head2 B<name>

The name of the project version.

=head2 B<projectId>

The ID of the project this is a version of.

=head2 B<released>

A boolean indicating whether the version is released.

=head2 B<self>

Returns the JIRA REST API URL of the project version.

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
