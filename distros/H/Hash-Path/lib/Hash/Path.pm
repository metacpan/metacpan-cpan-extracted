package Hash::Path;

use warnings;
use strict;

our $VERSION = '0.02';

use base 'Exporter';

our @EXPORT_OK = qw(hash_path);

sub get {
    my ($class, $data_ref, @path) = @_;
    return $data_ref unless scalar @path;
    my $return_value = $data_ref->{ $path[0] };
    for (1 .. (scalar @path - 1)) {
        $return_value = $return_value->{ $path[$_] };
    }
    return $return_value;
}

sub hash_path {
    return __PACKAGE__->get(@_);
}

1;

=pod

=head1 NAME

Hash::Path - A simple way to return a path of HoH

=head1 VERSION

0.02

=head1 SYNOPSIS

	 use Hash::Path;

	 my $hash_ref = {
	     key1 => {
	         key2 => {
	             key3 => 'value',
	         },
	     },
	 };

	 my $wanted = Hash::Path->( $hash_ref, qw{key1 key2 key3} );

	 # $wanted contains 'value'

=head1 DESCRIPTION

This module was written as proof of concept about how to find data inside a hash of hashes (HoH) with
unknown structure. You can think that as hierarchical data like LDAP does, so our C<path> could be the
exactly the same as LDAP's C<dn>, but a bit simpler because we (at least at this moment, who knows) don't
want to deal with that.

This is a perfect companion for traversing L<YAML>:

	use Hash::Path;
	use YAML;

	my ($hash_ref) = Load(<<'EOF');
	---
	name: john
	permissions:
	  some-module:
	    - read
	    - write
	    - execute
	  another-module:
	    - read
	EOF
	my $permissions = Hash::Path->get($hash_ref, qw(permissions some-module));

	# $permissions contains [ 'read', 'write', 'execute' ]

=head1 API

=over 4

=item get

	$scalar = Hash::Path->get($hash_ref, @path);

This is the only available method. It traverses the hash reference using the supplied path array,
returning the value as scalar value.

=item hash_path

        use Hash::Path qw(hash_path);
        $scalar = hash_path($hash_ref, @path);

Now you can export the C<hash_path> function to be a bit shorter. The
parameters it takes are the same as C<get>.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Arthur Axel "fREW" Schmidt "<FREW@cpan.org>" for using this
module and suggesting a better implementation for the C<get()> method.

=head1 AUTHOR

Copyright (c) 2007, Igor Sutton Lopes "<IZUT@cpan.org>". All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
