package Filesys::ZFS;

#
#    Copyright (C) 2014 Colin Faber
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation version 2 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#        Original author: Colin Faber <colin_faber@fpsn.net>
# Original creation date: 08/28/2014
#                Version: $Id: ZFS.pm,v 1.5 2014/09/06 22:17:55 cfaber Exp $
# 


# Required libraries
use strict;
use Sys::Hostname;
use Fcntl qw(:flock :seek);
use IPC::Open3;
use Symbol qw(gensym);

=head1 NAME

Filesys::ZFS

=head1 SYNOPSIS

use Filesys::ZFS;

=head1 DESCRIPTION

Filesys::ZFS is a simple interface to zfs and zpool commands for managing ZFS file systems

=head1 METHODS

=head2 new(\%options)

Create a new Filesys::ZFS object and return it.

=head3 OPTIONS

Various options can be passed to the new() method

=over

=item zpool

Path to the zpool command, defaults to B</sbin/zpool>

=item zfs

Path to the zfs command, defaults to B</sbin/zfs>

=item no_root_check

Don't warn if the calling program isn't root.

=back

=cut

sub new {
	my ($pkg, $opt) = @_;

	if($opt && ref($opt) ne 'HASH'){
		die __PACKAGE__ . ' only accepts a hash reference containing the options defined in the documentation.';
	} else {
		$opt			= { opt => $opt };
		$opt->{opt}->{zpool}	||= '/sbin/zpool';
		$opt->{opt}->{zfs}	||= '/sbin/zfs';


		if($< != 0 && !$opt->{opt}->{no_root_check}){
			warn "Warning: " . __PACKAGE__ . " is not running as a super user!\n";
		}

		return bless $opt, __PACKAGE__;
	}
}


# Local variables
$__PACKAGE__::VERSION = $1 if('$Revision: 1.5 $' =~ /: ([\d\.]+) /);

=head2 init()

Initialize. Read the various file system details. This method must be run prior to just about anything else working. If file system details change B<init()> should be run again.

=cut

sub init {
	my ($self) = @_;

	$self->_flush;
	$self->_populate_zfs_list || return;

	$self->{init} = 1;

	for my $type (qw(pools snapshots volumes bookmarks)){
		my (@list) = $self->list($type, 1);

		return if (!@list && $self->errstr);
		for my $pool (@list){
			$self->_populate_zpool_status($pool);
			$self->_populate_zfs_properties($pool);
		}
	}

	return 1;
}


=head2 list(TYPE)

Returns an object list

=head3 TYPE

=over

=item pools

Returns file system / Pools data (if any)

=item snapshots

Returns snapshots (if any)

=item volumes

Retruns volumes (if any)

=item bookmarks

Returns bookmarks (if any)

=back

=cut

sub list {
	my ($self, $key, $curse) = @_;

	# Flush error
	$self->_err;

	return $self->_err('list() cannot be called prior to initializing with init() methods') if !$self->{init};

	my %vkeys = map { $_ => 1 } qw(pools snapshots volumes bookmarks);

	return $self->_err('Unknown key passed to list(): ' . $key) if !$vkeys{ $key };

	my @ret;

#	for(sort { $a cmp $b || $a <=> $b } keys %{ $self->{buf}->{ $key } }){a
	for(@{ $self->{buf}->{order}->{ $key } }){
		my $t;
		if(!$curse){
 			$t = $self->{buf}->{ $key }->{ $_ };
			$t->{opt} = $self->{opt};
			$t = bless $t; #, 'Filesys::ZFS::list';
		} else {
			$t = $_;
		}

		push @ret, $t;
	}

	return (@ret);
}

# package Filesys::ZFS::list;
=head2 name()

Return the pool / snapshot / volume / bookmark name provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Pool: " . $pool->name . "\n";
 }

=back

=cut

sub name { return $_[0]->{name}; }

=head2 state()

Return the pool / snapshot / volume / bookmark state provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Current state: " . $pool->state . "\n";
 }

=back

=cut

sub state {
	my ($self) = @_;

	if($self->{nlevel}){
		return $self->{state};
	} elsif(exists $self->{level}) {
		return $self->{device}->{0}->{state};
	} else {
		 return join("\n", @{ $self->{state} }) if $self->{state};
	}
}

=head2 errors()

Return the pool / snapshot / volume / bookmark errors provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Current errors: " . $pool->errors . "\n";
 }

=back

=cut

