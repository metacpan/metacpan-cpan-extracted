package FormValidator::Nested::Result;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
use namespace::clean -except => 'meta';

use List::MoreUtils qw/any/;

has 'params' => (
    metaclass => 'Collection::Hash',
    is        => 'rw',
    isa       => 'HashRef[ArrayRef[FormValidator::Nested::Result::Param]]',
    default   => sub { {} },
    provides   => {
        values   => 'get_params',
        get      => 'get_param',
        set      => '_set_param',
        exists   => 'exists_param',
    },
);
__PACKAGE__->meta->make_immutable;

sub has_error {
    my $self = shift;

    if ( any { any { $_->has_error } @{$_} } $self->get_params ) {
        return 1;
    }
    return 0;
}

sub error_params {
    my $self = shift;

    my %error_params = ();
    foreach my $param_array_ref ($self->get_params) {
        my @error_params = grep { $_->has_error } @{$param_array_ref};
        if ( @error_params ) {
            $error_params{$error_params[0]->key} = \@error_params;
        }
    }

    return \%error_params;
}

# other_resultはResultでもResult::Paramでもおｋ
sub merge {
    my $self         = shift;
    my $other_result = shift;

    return if !blessed $other_result;

    if ( $other_result->isa('FormValidator::Nested::Result') ) {
        foreach my $param_array_ref ( $other_result->get_params ) {
            foreach my $param (@{$param_array_ref}) {
                $self->set_param($param);
            }
        }
    }
    elsif ( $other_result->isa('FormValidator::Nested::Result::Param') ) {
        $self->set_param($other_result);
    }
}

# result_paramはResult::Param
sub set_param {
    my $self         = shift;
    my $result_param = shift;

    if ( $self->exists_param($result_param->key) ) {
        push @{$self->get_param($result_param->key)}, $result_param;
    }
    else {
        $self->_set_param($result_param->key, [$result_param]);
    }
}

sub count_params {
    my $self = shift;

    my $count = 0;
    foreach my $param_array_ref ( $self->get_params ) {
        $count += @{$param_array_ref};
    }

    return $count;
}

1;

