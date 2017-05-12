=head1 NAME

Firefox::Sync::Client - A Client for the Firefox Sync Server

=head1 SYNOPSIS

Simple example:

  use Firefox::Sync::Client;

  my $c = new Firefox::Sync::Client(
      URL      => 'https://your.ffsync-server.org/',
      User     => 'your@mail.address',
      Password => 'SyncPassword',
      SyncKey  => 'x-thisx-isxxx-thexx-secre-txkey',
  );

  my $tabs = $c->get_tabs;

  foreach my $client (@$tabs) {
      print $client->{'payload'}->{'clientName'} . "\n";
      foreach my $tab (@{$client->{'payload'}->{'tabs'}}) {
          print '    ' . $tab->{'title'} . "\n";
          print '        --> ' . $tab->{'urlHistory'}[0] . "\n";
      }
      print "\n";
  }

Advanced example, printing HTML code with all bookmarks and links. Results will be cached:

  use Firefox::Sync::Client;
  use utf8;
  binmode STDOUT, ':encoding(UTF-8)';

  my $c = new Firefox::Sync::Client(
      URL       => 'https://your.ffsync-server.org/',
      User      => 'your@mail.address',
      Password  => 'SyncPassword',
      SyncKey   => 'x-thisx-isxxx-thexx-secre-txkey',
      CacheFile => '/tmp/ffsync-cache',
  );
  
  my $bm = $c->get_bookmarks;
  
  print '<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body>' . "\n";
  print_children(1, $bm);
  print '</body></html>' . "\n";
  
  sub print_children {
      my ($h, $bm) = @_;
  
      foreach my $item (@$bm) {
          if ($item->{'payload'}->{'type'} eq 'folder') {
              print '<h' . $h . '>' . $item->{'payload'}->{'title'} . '</h' . $h . '>' . "\n";
              print '<ul>' . "\n";
              print_children($h + 1, $item->{'payload'}->{'children'});
              print '</ul>' . "\n";
          }
  
          if (defined $item->{'payload'}->{'bmkUri'}) {
              print '<li>';
              print '<a href="' . $item->{'payload'}->{'bmkUri'} . '" target="_blank">' . $item->{'payload'}->{'title'} . '</a>';
              print '</li>' . "\n";
          }
          else {
              print '<hr>' . "\n";
          }
      }
  }

=head1 DESCRIPTION

This module implements a client to the popular Firefox Sync service.

More information on the server can be found at Mozilla:
https://developer.mozilla.org/en-US/docs/Firefox_Sync

For now, this module is only a read-only client. That means, it is possible to
get some collections of things from the server by using either the specialized
get_* methods or get_raw_collection(). The methods usually return an array
reference.

In a future release, caching and some other improvements will be realized.

=head1 METHODS

What each method actually returns, can be different. But it will always be a
reference to an array containing hashes. Every hash has the following keys:

  id       - The ID of the element.
  modified - A timestamp of the last modification
  payload  - Contains a hash of elements. The keys are different for each collection

=cut

package Firefox::Sync::Client;

use strict;
use warnings;
use utf8;
use MIME::Base32 qw( RFC );
use MIME::Base64;
use Digest::SHA qw( sha1 hmac_sha256 );
use Crypt::Rijndael;
use JSON;
use LWP::UserAgent;
use Storable;

our $VERSION = '0.04';

our @ISA = qw(Exporter);
our @EXPORT = qw(new get_raw_collection get_addons get_bookmarks get_clients get_forms get_history get_meta get_passwords get_prefs get_tabs);

=over

=item new(%config)

Constructor. You can set the following parameters during construction:

  ProtocolVersion - defaults to 1.1
  URL             - The server address
  User            - The username or e-mail address
  Password        - The password
  SyncKey         - The sync/recovery key
  CacheFile       - A file to be used for caching
  CacheLifetime   - Lifetime of cached requests in seconds

=cut

