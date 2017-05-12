package FormValidator::Nested::Result::Param;
use Any::Moose;
use namespace::clean -except => 'meta';


has 'key' => (
    is       => 'ro',
    isa      => 'Str',
    lazy_build => 1,
);
has 'validator' => (
    is       => 'ro',
    isa      => 'FormValidator::Nested::Profile::Param::Validator',
    required => 1,
    weak_ref => 1,
);
has 'has_error' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);
has 'msg' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);
__PACKAGE__->meta->make_immutable;

sub _build_key {
    my $self = shift;

    $self->validator->param->key;
}

sub _build_msg {
    my $self = shift;

    my $template = '';
    if ( $self->validator->options->{msg} ) {
        $template = $self->validator->options->{msg};
    }
    else {
        $template = $self->validator->msg;
    }

    my %vars = (
        name => $self->validator->param->name,
        %{$self->validator->options},
    );
    $template =~ s/\${([^}]*)}/$vars{$1}/g;

    return $template;
}

sub BUILD {
    my $self = shift;

    $self->key;
}

1;

