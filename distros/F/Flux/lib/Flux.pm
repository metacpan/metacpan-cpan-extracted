package Flux;
{
  $Flux::VERSION = '1.03';
}

# ABSTRACT: stream processing toolkit


1;

__END__

=pod

=head1 NAME

Flux - stream processing toolkit

=head1 VERSION

version 1.03

=head1 SYNOPSIS

  use Flux::Simple qw( array_in array_out mapper );

  my $in = array_in([ 5, 6, 7 ]);
  $in = $in | mapper { shift() * 2 };

  my @result;
  my $out = array_out(\@result);
  $out = mapper { shift() * 3 } | mapper { shift() . "x" } | $out;

  $out->write($in->read);
  $out->write($in->read);
  say for @result;

  # Output:
  # 30x
  # 36x

=head1 DESCRIPTION

Flux is the stream processing framework.

C<Flux::*> module namespace includes:

=over

=item *

groundwork for interoperable L<input|Flux::In> and L<output|Flux::Out> stream classes;

=item *

various implementations of input and output streams and storages: in-memory, file-based, db-based and others;

=item *

tools for making these streams work together nicely: L<mappers|Flux::Mapper>, L<data formatters|Flux::Format>, overloading syntax sugar, etc;

=item *

C<Flux::Catalog> module for the simple access to your collection of streams.

=back

Flux is a framework, but you can use lower-level parts of it without higher-level parts. For example, you can read and write files with L<Flux::File> without declaring it in the Flux catalog.

=head1 INTERFACE STABILITY NOTICE

This distribution and other C<Flux-*> distributions on CPAN are the result of the refactoring of our in-house framework.

It should be stable. We used it in production for years. But remember that:

1) I'm rewriting this in Moo/Moose, and there can be bugs.

2) I can refactor some API aspects in the process.

3) Not all of the code is uploaded yet.

=head1 SIMILAR MODULES

L<Message::Passing> is similar to Flux.

Unlike Flux, it's asynchronous (Flux can be made asynchronous by using L<Coro>, but its basic APIs are blocking).

L<IO::Pipeline> syntax is similar to Flux mappers.

I'm sure there're many others. Stream processing is reinvented often.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
