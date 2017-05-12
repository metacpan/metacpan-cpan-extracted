package Hyper::Developer::Generator;

use strict;
use warnings;
use version; our $VERSION = qv('0.01');

use Class::Std;
use Template;

use Hyper::Error;
use Hyper::Singleton::Context;

my %base_path_of :ATTR(:init_arg<base_path> :get<base_path>);
my %template_of  :ATTR(:get<template>);
my %namespace_of :ATTR(:name<namespace>);
my %verbose_of   :ATTR(:name<verbose> :default<()>);
my %force_of     :ATTR(:name<force> :default<()>);

sub START {
    my ($self, $ident) = @_;

    $base_path_of{$ident} ||= Hyper::Singleton::Context->singleton
        ->get_context->get_config()->get_base_path();

    # create Template object
    $template_of{$ident} = Template->new({
        INCLUDE_PATH => [
            map {
                "$_/var";
            } $base_path_of{$ident},
              Hyper::Functions::get_path_from_file(__FILE__),
        ],
        INTERPOLATE  => 0,
        POST_CHOMP   => 0,
        EVAL_PERL    => 1,
        COMPILE_DIR  => '/tmp/tt', # <= tt drops a f*** warning if this is not set
    });

    return $self;
}

sub create {
    throw('you have to implement this method :)');
}

sub verbose_message {
    my $self = shift;

    $verbose_of{ident $self} and print @_, "\n";

    return $self;
}

1;

__END__

=pod

=head1 NAME

Hyper::Developer::Generator - abstract base class for code generation.

=head1 VERSION

This document describes Hyper::Developer::Generator 0.01

=head1 SYNOPSIS

    package Hyper::Developer::Generator::Example;
    use base qw(Hyper::Developer::Generator);

    Hyper::Developer::Generator::Example->new({
        service   => 'MyService',
        usecase   => 'AnotherUsecase',
    });

    1;

=head1 DESCRIPTION

Hyper::Developer::Generator is an abstract base class for code and
environment generation in the Hyper framework.

=head1 ATTRIBUTES

=over

=item base_path :get :init_arg

=item template  :get

=item namespace :name

=item verbose   :name :default<()>

=item force     :name :default<()>

=back

=head1 SUBROUTINES/METHODS

=head2 START

    package Hyper::Developer::Generator::Example;
    use base qw(Hyper::Developer::Generator);

    Hyper::Developer::Generator::Example->new({
        service   => 'MyService',
        usecase   => 'AnotherUsecase',
    });

    1;

Called automatically from Class::Std after object
initialization.

=head2 create

    $generator->create();

Creates files for the service of the usecase.

=head2 verbose_message

    $object->verbose_message('message 1', 'message 2');

Prints params and a newline if verbose attribute is true.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Use L<Hyper::Singleton::Context> for your configuration.

Sample for your Context.ini

    [Global]
    base_path=/srv/web/www.example.com/

=head1 DEPENDENCIES

=over

=item *

version

=item *

Class::Std

=item *

Template

=item *

Hyper::Error

=item *

Hyper::Singleton::Context

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 RCS INFORMATIONS

=over

=item Last changed by

 $Author: ac0v $

=item Id

 $Id: Generator.pm 333 2008-02-18 22:59:27Z ac0v $

=item Revision

 $Revision: 333 $

=item Date

 $Date: 2008-02-18 23:59:27 +0100 (Mon, 18 Feb 2008) $

=item HeadURL

 $HeadURL: http://svn.hyper-framework.org/Hyper/Hyper-Developer/branches/0.07/lib/Hyper/Developer/Generator.pm $

=back

=head1 AUTHOR

Andreas Specht  C<< <ACID@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Andreas Specht C<< <ACID@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
