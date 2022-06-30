#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

dict.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/dict.t

	# run a single test
	% prove t/dict.t

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

my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

my $type_class = $class . '::dict';
my $parse_fqname = $class . '::parse_plist';

########################################################################
# Test the dict bits
{
my $dict = $type_class->new;
isa_ok( $dict, "${class}::dict" );
is( $dict->count, 0, "Empty object has right number of keys" );
}

########################################################################
my $dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<string>Roscoe</string>
	<key>Buster</key>
	<string>Juliet</string>
</dict>
</plist>
HERE

$plist = &{$parse_fqname}( $dict );
isa_ok( $plist, $type_class );
is( $plist->count, 2, "Has right number of keys" );
isnt( $plist->count, 3, "Hasn't wrong number of keys" );

my @keys = sort $plist->keys;
ok( eq_array( \@keys, [qw(Buster Mimi)] ), "Check hash keys" );

my @values = sort $plist->values;
ok( eq_array( \@values, [qw(Juliet Roscoe)] ), "Check hash values" );

ok( $plist->exists( 'Mimi' ),   'Mimi key exists' );
ok( $plist->exists( 'Buster' ), 'Buster key exists' );
is( $plist->exists( 'Juliet' ), 0, 'Juliet key does not exist' );

is( $plist->value( 'Mimi' ),   'Roscoe', "Check Mimi's value" );
is( $plist->value( 'Buster' ), 'Juliet', "Check Buster's value" );

$plist->delete( 'Mimi' );
is( $plist->exists( 'Mimi' ), 0, 'Mimi key does not exist' );
ok( $plist->exists( 'Buster' ), 'Buster key exists after delete' );
is( $plist->count, 1, "Has right count after delete" );

note 'Try non-canonical layout';

$plist = &{$parse_fqname}( <<"HERE" );
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict><key>Clayton</key><string>John</string><key>Napier</key><string>Carson</string><key>Gridley</key><string>Jason</string></dict>
</plist>
HERE
isa_ok( $plist, $type_class );
is( $plist->count, 3, "Has right number of keys" );

@keys = sort $plist->keys;
ok( eq_array( \@keys, [qw(Clayton Gridley Napier)] ), "Check hash keys" );

@values = sort $plist->values;
ok( eq_array( \@values, [qw(Carson Jason John)] ), "Check hash values" );

ok( $plist->exists( 'Clayton' ), 'Claytin key exists' );

is( $plist->value( 'Clayton' ),  'John', "Check Clayton's value" );

done_testing();
