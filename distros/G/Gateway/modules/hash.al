# hash.al -- Methods to read hashes from files.  -*- perl -*-
# $Id: hash.al,v 0.1 1998/03/26 07:12:36 eagle Exp $
#
# Copyright 1998 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

package News::Gateway;

############################################################################
# Methods
############################################################################

# Opens a hash file, returning a reference to a hash.  Takes in a file name
# as an argument.  If this file name ends in .db, we load DB_File and tie a
# hash to the file.  Otherwise, we take the file to be a text file and read
# it in a line at a time.  In this case, we use our second argument; if
# defined, it's taken to be an anonymous sub that will split each line apart
# into a key and then a list of values.  Otherwise, the entire line is taken
# to be the key and the value will be the number of times that key is seen.
# We return undef if we're unable to open the file, and the error will be in
# $!.
sub hash_open {
    my ($self, $file, $split) = @_;
    my %hash;
    if ($file =~ /\.db$/) {
        eval { require DB_File };
        if ($@) { $self->error ("Unable to load DB_File: $@") }
        tie (%hash, 'DB_File', $file) or return undef;
    } else {
        open (HASH, "< $file") or return undef;
        local $_;
        my ($key, @rest);
        while (<HASH>) {
            chomp;
            if (defined $split) {
                ($key, @rest) = &$split ($_);
                $hash{$key} = (@rest == 1) ? $rest[0] : [ @rest ];
            } else {
                $hash{$_}++;
            }
        }
        close HASH;
    }
    return \%hash;
}

1;
