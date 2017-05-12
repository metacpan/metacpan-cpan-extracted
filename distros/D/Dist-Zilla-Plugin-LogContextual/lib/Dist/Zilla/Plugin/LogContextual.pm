use strict;
use warnings;

package Dist::Zilla::Plugin::LogContextual;
BEGIN {
  $Dist::Zilla::Plugin::LogContextual::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Plugin::LogContextual::VERSION = '0.001000';
}

# ABSTRACT: Set up Log::Contextual for use with Dist::Zilla



use Moose;
use Log::Contextual::LogDispatchouli qw( set_logger log_debug log_fatal );

# WARNING: Removing this will cause log_debug { }
# to change from a function call to log_contextual's log_debug
# to the role method ->log_debug
# horribly breaking everything.
use namespace::autoclean;

# WARNING: Doesn't actually exclude anything
# See previous warning.
with 'Dist::Zilla::Role::Plugin' => { -excludes => [ 'log_debug', 'log_fatal', 'log', 'logger' ], };

sub bootstrap {
  my ($self) = @_;
  my $zilla  = $self->zilla;
  my $chrome = $zilla->chrome;
  if ( not $chrome ) {
    require Carp;
    Carp::croak(q[zilla->chrome returned undef. This is not ok]);
  }
  set_logger $chrome->logger;
  log_debug { [ q[If you are reading this message, %s works! -- %s], q[Log::Contextual], $self ] };
  return;
}

around plugin_from_config => sub {
  my ( $orig, $plugin_class, $name, $payload, $section ) = @_;

  my $instance = $plugin_class->$orig( $name, $payload, $section );

  $instance->bootstrap;

  return $instance;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::LogContextual - Set up Log::Contextual for use with Dist::Zilla

=head1 VERSION

version 0.001000

=head1 DESCRIPTION

L<< C<Log::Contextual>|Log::Contextual >> is a context driven Logging facility that aims to provide
cross-cutting log mechanisms.

However, the way it works means that if nobody starts an initial C<set_logger> call,
the logs may go nowhere. Or something.

I don't really understand it all fully, so I'm implementing what I know to learn it better.

=head1 TL;DR

One day C<dzil> may do this out of the box B<[citation needed]>

However, otherwise, if you have any plugins or tools or whatnot that want to use L<< C<Log::Contextual>|Log::Contextual >>, you'll need to load this C<plugin> first.

    [LogContextual]
    ; plugins with Log::Contextual in them should work nao

=head1 TIPS ON USING Log::Contextual

Using L<< C<Log::Contextual>|Log::Contextual >> with L<< C<Dist::Zilla>|Dist::Zilla >> is not entirely painless.

Notably, because the role C<Dist::Zilla::Role::Plugin> exports a few logging methods
with the same name as C<Log::Contextual>.

This has the unfortunate side effect of meaning the following wont work:

    use Moose;
    use Log::Contextual::LogDispatchouli  qw( log_debug );
    with 'Dist::Zilla::Role::Plugin';

    sub foo {
        log_debug {  }; # messes up and tries to call the log_debug method provided by $self->logger
    }

There's an easy way around this, but it doesn't seem obvious at first glance.

    use Moose;
    use Log::Contextual::LogDispatchouli qw( log_debug );
    use namespace::autoclean;
    with 'Dist::Zilla::Role::Plugin';

    sub foo {
        log_debug {  }; # Now works
    }

If you're confused, that is quite o.k.

But its sensible once you understand how.

Essentially, because the C<log_debug> C<sub> is removed at compile time, all calls to that become fixed, instead of flexible.

So here's how C<perl> processes the above code:

    # COMPILE PHASE
    use Moose;
    use Log::Contextual::LogDispatchouli qw( log_debug );
    use namespace::autoclean;

    sub foo {
        log_debug {  }; # BINDS this call to the imported sub
    }

    # END OF COMPILE PHASE
    # namespace::autoclean removes *log_debug forcing the bind
    # RUNTIME
    with  'Dist::Zilla::Role::Plugin'; # Cant change compile-time things.

Its not 100% ideal, but it works!.

=head1 CAVEATS

=over 4

=item * B<NO PREFIXES>

At this time, The nice pretty C<[Foo/Bar]> prefix from C<< $plugin->plugin_name >> is not supported.

We're not sure if it ever will, it probably will, but the code makes my head hurt at present.

Was better to release something, albeit feature incomplete, than to release nothing at all.

=item * B<< REQUIRES C<::LogDispatchouli> >> subclass

This seems in contrast to the Log::Contextual design principles, things invoking
loggers shouldn't care about how they're working, just they should work.

I'm I<Hoping> in a future release of C<::LogDispatchouli> that it can transparently
do the right thing when calling code simply does

    use Log::Contextual

So the C<Dispatchouli> is I<strictly> top level knowledge.

But I'll wait for updates on how that should work before I make it work that way =)

=back

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
