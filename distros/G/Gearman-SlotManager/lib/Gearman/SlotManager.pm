package Gearman::SlotManager;
# ABSTRACT: Managing Worker's lifecycle with Slots
our $VERSION = '0.3'; # VERSION
use namespace::autoclean;
use Devel::GlobalDestruction;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
Log::Log4perl->easy_init($ERROR);
use Data::Dumper;
use Any::Moose;

use AnyEvent;
use AnyEvent::HTTPD;
use Scalar::Util qw(weaken);

use Gearman::Slot;
has slotmap=>(is=>'rw', isa=>'HashRef', default=>sub{ return {}; });
has config=>(is=>'rw', isa=>'HashRef',required=>1);
has idle_watcher=>(is=>'rw');
has httpd=>(is=>'rw');
has port=>(is=>'rw',default=>sub{return 55995;});
sub BUILD{
    my $self = shift;

    my $conf = $self->config;
    my %global = %{$conf->{'global'}};
    my %baseconf = (
        job_servers=>[''],
        min=>1,
        max=>1,
        workleft=>0,
    );
    %global = (%baseconf,%global);
    
    my %confs = %{$conf->{slots}};
    foreach my $worker (keys %confs){
        my %conf = %{$confs{$worker}};

        %conf = (%global,%conf);
        DEBUG Dumper(\%conf);

        my @slots;
        foreach (0 .. $conf{max}-1){
            my $slot = Gearman::Slot->new(
                job_servers=>$conf{job_servers},
                libs=>$conf{libs},
                workleft=>$conf{workleft},
                worker_package=>$worker,
                worker_channel=>$worker.'__'.$_,
                sbbaseurl=>'http://localhost:'.$self->port,
            );
            push( @slots, $slot);
        }
        $self->slotmap->{$worker} = {conf=>\%conf, slots=>\@slots};
    }

    my $httpd = AnyEvent::HTTPD->new(port=>$self->port);
    $httpd->reg_cb (
        '/busy'=>sub{
            my ($httpd,$req) = @_;
            DEBUG "SB busy ".$req->parm('channel');
            my ($key,$idx) = split(/__/,$req->parm('channel'));
            DEBUG "SB busy $key $idx";
            $self->slots($key)->[$idx]->is_busy(1);
            $req->respond({content=>['text/plain','ok']});
        },
        '/idle'=>sub{
            my ($httpd,$req) = @_;
            DEBUG "SB idle ".$req->parm('channel');
            my ($key,$idx) = split(/__/,$req->parm('channel'));
            DEBUG "SB idle $key $idx";
            $self->slots($key)->[$idx]->is_busy(0);
            $req->respond({content=>['text/plain','ok']});
        },
    );
    $self->httpd($httpd);
    weaken($self);
}

sub slots{
    my $self = shift;
    my $key = shift;
    return $self->slotmap->{$key}->{slots};
}

sub conf{
    my $self = shift;
    my $key = shift;
    return $self->slotmap->{$key}->{conf};
}

sub start{
    DEBUG __PACKAGE__." start";
    my $self = shift;
    foreach my $key (keys %{$self->slotmap}){
        my $slots = $self->slots($key);
        my $conf = $self->conf($key);
        my $min = $conf->{min};
        foreach my $i ( 0 .. $min-1 ){
            $slots->[$i]->start();
        }
    }
    my $iw = AE::timer 0,5, sub{$self->on_idle;};
    $self->idle_watcher($iw);
    #weaken($self);
}

sub on_idle{
    my $self = shift;
    DEBUG "ON_IDLE";
    foreach my $key (keys %{$self->slotmap}){
        my @slots = @{$self->slots($key)};
        my %conf = %{$self->conf($key)};
        my $idle = 0;
        my $running = 0;
        foreach my $s ( @slots ){
            $idle += $s->is_idle;
            $running += $s->is_running;
        }
        DEBUG "[$key] idle: $idle, running: $running";
        if( !$idle ){
            if( $running < $conf{max} ){
                DEBUG "expand $key";
                my @stopped = grep{$_->is_stopped}@slots;
                shift(@stopped)->start;
            }
        }
        else{
            if( $running > $conf{min} ){
                DEBUG "reduce $key";
                my @running = grep{$_->is_running}@slots;
                pop(@running)->stop;
            }
        }
    }

}

sub stop{
    DEBUG __PACKAGE__." stop";
    my $self = shift;
    $self->idle_watcher(undef);
    foreach my $key (keys %{$self->slotmap}){
        my $slots = $self->slots($key);
        foreach my $s ( @{$slots} ){
            $s->stop() unless $s->is_stopped;
        }
    }
}

sub DEMOLISH{
    return if in_global_destruction;
    DEBUG __PACKAGE__.' DEMOLISHED';
    
}

__PACKAGE__->meta->make_immutable;
1;


=pod

=head1 NAME

Gearman::SlotManager - Managing Worker's lifecycle with Slots

=head1 VERSION

version 0.3

=head1 SYNOPSIS

Will be updated soon.

See testManager.pl in Gearman::SlotManager directory.

=head1 AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

