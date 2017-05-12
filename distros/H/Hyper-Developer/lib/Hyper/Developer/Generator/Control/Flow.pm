package Hyper::Developer::Generator::Control::Flow;

use strict;
use warnings;
use version; our $VERSION = qv('0.01');

use base qw(Hyper::Developer::Generator::Control::ContainerFlow);
use Class::Std;
use Hyper::Config::Reader::Flow;

sub BUILD {
    my $self = shift;

    $self->set_type('package');
    $self->set_sub_path('/Control/Flow/');
    $self->set_suffix('pm');

    return $self;
}

sub create {
    my $self     = shift;
    my $usecase  = $self->get_usecase();
    my $service  = $self->get_service();

    my $config = Hyper::Config::Reader::Flow->new({
        base_path  => $self->get_base_path(),
        config_for => $self->get_namespace() . "::Control::Flow::${service}::F${usecase}",
    });

    my $data_ref = $self->_get_data_ref_of_steps(
        $config->get_steps()
    );

    my $attr_ref = $config->get_attributes();

    if ( %{$data_ref} ) {
        $self->SUPER::create({
            data     => {
                attributes => $attr_ref,
                step_data  => $data_ref,
            },
            name     => "_F$usecase",
            template => "Generator/Control/_flow.tpl",
            force    => 1,
        });
        $self->SUPER::create({
            data     => {
                attributes => $attr_ref,
                step_data  => $data_ref,
            },
            name     => "F$usecase",
            template => "Generator/Control/flow.tpl",
        });
    }

    return $self;
}

1;

__END__

=pod

=head1 NAME

Hyper::Developer::Generator::Control::Flow - class for generating Flow Controls

=head1 VERSION

This document describes Hyper::Developer::Generator::Control::Flow 0.01

=head1 SYNOPSIS

    use Hyper::Developer::Generator::Control::Flow;

    my $object = Hyper::Developer::Generator::Control::Flow->new({
        base_path => '/srv/web/www.example.com/',
        namespace => 'Example',
        usecase   => 'ChangePassword',
        service   => 'AccountManagement',
    });

    $object->create();

=head1 DESCRIPTION

Used to create the initial environment for a Hyper Based Web Application.

=head1 SUBROUTINES/METHODS

=head2 BUILD

    my $object = Hyper::Developer::Generator::Control::Flow->new({
        base_path => '/srv/web/www.example.com/',
        namespace => 'Example',
        usecase   => 'ChangePassword',
        service   => 'AccountManagement',
    });

Called on object creation and sets some default vars.

=head2 create

    $object->create();

Creates the following files:

=over

=item $BASE_PATH/lib/$NAMESPACE/Control/Flow/$SERVICE/F$USECASE.pm

This is generated once and won't be signed over. That's the place where
you can put your code in.

=item $BASE_PATH/lib/$NAMESPACE/Control/Flow/$SERVICE/_F$USECASE.pm

This file will be reqritten on each method call. So don't change
anything in this file.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item *

version

=item *

Hyper::Developer::Generator::Control::ContainerFlow

=item *

Class::Std

=item *

Hyper::Config::Reader::Flow

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 RCS INFORMATIONS

=over

=item Last changed by

$Author: ac0v $

=item Id

$Id: Flow.pm 333 2008-02-18 22:59:27Z ac0v $

=item Revision

$Revision: 333 $

=item Date

$Date: 2008-02-18 23:59:27 +0100 (Mon, 18 Feb 2008) $

=item HeadURL

$HeadURL: http://svn.hyper-framework.org/Hyper/Hyper-Developer/branches/0.07/lib/Hyper/Developer/Generator/Control/Flow.pm $

=back

=head1 AUTHOR

Andreas Specht  C<< <ACID@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Andreas Specht C<< <ACID@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
