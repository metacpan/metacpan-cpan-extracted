package Linux::Systemd::Daemon 1.201600;

# ABSTRACT: Systemd daemon API

use v5.16;
use strictures 2;
use Exporter 'import';
use XSLoader;

our @EXPORT = qw/sd_notify/;
our @EXPORT_OK =
  qw/sd_notify sd_ready sd_stopping sd_reloading sd_status sd_watchdog/;
our %EXPORT_TAGS =
  (all =>
      [qw/sd_notify sd_ready sd_stopping sd_reloading sd_status sd_watchdog/]);

XSLoader::load;


# TODO optimise by pushing this into the XS
# *sd_notify = \&Linux::Systemd::Daemon::notify;
sub sd_notify {
    my %hash = @_;
    my $str;
    for my $k (keys %hash) {
        $str .= uc($k) . "=$hash{$k}\n";
    }
    return notify($str);
}


sub sd_watchdog {
    return notify('WATCHDOG=1');
}


sub sd_ready {
    return notify('READY=1');
}


sub sd_stopping {
    return notify('STOPPING=1');
}


sub sd_reloading {
    return notify('RELOADING=1');
}


sub sd_status {
    my $status = shift;
    return notify("STATUS=$status");
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Linux::Systemd::Daemon - Systemd daemon API

=head1 VERSION

version 1.201600

=head1 SYNOPSIS

  use Linux::Systemd::Daemon 'sd_ready';

  # program initialisation
  sd_ready;

  while (1) {
      sd_notify(watchdog => 1, status => 'Main loop running');
      # do something here
  }

  sd_notify(stopping => 1, status => 'Shutting down...');

=head1 DESCRIPTION

An XS wrapper for L<sd-daemon|https://www.freedesktop.org/software/systemd/man/sd-daemon.html>,
the systemd daemon interface.

Exports one function, L</sd_notify>, by default. A variety of convenience
functions are also available for import, either individually or with the C<:all>
tag.

For a fully featured example, see the C<perl-daemon> script and
C<perl-daemon.service> examples in C<eg>.

=head1 FUNCTIONS

=head2 C<sd_notify(@array_of_pairs)>

The main function, exported by default. Takes a list of pairs and converts them
to a string to be passed to the C function
L<man:sd_notify(3)|https://www.freedesktop.org/software/systemd/man/sd_notify.html>

e.g.

  sd_notify(ready => 1, status => 'Processing requests');

=head2 C<sd_watchdog()>

Convenience function. Optional export.

=head2 C<sd_ready()>

Convenience function. Optional export.

=head2 C<sd_stopping()>

Convenience function. Optional export.

=head2 C<sd_reloading()>

Convenience function. Optional export.

=head2 C<sd_status(Str $status_message)>

Convenience function. Optional export.

=head1 SEE ALSO

https://www.freedesktop.org/software/systemd/man/sd-daemon.html

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ioan Rogers.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
