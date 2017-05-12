package FormValidator::Nested::Profile::Param::Filter;
use Any::Moose;
use namespace::clean -except => 'meta';
with 'FormValidator::Nested::Profile::Param::Processor';

__PACKAGE__->meta->make_immutable;

sub process_scalar {
    my $self       = shift;
    my $req        = shift;
    my $value      = shift;
    my $param_name = shift || $self->param->key;

    $req->param($param_name => $self->method_ref->($value, $self->options, $req));
}

sub process_array {
    my $self       = shift;
    my $req        = shift;
    my $values_ref = shift;
    my $param_name = shift || $self->param->key;

    my @new_values = ();
    foreach my $value ( @$values_ref ) {
        push @new_values, $self->method_ref->($value, $self->options, $req);
    }

    $req->param($param_name => \@new_values);
}

1;

