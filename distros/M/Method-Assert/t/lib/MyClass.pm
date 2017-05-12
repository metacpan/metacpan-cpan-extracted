use strict;
use warnings;

{
    package MyClass;
    use Method::Assert;
    use Carp qw(confess);

    my $instance_count = 0;

    sub instance_count {
        &class_method;
        return $instance_count;
    }

    sub new {
        my ($class, @args) = &class_method;
        my $self = {};
        bless $self, $class;
        $self->_init(@args);
        $instance_count++;
        return $self;
    }

    sub _init {
        my $self = &instance_method;
        confess("Odd number of parameters for hash") if @_ % 2 == 1;
        my %args = @_;
        $self->{_FH} = \*STDERR;
        $self->{ keys %args } = values %args;
        return $self;
    }

    sub output {
        my $self = &instance_method;
        my $fh = $self->get_output_fh();
        print $fh @_;
    }

    sub get_output_fh {
        my $self = &instance_method;
        return $self->{_FH};
    }

    sub set_output_fh {
        my $self = &instance_method;
        confess("No parameter specified") unless @_;
        $self->{_FH} = $_[0];
        return $self;
    }

    sub DESTROY {
        &instance_method;
        $instance_count--;
        return 1;
    }

}

1;
