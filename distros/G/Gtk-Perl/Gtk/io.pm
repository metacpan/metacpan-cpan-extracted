package Gtk::io;

my %pending = ();
my $sweepid;
my $timeout = 2;

sub get_pending {
	my $fd = shift;
	if (defined $fd) {
		return grep {m/(read|write)$fd$/} keys %pending;
	} else {
		return \%pending;
	}
}

sub _sweeper {
	$sweepid = Gtk->timeout_add(1000, sub {
		my $now = time;
		my ($k, $v);
		while ( ($k, $v) = each %pending) {
			next unless ref $v;
			if ($now - $v->[1] > $timeout) {
				warn "Timeout on $k\n";
				Gtk::Gdk->input_remove($v->[0]);
				$pending{$k} = undef;
			}
		}
		1;
	});
}

sub _wait_for_condition ($$) {
	my ($fd, $cond) = @_;
	my $id;
	warn "Already scheduled a $cond on fd $fd\n" if exists $pending{$cond.$fd};
	_sweeper() unless $sweepid;
	$id = Gtk::Gdk->input_add($fd, [$cond], sub {
		#warn "callback $id for $cond on $fd\n" if $pending{$cond.$fd};
		return 1 unless ($_[1]->{$cond} || $_[1]->{'readwrite'});
		$pending{$cond.$fd} = 0;
		Gtk::Gdk->input_remove($id);
	});
	$pending{$cond.$fd} = [$id, time];
	Gtk->main_iteration while ($pending{$cond.$fd} || Gtk->events_pending);
	return $cond.$fd;
}

# sysread FILEHANDLE,SCALAR,LENGTH,OFFSET
# sysread FILEHANDLE,SCALAR,LENGTH

sub sysread ($$$;$) {
	my $doit = 0;
	my $fd = $_[0]->fileno();
	my $bits = '';
	vec($bits, $fd, 1) = 1;
	# short circuit it
	unless (select($bits, undef, undef, 0)) {
		$doit = defined(delete $pending{_wait_for_condition($fd, 'read')})?1:0;
	} else {
		$doit++;
	}
	return sysread($_[0], $_[1], $_[2], $_[3] || 0) if $doit;
	return undef;
}

# syswrite FILEHANDLE,SCALAR,LENGTH,OFFSET
# syswrite FILEHANDLE,SCALAR,LENGTH
# syswrite FILEHANDLE,SCALAR

sub syswrite ($$$;$) {
	my $doit = 0;
	my $fd = $_[0]->fileno();
	my $bits = '';
	vec($bits, $fd, 1) = 1;
	# short circuit it
	unless (select(undef, $bits, undef, 0)) {
		$doit = defined(delete $pending{_wait_for_condition($fd, 'write')})?1:0;
	} else {
		$doit++;
	}
	return syswrite($_[0], $_[1], $_[2], $_[3] || 0) if $doit;
	return undef;
}

package Gtk::io::INET;
@ISA = qw(Gtk::io IO::Socket::INET);
package Gtk::io::UNIX;
@ISA = qw(Gtk::io IO::Socket::UNIX);
package Gtk::io::Pipe;
@ISA = qw(Gtk::io IO::Pipe);
1;

