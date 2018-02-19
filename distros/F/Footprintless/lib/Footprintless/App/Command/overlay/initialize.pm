use strict;
use warnings;

package Footprintless::App::Command::overlay::initialize;
$Footprintless::App::Command::overlay::initialize::VERSION = '1.27';
# ABSTRACT: cleans, then processes the overlay base and template files
# PODNAME: Footprintless::App::Command::overlay::initialize

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    $logger->info('Performing initialize...');
    $self->{overlay}->initialize();

    $logger->info('Done...');
}

sub usage_desc {
    return "fpl overlay OVERLAY_COORD initialize %o";
}

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    eval { $self->{overlay} = $self->{footprintless}->overlay( $self->{coordinate} ); };

    $self->usage_error("invalid coordinate [$self->{coordinate}]: $@") if ($@);
}

1;

__END__

=pod

=head1 NAME

Footprintless::App::Command::overlay::initialize - cleans, then processes the overlay base and template files

=head1 VERSION

version 1.27

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=back

=for Pod::Coverage execute usage_desc validate_args

=cut
