#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

parse.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/parse.t

	# run a single test
	% prove t/parse.t

=head1 AUTHORS

Original author: brian d foy C<< <bdfoy@cpan.org> >>

Contributors:

=over 4

=item Andy Lester C<< <andy@petdance.com> >>

=item Chris Lloyd C<< <chris.lloyd@storyshareplatform.com> >>

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

my $string1_0 =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<string>This is it</string>
</plist>
HERE

my $string0_9 =<<"HERE";
<?xml version="0.9" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<string>This is it</string>
</plist>
HERE

my $empty_string =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<string/>
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

########################################################################
my $parse_fqname = $class . '::parse_plist';

my $array_shortname  = 'array';
my $dict_shortname   = 'dict';
my $string_shortname = 'string';

my $array_type  = join '::', $class, $array_shortname;
my $dict_type   = join '::', $class, $dict_shortname;
my $string_type = join '::', $class, $string_shortname;

{
my $plist = &{$parse_fqname}( $array );

isa_ok( $plist, $array_type );
is(     $plist->type, $array_shortname, "Item is an $array_shortname type" );
isa_ok( $plist->value, $array_type );

my @elements = @{ $plist->value };
isa_ok( $elements[0], $string_type );
isa_ok( $elements[1], $string_type );
is( $elements[0]->value, 'Mimi',   "Mimi $string_shortname is right"  );
is( $elements[1]->value, 'Roscoe', "Roscoe $string_shortname is right" );
}

########################################################################
{
my $plist = &{$parse_fqname}( $dict );
isa_ok( $plist, $dict_type );
is( $plist->type, $dict_shortname, "item is a $dict_shortname type" );
isa_ok( $plist->value, $dict_type );

my $hash = $plist->value;
ok( exists $hash->{Mimi}, 'Mimi key exists for dict' );
isa_ok( $hash->{Mimi}, $string_type );
is( $hash->{Mimi}->value, 'Roscoe', 'Mimi string has right value' );
}

########################################################################
foreach my $string ( ( $string0_9, $string1_0 ) ) {
	my $plist = &{$parse_fqname}( $string );

	isa_ok( $plist, $string_type );
	is( $plist->type, $string_shortname, 'type key has right value for string' );
	is( $plist->value, 'This is it', 'value is right for string' );
	}

$plist = &{$parse_fqname}( $nested_dict );

isa_ok( $plist, $dict_type );
is( $plist->type, $dict_shortname, 'type key has right value for nested dict' );
isa_ok( $plist->value, 'HASH' );

########################################################################
my $hash = $plist->value->{Mimi};

isa_ok( $plist, $dict_type );
is( $plist->type, $dict_shortname, "item is a $dict_shortname type" );
isa_ok( $plist->value, $dict_type );
is( $hash->value->{Roscoe}->value, 1, 'Roscoe string has right value'   );
is( $hash->value->{Boolean}->value, 'true', 'Boolean string has right value'  );

########################################################################

$plist = &{$parse_fqname}( $empty_string );

isa_ok( $plist, $string_type );
is( $plist->type, $string_shortname, 'type key has right value for string' );
is( $plist->value, '', 'value is right for string' );

done_testing();
