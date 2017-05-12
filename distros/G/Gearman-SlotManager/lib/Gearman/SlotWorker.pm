package Gearman::SlotWorker;
use namespace::autoclean;

# ABSTRACT: A worker launched by Slot

our $VERSION = '0.3'; # VERSION
use Devel::GlobalDestruction;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
Log::Log4perl->easy_init($ERROR);

use Any::Moose;
use Gearman::Worker;
use Scalar::Util qw(weaken);
use LWP::Simple;

# options
has job_servers=>(is=>'rw',isa=>'ArrayRef', required=>1);
has channel=>(is=>'rw',required=>1);
has workleft=>(is=>'rw',isa=>'Int', default=>-1);

# internal
has exported=>(is=>'ro',isa=>'ArrayRef[Class::MOP::Method]', default=>sub{[]});
has worker=>(is=>'rw');

has is_stopped=>(is=>'rw');
has is_busy=>(is=>'rw');

has sbbaseurl=>(is=>'rw',default=>sub{''});

sub BUILD{
    my $self = shift;
    # register
    my $meta = $self->meta();
    my $package = $meta->{package};
    my $exported = $self->exported();

    if( $self->workleft == 0 ){
        $self->workleft(-1);
    }

    for my $method ( $meta->get_all_methods) 
    {
        my $packname = $method->package_name;
        next if( $packname eq __PACKAGE__ ); # skip base class

        my $methname = $method->name;
        if( $packname eq $package )
        {
            if( $methname !~ /^_/ && $methname ne uc($methname) && $methname ne 'meta' )
            {
                if( !$meta->has_attribute($methname) ){
                    DEBUG 'filtered: '.$method->fully_qualified_name;
                    push(@{$exported},$method);
                }
            }
        }
    }
    
    $self->register();
    weaken($self);
}

sub report{
    my $self = shift;
    my $msg = lc(shift);
    if($self->sbbaseurl){
        DEBUG "report $msg ".$self->channel;
        get($self->sbbaseurl.'/'.$msg.'?channel='.$self->channel);
    }
}

sub unregister{
    my $self = shift;
    foreach my $m (@{$self->exported}){
        my $fname = $m->fully_qualified_name;
        $self->worker->unregister_function($fname);
    }
    $self->worker(undef);
}

sub register{
    my $self = shift;
    my $w = Gearman::Worker->new;
    $w->job_servers(@{$self->job_servers});
    foreach my $m (@{$self->exported}){
        DEBUG "register ".$m->fully_qualified_name;
        my $fname = $m->fully_qualified_name;
        my $fcode = $m->body;
        $w->register_function($fname =>
            sub{
                my $job = shift;
                my $workload = $job->arg;

                DEBUG "[$fname] '$workload' workleft:".$self->workleft;
                $self->report('BUSY');
                $self->is_busy(1);
                my $res;
                eval{
                    $res = $fcode->($self,$workload);
                };
                if ($@){
                    ERROR $@;
                    return;
                }

                $self->report('IDLE');
                $self->is_busy(0);

                if( $self->workleft > 0 ){
                    $self->workleft($self->workleft-1);
                }
                if( $self->is_stopped ){
                    $self->stop_safe('stopped');
                }
                if( $self->workleft == 0 ){
                    $self->stop_safe('overworked');
                }


                return $res;
            }
        );
    }
    $self->worker($w);
    #weaken($w);
    weaken($self);
}

sub work{
    my $self = shift;
    $self->worker->work(stop_if=>sub{ $self->is_stopped } );
    DEBUG "stop completely";
}

sub stop_safe{
    my $self = shift;
    my $msg = shift;
    $self->is_stopped(1);
    $self->unregister;
    $self->worker(undef);
    DEBUG "stop_safe $msg";
}

sub DEMOLISH{
    return if in_global_destruction;
    my $self = shift;
    $self->unregister() if $self->worker;
    DEBUG __PACKAGE__." DEMOLISHED";
}

# class member
sub Loop{

    my $class = shift;
    die 'Use like PACKAGE->Loop(%opts).' unless $class;
    die 'You need to use your own class extending '. __PACKAGE__ .'!' if $class eq __PACKAGE__;
    my %opt = @_;

    my $worker;
    $SIG{INT} = sub{
        $worker->stop_safe('SIGINT');
        exit;
    };


    eval{
        $worker = $class->new(%opt);
    };
    die $@ if($@);

    $worker->work();

}

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

Gearman::SlotWorker - A worker launched by Slot

=head1 VERSION

version 0.3

=head1 SYNOPSIS

make TestWorker.pm

    package TestWorker;
    use Any::Moose;
    extends 'Gearman::SlotWorker';

    sub reverse{ # will be registered as function 'TestWorker::reverse'
        my $self = shift;
        my $data = shift;
        return reverse($data);
    }

    sub _private{  # not care leading '_'
        my $self = shift;
        my $data = shift;
        return $data;
    }

    sub NOTVISIBLE{ # not care all-uppercase
        #...
    }

You can see only 'reverse'

=head1 AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


