use strict;
use warnings;
use utf8;

package Log::Contextual::LogDispatchouli;
BEGIN {
  $Log::Contextual::LogDispatchouli::AUTHORITY = 'cpan:KENTNL';
}
{
  $Log::Contextual::LogDispatchouli::VERSION = '0.001000';
}

# ABSTRACT: A Log::Dispatchouli specific wrapper for Log::Contextual


use Moo;

extends 'Log::Contextual';

## no critic (ProhibitPackageVars, Capitalization)
our $Router_Instance;


sub router {
  return (
    $Router_Instance ||= do {
      require Log::Contextual::Router::LogDispatchouli;
      Log::Contextual::Router::LogDispatchouli->new;
      }
  );
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Contextual::LogDispatchouli - A Log::Dispatchouli specific wrapper for Log::Contextual

=head1 VERSION

version 0.001000

=head1 DESCRIPTION

L<< C<Log::Dispatchouli>|Log::Dispatchouli >> doesn't need much to get it to work with L<< C<Log::Contextual>|Log::Contextual >> however,
it has one teeny annoying quirk in that its stack traces are always off by one.

Which has two primary side effects:

=over 4

=item 1. Under L<< C<Log::Contextual>|Log::Contextual >>, it shows errors coming from C<LC>, not C<LC>'s caller ( Useless )

=item 2. Under L<< C<Moose>|Moose >>, if you use a delegation, C<LD> will report problems coming from the delegate ( Useless )

=back

So this module exists to solve #2, and it has to solve #1 in the process.

=head1 METHODS

=head2 C<router>

This is the only difference this module has from L<< C<Log::Contextual>|Log::Contextual >>,
and its that it returns a L<< C<Log::Contextual::Router::LogDispatchouli>|Log::Contextual::Router::LogDispatchouli >> instead of the default router.

=head1 USAGE

    use Log::Contextual::LogDispatchouli qw( set_logger );

    set_logger $ld;

Other than that, this module is just a wrapper around the rest of L<< C<Log::Contextual>|Log::Contextual >>

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
