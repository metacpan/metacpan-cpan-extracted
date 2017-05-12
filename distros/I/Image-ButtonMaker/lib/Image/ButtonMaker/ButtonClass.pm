package Image::ButtonMaker::ButtonClass;
use strict;
use Image::ButtonMaker::Button;

#### Default values for classes: a class is just a hash
my @defaults = (
                classname      => '',
                parent         => '',
                container      => undef,
                properties     => {},
                );

our $error;
our $errorstr;

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;

    my %prototype = @_;    
    return
        set_error(1000, "No class name specified")
        unless($prototype{classname});

    #### Check properites validity ####
    my $prop = $prototype{properties} || {};
    return
        set_error(1001, "properties argument must be a HASH ref")
        if(ref($prop) ne 'HASH');

    foreach my $p (keys(%$prop)) {
        return
            set_error(1002, "Illegal property: $p")
            unless(Image::ButtonMaker::Button->is_property_legal($p));

    }

    my $object = { @defaults, %prototype};
    bless $object, $class;
    return $object;
}


#### Instance Methods #######################################################
sub set_container {
    my $self = shift;
    my $container = shift;
    reset_error();

    $self->{container} = $container;
    return;
}


sub lookup_name {
    my $self = shift;
    reset_error();

    return $self->{classname};
}


sub lookup_parent {
    my $self = shift;
    reset_error();
    return $self->{parent};
}


sub lookup_property {
    my $self     = shift;
    my $propname = shift;

    reset_error();
    
    my $prop = $self->{properties};

    return $prop->{$propname} if(defined($prop->{$propname}));

    if($self->{parent}) {

        return set_error(2000, "Parent attribute is set, but no container is given")
            unless($self->{container});
        my $container = $self->{container};

        my $parent_obj = $container->lookup_class($self->{parent});
        return set_error(2000, "Parent class not found") 
            unless($parent_obj);

        return $parent_obj->lookup_property($propname);
    }

    return undef;
}


#### Set property. Return undef if property is illegal 
sub set_property {
    reset_error();

    my $self = shift;
    my ($propname, $propvalue) = (@_);

    return set_error(2000, "No property name given") 
        unless(defined($propname));
    return set_error(2000, "Illegal property name $propname") 
        unless(Image::ButtonMaker::Button->is_property_legal($propname));

    $self->{properties}{$propname} = $propvalue;
    return $propvalue;
}


#### Remove property from properties HASH and return the property value
##   which _can_ be inherited from some parent class
sub delete_property {
    reset_error();
    my $self = shift;
    my ($propname) = (@_);

    return set_error(2000, "No property name given")
        unless(defined($propname));
    return set_error(2000, "Illegal property name $propname")
        unless(Image::ButtonMaker::Button->is_property_legal($propname));
}


#### Package methods ############################################################
#### Set and reset package-wide error codes
sub reset_error {
    $error = 0;
    $errorstr = 0;
    return;
}

sub set_error {
    $error = shift;
    $errorstr = shift;
    return undef;
}

1;
