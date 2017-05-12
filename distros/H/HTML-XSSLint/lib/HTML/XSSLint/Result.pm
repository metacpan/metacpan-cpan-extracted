package HTML::XSSLint::Result;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use URI;

sub new {
    my($class, %p) = @_;
    bless {%p}, $class;
}

sub action {
    my $self = shift;
    return $self->{form}->action;
}

sub names {
    my $self = shift;
    return @{$self->{names}};
}

sub vulnerable {
    my $self = shift;
    return scalar @{$self->{names}} > 0;
}

sub example {
    my $self = shift;
    return undef unless $self->vulnerable;
    my $uri = URI->new($self->action);
    $uri->query_form(map { $_ => '<s>test</s>' } $self->names);
    return $uri;
}

1;
__END__

=head1 NAME

HTML::XSSLint::Result - XSS audit result

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 DESCRIPTION

HTML::XSSLint::Result is a base class for HTML::XSSLint results objects.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::XSSLint>

=cut
