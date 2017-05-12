package Memcached::Client::Protocol::Text;
BEGIN {
  $Memcached::Client::Protocol::Text::VERSION = '2.01';
}
# ABSTRACT: Implements original text-based memcached protocol

use strict;
use warnings;
use Memcached::Client::Log qw{DEBUG LOG};
use base qw{Memcached::Client::Protocol};

sub __cmd {
    return join (' ', grep {defined} @_) . "\r\n";
}

sub __connect {
    my ($self, $c, $r) = @_;
    $self->rlog ($c, $r, "Connected") if DEBUG;
    $r->result (1);
    $c->complete;
}

sub __add {
    my ($self, $c, $r) = @_;
    my ($data, $flags) = $self->encode ($r->{command}, $r->{value});
    my $command = __cmd ($r->{command}, $r->{nskey}, $flags, $r->{expiration}, length $data) . __cmd ($data);
    $self->rlog ($c, $r, $command) if DEBUG;
    $c->{handle}->push_write ($command);
    $c->{handle}->push_read (line => sub {
                                 my ($handle, $line) = @_;
                                 $r->result ($line eq 'STORED' ? 1 : 0);
                                 $c->complete;
                             });
}

sub __decr {
    my ($self, $c, $r) = @_;
    my $command = __cmd ($r->{command}, $r->{nskey}, $r->{delta});
    $self->rlog ($c, $r, $command) if DEBUG;
    $c->{handle}->push_write ($command);
    $c->{handle}->push_read (line => sub {
                                 my ($handle, $line) = @_;
                                 if ($line eq 'NOT_FOUND') {
                                     if ($r->{data}) {
                                            $command = __cmd (add => $r->{nskey}, 0, 0, length $r->{data}) . __cmd ($r->{data});
                                            $c->{handle}->push_write ($command);
                                            $c->{handle}->push_read (line => sub {
                                                                    my ($handle, $line) = @_;
                                                                    $r->result ($line eq 'STORED' ? $r->{data} : undef);
                                                                    $c->complete;
                                                                });
                                     } else {
                                         $r->result;
                                         $c->complete
                                     }
                                 } else {
                                     $r->result ($line);
                                     $c->complete;
                                 }
                             });
}

sub __delete {
    my ($self, $c, $r) = @_;
    my $command = __cmd (delete => $r->{nskey});
    $self->rlog ($c, $r, $command) if DEBUG;
    $c->{handle}->push_write ($command);
    $c->{handle}->push_read (line => sub {
                                 my ($handle, $line) = @_;
                                 $r->result ($line eq 'DELETED' ? 1 : 0);
                                 $c->complete;
                             });
}

sub __flush_all {
    my ($self, $c, $r) = @_;
    my $command = $r->{delay} ? __cmd (flush_all => $r->{delay}) : __cmd ("flush_all");
    $self->rlog ($c, $r, $command) if DEBUG;
    $c->{handle}->push_write ($command);
    $c->{handle}->push_read (line => sub {
                                 my ($handle, $line) = @_;
                                 $r->result (1);
                                 $c->complete;
                             });
}

sub __get {
    my ($self, $c, $r) = @_;
    my $command = __cmd (get => $r->{nskey});
    $self->rlog ($c, $r, $command) if DEBUG;
    $c->{handle}->push_write ($command);
    $c->{handle}->push_read (line => sub {
                                 my ($handle, $line) = @_;
                                 $self->log ("Got line %s", $line) if DEBUG;
                                 my @bits = split /\s+/, $line;
                                 if ($bits[0] eq "VALUE") {
                                     my ($key, $flags, $size, $cas) = @bits[1..4];
                                     $c->{handle}->unshift_read (chunk => $size, sub {
                                                                my ($handle, $data) = @_;
                                                                # Catch the \r\n trailing the value...
                                                                $c->{handle}->unshift_read (line => sub {
                                                                                           my ($handle, $line) = @_;
                                                                                           $c->{handle}->unshift_read (line => sub {
                                                                                                                      my ($handle, $line) = @_;
                                                                                                                      warn ("Unexpected result $line from $command") unless ($line eq 'END');
                                                                                                                      $r->result ($self->decode ($data, $flags));
                                                                                                                      $c->complete;
                                                                                                                  });
                                                                                       });
                                                            });
                                 } elsif ($bits[0] eq "END") {
                                     $r->result;
                                     $c->complete;
                                 }
                             });
}

sub __stats {
    my ($self, $c, $r) = @_;
    my $command = $r->{command} ? __cmd (stats => $r->{command}) : __cmd ("stats");
    $self->rlog ($c, $r, $command) if DEBUG;
    $c->{handle}->push_write ($command);
    my ($code, $result);
    $code = sub {
        my ($handle, $line) = @_;
        my @bits = split /\s+/, $line;
        if ($bits[0] eq 'STAT') {
            $result->{$bits[1]} = $bits[2];
            $c->{handle}->push_read (line => $code);
        } else {
            warn ("Unexpected result $line from $command") unless ($bits[0] eq 'END');
            undef $code;
            $r->result ($result);
            $c->complete;
        }
    };
    $c->{handle}->push_read (line => $code);
}

sub __version {
    my ($self, $c, $r) = @_;
    my $command = __cmd ("version");
    $self->rlog ($c, $r, $command) if DEBUG;
    $c->{handle}->push_write ($command);
    $c->{handle}->push_read (line => sub {
                                 my ($handle, $line) = @_;
                                 my @bits = split /\s+/, $line;
                                 if ($bits[0] eq 'VERSION') {
                                     $r->result ($bits[1]);
                                 } else {
                                     warn ("Unexpected result $line from $command");
                                 }
                                 $c->complete;
                             });
}

1;

__END__
=pod

=head1 NAME

Memcached::Client::Protocol::Text - Implements original text-based memcached protocol

=head1 VERSION

version 2.01

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

