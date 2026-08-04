package JMAP::Tester::Manual 0.112;
# ABSTRACT: how to use JMAP::Tester

#pod =head1 OVERVIEW
#pod
#pod JMAP::Tester is a simple JMAP client designed for testing, although it can
#pod certainly be used outside of tests.  It's meant to be easy to use without a lot
#pod of training, but it's not so simple that you don't need a little bit of
#pod up-front knowledge.  This document is meant to give a high-level overview of
#pod how to use it, with links to more detailed information as needed.  Quite
#pod possibly, you won't need to click even one of them.
#pod
#pod =head2 Return types and asynchrony
#pod
#pod When using a JMAP::Tester, you'll need to know whether it was configured to run
#pod synchronously or asynchronously.  You can check the result of calling
#pod C<< L<JMAP::Tester/should_return_futures> >>, but really you want to know this
#pod while writing your code, so just make sure you pay attention to how the object
#pod was constructed.  If your tester returns futures, then its async methods return
#pod Future objects and can be called with C<await>.  Otherwise, they will block and
#pod return whatever the future would have resolved to.
#pod
#pod The default behavior is to I<not> return futures, as most test suites are
#pod synchronous.
#pod
#pod Methods generally return an object that does the
#pod L<HTTPResult|JMAP::Tester::Role::HTTPResult> role, which has just a few
#pod important methods:
#pod
#pod =for :list
#pod * C<is_success>, which returns true for a successful HTTP response and false otherwise
#pod * C<http_response>, which returns the L<HTTP::Response> object for the result
#pod * C<response_payload>, which returns the HTTP response as a string
#pod
#pod =head2 Authentication and session
#pod
#pod JMAP does not specify authentication, so authenticating your tester is up to
#pod you.  Most often, you do that by setting a default header on the tester's user
#pod agent, like this:
#pod
#pod   my $tester = JMAP::Tester->new( ... );
#pod   $tester->ua->set_default_header(Authorization => 'Bearer 1234');
#pod
#pod This is a pretty broad brush, but for testing your local test system, generally
#pod fine.
#pod
#pod The other thing associated with authentication is your JMAP session, which
#pod describes your account's capabilities and HTTP endpoints.  The session object
#pod is generally represented as a L<JMAP::Tester::Result::Auth> object, which has
#pod one useful method: C<client_session>, which returns the decoded JSON structure
#pod of the session.
#pod
#pod There are a few methods for dealing with the session:
#pod
#pod =for :list
#pod * C<< L<JMAP::Tester/get_client_session> >>, an async method that fetches and returns the session object; on success, it returns an Auth object
#pod * C<< L<JMAP::Tester/update_client_session> >>, an async method that gets the client session, uses it to reconfigure the tester (if necessary), and returns the Auth object
#pod
#pod =head2 API requests
#pod
#pod The most common thing you'll do with a tester is probably make API requests.
#pod Those are the ones defined in L<RFC 8620
#pod §3.1|https://datatracker.ietf.org/doc/html/rfc8620#section-3.1> -- the ones
#pod with C<methodCalls>, where you do most of the work of JMAP.
#pod
#pod You call it like this:
#pod
#pod   my $res = $tester->request({
#pod     using       => [ 'urn:ietf:params:jmap:core', 'urn:ietf:params:jmap:mail' ],
#pod     methodCalls => [ [ 'Some/method', { ... }, 'a' ], ... ],
#pod   });
#pod
#pod If you trust the client's C<default_using>, provided during creation, you can
#pod skip the outer hashref and just provide an arrayref, which will be used as the
#pod C<methodCalls> value.  Each entry in that arrayref is itself an arrayref that
#pod becomes the C<Invocation> (in RFC 8620 terms) that's passed to the remote API.
#pod If you don't include a method call id, the third element in the array, one will
#pod be generated for you.
#pod
#pod C<request> is an async method, and on success returns a
#pod L<Response|JMAP::Tester::Response> object.  Since a I<lot> of testing your JMAP
#pod server involves inspecting API responses, it's important to know the interface!
#pod First, some jargon:  a I<sentence> is one entry in the C<methodResponses>
#pod array; a I<paragraph> is a group of sequential sentences all sharing the same
#pod method call id.  The first element in a sentence is its I<name>.  Almost
#pod always, you'll be working with the sentences in a response, usually looked up
#pod by name.
#pod
#pod Here are the most important methods on a Response:
#pod
#pod =for :list
#pod * C<sentence($n)> returns the I<n>th sentence in the response (or dies if out of bounds)
#pod * C<sentence_named($name)> returns the sentence with this name (or dies if there isn't exactly one with that name)
#pod * C<single_sentence($name)> dies unless there is exactly one sentence in the response; if C<$name> is given, the method dies unless the sentence has that name; if it doesn't die, it returns that sentence.
#pod * C<as_pairs> and C<as_triples> return arrayrefs where each element is a 2- or 3-element arrayref of the name, arguments, and (maybe) client id of each sentence -- in other words, a plain structure representing the method response
#pod * C<as_stripped_pairs> and C<as_stripped_triples> return the same, but with L<JSON::Typist> data tripped from the arguments
#pod
#pod L<Sentence|JMAP::Tester::Response::Sentence> objects have these useful methods:
#pod
#pod =for :list
#pod * C<name> returns the sentence name
#pod * C<arguments> returns the sentence arguments
#pod * C<client_id> returns the method call id
#pod * C<as_pair>, C<as_triple>, C<as_stripped_pair>, and C<as_stripped_triple> behave like the similarly-named methods on a Response, but just return the arrayref representing this sentence
#pod * C<as_set> returns a new L<Set|JMAP::Tester::Response::Sentence::Set> object,
#pod with extra methods for testing the response to C</set>-style methods
#pod
#pod A "Set" sentence has all the methods of a normal sentence as well as:
#pod
#pod =for :list
#pod * C<new_state> and C<old_state>: return the new and old state
#pod * C<created>: returns the C<created> argument, or an empty hashref if null
#pod * C<created_id($creation_id)>: returns the C<id> for the object created for that creation id
#pod * C<updated>: returns the C<updated> argument, or an empty hashref if null
#pod * C<created_ids>, C<updated_ids>, C<destroyed_ids>: return the ids of objects created, updated, or destroyed
#pod * C<create_errors>, C<update_errors>, C<destroy_errors>: return the errors with their respective operations, or an empty hashref if none
#pod * C<not_created_ids>, C<not_updated_ids>, C<not_destroyed_ids>: return the ids of objects not created, not updated, or not destroyed; in other words, the keys of the hashrefs returned by the error methods above
#pod
#pod There are also a few useful assertion-making methods to know.  These will throw
#pod aborts (L<see below|/Diagnostics and logging>) if the condition they assert
#pod doesn't hold true:
#pod
#pod =for :list
#pod * C<< $result->assert_successful >>: the result must be a success (C<is_success> is true)
#pod * C<< $result->assert_successful_set($name) >>: the result must be an API request result with a sentence named C<$name>, which must be a C</set> method, and it must be reporting zero errors (like C<notCreated> etc.)
#pod * C<< $result->assert_single_successful_set($name) >>: just like the above, but there must be only one sentence in the response; C<$name> can be omitted to allow any C</set>
#pod * C<< $set->assert_no_errors >>: on a Set sentence, this asserts that there were no errors in any of its operations
#pod
#pod =head2 Uploads and downloads
#pod
#pod Testing blobs might require that you perform JMAP upload or download requests.
#pod For these, the C<< L<JMAP::Tester/upload> >> and C<< L<JMAP::Tester/download>
#pod >> methods exist.
#pod
#pod C<upload> takes as its argument a hashref of upload properties and on success
#pod returns an L<Upload|JMAP::Tester::Result::Upload> object.  The argument hashref
#pod must contain:
#pod
#pod   accountId - the account for which we're uploading (no default)
#pod   type      - the content-type we want to provide to the server
#pod   blob      - the data to upload. Must be a reference to a string
#pod
#pod C<download> takes as its argument a hashref of download properties and on
#pod success returns a L<Download|JMAP::Tester::Result::Download> object.  The
#pod argument hashref must contain:
#pod
#pod   blobId    - the blob to download (no default)
#pod   accountId - the account for which we're downloading (no default)
#pod   type      - the content-type we want the server to provide back (no default)
#pod   name      - the name we want the server to provide back (default: "download")
#pod
#pod =head2 Other HTTP requests
#pod
#pod Sometimes, you may need to make a custom HTTP request with the same underlying
#pod user agent as your tester uses.  This might be to interact with a custom
#pod authentication mechanism, to access custom endpoints, or just to make very,
#pod very specifically crafted requests.  For this reason, C<http_request> exists.
#pod It's an async method that takes an L<HTTP::Request> object as its argument and
#pod returns an L<HTTP::Response>.  Remember when you make this call that the
#pod default headers you may have set up for auth will be applied!
#pod
#pod =head2 Diagnostics and logging
#pod
#pod Many of JMAP::Tester's failures are L<Test::Abortable> exceptions ("aborts")
#pod that can terminate subtests without terminating the whole test program.  They
#pod provide useful diagnostics on failure, so learning and using the JMAP::Tester
#pod methods that die on unexpected results can save you time later.
#pod
#pod Further, JMAP::Tester has a generic request logging system.  It's subject to
#pod significant change, but the important thing to know is that if you set the
#pod C<JMAP_TESTER_LOGGER> environment variable to C<HTTP>, you'll end up with a
#pod file in the current working directory with a name like F<jmap-tester-….log>
#pod that contains the requests and responses made.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Manual - how to use JMAP::Tester

