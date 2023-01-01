use strict;
use warnings;
package HTML::MasonX::Free::Request 0.007;

# ABSTRACT: a request class that eliminates the wrapping chain
use parent 'HTML::Mason::Request';

#pod =head1 OVERVIEW
#pod
#pod You don't want to know about this class.  The basic thing is: if you're using
#pod L<HTML::MasonX::Free::Resolver>, you should use this.
#pod
#pod If you want a little more information:  this gets rid of the notion of
#pod automatically execing the whole wrapping chain (like autohandlers) for
#pod components.  It's gross, but it can make things a fair bit simpler.
#pod
#pod =cut

use Log::Any qw($log);
use HTML::Mason::Exceptions( abbr => [qw(error param_error syntax_error
                                         top_level_not_found_error error)] );

# BEGIN DIRECT THEFT FROM HTML-Mason 1.50
sub exec {
    my ($self) = @_;

    # If the request failed to initialize, the error has already been handled
    # at the bottom of _initialize(); just return.
    return unless $self->initialized();

    local $SIG{'__DIE__'} = $self->component_error_handler
        if $self->component_error_handler;

    # Cheap way to prevent users from executing the same request twice.
    #
    if ($self->{execd}++) {
        error "Can only call exec() once for a given request object. Did you want to use a subrequest?";
    }

    # Check for infinite subrequest loop.
    #
    error "subrequest depth > " . $self->max_recurse . " (infinite subrequest loop?)"
        if $self->request_depth > $self->max_recurse;

    #
    # $m is a dynamically scoped global containing this
    # request. This needs to be defined in the HTML::Mason::Commands
    # package, as well as the component package if that is different.
    #
    local $HTML::Mason::Commands::m = $self;

    # Dynamically scoped global pointing at the top of the request stack.
    #
    $self->{top_stack} = undef;

    # Save context of subroutine for use inside eval.
    my $wantarray = wantarray;
    my @result;

    # Initialize output buffer to interpreter's preallocated buffer
    # before clearing, to reduce memory reallocations.
    #
    $self->{request_buffer} = $self->interp->preallocated_output_buffer;
    $self->{request_buffer} = '';

    $log->debugf("starting request for '%s'", $self->request_comp->title)
        if $log->is_debug;

    eval {
        # Build wrapper chain and index.
        my $request_comp = $self->request_comp;
        my $first_comp;
        {
            my @wrapper_chain = ($request_comp);

            ## XXX: eliminated for(;;) loop here -- rjbs, 2012-09-24
            $first_comp = $wrapper_chain[0];
            $self->{wrapper_chain} = [@wrapper_chain];
            $self->{wrapper_index} = { map
                                       { $wrapper_chain[$_]->comp_id => $_ }
                                       (0..$#wrapper_chain)
                                     };
        }

        # Get original request_args array reference to avoid copying.
        my $request_args = $self->{request_args};
        {
            local *SELECTED;
            tie *SELECTED, 'Tie::Handle::Mason';

            my $old = select SELECTED;
            my $mods = {base_comp => $request_comp, store => \($self->{request_buffer}), flushable => 1};

            if ($self->{has_plugins}) {
                my $context = bless
                    [$self, $request_args],
                    'HTML::Mason::Plugin::Context::StartRequest';
                eval {
                    foreach my $plugin_instance (@{$self->plugin_instances}) {
                        $plugin_instance->start_request_hook( $context );
                    }
                };
                if ($@) {
                    select $old;
                    rethrow_exception $@;
                }
            }

            if ($wantarray) {
                @result = eval {$self->comp($mods, $first_comp, @$request_args)};
            } elsif (defined($wantarray)) {
                $result[0] = eval {$self->comp($mods, $first_comp, @$request_args)};
            } else {
                eval {$self->comp($mods, $first_comp, @$request_args)};
            }
 
            my $error = $@;

            if ($self->{has_plugins}) {
                # plugins called in reverse order when exiting.
                my $context = bless
                    [$self, $request_args, \$self->{request_buffer}, $wantarray, \@result, \$error],
                    'HTML::Mason::Plugin::Context::EndRequest';
                eval {
                    foreach my $plugin_instance (@{$self->{plugin_instances_reverse}}) {
                        $plugin_instance->end_request_hook( $context );
                    }
                };
                if ($@) {
                    # plugin errors take precedence over component errors
                    $error = $@;
                }
            }
            
            select $old;
            rethrow_exception $error;
        }
    };

    $log->debugf("finishing request for '%s'", $self->request_comp->title)
        if $log->is_debug;

    # Purge code cache if necessary.
    $self->interp->purge_code_cache;

    # Handle errors.
    my $err = $@;
    if ($err and !$self->_aborted_or_declined($err)) {
        $self->_handle_error($err);
        return;
    }

    # If there's anything in the output buffer, send it to out_method.
    # Otherwise skip out_method call to avoid triggering side effects
    # (e.g. HTTP header sending).
    if (length($self->{request_buffer}) > 0) {
        $self->out_method->($self->{request_buffer});
    }

    # Return aborted value or result.
    @result = ($err->aborted_value) if $self->aborted($err);
    @result = ($err->declined_value) if $self->declined($err);
    return $wantarray ? @result : defined($wantarray) ? $result[0] : undef;
}
# BEGIN DIRECT THEFT FROM HTML-Mason 1.50

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::MasonX::Free::Request - a request class that eliminates the wrapping chain

=head1 VERSION

version 0.007

=head1 OVERVIEW

You don't want to know about this class.  The basic thing is: if you're using
L<HTML::MasonX::Free::Resolver>, you should use this.

If you want a little more information:  this gets rid of the notion of
automatically execing the whole wrapping chain (like autohandlers) for
components.  It's gross, but it can make things a fair bit simpler.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