sub errors { return join("\n", @{ $_[0]->{errors} }) if $_[0]->{errors}; }

=head2 mount()

Return the pool / volume mount point (if available) provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Mount point: " . $pool->mount . "\n";
 }

=back

=cut

sub mount { return $_[0]->{mount}; }

=head2 scan()

Return the pool / volume scan message (if available) provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Last scan: " . $pool->scan . "\n";
 }

=back

=cut

sub scan { return join("\n", @{ $_[0]->{scan} }) if $_[0]->{scan}; }

=head2 free()

Return the pool / volume free space (in KB) provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Free Space: " . $pool->free . "\n";
 }

=back

=cut

sub free { return $_[0]->{free}; }

=head2 used()

Return the pool / volume used space (in KB) provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Used Space: " . $pool->used . "\n";
 }

=back

=cut

sub used { return $_[0]->{used}; }

=head2 referenced()

Return the pool / volume referenced space (in KB) provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Referencing: " . $pool->referenced . "\n";
 }

=back

=cut

sub referenced { return $_[0]->{refer}; }

=head2 status()

Return the pool / volume current status message  provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Current status: " . $pool->status . "\n";
 }

=back

=cut

sub status { 
	my ($self) = @_;
	return join("\n", @{ $self->{status} }) if $self->{status};
}

=head2 action()

Return the pool / volume current action message  provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Requested action: " . $pool->action . "\n";
 }

=back

=cut

sub action { join("\n", @{ $_[0]->{action} }) if $_[0]->{action}; }

=head2 read()

Return the pool / volume read errors (if any) provided by the B<list()> method

=cut

sub read {
	my ($self) = @_;

	if($self->{nlevel}){
		return $self->{read};
	} else {
		return $self->{device}->{0}->{read};
	}
}

=head2 write()

Return the pool / volume write errors (if any) provided by the B<list()> method

=cut

sub write {
	my ($self) = @_;

	if($self->{nlevel}){
		return $self->{write};
	} else {
		return $self->{device}->{0}->{write};
	}
}

=head2 cksum()

Return the pool / volume checksum errors (if any) provided by the B<list()> method

=cut

sub cksum {
	my ($self) = @_;

	if($self->{nlevel}){
		return $self->{cksum};
	} else {
		return $self->{device}->{0}->{cksum};
	}
}

=head2 note()

Return the pool / volume error note (if any) provided by the B<list()> method

=cut

sub note {
	my ($self) = @_;

	if($self->{nlevel}){
		return $self->{note};
	} else {
		return $self->{device}->{0}->{note};
	}
}

=head2 config()

Return the pool / volume / snapshot / bookmark raw configuration message  provided by the B<list()> method

=over

 for my $pool ($ZFS->list('pools')){
 	print "Configuration: " . $pool->config . "\n";
 }

=back

=cut

sub config { join("\n", @{ $_[0]->{config} }) if $_[0]->{config}; }

=head2 providers()

The B<providers()> method is intended to be called from a B<list()> object initially, it returns a list of pool / volume providers, such as virtual devices or block devices.

The resulting list returned is a list of provider objects, which can be used to call the standard B<name()>, B<read()>, B<write()>, B<cksum()>, B<state()> and B<note()> methods defined above.

Additionally B<providers()> can be called with a B<providers()> object, allowing you to successully recruse through the providers stack. An example of this is as follows:

=over

 prov($list_obj)

 sub prov {
        my ($p) = @_;
        for my $prov ($p->providers){
                if($prov->is_vdev){
                        print "\tVirtual Device: " . $prov->name . "\n";
                        prov($prov);
                } else {
                        print "\tBlock Device: " . $prov->name . "\n";
                }
        }
 }

=back

=cut


sub providers {
	my ($self) = @_;

	if($self->{nlevel}){
		$self->{level} = $self->{nlevel};
	} elsif(!$self->{level}){
		$self->{level} = 2;
	}

	my @ret;
	for(@{ $self->{device}->{ $self->{level} . '.order' } }){
		my $dev = $self->{device}->{ $self->{level} }->{ $_ };
		push @ret, bless {
			'device'	=> $self->{device},
			'nlevel'	=> $self->{level} + 2,
			'name'		=> $_,
			'level'		=> $self->{level},
			'read'		=> $dev->{read},
			'write'		=> $dev->{write},
			'cksum'		=> $dev->{cksum},
			'state'		=> $dev->{state},
			'note'		=> $dev->{note}
		};
	}

	return @ret;	
}

