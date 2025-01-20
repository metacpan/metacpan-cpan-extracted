#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

write.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/write.t

	# run a single test
	% prove t/write.t

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

my $array =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>Mimi</string>
	<string>Roscoe</string>
</array>
</plist>
HERE

my $dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<string>Roscoe</string>
</dict>
</plist>
HERE

my $nested_dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<dict>
		<key>Roscoe</key>
		<integer>1</integer>
		<key>Boolean</key>
		<true/>
	</dict>
</dict>
</plist>
HERE

my $nested_dict_alt =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<dict>
		<key>Boolean</key>
		<true/>
		<key>Roscoe</key>
		<integer>1</integer>
	</dict>
</dict>
</plist>
HERE

my $array_various =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<data>
	RHJpbmsgeW91ciBvdmFsdGluZS4=
	</data>
	<data></data>
	<date>2009-07-11T18:40:29Z</date>
</array>
</plist>
HERE

foreach my $start ( ( $array, $dict ) )
	{
	my $plist  = Mac::PropertyList::parse_plist( $start );
	my $string = Mac::PropertyList::plist_as_string( $plist );
	is( $string, $start, 'Original and rewritten string match' );
	}

my $plist  = Mac::PropertyList::parse_plist( $nested_dict );
my $string = Mac::PropertyList::plist_as_string( $plist );

note( "\n$string\n" ) if $ENV{DEBUG};

ok( ($string eq $nested_dict) || ($string eq $nested_dict_alt), "Nested dict" );

$plist = Mac::PropertyList::parse_plist( $array_various );
is($plist->[0]->value, 'Drink your ovaltine.', 'data decode');
is($plist->[1]->value, '', 'empty data');
is($plist->[2]->value, '2009-07-11T18:40:29Z', 'date value');
$string = Mac::PropertyList::plist_as_string( $plist );
$string = &canonicalize_data_elts($string);
is($string, &canonicalize_data_elts($array_various),
   'Original and rewritten string match');
is_deeply($plist, Mac::PropertyList::parse_plist($string),
   "canonicalization doesn't break test");

done_testing();

sub canonicalize_data_elts {
    my($string) = @_;

    # Whitespace is ignored inside <data>
    $string =~ s#(\<data\>)([a-zA-Z0-9_+=\s]+)(\</data\>)# my($b64) = $2; $b64 =~ y/a-zA-Z0-9_+=//cd; $1.$b64.$3; #gem;
    $string;
}
