package HTML::WidgetValidator::Result;
use base qw(Class::Accessor::Fast);
use warnings;
use strict;

__PACKAGE__->mk_accessors(qw(widget elements));

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(\%args);
}

sub code {
    my $self = shift;
    return join '', map {$_->{text}} @{$self->elements};
}

sub name {
    my $self = shift;
    return unless $self->widget;
    return $self->widget->name;
}

sub url {
    my $self = shift;
    return unless $self->widget;
    return $self->widget->url;
}

1;
__END__

=head1 NAME

HTML::WidgetValidator::Result


=head1 DESCRIPTION

Result object returned by HTML::WidgetValidator.


=head1 SEE ALSO

L<HTML::WidgetValidator>
L<Class::Accessor::Fast>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
