package FormValidator::Nested::Profile::Param::Validator;
use Any::Moose;
use namespace::clean -except => 'meta';
with 'FormValidator::Nested::Profile::Param::Processor';

use FormValidator::Nested;
use FormValidator::Nested::Result;
use FormValidator::Nested::Result::Param;

use UNIVERSAL::require;

has 'blank_process' => (
    is  => 'ro',
    isa => 'Bool',
    lazy_build => 1,
);
__PACKAGE__->meta->make_immutable;

sub _build_blank_process {
    my $self = shift;
    no strict 'refs';
    return ${$self->class . '::BLANK'};
}

sub msg {
    my $self = shift;

    my $class = $self->class;
    $class =~ s/^FormValidator::Nested::Validator:://;

    return $FormValidator::Nested::MESSAGES->{$class . '#' . $self->method};
}

sub _if_check {
    my $self = shift;
    my $req  = shift;

    if ( !$self->options->{if} ) {
        return 1;
    }

    foreach my $condition ( @{$self->options->{if}} ) {
        my ($method) = keys %{$condition};
        if ( $method eq 'EMPTY' ) {
            my ($target) = values %{$condition};
            my $value = $req->param($target);
            if ( defined $value && $value ne '' ) {
                return 0;
            }
        }
        elsif ( $method eq 'NOT_EMPTY' ) {
            my ($target) = values %{$condition};
            my $value = $req->param($target);
            if ( !defined $value || $value eq '' ) {
                return 0;
            }
        }
        elsif ( $method eq 'EQUAL' ) {
            my $target = $condition->{EQUAL}->{target};
            my $value  = $condition->{EQUAL}->{value};
            if ( $req->param($target) ne $value ) {
                return 0;
            }
        }
        elsif ( $method eq 'NOT_EQUAL' ) {
            my $target = $condition->{NOT_EQUAL}->{target};
            my $value  = $condition->{NOT_EQUAL}->{value};
            if ( $req->param($target) eq $value ) {
                return 0;
            }
        }
    }
    return 1;
}

sub process_scalar {
    my $self         = shift;
    my $req          = shift;
    my $value        = shift;
    my $param_name   = shift || $self->param->key;
    my $parent_names = shift;

    return if !$self->_if_check($req);

    if ( (!defined $value || $value eq '') && !$self->blank_process ) {
        return;
    }

    $param_name ||= $self->param->key;
    FormValidator::Nested::Result::Param->new({
        validator => $self,
        has_error => $self->method_ref->($value, $self->options, $req, $param_name) ? 0 : 1,
        key => $self->_make_param_name($parent_names, $param_name),
    });
}

sub process_array {
    my $self         = shift;
    my $req          = shift;
    my $values_ref   = shift;
    my $param_name   = shift || $self->param->key;
    my $parent_names = shift;

    my $result = FormValidator::Nested::Result->new({});

    my @values = @$values_ref;
    if ( !@values ) {
        push @values, undef;
    }

    foreach my $value ( @values ) {
        $result->merge($self->process_scalar($req, $value, $param_name, $parent_names));
    }

    return $result;
}


1;

