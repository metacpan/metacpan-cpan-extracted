package LibTmux::Async;
use v5.44;
our $VERSION = '0.003';

=head1 NAME

LibTmux::Async - Optional Future-based libtmux execution

=head1 DESCRIPTION

The async distribution depends on L<LibTmux>, L<IO::Async>, L<Future>,
L<IO::Async::Loop::Ppoll>, and L<IO::Ppoll>. Use L<LibTmux::Async::Server>
or L<LibTmux::Async::Transport> with an explicitly supplied Ppoll loop. Core
snapshot filtering remains local and synchronous. Async dependencies are not
required by the core or workspace distributions.

=head1 DOCUMENTATION

Read the L<Perl documentation|https://libtmux.org/en/perl/> and
L<async guide|https://libtmux.org/en/perl/latest/guides/async/> for setup,
concurrency, cancellation, and executor cleanup. The
L<API reference|https://libtmux.org/en/perl/latest/reference/libtmux-async-server/>
documents Future-returning operations. The
L<CPAN distribution|https://metacpan.org/dist/LibTmux-Async> includes runnable
consumer examples. The C<0.x> API can change between releases.

=cut
