package Foorum::ResultSet::ForumSettings;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

sub get_all {
    my ( $self, $forum_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key = "forum_settings|forum_id=$forum_id";
    my $cache_val = $cache->get($cache_key);

    if ( $cache_val and ref $cache_val eq 'HASH' ) {
        return $cache_val;
    }

    # get and set cache
    my $settings;
    my $settings_rs = $self->search( { forum_id => $forum_id } );
    while ( my $r = $settings_rs->next ) {
        $settings->{ $r->type } = $r->value;
    }
    $cache->set( $cache_key, $settings, 3600 );    # 1 hour

    return $settings;
}

sub get_basic {
    my ( $self, $forum_id ) = @_;

    my $settings = $self->get_all($forum_id);

    # grep those types
    my @all_types = qw/can_post_threads can_post_replies can_post_polls/;
    my %settings = map { $_ => $settings->{$_} || 'Y' } @all_types;

    return \%settings;
}

sub get_forum_links {
    my ( $self, $forum_id ) = @_;

    my $settings = $self->get_all($forum_id);

    # grep those keys with forum_link\d+
    my @links = grep {/^forum_link\d+$/} keys %$settings;
    @links = map { $settings->{$_} } sort @links;

    foreach (@links) {
        my ( $url, $text ) = split( /\s+/, $_, 2 );
        $_ = {
            url  => $url,
            text => $text
        };
    }

    return wantarray ? @links : \@links;
}

sub clear_cache {
    my ( $self, $forum_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key = "forum_settings|forum_id=$forum_id";
    $cache->remove($cache_key);
}

1;
__END__

=pod

=head1 NAME

Foorum::ResultSet::ForumSettings - ForumSettings object

=head1 FUNCTION

=over 4

=item get_all($forum_id)

  $schema->resultset('ForumSettings')->get_all( $forum_id );
  $c->model('DBIC::ForumSettings')->get_all( $forum_id );

It gets the data from forum_settings table.

return $HASHREF

=item get_basic($forum_id)

  $schema->resultset('ForumSettings')->get_basic( $forum_id );
  $c->model('DBIC::ForumSettings')->get_basic( $forum_id );

get the settings of my @all_types = qw/can_post_threads can_post_replies can_post_polls/;

return $HASHREF

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
