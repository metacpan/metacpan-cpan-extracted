# Linux::LXC - Manage LXC containers.
# Copyright (C) 2020 Spydemon <jsaipakoimetr@spyzone.fr>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Linux::LXC;
$Linux::LXC::VERSION = '1.0006';

use v5.0;

use Backticks;
use Carp;
use Exporter qw(import);
use File::Copy qw(move);
use File::Temp;
use Moo;
use IPC::Run qw(run);

use constant ALLOW_UNDEF => 0x01;
use constant ERASING_MODE => 0x01;
use constant ADDITION_MODE => 0x02;
our @EXPORT_OK = ('ALLOW_UNDEF', 'ERASING_MODE', 'ADDITION_MODE');

$Backticks::autodie = 1;

BEGIN {
	my $lxc = `lxc-start --version`;
	die ("LXC seems to not be installed and is needed for Linux::LXC.\n") unless $lxc;
}

######################
# Module subroutines #
######################
sub get_existing_containers {
	split("\n", `lxc-ls -1`);
}

sub get_running_containers {
	split("\n", `lxc-ls -1 --running`);
}

sub get_stopped_containers {
	split("\n", `lxc-ls -1 --stopped`);
}

sub get_version {
	my $version = `lxc-start --version`;
	chomp($version);
	return $version;
}

#######################
# Objects subroutines #
#######################
has utsname => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'get_utsname'
);

has template => (
	'is' => 'rw',
	'reader' => '_get_template',
	'writer' => 'set_template'
);

sub deploy {
	my ($this) = @_;
	$this->_check_container_is_not_existing();
	my $utsname = $this->get_utsname();
	my $template = $this->get_template();
	$this->_qx("lxc-create -n $utsname -t $template", undef, wantarray);
}

sub destroy {
	my ($this) = @_;
	$this->is_running() and $this->stop();
	$this->_qx('lxc-destroy -n '.$this->get_utsname(), undef, wantarray);
}

sub exec {
	my ($this, $cmd) = @_;
	$this->_check_container_is_running();
	$this->_qx('lxc-attach --clear-env -n '.$this->get_utsname(), $cmd, wantarray);
}

sub get_lxc_path {
	my ($this) = @_;
	'/var/lib/lxc/' . $this->get_utsname();
}

sub get_config {
	my ($this, $attr, $filter, $flags) = @_;
	unless ($attr) {
		croak 'Parameter to get is missing';
	}
	if (defined $filter and ref($filter) ne 'Regexp') {
		croak '$filter should be a regular expresion';
	}
	$filter //= qr/(.*)/;
	my $allow_undef = defined ($flags) && $flags & ALLOW_UNDEF;
	$this->_check_container_is_existing();
	open my $CONF, '<', $this->get_lxc_path() . '/config';
	my @results;
	for (<$CONF>) {
		if (/^$attr\W*=\W*(?P<value>.*)$/) {
			push @results, $+{value} =~ $filter;
		}
	}
	if (!@results && !$allow_undef) {
		croak "'$attr' attribute was not found in lxc configuration file with filter $filter";
	}
	return @results;
}

sub get_template {
	my ($this) = @_;
	if (!$this->_get_template()) {
		my $utsname = $this->get_utsname();
		croak "Template is not provided for '$utsname' container.";
	}
	$this->_get_template();
}

sub is_existing {
	my ($this) = @_;
	my $name = $this->get_utsname();
	grep {/^$name$/} get_existing_containers();
}

sub is_running {
	my ($this) = @_;
	my $name = $this->get_utsname();
	grep {/^$name$/} get_running_containers();
}

sub is_stopped {
	my ($this) = @_;
	my $name = $this->get_utsname();
	grep {/^$name$/} get_stopped_containers();
}

