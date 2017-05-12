#!/usr/bin/perl -w

use Gallery::Remote;

# XXX - Currently all commented out because you can't really
# test this automatically very well.

# print "Logging in\n";
# my $gr = Gallery::Remote->new(URL => "http://gallery.example.com/",
# 			      USERNAME => "admin",
# 			      PASSWORD => "password",
# 			      VERBOSE => 0,
# 			      DEBUG => 0,
# 			     );

# $gr->login();
# print "done logging in, fetching albums\n";

# my $album_data = $gr->fetch_albums_prune();

# if ($album_data) {
#     print "Albums found: " . scalar(@$album_data) . "\n";
# } else {
#     print "No albums found.\n";
# }

# foreach my $album_entry (@$album_data) {
#     foreach my $key (keys %$album_entry) {
# 	print "Found: album_entry{$key} = $$album_entry{$key}\n";
#     }
# }

# my $parms = {};
# my $picparms = {};

# $$parms{newAlbumName} = "test";
# $$parms{newAlbumTitle} = "A test of Gallery::Remote";
# $$parms{newAlbumDesc} = "I'm testing out my perl script";

# my $parent_album = $gr->new_album( %$parms );
# print "Created new album: $parent_album\n";

# $parms = {};
# $$parms{set_albumName} = $parent_album;
# $$parms{newAlbumName} = "Test Album";
# $$parms{newAlbumDesc} = "Sub album test";
# $$parms{newAlbumName} = "test2";
# my $new_album_name = $gr->new_album( %$parms );
# print "Created new album: $new_album_name under parent album $parent_album\n";

# $$picparms{set_albumName} = $new_album_name;
# $$picparms{userfile} = [ "./example.jpg" ];
# $$picparms{userfile_name} = "example.jpg";
# $$picparms{caption} = "Testing Gallery::Remote";

# $gr->add_item( %$picparms );
