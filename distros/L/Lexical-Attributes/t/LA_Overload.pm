package LA_Overload;

use strict;
use warnings;
use Lexical::Attributes;

use overload '""' => \&stringify;

has ($.key1, $.key2);
has $.key3 is rw;

sub new {
    bless [] => shift;
}

method load_me {
    $.key1 = shift if @_;
    $.key2 = shift if @_;
    $.key3 = shift if @_;
}

method stringify {
    my $foo = "###"; $foo =~ s/foo/bar/;
    qq !key1 = ! . $.key1 . "; key2 = " . $.key2 . '; key3 = ' . $.key3;
}

1;

__END__
