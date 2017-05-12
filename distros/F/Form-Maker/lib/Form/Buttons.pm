package Form::Buttons;
use Form::Button;
# I am a collection of Form::Button objects. Oh, the shame.

use overload '""', sub { join "", @{$_[0]} };

sub new {
    bless [], shift;
}

1;
