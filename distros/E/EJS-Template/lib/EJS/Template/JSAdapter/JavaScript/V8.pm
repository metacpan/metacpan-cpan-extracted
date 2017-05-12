use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::JSAdapter::JavaScript::V8

=cut

package EJS::Template::JSAdapter::JavaScript::V8;
use base 'EJS::Template::JSAdapter';

use EJS::Template::Util qw(clean_text_ref);
use Scalar::Util qw(reftype tainted);

our $ENCODE_UTF8   = 0;
our $SANITIZE_UTF8 = 0;
our $FORCE_UNTAINT = 1;
our $PRESERVE_UTF8 = 1;

=head1 Methods

=head2 new

Creates an adapter object.

=cut

sub new {
    my ($class) = @_;
    eval 'use JavaScript::V8';
    die $@ if $@;
    my $engine = JavaScript::V8::Context->new();
    return bless {engine => $engine}, $class;
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
        my ($target_ref, $source_ref) = @_;
        my $reftype = reftype $$source_ref;
        
        if ($reftype) {
            if ($reftype eq 'HASH') {
                $assign_hash->($$target_ref = {}, $$source_ref);
            } elsif ($reftype eq 'ARRAY') {
                $assign_array->($$target_ref = [], $$source_ref);
            } elsif ($reftype eq 'CODE') {
                $$target_ref = $$source_ref;
            } elsif ($reftype eq 'SCALAR') {
                $assign_value->($target_ref, $$source_ref);
            } else {
                # ignore?
            }
        } else {
            my $text_ref = clean_text_ref($source_ref, $ENCODE_UTF8, $SANITIZE_UTF8, $FORCE_UNTAINT);
            $$target_ref = $$text_ref;
        }
    };
    
    $assign_hash = sub {
        my ($target, $source) = @_;
        
        for my $name (keys %$source) {
            $assign_value->(\$target->{$name}, \$source->{$name});
        }
    };
    
    $assign_array = sub {
        my ($target, $source) = @_;
        my $len = scalar(@$source);
        
        for (my $i = 0; $i < $len; $i++) {
            $assign_value->(\$target->[$i], \$source->[$i]);
        }
    };
    
    my $clone = {};
    $assign_hash->($clone, $variables);
    
    for my $name (keys %$clone) {
        $engine->bind($name, $clone->{$name});
    }
    
    return $engine;
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=item * L<EJS::Template::JSAdapter>

=item * L<JavaScript::V8>

=back

=cut

1;