=head1 VERSION

version 0.112

=head1 OVERVIEW

JMAP::Tester is a simple JMAP client designed for testing, although it can
certainly be used outside of tests.  It's meant to be easy to use without a lot
of training, but it's not so simple that you don't need a little bit of
up-front knowledge.  This document is meant to give a high-level overview of
how to use it, with links to more detailed information as needed.  Quite
possibly, you won't need to click even one of them.

=head2 Return types and asynchrony

When using a JMAP::Tester, you'll need to know whether it was configured to run
synchronously or asynchronously.  You can check the result of calling
C<< L<JMAP::Tester/should_return_futures> >>, but really you want to know this
while writing your code, so just make sure you pay attention to how the object
was constructed.  If your tester returns futures, then its async methods return
Future objects and can be called with C<await>.  Otherwise, they will block and
return whatever the future would have resolved to.

The default behavior is to I<not> return futures, as most test suites are
synchronous.

Methods generally return an object that does the
L<HTTPResult|JMAP::Tester::Role::HTTPResult> role, which has just a few
important methods:

=over 4

=item *

C<is_success>, which returns true for a successful HTTP response and false otherwise

=item *

C<http_response>, which returns the L<HTTP::Response> object for the result

=item *

C<response_payload>, which returns the HTTP response as a string

