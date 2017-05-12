Perl module for reading IR data from LIRC. Note that this doesn't go through the 
higher-level mappings, but rather parses the pulse and space data. At the moment, 
this is parsed based on `mode2`, but may access `/dev/lirc*` directly in the future.
