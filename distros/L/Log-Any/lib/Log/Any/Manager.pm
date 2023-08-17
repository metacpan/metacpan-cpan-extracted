use 5.008001;
use strict;
use warnings;

package Log::Any::Manager;

our $VERSION = '1.717';

sub new {
    my $class = shift;
    my $self  = {
        # The stack of adapter entries
        entries         => [],
        # A cache of keys with category names and values of a hashref
        # with stack entries (from the entries attribute) and adapters
        category_cache  => {},
        # The adapter to use if no other adapter is appropriate
        default_adapter => {},
        # The context hashref that is passed to all proxies
        context => {},
    };
    bless $self, $class;

    return $self;
}

sub has_consumer {
    my ( $self ) = @_;
    return !!( @{ $self->{entries} } || keys %{ $self->{default_adapter} } || $ENV{LOG_ANY_DEFAULT_ADAPTER} );
}

sub get_adapter {
    my ( $self, $category ) = @_;

    # Create a new adapter for this category if it is not already in cache
    #
    my $category_cache = $self->{category_cache};
    if ( !defined( $category_cache->{$category} ) ) {
        my $entry = $self->_choose_entry_for_category($category);
        my $adapter = $self->_new_adapter_for_entry( $entry, $category );
        $category_cache->{$category} = { entry => $entry, adapter => $adapter };
    }
    return $category_cache->{$category}->{adapter};
}

{
    no warnings 'once';
    *get_logger = \&get_adapter;    # backwards compatibility
}

sub get_context {
    my ( $self ) = @_;
    return $self->{context};
}

sub _choose_entry_for_category {
    my ( $self, $category ) = @_;

    foreach my $entry ( @{ $self->{entries} } ) {
        if ( $category =~ $entry->{pattern} ) {
            return $entry;
        }
    }
    # nothing requested so fallback to default
    my $default_adapter_name = $ENV{LOG_ANY_DEFAULT_ADAPTER} || "Null";
    my $default = $self->{default_adapter}{$category}
        || [ $self->_get_adapter_class($default_adapter_name), [] ];
    my ($adapter_class, $adapter_params) = @$default;
    _require_dynamic($adapter_class);
    return {
        adapter_class  => $adapter_class,
        adapter_params => $adapter_params,
    };
}

sub _new_adapter_for_entry {
    my ( $self, $entry, $category ) = @_;

    return $entry->{adapter_class}
      ->new( @{ $entry->{adapter_params} }, category => $category );
}

sub set_default {
    my ( $self, $category, $adapter_name, @adapter_params ) = @_;
    Log::Any::Proxy::Null->inflate_nulls;
    my $adapter_class = $self->_get_adapter_class($adapter_name);
    $self->{default_adapter}{$category} = [$adapter_class, \@adapter_params];
}

# =head2 set
#
#   $mgr->set( $options );
#
# Set the current adapter. Called from
# L<Log::Any::Adapter::set|Log::Any::Adapter/SETTING AND REMOVING ADAPTERS>, the
# standard API for setting the current adapter. Adds a new entry to the
# C<entries> stack and refreshes all the matching adapters.
#
# See L<Log::Any::Adapter|Log::Any::Adapter/SETTING AND REMOVING ADAPTERS>
# for available options.
#
# Returns the newly-created entry in the stack.
sub set {
    my $self = shift;
    my $options;
    if ( ref( $_[0] ) eq 'HASH' ) {
        $options = shift(@_);
    }
    my ( $adapter_name, @adapter_params ) = @_;

    unless ( defined($adapter_name) && $adapter_name =~ /\S/ ) {
        require Carp;
        Carp::croak("expected adapter name");
    }

    my $pattern = $options->{category};
    if ( !defined($pattern) ) {
        $pattern = qr/.*/;
    }
    elsif ( !ref($pattern) ) {
        $pattern = qr/^\Q$pattern\E$/;
    }

    my $adapter_class = $self->_get_adapter_class($adapter_name);
    _require_dynamic($adapter_class);

    my $entry = $self->_new_entry( $pattern, $adapter_class, \@adapter_params );
    unshift( @{ $self->{entries} }, $entry );

    $self->_reselect_matching_adapters($pattern);

    if ( my $lex_ref = $options->{lexically} ) {
        $$lex_ref = Log::Any::Manager::_Guard->new(
            sub { $self->remove($entry) unless _in_global_destruction() } );
    }

    Log::Any::Proxy::Null->inflate_nulls;
    return $entry;
}

