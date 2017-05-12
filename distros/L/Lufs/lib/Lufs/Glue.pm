package Lufs::Glue;
$|++;

use Fcntl;
use Linux::Pid;

our $trace = 0;

sub TRACE {
	my $self = shift;
	my $method = shift;
	return unless $trace;
	my (@arg) = @_;
	my $ret = pop(@arg);
	if ($method eq 'create') {
		$arg[1] = $self->mode($arg[1]);
	}
	if ($method eq 'stat' or $method eq 'setattr') {
		$arg[1] = $self->hashdump($arg[1]);
	}
	if ($method eq 'write' or $method eq 'read') {
		$arg[3] = $self->_truncdata($arg[3]);
	}
	if ($method eq '_init') {
		$arg[0] = $self->hashdump($arg[0]);
	}
	if ($method eq 'GET' or $method eq 'HEAD') {
		$ret = pop(@arg).' '.pop(@arg).' '.$self->hashdump($ret);
	}
	if ($method eq 'readdir') {
		$arg[-1] = '['.join(', ', @{$arg[-1]}).']';
	}
	$arg[0] = "'$arg[0]'";
    print STDERR '['.Linux::Pid::getpid()."] $method (".join(', ', @arg).") = $ret\n";
}

sub _truncdata {
	my $self = shift;
	my $data = shift;
	no warnings;
	my $s = $data;
	$s=~s{\n}{\\n}g;
	$s=~s{([^ -~])}{sprintf"0x%02x",ord($1)}ge;
	my $pad = (length($s)>32) ? '...' : '';
	$s="'".substr($s, 0, 32)."$pad'";
}

sub modes { # this generates the %m hash
	my $self = shift;
	my $arg = shift;
	if ($arg eq 'S') {
		return (Fcntl::S_IFREG() => 'S_IFREG', 
				Fcntl::S_IFDIR() => 'S_IFDIR',
				Fcntl::S_IFLNK() => 'S_IFLNK',
				Fcntl::S_IFCHR() => 'S_IFCHR',
				Fcntl::S_IFIFO() => 'S_IFIFO',
				Fcntl::S_IFSOCK() => 'S_IFSOCK');
	}
	my %m;
	for (grep /^O/, keys %{Fcntl::}) {
		my $v = eval "Fcntl::$_";
		next unless (int($v) eq $v);
		$m{$v} = $_ if $v;
	}
	%m;
}

sub mode {
	my $self = shift;
	my $mode = shift;
	my @m;
	my %m = $self->modes('O');
	for (keys %m) {
		if (($mode & $_) == $_) {
			push @m, $m{$_};
		}
	}
	join(' | ', @m);
}

sub fmode {
	my $self = shift;
	my $mode = shift;
	my @m;
	my %m = $self->modes('S');
	for (keys %m) {
		if (($mode & $_) == $_) {
			push @m, $m{$_};
		}
	}
	join(' | ', @m);
}

sub hashdump {
	my $self = shift;
	my $h = shift;
 	'{ '.join(', ', 
		map { "$_->[0] => $_->[1]" }
		map { $_ eq 'f_mode' ? [$_, $self->fmode($h->{$_})] : [$_, $h->{$_}] }
	keys %{$h}).'}';
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lufs::Glue - misc subs

=head1 SYNOPSIS

  use base 'Lufs::Glue';
  $self->foo

=head1 ABSTRACT

  This should be the abstract for Lufs::Glue.
  The abstract is used when making PPD (Perl Package Description) files.
  If you don't want an ABSTRACT you should also edit Makefile.PL to
  remove the ABSTRACT_FROM option.

=head1 DESCRIPTION

Stub documentation for Lufs::Glue, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

root, E<lt>root@internE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
