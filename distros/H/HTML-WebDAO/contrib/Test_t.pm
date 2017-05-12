package Test_t;
use strict;
use warnings;
use Data::Dumper;
use HTML::WebDAO::Component;
use base 'HTML::WebDAO::Component';

sub ___my_name {
    return "aaraer/aaa"
}

sub test_echo {
    my $self = shift;
    return @_
}

#default method for methods call
sub index_x {
    my $self = shift;
    return '2'
}

sub index_html {
    my $self = shift;
    return "aaaa"
}
sub test_resonse {
    my $self = shift;
    my $resonse = $self->response;
    $resonse->html = 'ok';
    return $resonse
}
1;