=back

=head2 Authentication and session

JMAP does not specify authentication, so authenticating your tester is up to
you.  Most often, you do that by setting a default header on the tester's user
agent, like this:

  my $tester = JMAP::Tester->new( ... );
  $tester->ua->set_default_header(Authorization => 'Bearer 1234');

This is a pretty broad brush, but for testing your local test system, generally
fine.

The other thing associated with authentication is your JMAP session, which
describes your account's capabilities and HTTP endpoints.  The session object
is generally represented as a L<JMAP::Tester::Result::Auth> object, which has
one useful method: C<client_session>, which returns the decoded JSON structure
of the session.

There are a few methods for dealing with the session:

=over 4

=item *

C<< L<JMAP::Tester/get_client_session> >>, an async method that fetches and returns the session object; on success, it returns an Auth object

=item *

C<< L<JMAP::Tester/update_client_session> >>, an async method that gets the client session, uses it to reconfigure the tester (if necessary), and returns the Auth object

=back

=head2 API requests

The most common thing you'll do with a tester is probably make API requests.
Those are the ones defined in L<RFC 8620
§3.1|https://datatracker.ietf.org/doc/html/rfc8620#section-3.1> -- the ones
with C<methodCalls>, where you do most of the work of JMAP.

You call it like this:

  my $res = $tester->request({
    using       => [ 'urn:ietf:params:jmap:core', 'urn:ietf:params:jmap:mail' ],
    methodCalls => [ [ 'Some/method', { ... }, 'a' ], ... ],
  });

If you trust the client's C<default_using>, provided during creation, you can
skip the outer hashref and just provide an arrayref, which will be used as the
C<methodCalls> value.  Each entry in that arrayref is itself an arrayref that
becomes the C<Invocation> (in RFC 8620 terms) that's passed to the remote API.
If you don't include a method call id, the third element in the array, one will
be generated for you.

C<request> is an async method, and on success returns a
L<Response|JMAP::Tester::Response> object.  Since a I<lot> of testing your JMAP
server involves inspecting API responses, it's important to know the interface!
First, some jargon:  a I<sentence> is one entry in the C<methodResponses>
array; a I<paragraph> is a group of sequential sentences all sharing the same
method call id.  The first element in a sentence is its I<name>.  Almost
always, you'll be working with the sentences in a response, usually looked up
by name.

Here are the most important methods on a Response:

=over 4

=item *

C<sentence($n)> returns the I<n>th sentence in the response (or dies if out of bounds)

=item *

