#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

false_key.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/false_key.t

	# run a single test
	% prove t/false_key.t

=head1 AUTHORS

Original author: brian d foy C<< <bdfoy@cpan.org> >>

Contributors:

=over 4

=item Andy Lester C<< <andy@petdance.com> >>

=back

=head1 SOURCE

This file was originally in https://github.com/briandfoy/mac-propertylist

=head1 COPYRIGHT

Copyright © 2002-2022, brian d foy, C<< <bdfoy@cpan.org> >>

=head1 LICENSE

This file is licenses under the Artistic License 2.0. You should have
received a copy of this license with this distribution.

=cut

my $class = 'Mac::PropertyList::SAX';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

my $parse_fqname = $class . '::parse_plist';

my $good_dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>0</key>
	<string>Roscoe</string>
	<key> </key>
	<string>Buster</string>
</dict>
</plist>
HERE

my $bad_dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key></key>
	<string>Roscoe</string>
</dict>
</plist>
HERE

my $ok = eval {
	my $plist = &{$parse_fqname}( $good_dict );
	};
ok( $ok, "Zero and space are valid key values" );

TODO: {
    local $TODO = "Doesn't work, but poor Andy doesn't know why.";

    my $ok = eval {
		my $plist = &{$parse_fqname}( $good_dict );
		};

	like( $@, qr/key not defined/, "Empty key causes $parse_fqname to die" );
	}

done_testing();
