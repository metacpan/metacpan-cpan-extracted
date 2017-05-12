# NAME

Hash::BulkKeyCopy - a xs module for clone hash with keys

# SYNOPSIS

    use Hash::BulkKeyCopy;

# USAGE

    my $ht_ka = ["k1_1", "k1_2", "k1_3"]; # it will use src_hash's keys when give an empty array   
    my $hs_ka = ["k2_1", "k2_2", "k2_3"];   
       
    my ($h1, $h2) = ({}, {"k2_1" => 1, "k2_2" => undef, "k2_3" => []});   
    hash_bulk_keycopy($h1, $h2, $ht_ka, $hs_ka);   

# DESCRIPTION

Hash::BulkKeyCopy is a xs module for clone hash by a key arr.  
Double faster than PP source.

# LICENSE

Copyright (C) itsusony. FreakOut.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

itsusony <itsusony@fout.jp>
