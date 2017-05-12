use strict;
use warnings;

package Jifty::Plugin::SiteNews::Mixin::Model::News;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';

our @EXPORT = qw(create as_atom_entry);

=head1 NAME

Jifty::Plugin::SiteNews::Mixin::Model::News - News model

=cut

use Jifty::Record schema {

column created   =>
  type is 'timestamp',
  filters are qw( Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime),
  label is 'Created on',
  is protected;
column title     =>
  type is 'text',
  label is 'Title';
column content   =>
  type is 'text',
  label is 'Article',
  render_as is 'Textarea';
};

=head2 create

Create the News model. Takes a paramhash with keys author_id, created, title, and content.

=cut

sub create {
    my $self = shift;
    my %args = (
        title     => undef,
        content   => undef,
        @_,
        created   => DateTime->now,
    );

    $self->SUPER::create(%args);
}

=head2 as_atom_entry

Returns the task as an L<XML::Atom::Entry> object.

=cut

sub as_atom_entry {
    my $self = shift;

    my $entry = XML::Atom::Entry->new;
    $entry->title( $self->title );
    $entry->content( $self->content);
    return $entry;
}

1;
