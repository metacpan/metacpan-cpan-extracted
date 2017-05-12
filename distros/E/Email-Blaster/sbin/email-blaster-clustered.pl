#!/usr/bin/perl -w

use strict;
use warnings 'all';
use forks;
use Email::Blaster::Clustered;
use Email::Blaster::Transmission;
use My::TransmissionInitHandler;


my $blaster = Email::Blaster::Clustered->new( );

$blaster->handle_event( type => 'server_startup' );

my $main = threads->create(sub {
  local $SIG{INT} = $SIG{TERM} = sub {
    # Quitting:
    warn "Bulk Server shutting down...\n";
    $blaster->handle_event( type => 'server_shutdown' );
    exit;
  };
  
  $blaster->run( );
});

$main->join();

__END__

=pod

=head1 NAME

email-blaster-clustered.pl - Clustered email blaster.

=head1 DESCRIPTION

After following the steps for Setup (L<Email::Blaster::Manual::Setup>), just run the email blaster from the command-line.

Unless you really want to watch its output scroll slowly by, it is recommended that
you use the C<nohup> tool (Linux/Unix only).

Example:

  % nohup email-blaster-clustered.pl &

This will cause all output to be appended to C<nohup.out> in your current working directory.

=head1 SUPPORT

Visit L<http://www.devstack.com/contact/> or email the author at <jdrago_999@yahoo.com>

Commercial support and installation is available.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>
 
=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by John Drago

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

