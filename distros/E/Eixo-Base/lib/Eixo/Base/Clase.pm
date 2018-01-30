package Eixo::Base::Clase;

use Eixo::Base::Util;
use Clone 'clone';
use mro;

use Attribute::Handlers;
use strict;
use warnings;


sub import{
    my $class = shift;

    $_->import for qw(strict warnings utf8);
    #mro->import('c3');

    return unless($class eq 'Eixo::Base::Clase');

    if(@_ && $_[0] eq '-norequire'){
        shift @_;
    }
    else{
        foreach my $f (my @copy = @_){

            $f =~ s!::|'!/!g;

            no strict 'refs';

            require "$f.pm";

        }
    }

    my @inheritance = (@_ > 0) ? @_ : $class;

    my $caller = caller;

    {
        no strict 'refs';

        foreach my $parent (@inheritance){

            foreach my $my_class (@{mro::get_linear_isa($parent)}){
                #print "$my_class\n";
                
                #next if($caller->isa($my_class));

                #print "------>$caller $my_class \n";

                push @{"${caller}\:\:ISA"}, $my_class;
            }


        }


        *{$caller . '::has'} = \&has;

    };


}



sub has{
    my (%attributes) = @_;

    my $class = (caller(0))[0];

    no strict 'refs';
    
    foreach my $attribute (keys(%attributes)){

        $class->__createSetterGetter($attribute, $attributes{$attribute});        
    }

    *{$class . '::' . '__initialize'} = sub {

        my $c_attributes = clone(\%attributes);

        my ($self) = @_;

        foreach(keys %$c_attributes){

            $self->{$_} = $c_attributes->{$_};
        }
    };  
}

sub __createSetterGetter{
    my ($class, $attribute, $value) = @_;

    no strict 'refs';

    unless(defined(&{$class . '::' . $attribute})){

        *{$class . '::' . $attribute} = sub {

            my ($self, $value)  = @_;

            if(defined($value)){
                
                $self->{$attribute} = $value;
                
                $self;
            }
            else{
                $self->{$attribute};
            }    

        };
    }

}

sub new{
    my ($clase, @args) = @_;

    my $self = bless({}, $clase);

    # initialize attributes with default values from 'has' 
    $self->__chainInitialize;    

    # finally call initialize method
    $self->initialize(@args);

    $self;
}


sub __chainInitialize{
    my ($self) = @_;

    no strict 'refs';    

    foreach(@{ref($self) . '::ISA'}){

        if(my $code = $_->can('__initialize')){

            $code->(@_);
        }
    }

    $self->__initialize if($self->can('__initialize'));
}

#
# default initialize 
#
sub initialize{
    
    my ($self, @args) = @_;

        # default initialize
    

    # if new is called with initialization values (not recommended)
    if(@args % 2 == 0){

        my %args = @args;

        foreach(keys(%args)){

            $self->$_($args{$_}) if($self->can($_));

        }
    }
}

#
# Methods
#
sub methods{
    my ($self, $class, $nested) = @_;

    $class = $class || ref($self) || $self;

    no strict 'refs';

    my @methods = grep { defined(&{$class . '::' . $_} ) } keys(%{$class . '::'});

    push @methods, $self->methods($_, 1) foreach(@{ $class .'::ISA' } );


    unless($nested){

        my %s;

        $s{$_}++ foreach( map { $_ =~ s/.+\:\://; $_ } @methods);

        return keys(%s);
    }

    @methods;
    
}

#
# ABSTRACT method
#
sub Abstract :ATTR(CODE){
    my ($pkg, $sym, $code, $attr_name, $data) = @_;

    no warnings 'redefine';

    my $n = $pkg . '::' . *{$sym}{NAME};

    *{$sym} = sub {

        die($n . ' is ABSTRACT!!!');
 
    };    

}

#
# logger installing code
#
sub Log :ATTR(CODE){

    my ($pkg, $sym, $code, $attr_name, $data) = @_;

    no warnings 'redefine';

    *{$sym} = sub {

        my ($self, @args) = @_;

        $self->logger([$pkg, *{$sym}{NAME}], \@args);

        $code->($self, @args);
    };

}

sub flog{
    my ($self, $code) = @_;

    unless(ref($code) eq 'CODE'){
        die(ref($self) . '::flog: code ref expected');
    }

    $self->{flog} = $code;
}

sub logger{
    my ($self, @args) = @_;

    return unless($self->{flog});

    $self->{flog}->($self, @args);
}

1;


