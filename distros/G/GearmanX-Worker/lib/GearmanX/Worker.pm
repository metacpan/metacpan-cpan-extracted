package GearmanX::Worker;

use warnings;
use strict;

use Attribute::Handlers;
use Data::Dumper;

=head1 NAME

GearmanX::Worker - Working class for the Gearmand job server

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    #-- define a class for your workers:
    package MyWorker;
    use base qw(GearmanX::Worker);

    sub echo  :Expose  {
	my $param = shift;
        # ... compute something
        return $result;
    }

    1;

    #-- in the meantime in the worker server
    my $w = new MyWorker;
    $w->run_as_thread;

    #-- or alternatively
    $w->run; # block here

    # somewhere else in a gearman client
    use GearmanX::Client;
    my $c = new GearmanX::Client;
    my $r = $c->job ('echo', '1+2');

=head1 DESCRIPTION

This class implements the necessary infrastructure to comfortably write a gearman
(L<http://www.gearman.org/>) server. Instead of messing around with a task object where you get your
arguments, you simply derive a subclass of L<GearmanX::Worker> and define some methods (subs
actually) which can handle certain gearman jobs. For that you mark these methods with an
attribute C<Expose>.

=head2 Parameter Handling

Every job handler receives exactly one parameter. That can be a scalar, a list reference or a hash
reference. This is the data sent from the client, which may use L<GearmanX::Client>.

=head2 Result Handling

Every job handler is supposed to return a result. That should be a scalar, a list reference or a
hash reference. This data will be sent back to the client.

=head2 Owning the Protocol

As the gearman system only allows strings to be passed between clients and workers, there is a
special encoding for list and hash references. See the implementation for details.


=head1 INTERFACE

=head2 Constructor

The constructor expects the following fields:

=over

=item C<SERVERS> (optional, default: C<127.0.0.1>)

This field controls where the jobs servers are.

=back

=cut

my %exposed;
    
sub _register {
    my $self = shift;
    
    foreach my $ref (keys %{$self->{exposes}}) {
	next unless $self->{exposes}->{$ref}->{name};                                  # nonames we do not like
	$self->{worker}->register_function ( 
	    $self->{exposes}->{$ref}->{name} => $self->{exposes}->{$ref}->{'exec'}
	    );
    }
}

sub new {
    my $class = shift;
    my $exposes = $exposed{$class};                                                     # TODO die if empty
    my %options = @_;
    $options{SERVERS} ||= "127.0.0.1" ;
    return bless { exposes => $exposes, %options }, $class;
}

=head2 Attributes

=over

=item B<Expose>

With this attribute you signal to the constructor that you intent a certain method to be exposed to
the gearman systems as a job handler. At constructor time of your worker this method will be
registered with the gearman server.

=cut

sub Expose :ATTR {
    my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;
    my $name;
    $name ||= shift @$data if ref($data) eq 'ARRAY';
    $name ||= *{$symbol}{NAME};                                                         # fall back to name of routine

    $exposed{$package}->{"$referent"}->{'name'} ||= $name;
    $exposed{$package}->{"$referent"}->{'exec'} ||= sub {
	my $task = $_[0];
	my $s = $task->arg;
#	warn "in default stub arg ".Dumper $s;

	use GearmanX::Serialization;
	my $p = GearmanX::Serialization::_deserialize (\ $s);
#	warn "before referent ".Dumper $p;
	my $r = &$referent ($p);
#	warn "after referent ".Dumper $r;
	$s = GearmanX::Serialization::_serialize ($r);
#	warn "after serializ ".Dumper $s;

	return \ $s;
    };
}

=pod

=back

=head2 Methods

=over

=item B<run>

This starts the worker and blocks there. This method will never terminate. Well, unless the world
explodes.

=cut

sub run {
    my $self = shift;
#    warn "in run self $self". Dumper $self->{SERVERS};
    use Gearman::Worker;
    $self->{worker} = Gearman::Worker->new;
    $self->{worker}->job_servers( $self->{SERVERS} );
    $self->_register;
#    warn "WORKER starting worker\n";
    
    $self->{worker}->work while (1);
#    warn "WORKER ending worker\n";
}

=item B<run_as_thread>

This method launches a thread and detaches it. It will not block and returns the thread object.

=cut


sub run_as_thread {
    my $self = shift;
    
    use threads;
    my $thr = threads->new (\&run, $self);
    $thr->detach;
    return $thr;
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gearmanx-worker at rt.cpan.org>, or through the
web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GearmanX-Worker>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

"against all gods";

__END__



sub storable :ATTR {
    warn "storable data ".Dumper \@_;
    my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;
    $data ||= [ ];
    warn Dumper $data;
    my $in_storable  = grep { $_ eq 'in'  } @$data;
    my $out_storable = grep { $_ eq 'out' } @$data;

    $exposed{$package}->{"$referent"}->{'exec'} = sub {
	warn "before xxxx ".Dumper \@_;
	my $task = $_[0];
	my $s;
	if ($in_storable) {
	    warn "taking care of in storable";
	    use Storable qw(thaw);
	    $s = thaw $task->arg;
	} else {
	    $s = $task->arg;
	}

	warn "before return ".Dumper $s;
	return \ $s;
    }
}



