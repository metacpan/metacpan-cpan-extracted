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

Original author: brian d foy C<< <briandfoy@pobox.com> >>

Contributors:

=over 4

=item Andy Lester C<< <andy@petdance.com> >>

=item Chris Lloyd C<< <chris.lloyd@storyshareplatform.com> >>

=back

=head1 SOURCE

This file was originally in https://github.com/briandfoy/mac-propertylist

=head1 COPYRIGHT

Copyright © 2002-2026, brian d foy, C<< <briandfoy@pobox.com> >>

=head1 LICENSE

This file is licenses under the Artistic License 2.0. You should have
received a copy of this license with this distribution.

=cut

my $class = 'Mac::PropertyList';
my $method = 'parse_plist';
my $method_ref;
subtest sanity => sub {
	use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );
	can_ok $class, $method;
	$method_ref = $class->can($method);
};

my $old_template = <<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
%s
</plist>
HERE

my $new_template = $old_template;
$new_template =~ s/Apple Computer/Apple/;

my %templates = (
	'Apple' => $new_template,
	'Apple Computer' => $old_template,
	);

my $array =<<"HERE";
<array>
	<string>Mimi</string>
	<string>Roscoe</string>
</array>
HERE

my $dict =<<"HERE";
<dict>
	<key>Mimi</key>
	<string>Roscoe</string>
</dict>
HERE

my $string1_0 =<<"HERE";
<string>This is it</string>
HERE

my $string0_9 =<<"HERE";
<string>This is it</string>
HERE

my $empty_string =<<"HERE";
<string/>
HERE

my $nested_dict =<<"HERE";
<dict>
	<key>Mimi</key>
	<dict>
		<key>Roscoe</key>
		<integer>1</integer>
		<key>Boolean</key>
		<true/>
	</dict>
</dict>
HERE


my $array_shortname  = 'array';
my $dict_shortname   = 'dict';
my $string_shortname = 'string';

my $array_type  = join '::', $class, $array_shortname;
my $dict_type   = join '::', $class, $dict_shortname;
my $string_type = join '::', $class, $string_shortname;

foreach my $key ( sort keys %templates ) {
	subtest $key => sub {
		my $template = $templates{$key};

		subtest 'array' => sub {
			my $plist = $method_ref->( sprintf $template, $array );

			isa_ok( $plist, $array_type );
			is(     $plist->type, $array_shortname, "Item is an $array_shortname type" );
			isa_ok( $plist->value, $array_type );

			my @elements = @{ $plist->value };
			isa_ok( $elements[0], $string_type );
			isa_ok( $elements[1], $string_type );
			is( $elements[0]->value, 'Mimi',   "Mimi $string_shortname is right"  );
			is( $elements[1]->value, 'Roscoe', "Roscoe $string_shortname is right" );
			};

		subtest 'dict' => sub {
			my $plist = $method_ref->( sprintf $template, $dict );
			isa_ok( $plist, $dict_type );
			is( $plist->type, $dict_shortname, "item is a $dict_shortname type" );
			isa_ok( $plist->value, $dict_type );

			my $hash = $plist->value;
			ok( exists $hash->{Mimi}, 'Mimi key exists for dict' );
			isa_ok( $hash->{Mimi}, $string_type );
			is( $hash->{Mimi}->value, 'Roscoe', 'Mimi string has right value' );
			};

		subtest 'strings' => sub {
			foreach my $string ( $string0_9, $string1_0 ) {
				my $plist = $method_ref->( sprintf $template, $string );

				isa_ok( $plist, $string_type );
				is( $plist->type, $string_shortname, 'type key has right value for string' );
				is( $plist->value, 'This is it', 'value is right for string' );
				}
			};

		subtest 'nested dict' => sub {
			my $plist = $method_ref->( sprintf $template, $nested_dict );

			isa_ok( $plist, $dict_type );
			is( $plist->type, $dict_shortname, 'type key has right value for nested dict' );
			isa_ok( $plist->value, 'HASH' );

			my $hash = $plist->value->{Mimi};

			isa_ok( $plist, $dict_type );
			is( $plist->type, $dict_shortname, "item is a $dict_shortname type" );
			isa_ok( $plist->value, $dict_type );
			is( $hash->value->{Roscoe}->value, 1, 'Roscoe string has right value'   );
			is( $hash->value->{Boolean}->value, 'true', 'Boolean string has right value'  );
			};

		subtest 'empty string' => sub {
			my $plist = $method_ref->( sprintf $template, $empty_string );

			isa_ok( $plist, $string_type );
			is( $plist->type, $string_shortname, 'type key has right value for string' );
			is( $plist->value, '', 'value is right for string' );
			};
		};
	}

done_testing();
