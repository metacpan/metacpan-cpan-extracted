package Eidolon::Driver::Template::HTML;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Template/HTML.pm - HTML::Template driver
#
# ==============================================================================

use base qw/Eidolon::Driver::Template/;
use HTML::Template;
use warnings;
use strict;

our $VERSION = "0.01"; # 2008-07-20 05:10:45

# ------------------------------------------------------------------------------
# \% new()
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
    $self->{"object"} = HTML::Template->new
    (
        "filename"          => $tpl,
        "path"              => [ $self->{"templates_dir"} ],
        "die_on_bad_params" => 0,
        %{ $self->{"additional"} }
    );

    # set variables
    foreach (keys %{ $self->{"vars"} }) 
    {
        $self->{"object"}->param($_ => $self->{"vars"}->{$_});
    }

    $self->{"result"} = $self->{"object"}->output;
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

Eidolon::Driver::Template::HTML - Eidolon HTML::Template driver.

=head1 SYNOPSIS

Somewhere in application controller:

    my ($r, $tpl);

    $r   = Eidolon::Core::Registry->get_instance;
    $tpl = $r->loader->get_object("Eidolon::Driver::Template::HTML");

    $tpl->set
    (
        "TITLE"   => "Example",
        "CONTENT" => "Lorem ipsum dolor sit amet"
    );

    $r->cgi->send_header;
    $tpl->parse("index.tpl");
    $tpl->render;

=head1 DESCRIPTION

The I<Eidolon::Driver::Template::HTML> is a template driver for I<Eidolon>.
It is based on famous L<HTML::Template> package, that provides a lot of tasty 
functions for separating code and markup.

To use this driver you must have L<HTML::Template> package installed.

=head1 METHODS

=head2 new($templates_dir)

Inherited from L<Eidolon::Driver::Template/new($templates_dir)>.

=head2 set(%vars)

Inherited from L<Eidolon::Driver::Template/set(%vars)>.

=head2 parse($tpl)

Implementation of abstract method from L<Eidolon::Driver::Template/parse($tpl)>.

=head2 render()

Implementation of abstract method from L<Eidolon::Driver::Template/render()>.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Driver::Template>, L<HTML::Template>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
