package FormValidator::LazyWay::Rule::Object;

use strict;
use warnings;
use utf8;

sub boolean {
    my $bool = shift;
    return 0 unless defined $bool;
    return $bool =~ /^[01]$/ ? 1 : 0 ;
}

sub regexp {
    my $text = shift;
    my $args = shift;
    die 'please set format' unless $args->{format};
    return $text =~ m/$args->{format}/ ? 1 : 0 ;
}

sub true {
    return 1;
}

1;
__END__

=head1 NAME

FormValidator::LazyWay::Rule::Object - object

=head1 METHOD

=head2 boolean

1 | 0

=head2 regexp

regular expression

 Object#regexp
    format : ^\d+$

=head2 true

always true!

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=cut
