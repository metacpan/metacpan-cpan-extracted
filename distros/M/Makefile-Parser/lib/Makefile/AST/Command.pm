package Makefile::AST::Command;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
#use Smart::Comments;

__PACKAGE__->mk_accessors(qw{
    silent tolerant critical content target
});

sub as_str {
    my $self = shift;
    my $str;
    if ($self->silent) {
        $str .= '@';
    }
    if ($self->tolerant) {
        $str .= '-';
    }
    if ($self->critical) {
        $str .= '+';
    }
    $str .= $self->content;
}

1;

