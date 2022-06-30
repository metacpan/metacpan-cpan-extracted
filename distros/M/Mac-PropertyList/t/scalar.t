#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

scalar.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/scalar.t

	# run a single test
	% prove t/scalar.t

=head1 AUTHORS

Original author: brian d foy C<< <bdfoy@cpan.org> >>

Contributors:

=over 4

=item trwyant C<< <wyant@cpan.org> >>

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

########################################################################
# Test the data bits
{
my $type_class = $class . '::real';

my $date = $type_class->new();
isa_ok( $date, $type_class );
}

########################################################################
# Test the real bits
{
my $type_class = $class . '::real';

my $real = $type_class->new;
isa_ok( $real, $type_class );

my $value = 3.15;
$string = $type_class->new( $value );
isa_ok( $string, $type_class );
is( $string->value, $value );
is( $string->type, 'real' );
is( $string->write, "<real>$value</real>" );
}

########################################################################
# Test the integer bits
{
my $type_class = $class . '::integer';

my $integer = $type_class->new;
isa_ok( $integer, $type_class );

my $value = 37;
$string = $type_class->new( $value );
isa_ok( $string, $type_class );
is( $string->value, $value );
is( $string->type, 'integer' );
is( $string->write, "<integer>$value</integer>" );
}

########################################################################
# Test the uid bits
{
my $type_class = $class . '::uid';

my $uid = $type_class->new();
isa_ok( $uid, $type_class );

my $value = 37;
$string = $type_class->integer( $value );
isa_ok( $string, $type_class );
is( $string->value, sprintf '%x', $value );
is( $string->type, 'uid' );
# Per plutil, this is the xml1 representation of a UID.
is( $string->write, "<dict>
	<key>CF\$UID</key>
	<integer>$value</integer>
</dict>" );
}

########################################################################
# Test the string bits
{
my $type_class = $class . '::string';

my $string = $type_class->new;
isa_ok( $string, $type_class );

my $value = 'Buster';
$string = $type_class->new( $value );
isa_ok( $string, $type_class );
is( $string->value, $value );
is( $string->type, 'string' );
is( $string->write, "<string>$value</string>" );
}

########################################################################
# Test the data bits
{
my $type_class = $class . '::data';
my $data = $type_class->new;
isa_ok( $data, $type_class );
}

########################################################################
# Test the boolean bits
{
my $type_class = $class . '::true';
my $true = $type_class->new;
isa_ok( $true, $type_class );
is( $true->value, 'true' );
is( $true->write, '<true/>' );
}

{
my $type_class = $class . '::false';
my $false = $type_class->new;
isa_ok( $false, $type_class );
is( $false->value, 'false' );
is( $false->write, '<false/>' );
}

done_testing();
