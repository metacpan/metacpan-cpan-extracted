package Mason::Plugin::SliceFilter::Filters::Slice;
## So we can access Mason::Request->current_request
use Mason::Request;
use Moose;
extends qw/Mason::DynamicFilter/;

has 'get_slice' => ( is => 'ro' , isa => 'CodeRef' , required => 1 , default => sub{my $self = shift; return sub{ my $param = shift ; $self->m->request_args()->{$param} }; } );
has 'm' => ( is => 'ro' , isa => 'Mason::Request' , required => 1 , default => sub{ return Mason::Request->current_request();});
has 'slice_id' => ( is => 'ro' , isa => 'Str' , required => 1 );
has 'slice_param' => ( is => 'ro', isa => 'Str', required => 1 , default => 'slice' );
has 'can_skip' => ( is => 'ro', isa => 'Bool', required => 1 , default => 0 );
has 'yield_noslice' => ( is => 'ro' , isa => 'Bool', required => 1 , default => 1 );

has '+filter' =>
  ( default =>
    sub{
      my ($self) = @_;
      sub{
        my ($yield) = @_;
        my $m = $self->m();
        my $slice_param = &{$self->get_slice()}($self->slice_param());
        ## warn "GOT SLICE PARAM '$slice_param'";
        unless(length($slice_param // '' ) ){
          if( $self->yield_noslice() ){
            ## warn "NO SLICE PARAM. Yielding";
            return ( $yield->() );
          }else{
            return '';
          }
        }else{
          ## warn "We have a slice $slice_param";
          if( $slice_param eq $self->slice_id ){
            ## warn "SLICE HIT on $slice_param!";
            ## Flush any previously generated content
            $m->clear_buffer();
            # Record the fact we have a slice hit
            # That will prevent nested 'can_skip' slices to
            # skip their output.
            $m->notes(__PACKAGE__.'_slicehit' , 1);
            $m->out_method->(($yield->()), $m );
            $m->flush_buffer();
            $m->abort();
            ## Job done
          }else{
            ## warn "SLICE MISS on $slice_param";
            unless( $self->can_skip() && !$m->notes(__PACKAGE__.'_slicehit') ){
              return ( $yield->() );
            }else{
              return '';
            }
          }
        }
      }
    });

__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Mason::Plugin::SliceFilter::Filters::Slice - Actual implementation of Slice filter

=cut
