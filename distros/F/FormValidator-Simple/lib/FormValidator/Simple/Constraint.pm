package FormValidator::Simple::Constraint;
use strict;
use base qw/Class::Accessor::Fast/;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Validator;
use FormValidator::Simple::Constants;

__PACKAGE__->mk_accessors(qw/name command negative args/);

sub new {
    my $class = shift;
    my $self  = bless { }, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, $setting) = @_;
    if (ref $setting) {
        my($name, @args) = @$setting;
        $self->name($name);
        $self->args( [@args] );
    } else {
        $self->name($setting);
        $self->args( [] );
    }
    $self->_check_name;
}

sub _check_name {
    my $self = shift;
    my $name = $self->name;
    if($name =~ /^NOT_(.+)$/) {
        $self->command($1);
        $self->negative( TRUE );
    } else {
        $self->command($name);
        $self->negative( FALSE );
    }
}

sub check {
    my ($self, $params) = @_;

    my $command = $self->command;
    FormValidator::Simple::Exception->throw(
        qq/Unknown validation "$command"./
    ) unless FormValidator::Simple::Validator->can($command);

    my ($result, $data) = FormValidator::Simple::Validator->$command($params, $self->args);
    $result = not $result if $self->negative;
    return ($result, $data);
}


1;
__END__

