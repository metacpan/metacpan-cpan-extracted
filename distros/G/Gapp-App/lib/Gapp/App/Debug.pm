package Gapp::App::Debug;
{
  $Gapp::App::Debug::VERSION = '0.222';
}

use Moose;
use Sub::Exporter;

our $DEBUG = 0;

use DateTime;

Sub::Exporter::setup_exporter({
    exports => [qw( debug )],
    groups  => { all => [qw( debug )] }
});


sub debug {
    my ( $message, $opts ) = @_;
    $opts ||= {};
    
    # only if we are set to debug
    if ( $opts->{debug} || $DEBUG || $ENV{DEBUG}  ) {
        
        print q([D]  ), $message, qq[\n];
        
    }
}

1;

__END__

=pod

=head1 NAME

Gapp::App::Debug - Application debugging utility

=head1 DESCRIPTION

Provides utility functions for debugging Gapp applications.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<debug $message, \%options >

Use in your code to send debugging message. If $options->{debug}, $Gapp::App::DEBUG, or
$ENV{DEBUG} are true, this message will be displayed in the console.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2012 Jeffrey Ray Hallock.
    
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.
    
=cut

