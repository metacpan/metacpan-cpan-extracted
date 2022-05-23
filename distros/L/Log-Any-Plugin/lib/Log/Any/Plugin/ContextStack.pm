package Log::Any::Plugin::ContextStack;
# ABSTRACT: Stack of context items that get prepended to each log message
$Log::Any::Plugin::ContextStack::VERSION = '0.012';
use strict;
use warnings;
use Carp qw( confess );
use Log::Any;
use Scope::Guard qw( guard );

use Log::Any::Plugin::Util qw( get_old_method set_new_method );
use Log::Any::Adapter::Util qw( logging_methods );

my @context_stack;
my $stringify_context = \&_default_stringify_context;

sub install {
    my ($class, $adapter_class, %args) = @_;

    if ($args{stringify}) {
        $stringify_context = delete $args{stringify};
    }

    if (%args) {
        my $keys = join(', ', sort keys %args);
        confess("Unexpected arguments $keys");
    }

    # Create the $log->push method
    set_new_method($adapter_class, push_context => sub {
        my $self = shift;
        push(@context_stack, @_);
        return $self;
    });

    # Create the $log->pop method
    set_new_method($adapter_class, pop_context => sub {
        my $self = shift;
        return pop(@context_stack);
    });

    # Create the $log->context method
    set_new_method($adapter_class, push_scoped_context => sub {
        my $self = shift;
        return unless @_;
        my $count = scalar @_;
        push(@context_stack, @_);
        return guard { splice(@context_stack, -$count) };
    });

    # Augment the main $log->debug methods (not the aliases)
    for my $method_name ( logging_methods() ) {
        my $old_method = get_old_method($adapter_class, $method_name);
        set_new_method($adapter_class, $method_name, sub {
            my $self = shift;
            if (@context_stack) {
                unshift(@_, $stringify_context->(\@context_stack));
            }
            $old_method->($self, @_);
        });
    }
}

sub _default_stringify_context {
    my ($context) = @_;
    return '' unless @$context;
    return '[' . join(':', @$context) . ']';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Plugin::ContextStack - Stack of context items that get prepended to each log message

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    # Set up some kind of logger.
    use Log::Any::Adapter;
    Log::Any::Adapter->set('SomeAdapter');

    # Apply the Levels plugin to your logger
    use Log::Any::Plugin;
    Log::Any::Plugin->add('ContextStack');


    # In your modules
    use Log::Any qw($log);

    $log->push_context('foo');
    $log->info('Hello');  # [foo] Hello
    $log->push_context('bar');
    $log->info('Hello');  # [foo:bar] Hello
    $log->pop_context;
    $log->info('Hello');  # [foo] Hello

    {
        # Must capture return value from push_scoped_context
        my $ctx = $log->push_scoped_context('bar', 'baz');
        $log->info('Hello');  # [foo:bar:baz] Hello
        # $ctx goes out of scope, automatically popping baz and bar
    }
    $log->info('Hello');  # [foo] Hello

=head1 DESCRIPTION

It can be useful to include some bits of context with your log messages. This
plugin allows you to push and pop context on a stack, and have it automatically
prepended to each log message.

=head1 CONFIGURATION

Configuration values are passed as key-value pairs when adding the plugin:
    Log::Any::Plugin->add('ContextStack', stringify => \&my_stringifier);

=head2 stringify => sub { ... }

Stringify function to turn the context stack into a string. Receives a single
arrayref argument, and should return a single string. If there are no items on
the context stack, this function won't be called. You don't need to handle the
empty array case.

Default stringifier renders C<['foo', 'bar']> as C<"[foo:bar]">.

=head1 METHODS

There are no methods in this package which should be directly called by the
user. Use Log::Any::Plugin->add() instead.

=head2 install

Private method called by Log::Any::Plugin->add()

=head1 ADAPTER METHODS

The following methods are injected into the adapter class.

=head2 $log->push_context(ARRAY)

Push one or more items onto the context stack.

=head2 $log->pop_context()

Pop a single item off the context stack.

=head2 my $ctx = $log->push_scoped_context(ARRAY)

Push one or more items onto the context stack, and return a L<Scope::Guard>
object that pops the same amount when it goes out of scope.

=head1 AUTHOR

Stephen Thirlwall <sdt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2019, 2017, 2015, 2014 by Stephen Thirlwall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