sub put {
	my ($this, $input, $dest_from_container_root) = @_;
	# id map configuration attribute name changes between LXC version 2 and 3… Purpose of $idmap_label variable is to
	# take care of it.
	my $idmap_label = $this->get_version() =~ /^2/
		? 'lxc.id_map'
		: 'lxc.idmap';
	my ($uid) = $this->get_config($idmap_label, qr/^u 0 (\d+)/, ALLOW_UNDEF);
	$this->_check_container_is_existing();
	if (!-r $input) {
		croak "Input $input is not readable";
	}
	if ($dest_from_container_root !~ /^\//) {
		croak 'Destination should be an absolute path';
	}
	my $container_root = $this->get_lxc_path() . '/rootfs';
	my ($dir_dest) = $dest_from_container_root =~ /^(.*\/)/;
	# He have to use a transit folder and to use chroot for being able to correctly resolve symlinks.
	$Backticks::autodie = 0;
	`test -e $container_root/tmp/lxc-transit && rm -rf $container_root/tmp/lxc-transit`;
	$Backticks::autodie = 1;
	`cp -R $input $container_root/tmp/lxc-transit`;
	# Here, we are creating all folder path in which we want to copy the $input.
	my @folders = split(/\//, $dir_dest);
	shift @folders;
	my $abs_folder = '';
	while (my $cur_folder = shift @folders) {
		$abs_folder .= '/' . $cur_folder;
		# If the current folder is not existing or if it is not a symlink, we create it.
		if (!$this->_check_folder_existence($container_root, $abs_folder)) {
			`chroot $container_root mkdir $abs_folder`;
			# This instruction is the cause we can not simply use a `mkdir -p` command for creating the path: we need
			# to set the good rights to folder in order to copy it.
			# Note: we set right only if we have to create the folder, for avoiding to create too much mess.
			`chroot $container_root chown $uid:$uid $abs_folder` if (defined $uid);
		}
	}
	`chroot $container_root mv /tmp/lxc-transit $dest_from_container_root`;
	`chroot $container_root chown -R $uid:$uid $dest_from_container_root` if defined $uid;
}

sub del_config {
	my ($this, $attr, $filter) = @_;
	if (defined $filter and ref($filter) ne 'Regexp') {
		croak '$filter should be a regular expression';
	}
	$filter //= qr/(.*)/;
	open my $CONF_R, '<', $this->get_lxc_path() . '/config';
	my $CONF_W = new File::Temp();
	my $entries_deleted = 0;
	for (<$CONF_R>) {
		if (/^$attr\W*=\W*(?P<value>.*)$/) {
			if ($+{value} =~ $filter) {
				$entries_deleted++;
				next;
			}
		}
		print $CONF_W $_;
	}
	close $CONF_W;
	move ($CONF_W->filename, $this->get_lxc_path() . '/config') or die ($!);
	return $entries_deleted;
}

sub set_config {
	my ($this, $attr, $value, $flags) = @_;
	$flags = ERASING_MODE unless defined $flags;
	croak 'set_config can not be in erasing and addition mode'
		if ($flags == (ERASING_MODE | ADDITION_MODE));
	$this->_check_container_is_existing();
	if ($flags & ADDITION_MODE) {
		open my $CONF, '>>', $this->get_lxc_path() . '/config';
		print $CONF "$attr = $value\n";
	} else {
		my $written = 0;
		open my $CONF_R, '<', $this->get_lxc_path().'/config';
		my $CONF_W = File::Temp->new();
		for (<$CONF_R>) {
			if (/^$attr = .*$/) {
				print $CONF_W "$attr = $value\n";
				$written = 1;
			} else {
				print $CONF_W $_;
			}
		}
		!$written and print $CONF_W "$attr = $value\n";
		close $CONF_R;
		close $CONF_W;
		move ($CONF_W->filename, $this->get_lxc_path().'/config') or die ($!);
	}
}

sub start {
	my ($this) = @_;
	my $utsname = $this->get_utsname();
	$this->_check_container_is_existing();
	if ($this->is_running()) {
		return;
	}
	$this->_qx("lxc-start -d -n $utsname", undef, wantarray);
}

sub stop {
	my ($this) = @_;
	if (!$this->is_running()) {
		return;
	}
	$this->_qx('lxc-stop -n '.$this->get_utsname(), undef, wantarray);
}

########################
# Internal subroutines #
########################
sub _check_container_is_existing {
	my ($this) = @_;
	if (!$this->is_existing()) {
		my (undef, undef, undef, $caller) = caller(1);
		$caller =~ /::(\w*)$/;
		croak 'Container ' . $this->get_utsname() . ' doesn\'t exist';
	}
}

sub _check_container_is_not_existing {
	my ($this) = @_;
	if ($this->is_existing())  {
		croak 'Container ' . $this->get_utsname() . ' already exists';
	}
}

sub _check_container_is_running {
	my ($this) = @_;
	if ($this->is_stopped()) {
		croak 'Container ' . $this->get_utsname() . ' is not running';
	}
}

# Subroutine to use for knowing if a given folder exists on the container.
# This check is able to solve symlinks too.
sub _check_folder_existence {
	my ($this, $container_root, $abs_folder) = @_;
	$Backticks::autodie = 0;
	my $res1 = `chroot $container_root test -e $abs_folder`->success;
	my $res2 = `chroot $container_root test -L $abs_folder`->success;
	$Backticks::autodie = 1;
	return ($res1 || $res2);
}

sub _qx {
	my ($this, $cmd, $params, $wantarray) = @_;
	my @cmd = split(' ', $cmd);
	my ($stdout, $stderr);
	my $result = run \@cmd, \$params, \$stdout, \$stderr;
	$wantarray and return ($result, $stdout, $stderr);
	return $result;
}

1
