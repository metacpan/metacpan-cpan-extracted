package Math::Matlab::Pool;

use strict;
use vars qw($VERSION $MEMBERS $SYNC_FILE);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;
}

use Math::Matlab;
use base qw( Math::Matlab );

use Fcntl qw(:DEFAULT :flock);

##-----  assign defaults, unless already set externally  -----
$MEMBERS	= []						unless defined $MEMBERS;
$SYNC_FILE	= '/tmp/MatlabPool.lock'	unless defined $SYNC_FILE;

##-----  Public Class Methods  -----
sub new {
	my ($class, $href) = @_;
	my $self	= {
		members		=> defined($href->{members})	? $href->{members}		: $MEMBERS,
		sync_file	=> defined($href->{sync_file})	? $href->{sync_file}	: $SYNC_FILE,
		err_msg	=> '',
		result	=> ''
	};

	bless $self, $class;

	## create objects from config as necessary
	foreach my $i ( 0..$#{$self->members} ) {
		my $member = $self->members->[$i];
		next unless ref $member eq 'HASH';
		my $class = $member->{class};
		$self->members->[$i] = $class->new( $member->{args} );
	}

	return $self;
}

##-----  Public Object Methods  -----
sub execute {
	my ($self, $code, $rel_mwd) = @_;

	my $matlab = $self->members->[ $self->next_index ];
	
	if ($matlab->execute($code, $rel_mwd)) {
		$self->{'result'} = $matlab->fetch_raw_result;
		return 1;
	} else {
		$self->err_msg( $matlab->err_msg );
		return 0;
	}
}

sub next_index {
	my ($self) = @_;
	
	## the following code from p. 247 of Perl Cookbook
	sysopen(FH, $self->sync_file, O_RDWR|O_CREAT)
							or die "can't open syncfile: $!";
	flock(FH, LOCK_EX)		or die "can't lock syncfile: $!";
	## now we have the lock, let's do our stuff
	my $num = <FH> || $#{$self->members};
	seek(FH, 0, 0)			or die "can't rewind syncfile: $!";
	truncate(FH, 0)			or die "can't truncate syncfile: $!";
	$num++;
	$num = 0	if $num > $#{$self->members};
	print FH $num, "\n"		or die "can't write syncfile: $!";
	close(FH)				or die "can't close syncfile: $!";

	return $num;
}

sub members {	my $self = shift; return $self->_getset('members',		@_); }
sub sync_file {	my $self = shift; return $self->_getset('sync_file',	@_); }

1;
__END__

=head1 NAME

Math::Matlab::Pool - Interface to a pool of Matlab processes.

=head1 SYNOPSIS

  use Math::Matlab::Pool;
  $matlab = Math::Matlab::Pool->new({
      members   => [ $matlab1, $matlab2, $matlab3 ],
      sync_file => '/path/to/sync/file'
    });
  
  my $code = q/fprintf( 'Hello world!\n' );/
  if ( $matlab->execute($code) ) {
      print $matlab->fetch_result;
  } else {
      print $matlab->err_msg;
  }

=head1 DESCRIPTION

Math::Matlab::Pool implements an interface to a pool of Matlab
processes. It consists of a simple list of other Matlab objects (Local,
Remote or Pool). Each call to execute() is simply passed on to one of
the other objects in the list as determined by the next_index() method.

In this base class, the next_index() method uses a counter in a text
file to store the index of the currently selected member of the list.
Each time execute is called the value is incremented and the new index
is used to determine which member to pass the execute call to. File
locking is used to ensure multiple processes running with identical
Pool's will distribute execute calls in round robin style to each member
of the pool sequentially.

=head1 Attributes

=over 4

=item members

An arrayref of Math::Matlab objects used for execution.

=item sync_file

A string containing the name of the file to be used for the counter.

=back

=head1 METHODS

=head2 Public Class Methods

=over 4

=item new

 $matlab = Math::Matlab::Pool->new;
 $matlab = Math::Matlab::Pool->new( {
      members   => [ $matlab1, $matlab2, $matlab3 ],
      sync_file => '/path/to/sync/file'
 } )

Constructor: creates an object which can run Matlab programs and return
the output. Attributes 'members' and 'sync_file' can be initialized via
a hashref argument to new(). Defaults for these values are taken from
the package variables $MEMBERS and $SYNC_FILE, respectively. The members
arrayref of the initialization hash may contain either Math::Matlab
objects, which are put in the list directly, or hashrefs with 'class'
and 'args' keys. The value of 'class' must be the name of the
Math::Matlab class to use to construct this memmber, and the args should
be a hashref of args to pass to the new method.

This allows one to construct a Pool and all of its members with a single
call to the Pool's new() method.

E.g.
 $class = 'Math::Matlab::Remote';
 $matlab = Math::Matlab::Pool->new({
    sync_file => '/tmp/matlab-pool-sync.txt',
    members   => [
        { class => $class, args => { uri => 'https://server1.mydomain.com' }},
        { class => $class, args => { uri => 'https://server2.mydomain.com' }},
        { class => $class, args => { uri => 'https://server3.mydomain.com' }}
    ]
 });

=back

=head2 Public Object Methods

=over 4

=item execute

 $TorF = $matlab->execute($code, @args)

Takes a string containing Matlab code and optional extra arguments and
passes them to the execute method of the Math::Matlab object in the
'members' list, selected by the next_index() method.

=item next_index

 $index = $matlab->next_index

Returns the index of the next member of the 'members' list. This method
can be overridden in sub-classes to use alternative rules for selection.
In this class it increments a counter in a file and uses the new counter
value as the index into the list. The counter wraps around to zero when
it reaches the end of the list.

=item members

 $members = $matlab->members
 $members = $matlab->members($members)

Get or set the members attribute.

=item sync_file

 $sync_file = $matlab->sync_file
 $sync_file = $matlab->sync_file($sync_file)

Get or set the sync_file attribute.

=back

=head1 CHANGE HISTORY

=over 4

=item *

10/16/02 - (RZ) Created.

=back

=head1 COPYRIGHT

Copyright (c) 2002 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

  perl(1), Math::Matlab

=cut
