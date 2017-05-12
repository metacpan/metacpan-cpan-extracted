package HTML::WidgetValidator::WidgetContainer;
use warnings;
use strict;
use base qw(Class::Accessor::Fast);
use UNIVERSAL::require;
use Module::Pluggable search_path => ['HTML::WidgetValidator::Widget'],  sub_name => 'all_widgets';
use List::MoreUtils qw(each_arrayref any);

use HTML::WidgetValidator::Result;

__PACKAGE__->mk_accessors(qw(widgets));
my $widget_namespace = 'HTML::WidgetValidator::Widget::';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(\%args);
    unless( defined $args{widgets} ){
	my @widgets = map { $_ =~ s/^$widget_namespace//; $_ } $self->all_widgets;
	$self->widgets(\@widgets);
    }
    $self->build_tree;
    return $self;
}

sub add {
    my ($self, @widgets) = @_;
    foreach( @widgets ){
	my $module = $widget_namespace.$_;
	$self->add_tree($module)
    }
    push @{$self->{widgets}}, @widgets;
}

sub add_tree {
    my $self = shift;
    my $module = shift;
    if( !$module->require ){
	warn $@;
	return;
    }
    my $models = $module->models || [];
    foreach my $model ( @$models ){
	next if ref $model ne 'ARRAY' || $#{$model} == -1;
	my $name = $model->[0]->{name} || next;
	$self->{pattern_tree}->{$name} = [] unless $self->{pattern_tree}->{$name};
	push @{$self->{pattern_tree}->{$name}},
	    {
		widget => $module,
		model  => $model,
	    };
    }
}

sub build_tree {
    my $self = shift;
    $self->{pattern_tree} = {};
    my @widgets = @{$self->widgets};
    $self->add( @widgets );
    $self->widgets( \@widgets );
}

sub match {
    my ( $self, $elements, $html ) = @_;
    return if ref $elements ne 'ARRAY' || $#{$elements} == -1;
    my $models  = $self->{pattern_tree}->{$elements->[0]->name || ''} || return;
    MODEL: foreach ( @$models ){
	my $model = $_->{model};
	next if( $#{$model} != $#{$elements} );
	my $ea = each_arrayref($model, $elements);
	while ( my ($m, $e) = $ea->() ){
	    next MODEL unless $e->compare($m);
	}
	return HTML::WidgetValidator::Result->new(
	    widget    => $_->{widget},
	    elements => $elements,
	);
    }
}

1;
__END__

=head1 NAME

HTML::WidgetValidator::WidgetContainer


=head1 DESCRIPTION

Container class for HTML::WidgetValidator widget patterns.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<Class::Accessor::Fast>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
