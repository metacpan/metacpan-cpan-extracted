use utf8;

package Interchange6::Schema::ResultSet::Message;

=head1 NAME

Interchange6::Schema::ResultSet::Message

=cut

=head1 SYNOPSIS

Provides extra accessor methods for L<Interchange6::Schema::Result::Message>

=cut

use strict;
use warnings;
use mro 'c3';

use parent 'Interchange6::Schema::ResultSet';

=head1 METHODS

=head2 approved

Messages where C<approved> is true.

=cut

sub approved {
    return $_[0]->search( { -bool => $_[0]->me('approved') } );
}

=head2 public

Messages where C<public> is true.

=cut

sub public {
    return $_[0]->search( { -bool => $_[0]->me('public') } );
}

=head2 with_author

Prefetch C<author> relationship.

=cut

sub with_author {
    return $_[0]->prefetch('author');
}

=head2 with_children

Prefetch C<children> relationship.

=cut

sub with_children {
    return $_[0]->prefetch('children');
}

1;
