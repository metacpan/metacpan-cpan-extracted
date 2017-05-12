package Exobrain::Agent::Twitter::Source;
use v5.10.0;
use Moose;
use Method::Signatures;

our $VERSION = '1.04'; # VERSION
# ABSTRACT: Agent for reading tweets

with 'Exobrain::Agent::Poll';
with 'Exobrain::Agent::Twitter';


# Key used by the cache for our last Twitter ID.
# Called 'last_check' for historical reasons.
use constant CACHE_LAST_MENTION => 'last_mention';
use constant CACHE_LAST_DM      => 'last_dm';
use constant DEBUG              => 0;

has last_mention => (
    is => 'rw',
    lazy => 1,
    builder => '_build_last_mention',
    trigger => \&_cache_last_mention,
);

method _build_last_mention() {
    return $self->cache->get( CACHE_LAST_MENTION ) || 0;
}

method _cache_last_mention($new, $old?) {
    print "Setting last mention to $new\n" if DEBUG;
    $self->cache->set( CACHE_LAST_MENTION, $new );
    return;
}

has last_dm => (
    is => 'rw',
    lazy => 1,
    builder => '_build_last_dm',
    trigger => \&_cache_last_dm,
);

method _build_last_dm() {
    return $self->cache->get( CACHE_LAST_DM ) || 0;
}

method _cache_last_dm($new, $old?) {
    print "Setting last DM to $new\n" if DEBUG;
    $self->cache->set( CACHE_LAST_DM, $new );
    return;
}

method poll() {
    my $last_mention = $self->last_mention;

    my $statuses = 
        $last_mention ?
        $self->twitter->mentions({ since_id => $last_mention }) :
        $self->twitter->mentions()
    ;

    for my $status ( @$statuses ) {

        my $text       = $status->{text};
        my @tags       = $self->tags( $text );
        my $epoch_time = $self->to_epoch( $status->{created_at} );

        print "[$status->{id}] $epoch_time <$status->{user}{screen_name}> $status->{text} (Tags: @tags)\n" if DEBUG;

        # TODO: Parse or figure out who this is to, for the 'to' attribute.

        $self->exobrain->measure('Tweet',
            timestamp => $epoch_time,
            from      => $status->{user}{screen_name},
            tags      => \@tags,
            to_me     => 1,     # Because we're only looking at replies
            text      => $status->{text},
            raw       => $status,
            id        => $status->{id},
            platform  => $self->component,
        );

        # We explicitly check to see if we have a newer last_mention
        # because we don't want to rely upon the ordering in which
        # tweets are returned. In fact, they're almost always in the
        # order we don't want.

        if ($status->{id} > $self->last_mention) {
            $self->last_mention( $status->{id} );
        }
    }

    # Ugh. Repeated code for DMs. We should be able to combine
    # These two loops.

    my $last_dm = $self->last_dm;

    my $dms =
        $last_dm ?
        $self->twitter->direct_messages({ since_id => $last_dm }) :
        $self->twitter->direct_messages
    ;

    foreach my $dm ( @$dms ) {
        my $text       = $dm->{text};
        my $epoch_time = $self->to_epoch( $dm->{created_at} );
        my $from       = $dm->{sender_screen_name};

        $self->exobrain->measure('DirectMessage',
            timestamp => $epoch_time,
            from      => $from,
            text      => $text,
            summary   => "[DM] \@$from: $text",
            raw       => $dm,
            id        => $dm->{id},
            platform  => $self->component,
        );

        if ($dm->{id} > $self->last_dm ) {
            $self->last_dm( $dm->{id} );
        }
    }
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Twitter::Source - Agent for reading tweets

=head1 VERSION

version 1.04

=head1 DESCRIPTION

Exobrain agent class for twitter.

This requires the following configuration section:

    [Twitter]
    consumer_key =
    consumer_secret =
    access_token =
    access_token_secret =

=for Pod::Coverage DEBUG CACHE_LAST_MENTION CACHE_LAST_DM

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