sub new {
    my ($class, %args) = @_;

    # Get parameters and set values accordingly
    my $self = {};
    $self->{'protocol_version'} = $args{'ProtocolVersion'} || '1.1';
    $self->{'username'}         = $args{'User'}            || '';
    $self->{'password'}         = $args{'Password'}        || '';
    $self->{'sync_key'}         = $args{'SyncKey'}         || '';
    $self->{'base_url'}         = $args{'URL'}             || '';
    $self->{'cachefile'}        = $args{'CacheFile'}       || undef;
    $self->{'cachelifetime'}    = $args{'CacheLifetime'}   || 300;

    # Construct user name
    $self->{'username'} = lc(MIME::Base32::encode(sha1(lc($self->{'username'})))) if ($self->{'username'} =~ /[^A-Z0-9._-]/i);

    # Extract hostname and port from URL
    $self->{'base_url'} =~ /^(http|https):\/\/([^:\/]*):?(\d+)?/ or die 'Invalid URL format';
    $self->{'hostname'} = $2;
    $self->{'port'}     = ( $3 ? $3 : ( $1 eq 'http' ? '80' : '443' ) );

    # Construct base url
    $self->{'base_url'} .= '/' unless $self->{'base_url'} =~ /\/$/;
    $self->{'base_url'} .= $self->{'protocol_version'} . '/' . $self->{'username'} . '/';

    # Prepare hash for keys
    $self->{'bulk_keys'} = {};

    # Prepare temp file if used
    if (defined $self->{'cachefile'}) {
        open TF, '>>', $self->{'cachefile'};
        close TF;
    }

    bless($self, $class);
    return $self;
}

=item get_raw_collection($collection)

Returns an array reference containing all elements of the given collection.

The following collections are tested (but other collections may also work):

  bookmarks
  prefs
  clients
  forms
  history
  passwords
  tabs
  addons

You can not fetch the metadata with this method, please use get_meta() instead.
Also, if you plan to do something with the 'bookmarks' collection, better use
get_bookmarks(), as it returns a somewhat nicer formatted array reference.

=cut

sub get_raw_collection {
    my ($self, $collection) = @_;

    # First, fetch the keys we use for decryption later - if we haven't already
    $self->{'bulk_keys'} = fetch_bulk_keys($self) unless $self->{'bulk_keys'}->{'default'};

    # Fetch the whole collection from the server.
    my $ret = fetch_json($self, $self->{'base_url'} . 'storage/' . $collection . '?full=1');

    # The 'payload' elements of the fetched array contain a JSON object that
    # has to be decrypted.
    foreach my $item (@$ret) {
        my $json = decrypt_collection($self, decode_json($item->{'payload'}), $collection);

        # What we see now, looks like another JSON object, but it contains some
        # noise, so we first repair it, then decode it and write it back to the item.
        $json = repair_json($self, $json);
        $item->{'payload'} = decode_json($json);
    }

    return $ret;
}

=item get_addons()

Returns an array of the synced add-on data.

=cut

sub get_addons {
    my $self = shift;
    return get_raw_collection($self, 'addons');
}

=item get_bookmarks()

Returns all bookmark collections, folders and bookmarks in a well formatted
array. That means, the references are recursively resolved in the tree.

=cut

sub get_bookmarks {
    my $self = shift;
    my $collection = get_raw_collection($self, 'bookmarks');

    my @tree;

    foreach my $bm (@$collection) {
        next unless $bm->{'payload'}->{'parentid'} and $bm->{'payload'}->{'parentid'} eq 'places';
        resolve_children($collection, $bm);
        push @tree, $bm if defined $bm;
    }

    return \@tree;
}

=item get_clients()

Returns all known data of the connected Sync clients.

=cut

sub get_clients {
    my $self = shift;
    return get_raw_collection($self, 'clients');
}

=item get_forms()

Returns an array of synchronized form input data.

=cut

sub get_forms {
    my $self = shift;
    return get_raw_collection($self, 'forms');
}

=item get_history()

Returns the synced browser history.

=cut

sub get_history {
    my $self = shift;
    return get_raw_collection($self, 'history');
}

=item get_meta()

Returns an array containing the sync metadata for the user.

=cut

sub get_meta {
    my $self = shift;
    $self->{'bulk_keys'} = fetch_bulk_keys($self) unless $self->{'bulk_keys'}->{'default'};
    my $ret = fetch_json($self, $self->{'base_url'} . 'storage/meta?full=1');

    foreach my $item (@$ret) {
        my $json = $item->{'payload'};
        $json = repair_json($self, $json);
        $item->{'payload'} = decode_json($json);
    }

    return $ret;
}

=item get_passwords()

Returns all synchronized passwords. The passwords are returned
unencrypted.

=cut

sub get_passwords {
    my $self = shift;
    return get_raw_collection($self, 'passwords');
}

=item get_prefs()

Returns the synchronized browser preferences.

=cut

sub get_prefs {
    my $self = shift;
    return get_raw_collection($self, 'prefs');
}

=item get_tabs()

Returns an array of tabs opened on each Sync client / Browser.

