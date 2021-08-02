use 5.008001;
use strict;
use warnings;

package Log::Any::Test;

# ABSTRACT: Test what you're logging with Log::Any
our $VERSION = '1.710';

no warnings 'once';
$Log::Any::OverrideDefaultAdapterClass = 'Log::Any::Adapter::Test';
$Log::Any::OverrideDefaultProxyClass   = 'Log::Any::Proxy::Test';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Test - Test what you're logging with Log::Any

=head1 VERSION

version 1.710

=head1 SYNOPSIS

    use Test::More;
    use Log::Any::Test;    # should appear before 'use Log::Any'!
    use Log::Any qw($log);

    # ...
    # call something that logs using Log::Any
    # ...

    # now test to make sure you logged the right things

    $log->contains_ok(qr/good log message/, "good message was logged");
    $log->does_not_contain_ok(qr/unexpected log message/, "unexpected message was not logged");
    $log->empty_ok("no more logs");

    # or

    my $msgs = $log->msgs;
    cmp_deeply($msgs, [{message => 'msg1', level => 'debug'}, ...]);

=head1 DESCRIPTION

C<Log::Any::Test> is a simple module that allows you to test what has been
logged with Log::Any. Most of its API and implementation have been taken from
L<Log::Any::Dispatch|Log::Any::Dispatch>.

Using C<Log::Any::Test> signals C<Log::Any> to send all subsequent log
messages to a single global in-memory buffer and to make the log proxy
provide a number of testing functions.  To use it, load C<Log::Any::Test>
before anything that loads C<Log::Any>.  To actually use the test methods,
you need to load C<Log::Any> and get a log object from it, as shown in the
L</SYNOPSIS>.

=head1 METHODS

The test_name is optional in the *_ok methods; a reasonable default will be
provided.

=over

=item msgs ()

Returns the current contents of the global log buffer as an array reference,
where each element is a hash containing a I<category>, I<level>, and I<message>
key.  e.g.

  {
    category => 'Foo',
    level => 'error',
    message => 'this is an error'
  },
  {
    category => 'Bar::Baz',
    level => 'debug',
    message => 'this is a debug'
  }

=item contains_ok ($regex[, $test_name])

Tests that a message in the log buffer matches I<$regex>. On success, the
message is I<removed> from the log buffer (but any other matches are left
untouched).

=item does_not_contain_ok ($regex[, $test_name])

Tests that no message in the log buffer matches I<$regex>.

=item category_contains_ok ($category, $regex[, $test_name])

Tests that a message in the log buffer from a specific category matches
I<$regex>. On success, the message is I<removed> from the log buffer (but any
other matches are left untouched).

=item category_does_not_contain_ok ($category, $regex[, $test_name])

Tests that no message from a specific category in the log buffer matches
I<$regex>.

=item empty_ok ([$test_name])

Tests that there is no log buffer left. On failure, the log buffer is cleared
to limit further cascading failures.

=item contains_only_ok ($regex[, $test_name])

Tests that there is a single message in the log buffer and it matches
I<$regex>. On success, the message is removed.

=item clear ()

Clears the log buffer.

=back

=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Test::Log::Dispatch|Test::Log::Dispatch>

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
