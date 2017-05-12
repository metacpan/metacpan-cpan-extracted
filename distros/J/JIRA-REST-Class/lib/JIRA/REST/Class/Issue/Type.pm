package JIRA::REST::Class::Issue::Type;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA issue type as an object.

use Readonly 2.04;

Readonly my @ACCESSORS => qw( description iconUrl id name self subtask );

__PACKAGE__->mk_data_ro_accessors( @ACCESSORS );

#pod =head1 DESCRIPTION
#pod
#pod This object represents a type of JIRA issue as an object.  It is overloaded
#pod so it returns the C<key> of the issue type when stringified, the C<id> of
#pod the issue type when it is used in a numeric context, and the value of the
#pod C<subtask> field if is used in a boolean context.  If two of these objects
#pod are compared I<as strings>, the C<key> of the issue types will be used for
#pod the comparison, while numeric comparison will compare the C<id>s of the
#pod issue types.
#pod
#pod =cut

#<<<
use overload
    '""'   => sub { shift->name    },
    '0+'   => sub { shift->id      },
    'bool' => sub { shift->subtask },
    '<=>'  => sub {
        my( $A, $B ) = @_;
        my $AA = ref $A ? $A->id : $A;
        my $BB = ref $B ? $B->id : $B;
        $AA <=> $BB
    },
    'cmp'  => sub {
        my( $A, $B ) = @_;
        my $AA = ref $A ? $A->name : $A;
        my $BB = ref $B ? $B->name : $B;
        $AA cmp $BB
    };
#>>>

1;

#pod =accessor B<description>
#pod
#pod Returns the description of the issue type.
#pod
#pod =accessor B<iconUrl>
#pod
#pod Returns the URL of the icon the issue type.
#pod
#pod =accessor B<id>
#pod
#pod Returns the id of the issue type.
#pod
#pod =accessor B<name>
#pod
#pod Returns the name of the issue type.
#pod
#pod =accessor B<self>
#pod
#pod Returns the JIRA REST API URL of the issue type.
#pod
#pod =accessor B<subtask>
#pod
#pod Returns a boolean indicating whether the issue type is a subtask.
#pod
#pod =for stopwords iconUrl
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik iconUrl

=head1 NAME

JIRA::REST::Class::Issue::Type - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA issue type as an object.

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This object represents a type of JIRA issue as an object.  It is overloaded
so it returns the C<key> of the issue type when stringified, the C<id> of
the issue type when it is used in a numeric context, and the value of the
C<subtask> field if is used in a boolean context.  If two of these objects
are compared I<as strings>, the C<key> of the issue types will be used for
the comparison, while numeric comparison will compare the C<id>s of the
issue types.

=head1 READ-ONLY ACCESSORS

=head2 B<description>

Returns the description of the issue type.

=head2 B<iconUrl>

Returns the URL of the icon the issue type.

=head2 B<id>

Returns the id of the issue type.

=head2 B<name>

Returns the name of the issue type.

=head2 B<self>

Returns the JIRA REST API URL of the issue type.

=head2 B<subtask>

Returns a boolean indicating whether the issue type is a subtask.

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
