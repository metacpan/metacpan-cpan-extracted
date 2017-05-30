## ----------------------------------------------------------------------------
# Copyright (C) 2014-2016 NZRS Ltd.
## ----------------------------------------------------------------------------
package Test::JSON::Assert;

use 5.006000;
use strict;
use warnings;
use Test::Builder::Module;
our @ISA = qw(Test::Builder::Module);
use JSON::Assert;

our @EXPORT = qw(
    is_jpath_count
    does_jpath_value_match
    do_jpath_values_match
    does_jpath_contains
);


my $CLASS = __PACKAGE__;

sub is_jpath_count($$$;$) {
    my ($doc, $jpath, $count, $name) = @_;

    # create the $json_assert object
    my $json_assert = JSON::Assert->new();

    # do the test and remember the result
    my $is_ok = $json_assert->is_jpath_count($doc, $jpath, $count);

    my $tb = $CLASS->builder();
    return $tb->ok($is_ok, $name);
}

sub does_jpath_value_match($$$;$) {
    my ($doc, $jpath, $match, $name) = @_;

    my $json_assert = JSON::Assert->new();

    # do the test and remember the result
    my $is_ok = $json_assert->does_jpath_value_match($doc, $jpath, $match);

    my $tb = $CLASS->builder();
    return $tb->ok($is_ok, $name);
}

sub do_jpath_values_match($$$;$) {
    my ($doc, $jpath, $match, $name) = @_;

    my $json_assert = JSON::Assert->new();

    # do the test and remember the result
    my $is_ok = $json_assert->do_jpath_values_match($doc, $jpath, $match);

    my $tb = $CLASS->builder();
    return $tb->ok($is_ok, $name);
}

sub does_jpath_contains($$$;$) {
    my ($doc, $jpath_str, $match, $name) = @_;

    my $json_assert = JSON::Assert->new();

    # do the test and remember the result
    my $is_ok = $json_assert->does_jpath_contains($doc, $jpath_str, $match);

    my $tb = $CLASS->builder();
    return $tb->ok($is_ok, $name);

}


1;

__END__

=head1 NAME

Test::JSON::Assert - Tests JPaths into an JSON Data structure for correct values/matches

=head1 SYNOPSIS

 use Test::JSON::Assert tests => 2;

 my $xml1 = "<foo xmlns="urn:message"><bar baz="buzz">text</bar></foo>";
 my $xml2 = "<f:foo xmlns:f="urn:message"><f:bar baz="buzz">text</f:bar></f:foo>";
 my $xml3 = "<foo><bar baz="buzz">text</bar></foo>";

 ToDo

=head1 DESCRIPTION

This module allows you to test if two JSON data structures are semantically the
same.

It uses JSON::Assert to do all of it's checking.

=head1 SUBROUTINES

In all of the following subroutines there are three common parameters.

C<$doc> is a data structure generated from a JSON document.

C<$jpath> is a string which contains the path to the element(s) you'd like to
match against, whether this is for a count or a value match.

=over 4

=item is_jpath_count($doc, $jpath, $count, $name)

Test passes if there are $count keys referenced by $jpath in the $doc.

C<$count> is the number of expected keys which match the C<$jpath>.

=item does_jpath_value_match($doc, $jpath, $match, $name)

Test passes if C<$jpath> matches only one key in C<$doc> and the value
matched smart matches against C<$match>.

Again, C<$match> can be a scalar, regex, arrayref or anything the smart match
operator can match on.

=item do_jpath_values_match($doc, $jpath, $match, $name)

Test passes if C<$jpath> matches at least one key in C<$doc> and all nodes
matched smart matches against C<$match>.

Again, C<$match> can be a scalar, regex, arrayref or anything the smart match
operator can match on.

=item does_jpath_contains($doc, $jpath, $match, $name)

Test passes if C<$jpath> contains a key in C<$doc> that matches against C<$match>.

Again, C<$match> can be a scalar, regex, arrayref.

=back

=head1 EXPORTS

Everything in L<"SUBROUTINES"> by default, as expected.

=head1 SEE ALSO

L<JSON::Assert>, L<XML::Assert>, L<XML::Compare>, L<Test::Builder>

=head1 AUTHOR

=over 4

=item Work

E<lt>puck at catalyst dot net dot nzE<gt>, http://www.catalyst.net.nz/

=item Personal

E<lt>andrew at etc dot gen dot nz<gt>, http://www.etc.gen.nz/

=back

=head1 COPYRIGHT & LICENSE

This software development is sponsored and directed by NZRS Ltd., http://www.nzrs.net.nz/

Part of work was carried out by Catalyst IT, http://www.catalyst.net.nz/

Copyright (c) 2014-2015, NZRS Limited.  All Rights Reserved.  This software
may be used under the terms of the Artistic License 2.0.  Note that this
license is compatible with both the GNU GPL and Artistic licenses.  A copy of
this license is supplied with the distribution in the file COPYING.txt.

=cut