=head2 is_vdev(NAME)

Return true if the B<NAME> device is a virtual device (vdev) of some kind or a regular block device or file

If B<NAME> is omitted then the object name is used. This is useful when calling is_dev() from a providers() return:

=over
 for my $prov ($list_obj->providers){
 	if($prov->is_vdev){
 		do something neat;
 	}
 }

=back

=cut


sub is_vdev {
	my ($self, $name) = @_;
	if(!$name){
		$name = $self->{name};
	}

	if($name =~ /^(raidz[123]\-\d+|mirror\-\d+|logs|cache|spares|replacing\-\d+)$/){
		return 1;
	} else {
		return;
	}
}


# Returns true if all ZFS pools appear healthy
=head2 is_health()

Return true if all zpools are in a healthy state. This can be called without initializing with init()

=cut

sub is_healthy {
	my ($self) = @_;
	my (@res) = $self->_run($self->{opt}->{zpool}, 'status', '-x');
	if((split(/\s+/, $res[0]))[3] eq 'healthy'){
		return 1;
	} else {
		return;
	}
}

=head2 properties(POOL)

Return a list (in order) of all property keys for B<POOL>, which can be a pool / file system / volume, etc.

=cut

sub properties {
	my ($self, $pool) = @_;
	return $self->_err('properties() cannot be called prior to initializing with init() methods') if !$self->{init};

	if(ref($self->{buf}->{properties}->{ $pool }->{order}) eq 'ARRAY'){
		return @{ $self->{buf}->{properties}->{ $pool }->{order} };
	}
}

=head2 propval(POOL, PROPERTY_KEY)

Return a two element list of the property value, and default for the property key B<PROPERTY_KEY> in B<POOL> pool / file system / volume.

=cut

sub propval {
	my ($self, $pool, $key) = @_;

	return $self->_err('propval() cannot be called prior to initializing with init() methods') if !$self->{init};
	if(ref($self->{buf}->{properties}->{ $pool }->{set}->{ $key }) eq 'ARRAY'){
		return @{ $self->{buf}->{properties}->{ $pool }->{set}->{ $key } };
	}
}


=head2 errstr()

Return the last error string captured if any.

=cut

sub errstr { return $_[0]->{err}; }


sub _flush { $_[0]->{buf} = {}; $_[0]->{init} = 0; }

sub _err {
	my ($self, $msg) = @_;
	$self->{err} = $msg;
	return;
}


# List active pools and details
sub _populate_zfs_list {
	my ($self) = @_;

	my @types = qw(filesystem snapshot snap volume bookmark);
	for my $type (@types){
		my (@res) = $self->_run($self->{opt}->{zfs}, 'list', '-H', '-p', '-t', $type);
		if(!@res && $self->_run_err){
			return $self->_err("Unable to read $type list: " . $self->_run_err);
		} 

		if($type eq 'filesystem'){
			$type = 'pools';
		}

		for(@res){
			chomp;
			if($_ eq 'no datasets available'){
				$self->{buf}->{ $type }  = '';
			} else {
				my ($pool, $used, $free, $refer, $mount) = split(/\s+/, $_, 5);
				$used  = int($used / 1024) if $used;
				$free  = int($free / 1024) if $free;
				$refer = int($refer / 1024) if $refer;

				$self->{buf}->{ $type }->{ $pool }->{name}  = $pool;
				$self->{buf}->{ $type }->{ $pool }->{used}  = $used;
				$self->{buf}->{ $type }->{ $pool }->{free}  = $free;
				$self->{buf}->{ $type }->{ $pool }->{refer} = $refer;
				$self->{buf}->{ $type }->{ $pool }->{mount} = $mount;
				push @{ $self->{buf}->{order}->{ $type } }, $pool;
			}
		}
	}

	return 1;
}

