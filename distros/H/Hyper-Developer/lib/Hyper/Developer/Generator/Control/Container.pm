package Hyper::Developer::Generator::Control::Container;

use strict;
use warnings;
use version; our $VERSION = qv('0.01');

use Class::Std;
use base qw(Hyper::Developer::Generator::Control::ContainerFlow);

use Hyper::Config::Reader::Container;

my %create_template_of :ATTR(:init_arg<template>);
my %create_code_of     :ATTR(:init_arg<code>);

sub BUILD {
    my $self = shift;

    $self->set_type('package');
    $self->set_sub_path('/Control/Container/');
    $self->set_suffix('pm');

    return $self;
}

sub create {
    my $self     = shift;
    my $ident    = ident $self;
    my $usecase  = $self->get_usecase();
    my $service  = $self->get_service();

    my $config = Hyper::Config::Reader::Container->new({
        base_path => $self->get_base_path(),
        config_for => $self->get_namespace() . "::Control::Container::${service}::C${usecase}",
    });

    my $data_ref = $self->_get_data_ref_of_steps(
        $config->get_steps()
    );

    my $attr_ref = $config->get_attributes();

    if ( %{$data_ref} ) {
        if ( $create_code_of{$ident} ) {
            $self->SUPER::create({
                data       => {
                    attributes => $attr_ref,
                    step_data  => $data_ref,
                },
                name     => "_C$usecase",
                template => 'Generator/Control/_container.tpl',
                force    => 1,
            });
            $self->SUPER::create({
                data       => {
                    attributes => $attr_ref,
                    step_data  => $data_ref,
                },
                name     => "C$usecase",
                template => 'Generator/Control/container.tpl',
            });
        }
        if ( $create_template_of{$ident} ) {
            $self->set_type('template');
            $self->set_suffix('htc');
            $self->SUPER::create({
                data       => {
                    attributes => $attr_ref,
                    step_data  => $data_ref,
                },
                name       => "C$usecase",
                template   => 'Generator/Control/Container/template.tpl',
            });
        }
    }

    return $self;
}

1;


__END__

=pod

=head1 NAME

Hyper::Developer::Generator::Control::Container - class for generating Container Controls

=head1 VERSION

This document describes Hyper::Developer::Generator::Control::Container 0.01

=head1 SYNOPSIS

    use Hyper::Developer::Generator::Control::Container;

    my $object = Hyper::Developer::Generator::Control::Container->new({
        base_path => '/srv/web/www.example.com/',
        namespace => 'Example',
        usecase   => 'ChangePassword',
        service   => 'AccountManagement',
    });

    $object->create();

=head1 DESCRIPTION

Used to create the initial environment for a Hyper Based Web Application.

=head1 ATTRIBUTES

=over

=item template :init_arg

Indicated if the template should be generated.

=item code     :init_arg

Indicated if perl code should be generated.

=back

=head1 SUBROUTINES/METHODS

=head2 BUILD

    my $object = Hyper::Developer::Generator::Control::Container->new({
        base_path => '/srv/web/www.example.com/',
        namespace => 'Example',
        usecase   => 'ChangePassword',
        service   => 'AccountManagement',
    });

Called on object creation and sets some default vars.

=head2 create

    $object->create();

Creates the following files (depends on the init_args - see ATTRIBUTES):

=over

=item $BASE_PATH/lib/$NAMESPACE/Control/Container/$SERVICE/C$USECASE.pm

This is generated once and won't be signed over. That's the place where
you can put your code in.

=item $BASE_PATH/lib/$NAMESPACE/Control/Container/$SERVICE/_C$USECASE.pm

This file will be reqritten on each method call. So don't change
anything in this file.

=item $BASE_PATH/var/$NAMESPACE/Control/Container/$SERVICE/C$USECASE.htc

This is the default template for the new container.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item *

version

=item *

Class::Std

=item *

Hyper::Developer::Generator::Control::ContainerFlow

=item *

Hyper::Config::Reader::Container

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 RCS INFORMATIONS

=over

=item Last changed by

$Author: ac0v $

=item Id

$Id: Container.pm 333 2008-02-18 22:59:27Z ac0v $

=item Revision

$Revision: 333 $

=item Date

$Date: 2008-02-18 23:59:27 +0100 (Mon, 18 Feb 2008) $

=item HeadURL

$HeadURL: http://svn.hyper-framework.org/Hyper/Hyper-Developer/branches/0.07/lib/Hyper/Developer/Generator/Control/Container.pm $

=back

=head1 AUTHOR

Andreas Specht  C<< <ACID@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Andreas Specht C<< <ACID@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
