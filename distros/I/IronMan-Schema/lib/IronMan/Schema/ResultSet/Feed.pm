package IronMan::Schema::ResultSet::Feed;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

use Data::UUID;
use Scalar::Util 'blessed';

## Need to check if url is duplicated by normalising it as well as just uniquing what is passed in!
sub add_new_blog {
    my ($self, %args) = @_;

#    print STDERR "Add new blog: ", Data::Dumper::Dumper(\%args );
    my $uuids = Data::UUID->new;
    my $fdb = $self->find_or_new
      ({
        id => $uuids->create_str,
        url => $args{url},
        title => $args{title},
        owner => $args{email},
       },
       { key => 'url' }
      );

    if($fdb->in_storage) {
        return (0, $fdb);
    }
    $fdb->insert;

    return (1, $fdb);
}

## Given a feed url that should exist as a unique feed in the db,
## and an arrayref of entry hashes/objects, return ones we dont
## have yet.
sub filter_unseen {
    my ($self, $feed_url, $entries) = @_;

    die "filter_unseen not passed a feed_url" if(!$feed_url);

    return [] if(!$entries || ref($entries) ne 'ARRAY' || !@$entries);

    my $feed = $self->find({ url => $feed_url}, { key => 'url' });
    die "No such feed: $feed_url" if(!$feed);

    my %entry_urls = map { 
       blessed($_) ?  
                              ( $_->can('url') && $_->url ) 
                                ||
                                ( $_->can('link') && $_->link )
                              : $_->{url} => $_  } @$entries;

    my @got_these = $feed->posts->search({ url => { -in => [ keys %entry_urls ] } });
    delete $entry_urls{$_->url} for @got_these;

    return [ values(%entry_urls) ];
}

1;
