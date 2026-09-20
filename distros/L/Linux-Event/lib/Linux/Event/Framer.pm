package Linux::Event::Framer;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use Carp qw(croak);
use Linux::Event::_ByteStream::Descriptor ();

sub _byte_stream_base ($target) {
    return 'Linux::Event::_ByteStream'
        if $target->isa('Linux::Event::_ByteStream');
    return undef;
}

sub import ($class, $keyword = undef, @args) {
    return if !defined($keyword) && !@args;

    my $target = caller;
    croak "use $class requires a built-in framer name"
        if !defined($keyword) || $keyword eq '';
    croak "invalid framer name '$keyword'"
        if $keyword !~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;

    my $base = _byte_stream_base($target);
    croak "$target must be a Linux::Event byte-stream subclass before declaring a framer"
        if !defined $base;

    my $package = "${class}::${keyword}";
    (my $file = "$package.pm") =~ s{::}{/}g;
    eval { require $file; 1 } or do {
        my $error = $@ || "unable to load $package";
        $error =~ s/\s+\z//;
        croak "cannot declare framer '$keyword': $error";
    };

    my $builder = $package->can('_build_definition')
        or croak "$package is not a Linux::Event built-in framer";
    my $definition = $builder->($package, @args);
    croak "$package returned an invalid framer definition"
        if ref($definition) ne 'HASH'
        || ref($definition->{native}) ne 'HASH'
        || ref($definition->{frame}) ne 'CODE';

    $definition->{package} = $package;
    Linux::Event::_ByteStream::Descriptor::declare_framer(
        $base, $target, $definition,
    );
    return;
}

sub declare_native_consumer ($class, $target, $definition) {
    croak 'declare_native_consumer(): must be called as a class method'
        if ref $class;
    croak 'declare_native_consumer(): target class is required'
        if !defined($target) || ref($target) || $target eq '';

    my $base = _byte_stream_base($target);
    croak "$target must be a Linux::Event byte-stream subclass before declaring a native consumer"
        if !defined $base;

    Linux::Event::_ByteStream::Descriptor::declare_consumer(
        $base, $target, $definition,
    );
    return;
}

1;

__END__

=head1 NAME

Linux::Event::Framer - native framing for ordered-byte I/O

=head1 SYNOPSIS

  use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

  package LineSocket;
  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  package main;
  socketpair(my $socket, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
      or die "socketpair: $!";

  my $stream = LineSocket->new(
      fh => $socket,
      on_message => sub ($stream, $message) {
          $stream->send($message);
      },
  );

=head1 DESCRIPTION

C<Linux::Event::Framer> declares native framing policy for an ordered-byte
Linux::Event subclass. Pipes, TTYs, and C<SOCK_STREAM> connections share the
same framing engine. The declaration is resolved once per concrete subclass;
there is no per-connection framer object.

Framing is class-level wire policy. Application delivery is independent of how
that policy is declared: C<on_message> or C<on_messages> may be a class method
or a constructor-supplied coderef. A constructor callback does not make the
framer per-instance; it only selects that object's effective application CV.

=head1 BUILT-IN FRAMERS

Supported declarations include C<Delimiter>, C<Fixed>, C<LengthPrefix>,
C<U32BE>, C<Netstring>, C<Varint>, and C<DecimalLength>. Each framer accepts
its own framing options; see F<docs/FRAMING.md> and the corresponding framer
module POD.

A readable class without a framer needs an effective C<on_data> callback. A
framed class normally needs an effective C<on_message> callback, or
C<on_messages> when explicit message batching is enabled. In each case the
callback may come from a class method or from the object's constructor.

Constructor callbacks are validated during construction and override a
same-named method for that object. Input dispatch then invokes one cached
effective CV directly from native ordered-byte state; it does not choose
between method and closure for every message. The framer itself remains
immutable class policy.

=head1 NATIVE CONSUMERS

External XS extensions may consume complete framed messages without routing
them through a Perl C<on_message> callback:

  Linux::Event::Framer->declare_native_consumer(
      'My::FramedConnection',
      {
          provider           => $provider_lifetime_token,
          abi_version        => $abi_version,
          operations_address => $native_table_address,
      },
  );

A native consumer may receive complete framed-message SVs, or an unframed
provider may request the raw-input ABI and receive a borrowed contiguous native
byte window before those bytes are converted to a Perl SV. Raw-input providers
report the number of leading bytes consumed; Linux::Event keeps the unconsumed
tail in native ordered-byte storage.

C<transition_to()> can retain one provider when source and target share the same
operations table, or replace one native consumer provider with another while
preserving unread native input. Source flush/lifetime obligations are settled
before the retiring context is destroyed and the retained tail is re-driven
through the target provider. Adding or removing native-consumer mode during a
live transition remains invalid.

This is an extension-author boundary for high-performance protocol and
coroutine/awaitable integrations. It is independent of the public Perl class
names and must not depend on retired implementation packages.

See F<docs/ORDERED-BYTE-CONSUMER-ABI.md>.

=head1 SEE ALSO

F<docs/FRAMING.md>, F<docs/CHOOSING-A-FRAMER.md>,
F<docs/FIRST-CLASS-STREAM-CALLBACKS.md>.

=cut
