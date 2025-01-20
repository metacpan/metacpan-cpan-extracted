#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

array.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/array.t

	# run a single test
	% prove t/array.t

=head1 AUTHORS

Original author: brian d foy C<< <bdfoy@cpan.org> >>

Contributors:

=over 4

=item Tom Wyant C<< <wyant@cpan.org> >>

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

my $type_class = $class . '::array';
my $parse_fqname = $class . '::parse_plist';

########################################################################
# Test the array bits
{
my $array = $type_class->new();
isa_ok( $array, $type_class, 'Make empty $type_class object' );
is( $array->count, 0, 'Empty object has no elements' );
}

my $array =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>Mimi</string>
	<string>Roscoe</string>
	<string>Juliet</string>
	<string>Buster</string>
</array>
</plist>
HERE

$plist = &{$parse_fqname}( $array );
isa_ok( $plist, "${class}::array", "Make object from plist string" );
is( $plist->count, 4, "Object has right number of values" );

my @values = $plist->values;
ok( eq_array( \@values, [qw(Mimi Roscoe Juliet Buster)] ),
	"Object has right values" );

note 'Try non-canonical layout';
$plist = &{$parse_fqname}( <<"HERE" );
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array><string>Athos</string><string>Porthos</string><string>Aramis</string></array>
</plist>
HERE
isa_ok( $plist, $type_class, "Make object from non-canonical plist string" );
is( $plist->count, 3, "Non-canonical object has right number of values" );

@values = $plist->values();
ok( eq_array( \@values, [ qw{ Athos Porthos Aramis } ] ),
	"Non-canonical object has right values" );

done_testing();
