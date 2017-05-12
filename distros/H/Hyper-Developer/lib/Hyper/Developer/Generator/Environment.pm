package Hyper::Developer::Generator::Environment;

use strict;
use warnings;
use version; our $VERSION = qv('0.01');

use base qw(Hyper::Developer::Generator);
use Class::Std;
use File::Path ();

use Hyper::Functions;
use Hyper::Error;

sub create {
    my $self    = shift;
    my $arg_ref = shift;

    my $base_path = $self->get_base_path();
    my $namespace = $self->get_namespace();
    my $lc_path   = Hyper::Functions::class_to_path(lc $namespace);
    my $template  = $self->get_template();

    File::Path::mkpath([
            map {
                my $path = "$base_path/$_/$namespace";
                $self->verbose_message("creating path >$path<");
                $path;
            } qw(lib var etc t)
        ], 0, 0770
    );


    for my $dir ( qw(cgi-bin htdocs bin) ) {
        my $path = "$base_path/$dir/$lc_path";
        $self->verbose_message("creating path >$path<");
        File::Path::mkpath([$path], 0, 0770);
    }

    # Context.ini
    my $file = "$base_path/"
        . Hyper::Functions::get_path_for('config')
        . "/$namespace/Context.ini";
    if ( $self->get_force() || ! -e $file ) {
        $self->verbose_message("creating initial context >$file<");
        $template->process(
            "Generator/Environment/Context.ini.tpl",
            { this => $self },
            $file
        ) or throw($template->error());
    }
    else {
        print STDERR "won't create >$file< - file already exists. use param force to overwrite\n";
    }

    # index.pl
    $file = "$base_path/cgi-bin/$lc_path/index.pl";
    if ( $self->get_force() || ! -e $file ) {
        $self->verbose_message("creating default cgi script >$file<");
        $template->process(
            "Generator/Environment/index.pl.tpl",
            { this => $self },
            $file,
        ) or throw($template->error());
    }
    else {
        print STDERR "won't create >$file< - file already exists. use param force to overwrite\n";
    }

    # server.pl
    $file = "$base_path/bin/$lc_path/server.pl";
    if ( $self->get_force() || ! -e $file ) {
        $self->verbose_message("creating default server >$file<");
        $template->process(
            "Generator/Environment/server.pl.tpl",
            { this => $self },
            $file,
        ) or throw($template->error());
    }
    else {
        print STDERR "won't create >$file< - file already exists. use param force to overwrite\n";
    }


    return $self;
}

1;

__END__

=pod

=head1 NAME

Hyper::Developer::Generator::Environment - class for generating a Hyper Environment

=head1 VERSION

This document describes Hyper::Developer::Generator::Environment 0.01

=head1 SYNOPSIS

    use Hyper::Developer::Generator::Environment;
    my $object = Hyper::Developer::Generator::Environment->new({
        base_path => '/srv/web/www.example.com/',
        namespace => 'Example',
    });
    $object->create();

=head1 DESCRIPTION

Used to create the initial environment for a Hyper Based Web Application.

=head1 SUBROUTINES/METHODS

=head2 create

    $object->create();

Creates the following folders:

    PATH                                      USED FOR
    ------------------------------------------------------
    $BASE_PATH/var/$NAMESPACE                 templates
    $BASE_PATH/etc/$NAMESPACE                 config files
    $BASE_PATH/cgi-bin/$LOWER_CASE_NAMESPACE  CGI binarys
    $BASE_PATH/htdocs/$LOWER_CASE_NAMESPACE   static files

And creates the following files:

=over

=item $BASE_PATH/var/$LOWER_CASE_NAMESPACE/index.pl

The CGI Script which is used for calling Hyper Applications.

So a sample URL to start a usecase of a service in the
namespace >Example< could look like:

http://www.example.com/cgi-bin/example/index.pl?service=Test&usecase=Test

=item $BASE_PATH/etc/$NAMESPACE/Context.ini

Initial Context.ini with global configuration items.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item *

version

=item *

Hyper::Developer::Generator

=item *

Class::Std

=item *

File::Path

=item *

Hyper::Functions

=item *

Hyper::Error

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 RCS INFORMATIONS

=over

=item Last changed by

$Author: ac0v $

=item Id

$Id: Environment.pm 333 2008-02-18 22:59:27Z ac0v $

=item Revision

$Revision: 333 $

=item Date

$Date: 2008-02-18 23:59:27 +0100 (Mon, 18 Feb 2008) $

=item HeadURL

$HeadURL: http://svn.hyper-framework.org/Hyper/Hyper-Developer/branches/0.07/lib/Hyper/Developer/Generator/Environment.pm $

=back

=head1 AUTHOR

Andreas Specht  C<< <ACID@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Andreas Specht C<< <ACID@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
