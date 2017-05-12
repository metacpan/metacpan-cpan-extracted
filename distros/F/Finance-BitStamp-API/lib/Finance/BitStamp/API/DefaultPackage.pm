package Finance::BitStamp::API::DefaultPackage;
# This is just some defaults that most Packages will want to use as a base...

# You will want to add these to the package that inherits this one...
use constant ATTRIBUTES => qw();
sub attributes { ATTRIBUTES }

sub new { (bless {} => shift)->init(@_) }
sub init {
    my $self = shift;
    my %args = @_;
    foreach my $attribute ($self->attributes) {
        $self->$attribute($args{$attribute}) if exists $args{$attribute};
    }
    return $self;
}

# this method simply makes all the get/setter attribute methods below very tidy...
sub get_set {
   my $self      = shift;
   my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
   $self->{$attribute} = shift if scalar @_;
   return $self->{$attribute};
}

1;

__END__

