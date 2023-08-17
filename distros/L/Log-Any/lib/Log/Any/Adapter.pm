use 5.008001;
use strict;
use warnings;

package Log::Any::Adapter;

# ABSTRACT: Tell Log::Any where to send its logs
our $VERSION = '1.717';

use Log::Any;
our @CARP_NOT = ( 'Log::Any::Manager' );

sub import {
    my $pkg = shift;
    Log::Any->_manager->set(@_) if (@_);
}

sub set {
    my $pkg = shift;
    Log::Any->_manager->set(@_)
}

sub remove {
    my $pkg = shift;
    Log::Any->_manager->remove(@_)
}

sub get {
    my $pkg = shift;
    Log::Any->_manager->get_adapter(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter - Tell Log::Any where to send its logs

=head1 VERSION

version 1.717

=head1 SYNOPSIS

    # Log to a file, or stdout, or stderr for all categories
    #
    use Log::Any::Adapter ('File', '/path/to/file.log');
    use Log::Any::Adapter ('Stdout');
    use Log::Any::Adapter ('Stderr');

    # Use Log::Log4perl for all categories
    #
    Log::Log4perl::init('/etc/log4perl.conf');
    Log::Any::Adapter->set('Log4perl');

    # Use Log::Dispatch for Foo::Baz
    #
    use Log::Dispatch;
    my $log = Log::Dispatch->new(outputs => [[ ... ]]);
    Log::Any::Adapter->set( { category => 'Foo::Baz' },
        'Dispatch', dispatcher => $log );

    # Use Log::Dispatch::Config for Foo::Baz and its subcategories
    #
    use Log::Dispatch::Config;
    Log::Dispatch::Config->configure('/path/to/log.conf');
    Log::Any::Adapter->set(
        { category => qr/^Foo::Baz/ },
        'Dispatch', dispatcher => Log::Dispatch::Config->instance() );

    # Use your own adapter for all categories
    #
    Log::Any::Adapter->set('+My::Log::Any::Adapter', ...);

=head1 DESCRIPTION

Log::Any::Adapter connects log producers and log consumers.  Its methods
instantiate a logging adapter (a subclass of L<Log::Any::Adapter::Base>)
and route log messages from one or more categories to it.

=head1 ADAPTERS

In order to use a logging mechanism with C<Log::Any>, there needs to be an
adapter class for it. Typically this is named Log::Any::Adapter::I<something>.

=head2 Adapters in this distribution

Three basic adapters come with this distribution -- L<Log::Any::Adapter::File>,
L<Log::Any::Adapter::Stdout> and L<Log::Any::Adapter::Stderr>:

    use Log::Any::Adapter ('File', '/path/to/file.log');
    use Log::Any::Adapter ('Stdout');
    use Log::Any::Adapter ('Stderr');

    # or

    use Log::Any::Adapter;
    Log::Any::Adapter->set('File', '/path/to/file.log');
    Log::Any::Adapter->set('Stdout');
    Log::Any::Adapter->set('Stderr');

All of them simply output the message and newline to the specified destination;
a datestamp prefix is added in the C<File> case. For anything more complex
you'll want to use a more robust adapter from CPAN.

=head2 Adapters on CPAN

A sampling of adapters available on CPAN as of this writing:

=over

=item *

L<Log::Any::Adapter::Log4perl|Log::Any::Adapter::Log4perl>

=item *

L<Log::Any::Adapter::Dispatch|Log::Any::Adapter::Dispatch>

=item *

L<Log::Any::Adapter::FileHandle|Log::Any::Adapter::FileHandle>

=item *

L<Log::Any::Adapter::Syslog|Log::Any::Adapter::Syslog>

=back

You may find other adapters on CPAN by searching for "Log::Any::Adapter", or
create your own adapter. See
L<Log::Any::Adapter::Development|Log::Any::Adapter::Development> for more
information on the latter.

=head1 SETTING AND REMOVING ADAPTERS

=over

=item Log::Any::Adapter->set ([options, ]adapter_name, adapter_params...)

This method sets the adapter to use for all log categories, or for a particular
set of categories.

I<adapter_name> is the name of an adapter. It is automatically prepended with
"Log::Any::Adapter::". If instead you want to pass the full name of an adapter,
prefix it with a "+". e.g.

    # Use My::Adapter class
    Log::Any::Adapter->set('+My::Adapter', arg => $value);

I<adapter_params> are passed along to the adapter constructor. See the
documentation for the individual adapter classes for more information.

An optional hash of I<options> may be passed as the first argument. Options
are:

=over

=item category

A string containing a category name, or a regex (created with C<qr//>) matching
multiple categories.  If not specified, all categories will be routed to the
adapter.

=item lexically

A reference to a lexical variable. When the variable goes out of scope, the
adapter setting will be removed. e.g.

    {
        Log::Any::Adapter->set({lexically => \my $lex}, ...);

        # in effect here
        ...
    }
    # no longer in effect here

=back

C<set> returns an entry object, which can be passed to C<remove>.  If you
call C<set> repeatedly without calling C<remove> you will leak memory.  For
most programs that set an adapter once until the end of the program, this
shouldn't matter.

=item use Log::Any::Adapter (...)

If you pass arguments to C<use Log::Any::Adapter>, it calls C<<
Log::Any::Adapter->set >> with those arguments.

=item Log::Any::Adapter->remove (entry)

Remove an I<entry> previously returned by C<set>.

=back

=head1 USING MORE THAN ONE ADAPTER

C<Log::Any> maintains a stack of entries created via C<set>.  If you call
C<set> repeatedly, you will leak memory unless you do one of the
following:

=for :list * call C<remove> on the adapter returned from C<set> when you are done with
  it
* use the C<lexically> feature to set a guard variable that will clean it
  up when it goes out of scope

When getting a logger for a particular category, C<Log::Any> will work its way
down the stack and use the first matching entry.

Whenever the stack changes, any C<Log::Any> loggers that have previously been
created will automatically adjust to the new stack. For example:

    my $log = Log::Any->get_logger();
    $log->error("aiggh!");   # this goes nowhere
    ...
    {
        Log::Any::Adapter->set({ lexically => \my $lex }, 'Log4perl');
        $log->error("aiggh!");   # this goes to log4perl
        ...
    }
    $log->error("aiggh!");   # this goes nowhere again

=head1 BUILDING ON THE Log::Any BACKEND

=over

=item get

  my $adapter= Log::Any::Adapter->get($category);

The primary intended way to extend the producing-side of Log::Any is with a custom
L<Log::Any::Proxy> class.  However, for special logging scenarios you might also
just want access to the adapter for a given category.  The API of an adapter object
is described in L<Log::Any::Adapter::Development>.  Beware that adapter objects can
be "rewritten" on the fly, so any conditional behavior you write depending on the
capabilities of an adapter must be re-checked every time you access the adapter.

=back

=head1 SEE ALSO

L<Log::Any|Log::Any>

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
