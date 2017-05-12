package Mail::Builder::Simple::HTML::Template;

use strict;
use warnings;
use HTML::Template;

use 5.008_008;

our $VERSION = '0.03';

sub new {
    my ( $class, $args, $vars ) = @_;

    my $self = {
        template_args => $args,
        template_vars => $vars,
    };

    return bless $self, $class;
}

sub process {
    my ( $self, $template, $source ) = @_;

    my $args = $self->{template_args};
    $args->{path}     ||= q{.};
    $args->{ENCODING} ||= 'utf8';
    $args->{die_on_bad_params} = ($args->{die_on_bad_params}
      and $args->{die_on_bad_params} eq 'yes') ? 1 : 0;

    my $t;
    if ( $source eq 'file' ) {
        $t = HTML::Template->new( filename => $template, %{$args} );
    }
    elsif ( $source eq 'scalar' ) {
        $t = HTML::Template->new( scalarref => \$template, %{$args} );
    }

    $t->param( %{ $self->{template_vars} } );

    return $t->output;
}

1;

__END__

=head1 NAME

Mail::Builder::Simple::HTML::Template - H::T plugin for Mail::Builder::Simple

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

 my $template = Mail::Builder::Simple::HTML::Template->new($args, $vars);
 $template->process($template, $source);

=head1 DESCRIPTION

This module shouldn't be used directly, but as a plugin of L<Mail::Builder::Simple|Mail::Builder::Simple> for sending email messages with the body or the attachments created using L<HTML::Template|HTML::Template>.

=head1 SUBROUTINES/METHODS

=head2 new

C<new()> is the class constructor. It accepts 2 parameters: $args and $vars.

$args is a hashref with the options for TT. $vars is the hashref with the template variables.

=head2 process

C<process()> processes the template. It accepts 2 parameters: $template and $source.

$source can be either "file" or "scalar". If $source eq "file", $template is the name of the template file. If $source eq "scalar", $template is the scalar variable that contains the template.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

This module doesn't require any configuration.

=head1 DEPENDENCIES

L<HTML::Template|HTML::Template>

=head1 INCOMPATIBILITIES

Not known incompatibilities.

=head1 BUGS AND LIMITATIONS

Not known bugs. If you find some, please announce.

=head1 SEE ALSO

L<Mail::Builder::Simple|Mail::Builder::Simple>, L<HTML::Template|HTML::Template>

=head1 AUTHOR

Octavian Rasnita <orasnita@gmail.com>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
