package JavaScript::Runtime;

use strict;
use warnings;

use Carp qw(croak);

use JavaScript;

sub new {
    my ($pkg, @args) = @_;

    $pkg = ref $pkg || $pkg;

    my $maxbytes = $JavaScript::MAXBYTES;
    $maxbytes = shift @args if (@args && $args[0] =~ /^\d+$/);
    
    my @does;
    for (@args) {
        if (my ($type) = $_ =~ /^-(\w+)$/) {
            my $does = "JavaScript::Runtime::" . $type;
            if (!exists $JavaScript::Runtime::{$type . '::'}) {
                eval "require $does;";
                croak $@ if $@;
            }
            push @does, $does;
        }
    }
    
    my $runtime = jsr_create($maxbytes);
    my $self = bless { _impl => $runtime, _does => \@does }, $pkg;
   
    for (@does) {
        my $init = $_->can('_init');
        $init->($self) if $init;
    }
 
    return $self;
}

sub _destroy {
    my $self = shift;

    for (@{$self->{_does}}) {
        my $destroy = $_->can('_destroy');
        $destroy->($self);
    }
    
    if ($self->{_perl_interrupt_handler}) {
        # Remove the current one
        $self->set_interrupt_handler();
    }

    return unless $self->{'_impl'};
    jsr_destroy($self->{'_impl'});
    delete $self->{'_impl'};
    return 1;
}

sub DESTROY {
    my ($self) = @_;
    $self->_destroy();
}

sub create_context {
	my $self = shift;
	
	warn "Requesting a custom stacksize is not longer supported" if @_ && $_[0];
	
    my $context = JavaScript::Context->new($self);

    return $context;
}

sub _add_interrupt_handler {
    my ($self, $handler) = @_;
    jsr_add_interrupt_handler($self->{_impl}, $handler);
}

sub _remove_interrupt_handler {
    my ($self, $handler) = @_;
    jsr_remove_interrupt_handler($self->{_impl}, $handler); 
}

sub set_interrupt_handler {
    my ($self, $handler) = @_;

    if ($handler && ref $handler eq '') {
        my $caller_pkg = caller;
        $handler = $caller_pkg->can($handler);
    }
    
    if ($handler) {
        $self->{_perl_interrupt_handler} = jsr_init_perl_interrupt_handler($handler);
        $self->_add_interrupt_handler($self->{_perl_interrupt_handler});
        
    }
    elsif ($self->{_perl_interrupt_handler}) {
        $self->_remove_interrupt_handler($self->{_perl_interrupt_handler});
        jsr_destroy_perl_interrupt_handler($self->{_perl_interrupt_handler});
        delete $self->{_perl_interrupt_handler};
    }
    
    1;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my ($method_name) = $AUTOLOAD =~ /::([A-Za-z0-9_]+)$/;
    
    for my $does (@{$self->{_does}}) {
        if (defined (my $method = $does->can($method_name))) {
            return $method->($self, @_);
        }
    }
    
    my $isa = join(", ", @{$self->{_does}});
    croak "Can't call method '$method_name' because it's not defined in $isa";
}

1;
__END__

=head1 NAME

JavaScript::Runtime - Runs contexts

=head1 DESCRIPTION

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( $maxbytes )

Creates a new runtime object. The optional argument I<$maxbytes> specifies the number
of bytes that can be allocated before garbage collection is runned. If ommited it
defaults to 1MB.

=back

=head2 INSTANCE METHODS

=over 4

=item create_context ()

Creates a new C<JavaScript::Context>-object in the runtime. 

=item set_interrupt_handler ( $handler )

Attaches an interrupt handler (a function that is called before each op is
executed ) to the runtime. The argument I<$handler> must be either a code-reference
or the name of a subroutine in the calling package.

To remove the handler call this method with an undef as argument.

Note that attaching an interrupt handler to the runtime causes a slowdown in
execution speed since we must execute some Perl code between each op.

In order to abort execution your handler should a false value (such as 0). All true values will continue
execution. Any exceptions thrown by the handler are ignored and $@ is cleared.

=back

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over 4

=item _destroy

Method that deallocates the runtime.

=item DESTORY

Called when the runtime is destroyed by Perl.

=item jsr_create ( int maxbytes )

Creates a runtime and returns a pointer to a C<PJS_Runtime> structure.

=item jsr_destroy ( PJS_Runtime *runtime )

Destorys the runtime and deallocates the memory occupied by it.

=item jsr_add_interrupt_handler ( PJS_Runtime *runtime, PJS_TrapHandler *handler )

Adds an interrupt handler. 

=item jsr_remove_interrupt_handler ( PJS_Runtime *runtime, PJS_TrapHandler *handler )

Removes an interrupt handler

=item jsr_init_perl_interrupt_handler ( CV *callback )

Initializes a new Perl level interrupt handler.

=item jsr_destroy_perl_interrupt_handler ( PJS_TrapHandler *handler )

Destroys a Perl level interrupt handler

=back

=end PRIVATE

=head1 SEE ALSO

L<JavaScript::Context>

=cut