sub remove {
    my ( $self, $entry ) = @_;

    my $pattern = $entry->{pattern};
    $self->{entries} = [ grep { $_ ne $entry } @{ $self->{entries} } ];
    $self->_reselect_matching_adapters($pattern);
}

sub _new_entry {
    my ( $self, $pattern, $adapter_class, $adapter_params ) = @_;

    return {
        pattern        => $pattern,
        adapter_class  => $adapter_class,
        adapter_params => $adapter_params,
    };
}

# =head2 _reselect_matching_adapters
#
#   $self->_reselect_matching_adapters( $pattern )
#
# Given a pattern, reselect which adapter should match. This is called
# after entries are added/removed from the C<entries> attribute.
#
# XXX Does not actually use $pattern, so do we need to pass it in?
sub _reselect_matching_adapters {
    my ( $self, $pattern ) = @_;

    return if _in_global_destruction();

    # Reselect adapter for each category matching $pattern
    #
    for my $category ( keys %{ $self->{category_cache} } ) {
        my $category_info = $self->{category_cache}->{$category};
        my $new_entry = $self->_choose_entry_for_category($category);
        if ( $new_entry ne $category_info->{entry} ) {
            my $new_adapter =
              $self->_new_adapter_for_entry( $new_entry, $category );
            # Replace existing references to the adapter with the new
            # adapter
            %{ $category_info->{adapter} } = %$new_adapter;
            bless( $category_info->{adapter}, ref($new_adapter) );
            $category_info->{entry} = $new_entry;
        }
    }
}

sub _get_adapter_class {
    my ( $self, $adapter_name ) = @_;
    return $Log::Any::OverrideDefaultAdapterClass if $Log::Any::OverrideDefaultAdapterClass;
    $adapter_name =~ s/^Log:://;    # Log::Dispatch -> Dispatch, etc.
    my $adapter_class = (
          substr( $adapter_name, 0, 1 ) eq '+'
        ? substr( $adapter_name, 1 )
        : "Log::Any::Adapter::$adapter_name"
    );
    return $adapter_class;
}

# This is adapted from the pure perl parts of Devel::GlobalDestruction
if ( defined ${^GLOBAL_PHASE} ) {
    eval 'sub _in_global_destruction () { ${^GLOBAL_PHASE} eq q[DESTRUCT] }; 1' ## no critic
      or die $@;
}
else {
    require B;
    my $started = !B::main_start()->isa(q[B::NULL]);
    unless ($started) {
        eval '0 && $started; CHECK { $started = 1 }; 1' ## no critic
          or die $@;
    }
    eval ## no critic
      '0 && $started; sub _in_global_destruction () { $started && B::main_start()->isa(q[B::NULL]) }; 1'
      or die $@;
}

# XXX not DRY and not a great way to do this, but oh, well.
sub _require_dynamic {
    my ($class) = @_;

    return 1 if $class->can('new'); # duck-type that class is loaded

    unless ( defined( eval "require $class; 1" ) )
    {    ## no critic (ProhibitStringyEval)
        die $@;
    }
}

package    # hide from PAUSE
  Log::Any::Manager::_Guard;

sub new { bless $_[1], $_[0] }

sub DESTROY { $_[0]->() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Manager

=head1 VERSION

version 1.717

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
