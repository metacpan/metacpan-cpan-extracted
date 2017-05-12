package HTML::WidgetValidator::HTMLElement;
use warnings;
use strict;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(type name attr text));

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(\%args);
    return $self;
}

sub compare {
    my ($self, $model ) = @_;

    return unless $model;
    return unless $self->{type} eq $model->{type};
    return if( $self->name && lc($self->name) ne $model->{name} );
    
    if( $model->{text} ){
	return unless _compare( $self->text, $model->{text} );
    }
    if( $self->attr && scalar keys %{$self->attr} > 0 ){
	return unless $model->{attr};
	return  if scalar keys %{$self->attr} != scalar keys %{$model->{attr}};
	foreach my $attr ( keys %{$self->attr} ){
	    return unless defined $model->{attr}->{$attr};
	    return unless _compare( $self->attr->{$attr}, $model->{attr}->{$attr} );
	}
    }elsif( $model->{attr} ){
	return;
    }
    return 1;
}

sub _compare {
    my ( $text, $model ) = @_;
    if( ref $model eq 'Regexp' ){
	return $text =~ /^(?:$model)$/is ? 1 : 0;
    }elsif( defined $model ){
	return lc($text) eq lc($model) ? 1 : 0;
    }
    return 0;
}

1;
__END__

=head1 NAME

HTML::WidgetValidator::HTMLElement


=head1 DESCRIPTION

HTML Element class for HTML::WidgetValidator.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<Class::Accessor::Fast>

=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