# Produce a text report of the zfs pool, include smart errors if any for each device.
sub _populate_zpool_status {
	my ($self, $pool) = @_;

	my (@res) = $self->_run($self->{opt}->{zpool}, 'status', '-v', $pool);

	if(!@res){
		return $self->_err("Unable to read pool data for: $pool\: " . $self->_run_err);
	}

	# First pass
	my $n;
	for(my $i = 0; $i < @res; $i++){
		chomp $res[$i];
		if($res[$i] =~ /^\s*(pool|state|scrub|scan|errors|config|status|action):\s*(.+)?$/){
			$n = $1;
			my $v = $2;
			chomp $v;
			next if !$v;
			push @{ $self->{buf}->{pools}->{ $pool }->{ $n } }, $v;
		} elsif($n && $res[$i]){
			push @{ $self->{buf}->{pools}->{ $pool }->{ $n } }, $res[$i];
		}
	}

	if(ref($self->{buf}->{pools}->{ $pool }->{config}) eq 'ARRAY'){
		my $cfg = $self->{buf}->{pools}->{ $pool }->{config};
		my ($name, $bd, $dev);

		for(@$cfg){
			chomp;

			# Headers
			next if(/^\s{8}NAME\s+STATE/ || !$_);


			# First stage entries (usually just pool name)
			if(/^\t(\s*)([^\s]+)\s+([A-Z]+)\s+(\d+)\s+(\d+)\s+(\d+)(\s+(.+))?$/){
				my $d = length($1);
				if($d){
					push @{ $self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d . '.order' } }, $2;
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ $2 }->{ 'state' } = $3;
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ $2 }->{ 'read' }  = $4;
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ $2 }->{ 'write' } = $5;
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ $2 }->{ 'cksum' } = $6;
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ $2 }->{ 'note' }  = $7;
				} else {
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ 'state' } = $3;
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ 'read' }  = $4;
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ 'write' } = $5;
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ 'cksum' } = $6;
					$self->{buf}->{pools}->{ $pool }->{ 'device' }->{ $d }->{ 'note' }  = $7;
				}
			}
		}

	}

	return 1;
}

# Get the pool / file system properties
sub _populate_zfs_properties {
	my ($self, $pool) = @_;

	my (@res) = $self->_run($self->{opt}->{zfs}, 'get', '-H', 'all', $pool);

	if(!@res && $self->_run_err){
		return $self->_err("Unable to read $pool properties list: " . $self->_run_err);
	} 

	for(my $i = 0; $i < @res; $i++){
		chomp $res[$i];
		my ($p, $prop, $val, $src) = split(/\t/, $res[$i]);

		push @{ $self->{buf}->{properties}->{ $pool }->{ 'order '} }, $prop;
		$self->{buf}->{properties}->{ $pool }->{ 'set' }->{ $prop } = [ $val, $src ];
	}

	return 1;
}

# Map by-id to device
sub _map_by_id {
        my ($self, $dev) = @_;
        if(opendir(my $dh, '/dev/disk/by-id')){
		my @loc;
                for(readdir $dh){
                        if($_ eq '.' || $_ eq '..'){
                                next;
                        } else {
                                my $link;
                                $link = $1 if(readlink('/dev/disk/by-id/' . $_) =~ /\/([^\/]+)$/);

                                if($link eq $dev){
					push @loc, $_;
                                } elsif($dev eq $_){
					push @loc, $link;
				}
                        }
                }

                closedir($dh);
                return (@loc);
        } else {
                return $self->_err("Unable to read udev path /dev/disk/by-id: " . $self->_run_err);
        }
}


# Execute and return the results 
sub _run {
	my ($self, @com) = @_;
	my @res;
	my @err;
	delete $self->{run_err};

	# Untaint external command
	for(my $i = 0; $i < @com; $i++){
		$com[$i] = $1 if($com[$i] =~ /(.+)/);
	}

	if(open(__ZFSERR, '+>', undef)){
		my $pid = open3(gensym, \*__ZFSOUT, ">&__ZFSERR", @com);
		while(<__ZFSOUT>){
			push @res, $_;
		}

		# Probably should allow for command timeout...
		waitpid($pid, 0);

		seek(__ZFSERR, 0, &SEEK_SET);
		while(<__ZFSERR>){
			chomp;
			push @err, $_ if $_;
		}

		close(__ZFSOUT);
		close(__ZFSERR);

		$self->{run_err} = join("\n", @err);
		return @res;
	} else {
		$self->{run_err} = "ERROR: can't generate anonymous file handle: $!";
		return;
	}
}

sub _run_err { 
	my ($self) = @_;
	return $self->{run_err};
}


=head1 LICENSE

This library is licensed under the Perl Artistic license and may be used, modified, and copied under it's terms.

=head1 AUTHOR

This library was authorized by Colin Faber <cfaber@fpsn.net>. Please contact the author with any questions.

=head1 BUGS

Please report all bugs to https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=Filesys-ZFS

=cut

1;