C<sentence_named($name)> returns the sentence with this name (or dies if there isn't exactly one with that name)

=item *

C<single_sentence($name)> dies unless there is exactly one sentence in the response; if C<$name> is given, the method dies unless the sentence has that name; if it doesn't die, it returns that sentence.

=item *

C<as_pairs> and C<as_triples> return arrayrefs where each element is a 2- or 3-element arrayref of the name, arguments, and (maybe) client id of each sentence -- in other words, a plain structure representing the method response

=item *

C<as_stripped_pairs> and C<as_stripped_triples> return the same, but with L<JSON::Typist> data tripped from the arguments

=back

L<Sentence|JMAP::Tester::Response::Sentence> objects have these useful methods:

=over 4

=item *

C<name> returns the sentence name

=item *

C<arguments> returns the sentence arguments

=item *

C<client_id> returns the method call id

=item *

C<as_pair>, C<as_triple>, C<as_stripped_pair>, and C<as_stripped_triple> behave like the similarly-named methods on a Response, but just return the arrayref representing this sentence

=item *

C<as_set> returns a new L<Set|JMAP::Tester::Response::Sentence::Set> object,

with extra methods for testing the response to C</set>-style methods

=back

A "Set" sentence has all the methods of a normal sentence as well as:

=over 4

=item *

C<new_state> and C<old_state>: return the new and old state

=item *

C<created>: returns the C<created> argument, or an empty hashref if null

=item *

C<created_id($creation_id)>: returns the C<id> for the object created for that creation id

=item *

C<updated>: returns the C<updated> argument, or an empty hashref if null

=item *

C<created_ids>, C<updated_ids>, C<destroyed_ids>: return the ids of objects created, updated, or destroyed

=item *

C<create_errors>, C<update_errors>, C<destroy_errors>: return the errors with their respective operations, or an empty hashref if none

=item *

C<not_created_ids>, C<not_updated_ids>, C<not_destroyed_ids>: return the ids of objects not created, not updated, or not destroyed; in other words, the keys of the hashrefs returned by the error methods above

=back

There are also a few useful assertion-making methods to know.  These will throw
aborts (L<see below|/Diagnostics and logging>) if the condition they assert
doesn't hold true:

=over 4

=item *

C<< $result->assert_successful >>: the result must be a success (C<is_success> is true)

=item *

C<< $result->assert_successful_set($name) >>: the result must be an API request result with a sentence named C<$name>, which must be a C</set> method, and it must be reporting zero errors (like C<notCreated> etc.)

=item *

C<< $result->assert_single_successful_set($name) >>: just like the above, but there must be only one sentence in the response; C<$name> can be omitted to allow any C</set>

=item *

C<< $set->assert_no_errors >>: on a Set sentence, this asserts that there were no errors in any of its operations

=back

=head2 Uploads and downloads

Testing blobs might require that you perform JMAP upload or download requests.
For these, the C<< L<JMAP::Tester/upload> >> and C<< L<JMAP::Tester/download>
>> methods exist.

C<upload> takes as its argument a hashref of upload properties and on success
returns an L<Upload|JMAP::Tester::Result::Upload> object.  The argument hashref
must contain:

  accountId - the account for which we're uploading (no default)
  type      - the content-type we want to provide to the server
  blob      - the data to upload. Must be a reference to a string

C<download> takes as its argument a hashref of download properties and on
success returns a L<Download|JMAP::Tester::Result::Download> object.  The
argument hashref must contain:

  blobId    - the blob to download (no default)
  accountId - the account for which we're downloading (no default)
  type      - the content-type we want the server to provide back (no default)
  name      - the name we want the server to provide back (default: "download")

=head2 Other HTTP requests

Sometimes, you may need to make a custom HTTP request with the same underlying
user agent as your tester uses.  This might be to interact with a custom
authentication mechanism, to access custom endpoints, or just to make very,
very specifically crafted requests.  For this reason, C<http_request> exists.
It's an async method that takes an L<HTTP::Request> object as its argument and
returns an L<HTTP::Response>.  Remember when you make this call that the
default headers you may have set up for auth will be applied!

=head2 Diagnostics and logging

Many of JMAP::Tester's failures are L<Test::Abortable> exceptions ("aborts")
that can terminate subtests without terminating the whole test program.  They
provide useful diagnostics on failure, so learning and using the JMAP::Tester
methods that die on unexpected results can save you time later.

Further, JMAP::Tester has a generic request logging system.  It's subject to
significant change, but the important thing to know is that if you set the
C<JMAP_TESTER_LOGGER> environment variable to C<HTTP>, you'll end up with a
file in the current working directory with a name like F<jmap-tester-….log>
that contains the requests and responses made.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
