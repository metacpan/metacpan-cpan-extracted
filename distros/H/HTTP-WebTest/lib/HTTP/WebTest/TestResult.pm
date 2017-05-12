# $Id: TestResult.pm,v 1.5 2003/03/02 11:52:10 m_ilya Exp $

package HTTP::WebTest::TestResult;

=head1 NAME

HTTP::WebTest::TestResult - Test results class

=head1 SYNOPSIS

    use HTTP::WebTest::TestResult;

    my $result = HTTP::WebTest::TestResult;

    my $bool = $result->ok;
    $result->ok($bool);
    my $comment = $result->comment;
    $result->comment($comment);

    if($result) { ... }

=head1 DESCRIPTION

Objects of this class represent test results.  Test results are
basicly C<ok>/C<not ok> and some attached commentary.

This class overloads C<bool> operation so it can be directly used in
statements that require boolean values.

    if($result) { ... }

is equivalent to

    if($result->ok) { ... }

=head1 CLASS METHODS

=cut

use strict;

use HTTP::WebTest::Utils qw(make_access_method);

use overload bool => \&_bool;

=head2 new ()

Constructor

=head3 Returns

A new C<HTTP::WebTest::TestResult> object.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    return $self;
}

=head2 ok ($optional_ok)

If C<$optional_ok> is passed,
Defines whether or not test is successful.

=head3 Returns

True if test is successful.  False otherwise.

=cut

*ok = make_access_method('OK');

=head2 comment ($optional_comment)

If C<$optional_comment> is passed, sets test result comment.

=head3 Returns

A test result comment.

=cut

*comment = make_access_method('COMMENT');

# this method is used to overload 'bool' operation.  'ok' can't be used
# directly because method which is overloads operation is called with
# some additional arguments which doesn't play nice with accessor
# method like 'ok'
sub _bool { shift->ok }

=head1 COPYRIGHT

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Test|HTTP::WebTest::Test>

=cut

1;
