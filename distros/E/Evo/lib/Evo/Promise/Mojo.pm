package Evo::Promise::Mojo;
use Evo '-Class; -Export *';

BEGIN {
  eval { require Mojo::IOLoop; 1 } or die "Install Mojolicious to use this module";
}

with '-Promise::Role';

sub postpone ($me, $sub) {
  Mojo::IOLoop->next_tick($sub);
}

foreach my $fn (qw(promise deferred resolve reject race all)) {
  export_code $fn , sub {
    __PACKAGE__->$fn(@_);
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Promise::Mojo

=head1 VERSION

version 0.0405

=head1 DESCRIPTION

Promises/A+ for L<Mojo::IOLoop> - install L<Mojolicious> to use this module

See L<Mojo::Pua> for more real-world examples.

=head1 SYNOSIS

  use Evo '-Promise::Mojo *';

  sub load_later($url) {
    my $d = deferred();
    Mojo::IOLoop->timer(1 => sub { $d->resolve("HELLO: $url") });
    $d->promise;
  }

  load_later('http://alexbyk.com')->then(sub($v) { say $v });

  Mojo::IOLoop->start;

=head1 FUNCTIONS

=head2 promise

  promise(
    sub ($resolve, $reject) {
      Mojo::IOLoop->timer(1 => sub { $resolve->('HELLO') });
    }
  )->then(sub($v) { say "Fulfilled: $v"; });

Return ES6 syntax promise. The first argument should be a function. Resolve and reject handlers(functions) will be passed to it  

Only the first invocation of either C<$resolve> or C<$reject> matters. The second one will be ignored.

=head2 deferred

Create a promise and attach it to the deferred object. Deferred object is a handler for the promise.

  my $d = deferred();
  Mojo::IOLoop->timer(1 => sub { $d->resolve('HELLO') });
  $d->promise->then(sub($v) { say "Fulfilled: $v"; });

=head2 resolve

  my $p = resolve('hello');

Generate a resolved promise with a given value. If value is a thenable object or another promise, the resulting promise will follow it. Otherwise it will be fulfilled with that value

=head2 reject

  my $p = reject('hello');

Generate a rejected promise with a reason. If the reason is a promise, resulting promise will NOT follow it.

=head2 all

Creates a promise that will be resolved only when all promise are resolved. The result will be an array containing resolved value with the same order, as passed to this function. If one of the collected promise become rejected, that promise will be rejected to with that reason.

  my ($d1, $d2) = (deferred, deferred);
  Mojo::IOLoop->timer( 1,   sub { $d1->resolve('first') });
  Mojo::IOLoop->timer( 0.1, sub { $d2->resolve('second') });

  all($d1->promise, $d2->promise)->then(sub($v) { say join ';', $v->@* });

Will print C<first;second>

L</"spread"> will help a lot

=head2 race

Return a promise that will be resolved or rejected with the value/reason of the first resolved/rejected promise

  my ($d1, $d2) = (deferred, deferred);
  race($d1->promise, $d1->promise)->then(sub($v) { say $v });

  Mojo::IOLoop->timer(1 => sub { $d1->resolve('1') });
  Mojo::IOLoop->timer(2 => sub { $d2->resolve('2') });

Will print C<1>

=head1 METHODS

=head2 then

Make a chain and return a promise. The 2 args form C<onResolve, onReject> isn't recommended. Better use L</"catch">

  $promise->then(sub($v) { say "Resolved $v" })->then(sub($v) { say "Step 2 $v" });
  $promise->then(sub($v) { say "Resolved $v" }, sub($r) { say "Rejected $r" });

=head2 catch

The same as C<then(undef, sub($r) {})>, recommended form

  $d->promise->then(sub { })->catch(sub($r) { say "Rejected with $r" });

=head2 spread

If you expect promise gets fulfilled with the array reference, you can dereference it and pass to function

  all(first => $d1->promise, second => $d2->promise)
    ->spread(sub(%res) { say $_ , ': ', $res{$_} for keys %res });

=head2 finally

Chain promise with a handler, that gets called with no argument when the parent promise is settled(fulfilled or rejected). When that handler returns a promise as result, the next promise gets postponed untill that promise will be settled. Returned value is ignored. If that handler causes an exception or returns rejected promise (or promise that will eventually gets rejected), the chain would be rejected.

A shorter. Causes no effect on the chain unless rejection happens

  resolve('VAL')->finally(sub() {'IGNORED'})->then(sub($v) { say $v});

Usefull for closing connections etc or making any internal stuff without affecting a chain

=head1 SEE ALSO

=over

=item * More info about promise, race, all etc.: L<https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Promise>

=item * L<Mojo::Pua> promises based http user agent

=item * L<Evo::Promise::Role> a base role to bring Promises/A+ to any event loop

=item * L<Evo::Promise::AE> the similar module for L<AE>

=back

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