=cut

sub get_tabs {
    my $self = shift;
    return get_raw_collection($self, 'tabs');
}

sub resolve_children {
    my ($collection, $bm) = @_;
    if ($bm->{'payload'}->{'children'} and scalar($bm->{'payload'}->{'children'})) {
        my @children;
        foreach my $child_id (@{$bm->{'payload'}->{'children'}}) {
            my $child_bm;
            foreach (@$collection) {
                next unless $_->{'id'} eq $child_id;
                $child_bm = $_;
                push @children, $_;
            }
            resolve_children($collection, $child_bm);
        }
        $bm->{'payload'}->{'children'} = \@children;
    }
}

sub sync_key_to_enc_key {
    my $self = shift;
    my $s_key = $self->{'sync_key'};
    $s_key =~ s/8/l/g;
    $s_key =~ s/9/o/g;
    $s_key =~ s/-//g;
    $s_key = uc($s_key);
    my $raw_bits = MIME::Base32::decode($s_key);
    my $key = hmac_sha256('Sync-AES_256_CBC-HMAC256' . $self->{'username'} . "\x01", $raw_bits);
    return $key;
}

sub fetch_bulk_keys {
    my $self = shift;
    my $json = fetch_json($self, $self->{'base_url'} . 'storage/crypto/keys');
    my $keys = decrypt_collection($self, decode_json($json->{'payload'}), 'crypto');
    my $default_keys = decode_json($keys);
    $self->{'bulk_keys'}{'default'} = decode_base64($default_keys->{'default'}[0]);
    return $self->{'bulk_keys'};
}

sub decrypt_payload {
    my ($self, $payload, $key) = @_;

    my $c = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC());
    $c->set_iv(decode_base64($payload->{'IV'}));

    my $data = $c->decrypt(decode_base64($payload->{'ciphertext'}));
    $data = repair_json($self, $data);

    return $data;
}

sub decrypt_collection {
    my ($self, $payload, $collection) = @_;
    my $key;

    if ($collection eq 'crypto') {
        $key = sync_key_to_enc_key($self);
    }
    else {
        if ($self->{'bulk_keys'}{$collection}) {
            $key = $self->{'bulk_keys'}{$collection};
        }
        else {
            $key = $self->{'bulk_keys'}{'default'};
        }
    }

    return decrypt_payload($self, $payload, $key);
}

sub fetch_json {
    my ($self, $url) = @_;
    my $res;

    if (defined $self->{'cachefile'}) {
        $self->{'cache'} = retrieve($self->{'cachefile'}) unless (-z $self->{'cachefile'});

        if (defined $self->{'cache'}->{$url} and (time - $self->{'cache'}->{$url . '_ts'} <= $self->{'cachelifetime'})) {
            # We have a cache hit, so simply return it
            return decode_json($self->{'cache'}->{$url}->content);
        }
        else {
            # Really do the request
            $res = really_fetch_json($self, $url);

            # Cache the request
            $self->{'cache'}->{$url}         = $res;
            $self->{'cache'}->{$url . '_ts'} = time;
            store($self->{'cache'}, $self->{'cachefile'});
        }
    }
    else {
        # We don't have a cache file, so simply request the data and return it
        $res = really_fetch_json($self, $url);
    }

    return decode_json($res->content);
}

sub really_fetch_json {
    my ($self, $url) = @_;

    # Initialize LWP
    my $ua = LWP::UserAgent->new;
    $ua->agent ("FFsyncClient/0.1 ");
    $ua->credentials ( $self->{'hostname'} . ':' . $self->{'port'}, 'Sync', $self->{'username'} => $self->{'password'} );

    # Do the request
    my $res = $ua->get($url);
    die $res->{'_msg'} if ($res->{'_rc'} != '200');

    return $res;
}

sub repair_json {
    my ($self, $json) = @_;
    $json =~ s/[\x00-\x1f]*//g;
    $json .= '}' unless $json =~ /\}$/;

    my $left  = ($json =~ tr/\{//);
    my $right = ($json =~ tr/\}//);
    
    if ($left > $right) {
        my $diff = $left - $right;
        ($json .= '}', $diff--) while ($diff > 0);
    }
    elsif ($left < $right) {
        my $diff = $right - $left;
        ($json = '{' . $json, $diff--) while ($diff > 0);
    }

    return $json;
}

1;

__END__

=back

=head1 AUTHOR

Robin Schroeder, E<lt>schrorg@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Robin Schroeder

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
