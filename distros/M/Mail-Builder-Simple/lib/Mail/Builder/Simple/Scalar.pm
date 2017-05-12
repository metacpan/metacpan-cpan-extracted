package Mail::Builder::Simple::Scalar;

use strict;
use warnings;
use Exception::Died;

use 5.008_008;

our $VERSION = '0.03';

sub new {
    return bless {}, shift;
}

sub process {
    my ( $self, $content ) = @_;
    return $content;
}

1;

__END__

=head1 NAME

Mail::Builder::Simple::Scalar - Plugin for Mail::Builder::Simple

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

 my $template = Mail::Builder::Simple::Scalar->new;
 $template->process($template);

=head1 DESCRIPTION

This module shouldn't be used directly, but as a plugin of L<Mail::Builder::Simple|Mail::Builder::Simple> for sending email messages with the body or the attachments created from a scalar variable.

This plugin module is usually used only for creating the attachments from a scalar variable, because the text and the HTML part of the email messages can be created directly without it.

=head1 SUBROUTINES/METHODS

=head2 new

C<new()> is the class constructor. It doesn't require any parameter.

=head2 process

C<process()> is the method that process the template.

It accepts a scalar value as a parameter which contains the body of the template.

=head1 SEE ALSO

L<Mail::Builder::Simple|Mail::Builder::Simple>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

This module doesn't require any configuration.

=head1 DEPENDENCIES

L<Exception::Died|Exception::Died>

=head1 INCOMPATIBILITIES

No known incompatibilities.

=head1 BUGS AND LIMITATIONS

Not known bugs. If you find some, please announce.

=head1 AUTHOR

Octavian Rasnita <orasnita@gmail.com>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
