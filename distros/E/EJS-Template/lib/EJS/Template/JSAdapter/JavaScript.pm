use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::JSAdapter::JavaScript

=cut

package EJS::Template::JSAdapter::JavaScript;
use base 'EJS::Template::JSAdapter';

use EJS::Template::Util qw(clean_text_ref);
use Scalar::Util qw(reftype);

our $ENCODE_UTF8   = 1;
our $SANITIZE_UTF8 = 1;
our $FORCE_UNTAINT = 1;
our $PRESERVE_UTF8 = 0;

=head1 Methods

=head2 new

Creates an adapter object.

=cut

sub new {
    my ($class) = @_;
    eval 'use JavaScript';
    die $@ if $@;
    my $runtime = JavaScript::Runtime->new;
    my $engine = $runtime->create_context;
    return bless {runtime => $runtime, engine => $engine}, $class;
}

=head2 bind

Implements the bind method.

=cut

sub bind {
    my ($self, $variables) = @_;
    my $engine = $self->engine;
    
    my $assign_value;
    my $assign_hash;
    my $assign_array;
    
    $assign_value = sub {
        my ($parent_path, $name, $source_ref, $in_array) = @_;
        
        my $reftype = reftype $$source_ref;
        
        my $path = $parent_path ne '' ?
                ($in_array ? "$parent_path\[$name]" : "$parent_path.$name") : $name;
        
        if ($reftype) {
            if ($reftype eq 'HASH') {
                #$engine->bind_value($path, {});
                JavaScript::Context::jsc_bind_value($engine, $parent_path, $name, {});
                $assign_hash->($path, $$source_ref);
            } elsif ($reftype eq 'ARRAY') {
                #$engine->bind_value($path, []);
                JavaScript::Context::jsc_bind_value($engine, $parent_path, $name, []);
                $assign_array->($path, $$source_ref);
            } elsif ($reftype eq 'CODE') {
                #$engine->bind_function($path, $$source_ref);
                JavaScript::Context::jsc_bind_value($engine, $parent_path, $name, $$source_ref);
            } elsif ($reftype eq 'SCALAR') {
                $assign_value->($parent_path, $name, $$source_ref, $in_array);
            } else {
                # ignore?
            }
        } else {
            # NOTE: Do NOT call a subroutine that takes $self as an argument here:
            # E.g.
            #   some_routine($self);
            #   $self->some_method();
            # If $self is passed as above, an odd memory leak occurs, detected by
            # JavaScript::Context::DESTROY
            
            #$engine->bind_value($path, $$source_ref);
            my $text_ref = clean_text_ref($source_ref, $ENCODE_UTF8, $SANITIZE_UTF8, $FORCE_UNTAINT);
            JavaScript::Context::jsc_bind_value($engine, $parent_path, $name, $$text_ref);
        }
    };
    
    $assign_hash = sub {
        my ($parent_path, $source) = @_;
        
        for my $name (keys %$source) {
            $assign_value->($parent_path, $name, \$source->{$name});
        }
    };
    
    $assign_array = sub {
        my ($parent_path, $source) = @_;
        my $len = scalar(@$source);
        
        for (my $i = 0; $i < $len; $i++) {
            $assign_value->($parent_path, $i, \$source->[$i], 1);
        }
    };
    
    $assign_hash->('', $variables);
    return $engine;
}

sub DESTROY {
    my ($self) = @_;
    $self->{engine}->_destroy() if $self->{engine};
    $self->{runtime}->_destroy() if $self->{runtime};
    delete $self->{engine};
    delete $self->{runtime};
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=item * L<EJS::Template::JSAdapter>

=item * L<JavaScript>

=back

=cut

1;
