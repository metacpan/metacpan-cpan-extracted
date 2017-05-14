use Java::Wrapper;
use Java::ClassProxy;

package Java::Import::TieJavaArray;
use Tie::Array;
push @ISA, "Tie::Array";

# mandatory methods
sub TIEARRAY {
        my $class = shift;
        my $java_array = shift;
        my $self = {};
        $$self{java_array} = $java_array;
        bless $self, $class;
}

sub FETCH {
        my $self = shift;
        my $index = shift;
        Java::Import::ClassProxy::_wrap_java_object($$self{java_array}->get($index));
}

sub FETCHSIZE {
        my $self = shift;
        $$self{java_array}->getSize();
}

sub STORE {
        my $self = shift;
        my $index = shift;
        my $value = shift;
        $$self{java_array}->set($$value{prisoner}, $index);
}

sub STORESIZE {}    # mandatory if elements can be added/deleted
sub EXISTS {}       # mandatory if exists() expected to work
sub DELETE {}       # mandatory if delete() expected to work

# optional methods - for efficiency
#These will not be used
sub CLEAR {}
sub PUSH {}
sub POP {}
sub SHIFT {}
sub UNSHIFT {}
sub SPLICE {}
sub EXTEND {}
sub DESTROY {}

1;
