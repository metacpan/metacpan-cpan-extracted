package Eidolon::Driver::Template::Toolkit;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Template/Toolkit.pm - Template Toolkit driver
#
# ==============================================================================

use base qw/Eidolon::Driver::Template/;
use Template;
use warnings;
use strict;

our $VERSION = "0.01"; # 2009-05-22 02:33:02

# ------------------------------------------------------------------------------
# \% new($templates_dir, $additional)
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $templates_dir, $additional, $self);

    ($class, $templates_dir, $additional) = @_;

    $self = $class->SUPER::new($templates_dir);
    $self->{"additional"} = $additional || {};

    return $self;
}

# ------------------------------------------------------------------------------
# parse($tpl)
# parse template
# ------------------------------------------------------------------------------
sub parse
{
    my ($self, $tpl) = @_;

    throw DriverError::Template::Open($tpl) if (!-f $self->{"templates_dir"}.$tpl);

    # create object
    $self->{"object"} = Template->new
    (
        "INCLUDE_PATH" => $self->{"templates_dir"},
        %{ $self->{"additional"} }
    );

    $self->{"object"}->process($tpl, $self->{"vars"}, \$self->{"result"});
}

# ------------------------------------------------------------------------------
# render()
# render template
# ------------------------------------------------------------------------------
sub render
{
    my $self = shift;

    throw DriverError::Template::NotParsed if (!$self->{"object"});

    print $self->{"result"};
}

1;

__END__

=head1 NAME

Eidolon::Driver::Template::Toolkit - Eidolon Template::Toolkit driver.

=head1 SYNOPSIS

Somewhere in application controller:

    my ($r, $tpl);

    $r   = Eidolon::Core::Registry->get_instance;
    $tpl = $r->loader->get_object("Eidolon::Driver::Template::Toolkit");

    $tpl->set
    (
        "TITLE"   => "Example",
        "CONTENT" => "Lorem ipsum dolor sit amet"
    );

    $r->cgi->send_header;
    $tpl->parse("index.tpl");
    $tpl->render;

=head1 DESCRIPTION

The I<Eidolon::Driver::Template::Toolkit> is a template driver for 
I<Eidolon>. It is based on famous L<Template::Toolkit> 
package, that provides a lot of tasty functions for separating code and markup.

To use this driver you must have L<Template> package installed.

=head1 METHODS

=head2 new($templates_dir, $additional)

Class constructor. C<$templates_dir> - directory with templates, C<$additional> 
- hash reference with additional options for Template::Toolkit.

=head2 set(%vars)

Inherited from
L<Eidolon::Driver::Template/set(%vars)>.

=head2 parse($tpl)

Implementation of abstract method from 
L<Eidolon::Driver::Template/parse($tpl)>.

=head2 render()

Implementation of abstract method from
L<Eidolon::Driver::Template/render()>.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Driver::Template>, L<Template>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
