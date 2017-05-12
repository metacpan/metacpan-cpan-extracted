package Mail::Builder::Simple::TT;

use strict;
use warnings;
use Template;
use Cwd;
use Exception::Died;

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
    $args->{INCLUDE_PATH} ||= q{.};
    $args->{ENCODING}     ||= 'utf8';

    my $t = Template->new($args);

    my $output = q{};
    if ( $source eq 'file' ) {
        $t->process( $template, $self->{template_vars}, \$output )
          || Exception::Died->throw( $t->error );
    }
    elsif ( $source eq 'scalar' ) {
        $t->process( \$template, $self->{template_vars}, \$output )
          || Exception::Died->throw( $t->error );
    }

    return $output;
}

1;

__END__

=head1 NAME

Mail::Builder::Simple::TT - Template-Toolkit plugin for Mail::Builder::Simple

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

 my $template = Mail::Builder::Simple::TT->new($args, $vars);
 $template->process($template, $source);

=head1 DESCRIPTION

This module shouldn't be used directly, but as a plugin of L<Mail::Builder::Simple|Mail::Builder::Simple> for sending email messages with the body or the attachments created using L<Template-Toolkit|Template>.

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

L<Template-Toolkit|Template>, L<Cwd|Cwd>, L<Exception::Died|Exception::Died>

=head1 INCOMPATIBILITIES

Not known incompatibilities.

=head1 BUGS AND LIMITATIONS

Not known bugs. If you find some, please announce.

=head1 SEE ALSO

L<Mail::Builder::Simple|Mail::Builder::Simple>, L<Template-Toolkit|Template>

=head1 AUTHOR

Octavian Rasnita <orasnita@gmail.com>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
