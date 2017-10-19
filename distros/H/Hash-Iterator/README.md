Hash-Iterator version 0.02
==========================

**INSTALLATION**

	To install this module type the following:

	perl Makefile.PL
	make
	make test
	make install
	
_cpan_

	sudo perl -MCPAN -e shel
	cpan> install Hash::Iterator
	
	cpan install Hash::Iterator
	

**NAME**

Hash::Iterator - Hashtable Iterator.

**SYNOPSIS**

    my $iterator = Hash::Iterator->new( map { $_ => uc $_ } 'a'..'z' );

    while ($iterator->next) {
        say sprintf("%s => %s", $iterator->peek_key, $iterator->peek_value);
    }

    my $iterator = Hash::Iterator->new( a => [qw(one two three)] );
    $iterator->next;

    if ( $iterator->is_ref('ARRAY') ) {
        foreach my $item ( @{$iterator->peek_value} ) {
            say $item;
        }
    }

**DESCRIPTION**

_CONSTRUCTORS_

_new_

	my $iterator = Hash::Iterator->new( %hash );

Return a Hash::Iterator for C<hash>

**METHODS**

_next_

    $iterator->next;

Advance the iterator to the next key-value pair

_previous_

    $iterator->previous;

Advance the iterator to the previous key-value pair

_done_

    do {
        ....
    } while ($iterator->done);

Returns a boolean value if the iterator was exhausted

_peek_key_

    say $iterator->peek_key;

Return the key of the current key-value pair. It's not allowed to
call this method before L<next()|/next> was called for the first time or
after the iterator was exhausted.

_peek_value_

    say $iterator->peek_value;

Return the value of the current key-value pair.  It's not allowed to
call this method before L<next()|/next> was called for the first time or
after the iterator was exhausted.

_is_ref_

    if ( $iterator->is_ref('ARRAY') ) {
        ...
    }

Returns a boolean value if value is a reference.

_get_keys_

    my @keys =  $iterator->get_keys;

Returns a list of all keys from hash

**AUTHOR**

vlad mirkos, E<lt>vladmirkos@sd.apple.comE<gt>

**COPYRIGHT AND LICENSE**

Copyright (C) 2017 by vlad mirkos

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.