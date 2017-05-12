use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::JSAdapter - JavaScript engine adapter for EJS::Template

=cut

package EJS::Template::JSAdapter;

=head1 Variables

=head2 @SUPPORTED_ENGINES

Supported JavaScript engine classes

=over 4

=item * L<JavaScript::V8>

=item * L<JavaScript>

=item * L<JavaScript::SpiderMonkey>

=item * L<JE>

=back

=cut

our @SUPPORTED_ENGINES = qw(
    JavaScript::V8
    JavaScript
    JavaScript::SpiderMonkey
    JE
);

my $default_adapter_class;

=head1 Methods

=head2 create

Instantiates a JavaScript engine adapter object.

    my $adapter = EJS::Template::JSAdapter->create();

If no argument is passed, an engine is selected from the available ones.

An explicit engine can also be specified. E.g.

    my $je_engine = EJS::Template::JSAdapter->create('JE');
    my $v8_engine = EJS::Template::JSAdapter->create('JavaScript::V8');

=cut

sub create {
    my ($class, $engine) = @_;
    
    if ($engine) {
        my $adapter_class = $class.'::'.$engine;
        eval "require $adapter_class";
        
        if ($@) {
            $adapter_class = $engine;
            eval "require $adapter_class";
            die $@ if $@;
        }
        
        return $adapter_class->new();
    } elsif ($default_adapter_class) {
        return $default_adapter_class->new();
    } else {
        for my $candidate (@SUPPORTED_ENGINES) {
            eval "require $candidate";
            next if $@;
            
            my $adapter_class = $class.'::'.$candidate;
            eval "require $adapter_class";
            next if $@;
            
            $default_adapter_class = $adapter_class;
            return $adapter_class->new();
        }
        
        die "No JavaScript engine modules are found. ".
            "Consider to install JavaScript::V8";
    }
}

=head2 new

Creates an adapter object.

This method should be overridden, and a property named 'engine' is expected to be set up.

    package Some::Extended::JSAdapter;
    use base 'EJS::Template::JSAdapter';
    
    sub new {
        my ($class) = @_;
        my $engine = Some::Underlying::JavaScript::Engine->new();
        return bless {engine => $engine}, $class;
    }

=cut

sub new {
    my ($class) = @_;
    return bless {engine => undef}, $class;
}

=head2 engine

Retrieves the underlying engine object.

=cut

sub engine {
    my ($self) = @_;
    return $self->{engine};
}

=head2 bind

Binds variable mapping to JavaScript objects.

This method should be overridden in a way that it can be invoked like this:

    $engine->bind({
        varname1 => $object1,
        funcname2 => sub {...},
        ...
    });

=cut

sub bind {
    my ($self, $variables) = @_;
    
    if (my $engine = $self->engine) {
        if ($engine->can('bind')) {
            return $engine->bind($variables);
        }
    }
}

=head2 eval

Evaluates a JavaScript code.

This method should be overridden in a way that it can be invoked like this:

    $engine->eval('print("ok\n")');

=cut

sub eval {
    my ($self) = @_;
    
    if (my $engine = $self->engine) {
        if ($engine->can('eval')) {
            return $engine->eval($_[1]);
        }
    }
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=back

=cut

1;
