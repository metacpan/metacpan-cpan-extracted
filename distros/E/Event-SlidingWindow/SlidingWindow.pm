package Event::SlidingWindow ;

use strict ;
use Carp ;


$Event::SlidingWindow::VERSION = '0.05' ;


sub new {
	my $class = shift ;
	my $nb_buckets = int(shift) ;		# Number of buckets, i.e. window size
	my $bucket_size = int(shift) || 1 ; # Bucket size in seconds
	
	# Validate paramters...
	if ($nb_buckets <= 0){
		croak("nb_buckets must be an integer > 0") ;
	}
	
	my $this = {
		nb_buckets => $nb_buckets,
		bucket_size => $bucket_size,
		loop => [],
	} ;

	bless($this, $class) ;
	$this->_init() ;
	
	return $this ;
}


sub _init {
	my $this = shift ;
	my $now = shift || time() ;
	
	$this->{cur_ts} = $now ;
	for (my $i = 0 ; $i < $this->{nb_buckets} ; $i++){
		$this->{loop}->[$i] = 0 ;
	}
	$this->{cur_idx} = 0 ;
}


sub record_event {
	my $this = shift ;
	my $now = shift ;
	my $incr = shift || 1 ;
	
	$this->_update($now) ;
	$this->{loop}->[$this->{cur_idx}] += $incr ;
}


sub count_events {
	my $this = shift ;
	my $now = shift ;
	
	$this->_update($now) ;
	my $cnt = 0 ;
	foreach my $c (@{$this->{loop}}){
		$cnt += $c ;
	}
	
	return $cnt ;
}


# This method is responsible for keeping the loop in sync for
# from current time value.
sub _update {
	my $this = shift ;
	my $now = shift || time() ;

	my $interval = int(($now - $this->{cur_ts}) / $this->{bucket_size}) ;
	if (! $interval){
		return ;
	}
	if ($interval >= $this->{nb_buckets}){
		$this->_init($now) ;
		return ;
	}
	
	# Now we really have some work to do.
	for (my $i = 0 ; $i < $interval ; $i++){
		$this->{loop}->[($this->{cur_idx} + $i + 1) % $this->{nb_buckets}] = 0 ;
	}	
	$this->{cur_idx} = ($this->{cur_idx} + $interval) % $this->{nb_buckets} ;
	$this->{cur_ts} = $now ;
}


sub _dump {
	my $this = shift ;
	
	my @ret = () ;
	for (my $i = 0 ; $i < $this->{nb_buckets} ; $i++){
		push @ret, $this->{loop}->[($this->{cur_idx} + $i + 1) % $this->{nb_buckets}] ;
	}
	
	return \@ret ;
}


1 ;


__END__
=head1 NAME

Event::SlidingWindow - Count events that occur within a fixed sliding window of time

=head1 SYNOPSIS

  use Event::SlidingWindow ;
  
  my $esw = new Event::SlidingWindow(30) ;
  $esw->record_event() ;
  my $cnt = $esw->count_events() ;

=head1 DESCRIPTION

Event::SlidingWindow allows you to create a time window of a fixed length and 
keeps track of how many events have occured within that window as it advances 
in time. It was created for use in daemons in order to detect denial of service 
attacks.


=head1 AUTHOR

Patrick LeBoutillier, E<lt>patl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Patrick LeBoutillier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
