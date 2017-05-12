package Hyper::Developer::Generator::Control;

use strict;
use warnings;
use version; our $VERSION = qv('0.01');

use base qw(Hyper::Developer::Generator);
use Class::Std;
use Hyper::Functions;
use File::Path ();
use Hyper::Error;

my %usecase_of  :ATTR(:name<usecase>);
my %service_of  :ATTR(:name<service>);

# spec for gen. target
my %type_of     :ATTR(:set<type>);
my %sub_path_of :ATTR(:set<sub_path>);
my %suffix_of   :ATTR(:set<suffix>);

sub create {
    my $self    = shift;
    my $arg_ref = shift || {}; # name, template, force, data
    my $ident   = ident $self;

    # $arg_ref->{name} => mandatory

    my $path = $self->get_base_path()
      . '/' . Hyper::Functions::get_path_for($type_of{$ident})
      . '/' . $self->get_namespace()
      . '/' . $sub_path_of{$ident}
      . '/' . $self->get_service();
    my $file = "$path/$arg_ref->{name}.$suffix_of{$ident}";

    # TODO modify to use IO::File->new( $file, O_CREAT | O_WRONLY | O_EXCL)
    # instead of "warn if -e $file";
    # open my $fh, $file if ( not (-e $file) )
    # is a race condition: If someone manages to put a file in place
    # between -e and open, we clobber an existing file...

    # return if file exists and force isn't set
    my $force = exists $arg_ref->{force}
        ? $arg_ref->{force}
        : $self->get_force();
    if ( ! $force && -e $file ) {
        warn "can't generate code, destination file >$file< exists";
        return $self;
    }

    File::Path::mkpath([$path], 0, 0770);

    my $template = $self->get_template();
    $template->process(
        $arg_ref->{template},
        { data => $arg_ref->{data},
          this => $self,
          name => $arg_ref->{name},
        },
        $file,
    ) or throw($template->error());

    return $self;
}

1;

__END__

=pod

=head1 NAME

Hyper::Developer::Generator::Control - abstract base class which offers
a special create method for Control generation.

=head1 VERSION

This document describes Hyper::Developer::Generator::Control 0.01

=head1 SYNOPSIS

    package Hyper::Developer::Generator::Control::ContainerFlow;
    use base qw(Hyper::Developer::Generator::Control);

    1;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=over

=item usecase  :name

=item service  :name

=item type     :set

=item sub_path :set

=item suffix   :set

=back

=pod

=head1 SUBROUTINES/METHODS

=head1 create

    $object->create({
        name     => 'filename_without_suffix', # MANDATORY
        template => '/template/to/use.tpl',
        force    => 'boolean value, overwrite existing file?'
        data     => {
            what => 'ever',
            passed => 'to template',
        },
    });

Calls the Hyper::Developer::Generator::create method with some special.
This method is only important for out code generator maintainers.

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

Hyper::Functions

=item *

File::Path

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

$Id: Control.pm 333 2008-02-18 22:59:27Z ac0v $

=item Revision

$Revision: 333 $

=item Date

$Date: 2008-02-18 23:59:27 +0100 (Mon, 18 Feb 2008) $

=item HeadURL

$HeadURL: http://svn.hyper-framework.org/Hyper/Hyper-Developer/branches/0.07/lib/Hyper/Developer/Generator/Control.pm $

=back

=head1 AUTHOR

Andreas Specht  C<< <ACID@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Andreas Specht C<< <ACID@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
