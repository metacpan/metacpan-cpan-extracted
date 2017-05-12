use strict;
use warnings;

{
    package MySubClass;
    use base 'MyClass';
    use Method::Assert;

    my $default_output_fh = \*STDERR;

    sub _init {
        my $self = &instance_method;
        $self->SUPER::_init(@_);
        delete $self->{_FH}; # Make sure _FH key is undefined
        return $self;
    }

    sub output_to {
        &instance_method;
        my $self = shift;
        $self->set_output_fh(shift);
        return $self->output(@_);
    }

    sub get_output_fh {
        my $self = &instance_method;
        return $self->SUPER::get_output_fh()
            || $self->get_default_output_fh(); # get_default_output_fh() is called as instance method, but is a class method - should die if triggered
    }

    sub get_default_output_fh {
        &class_method;
        return $default_output_fh;
    }

    sub set_default_output_fh {
        my ($class, $fh) = &class_method;
        $default_output_fh = $fh;
        return $class;
    }

}

1;
