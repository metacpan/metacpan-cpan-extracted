package GlbDNS;

use 5.008008;
use strict;
use warnings;
our $VERSION = '0.30';
use Net::DNS::Nameserver;
use Data::Dumper;
use threads;
use threads::shared;
use LWP::Simple;
use List::Util qw(sum);
my %status : shared;
my %stats : shared;
use Geo::IP;
my %counters : shared;

use GlbDNS::Resolver::Base;
use GlbDNS::Resolver::ShowServer;
use GlbDNS::Resolver::ShowLocation;
#to enable testing
our %TEST = ( noadmin => 0,
              nosocket => 0
    );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my $daemon = shift;
    $self->{name} = $daemon->name;

    $self->{dns} = Net::DNS::Nameserver->new(
        Verbose => $main::config{debug} || 0,
        LocalAddr => $daemon->options->{address},
        LocalPort => $daemon->options->{port},
        ReplyHandler => sub { $self->request(@_) },
        ) unless ($TEST{nosocket});

    #threads->create(sub { while(1) { sleep 60; print Dumper(\%counters) } });
    threads->create(\&admin) unless ($TEST{noadmin});

    $self->{resolver_hook} = [
	GlbDNS::Resolver::ShowLocation->new(),
	GlbDNS::Resolver::ShowServer->new(),
	GlbDNS::Resolver::Base->new(),
	];
    return $self;
}

sub admin {
    my $sock = IO::Socket::INET->new
        (Listen    => 5,
         LocalAddr => 'localhost',
         LocalPort => 9000,
         Proto     => 'tcp',
         Reuse     => 1
        );
    while(my $connection = $sock->accept) {
        $connection->print(Dumper \%counters);
        $connection->print(Dumper \%status);
        close($connection);
    }
}

sub check_service {

    my ($ip, $url, $expect, $interval) = @_;
    $url =~s/^\///;
    while(1) {
        my $foo = get("http://$ip/$url");
        if ($foo && $foo =~/$expect/) {
            $status{$ip} = $status{$ip} + 1;
        } else {
            $status{$ip} = 0;
        }
        sleep $interval;
    }
}

sub start {
    my $self = shift;
    $0 = "$self->{name} worker - waiting for status checks before accepting requests";
    while(keys %status && sum(values %status) == 0) {
        sleep 1;
    }
    $0 = "$self->{name} worker - accepting requests";

    foreach my $check (values %{$self->{checks}}) {
        $status{$check->{ip}} = 0;
        threads->create('check_service', $check->{ip}, $check->{url}, $check->{expect}, ($check->{interval} || 5));
    }

    $self->{dns}->main_loop;
}


sub request {
    my $self = shift;
    $counters{Request}++;
    foreach my $hook (@{$self->{resolver_hook}}) {
	if (my @answer = $hook->request($self, @_)) {
	    return @answer;
	}
    }
}


sub get_host {
    my $self = shift;
    my $qname = shift;
    my @query = split(/\./, $qname);
    while(@query) {
        my $test_domain = join (".", @query);
        if($self->{hosts}->{$test_domain}) {
            return $self->{hosts}->{$test_domain};
        }
        shift @query;
    }
    return;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

GlbDNS - Perl daemon for global load balancing

=head1 SYNOPSIS
 
 perl -Mblib  bin/glbdns.pl --help


=head1 DESCRIPTION

GlbDNS is a global load balancing DNS server. Partly inspired
by pgeodns -- it differs in that it uses the absolute position
of the DNS server to calculate which site is closest. All
other opensource servers I could find uses country level.
This doesn't work in the US. It also uses real zone files.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Artur Bergman, E<lt>sky-cpan@crucially.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009 by Artur Bergman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
