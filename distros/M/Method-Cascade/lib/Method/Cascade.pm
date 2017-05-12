package Method::Cascade;

use strict;

our $VERSION = '0.101';

require Exporter;
use base 'Exporter';
our @EXPORT = qw(cascade);


sub cascade {
  my $wrapped = shift;
  return bless { w => $wrapped, }, 'Method::Cascade::Wrapper'; 
}


package Method::Cascade::Wrapper;

use strict;

our $AUTOLOAD;

sub AUTOLOAD {
  my $self = shift;

  my $method = $AUTOLOAD;
  $method =~ s/.*://;

  $self->{w}->$method(@_);

  return $self;
}

1;


__END__


=encoding utf-8

=head1 NAME

Method::Cascade - Use method chaining with any API

=head1 SYNOPSIS

    use Method::Cascade;
    use IO::Socket::INET;

    cascade(IO::Socket::INET->new('google.com:http'))
      ->timeout(5)
      ->setsockopt(SOL_SOCKET, SO_KEEPALIVE, pack("l", 1))
      ->print("GET / HTTP/1.0\r\n\r\n")
      ->recv(my $response, 4096);

    print $response;


=head1 BACKGROUND

Method chaining is a very intuitive and convenient way to make sequential method calls on the same object.

Unfortunately, not all APIs support method chaining. In order for an API to be chainable, every method must return C<$self>. However often there are good reasons for an API to not return C<$self>. For instance, it can be useful for setter methods to return the previous values.

Method cascading is a feature borrowed from Smalltalk. Its advantage is that any API can be used in a chained fashion, even if the designers didn't plan or intend for it to be chainable. You, the user of the API, can choose if you care about the return values and, if not, go ahead and cascade method calls.


=head1 DESCRIPTION

This module exports one function: C<cascade>. You should pass it the object that you would like to chain/cascade method calls on. It will return a wrapper object that forwards all method calls to the object you passed in. After forwarding, it returns the same wrapper object.

Because return values are ignored (the methods are in fact called in void context), method cascading is most useful when used with APIs that throw exceptions instead of returning error values. For instance, with L<DBI>, as long as C<RaiseError> is true and C<AutoCommit> is false you can safely do the following:

    cascade($dbh)->do("INSERT INTO admins (name) VALUES (?)", undef, $user)
                 ->do("DELETE FROM users WHERE name=?", undef, $user)
                 ->commit;



=head1 OTHER LANGUAGES

As mentioned, method cascading was first invented in Smalltalk.

L<Dart|https://www.dartlang.org/> is a web-language that has also added this feature. In Dart, the C<..> operator is a method cascading operator that returns the object the method was invoked on instead of the method call result. Here is a Dart example:

    myTokenTable
      ..add("aToken")
      ..add("anotherToken")
      // and on and on
      ..add("theUmpteenthToken");



=head1 SEE ALSO

L<The Method::Cascade github repo|https://github.com/hoytech/Method-Cascade>

L<Method Cascades in Dart|http://news.dartlang.org/2012/02/method-cascades-in-dart-posted-by-gilad.html>

L<Wikipedia entry on Method Cascading|https://en.wikipedia.org/wiki/Method_cascading>

L<IO::All> - I/O library that makes heavy use of chaining


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

Thanks to Richard Farr for helping me come up with this idea (during a conversation about C++ smart pointers).


=head1 COPYRIGHT & LICENSE

Copyright 2014 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut
