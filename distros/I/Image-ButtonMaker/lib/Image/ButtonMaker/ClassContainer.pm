package Image::ButtonMaker::ClassContainer;
use strict;
use Image::ButtonMaker::ButtonClass;

#### Default values for class container
my @defaults = (
                classes  => undef,
                error    => 0,
                errorstr => undef,
                );

our $error;
our $errorstr;


sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $object = { @defaults };

    bless $object, $invocant;
    return $object;
}

sub lookup_class {
    my $self = shift;
    my $name = shift;
    return $self->{classes}{$name};
};


sub add_class {
    my $self = shift;
    my $class_obj = shift;

    my $name   = $class_obj->lookup_name;
    my $parent = $class_obj->lookup_parent;

    #### Can not add class to container if parent is not there
    if(length($parent)) {
        return $self->set_error(1000, "Parent '$parent' for class '$name' not found")
            unless($self->lookup_class($parent));
    }

    $self->{classes}{$name} = $class_obj;
    $class_obj->set_container($self);
    return 1;
}


sub reset_error {
    my $self = shift;
    $self->{error}    = 0;
    $self->{errorstr} = '';
    return;
}

sub set_error {
    my $self = shift;
    $self->{error}    = shift;
    $self->{errorstr} = shift;
    return shift;
}

1;
