use strict;
use warnings FATAL => 'all';

package HTML::Tested::ClassDBI::Upload;
use Carp;
use File::MMagic;

sub new { return bless([ $_[1]->CDBI_Class, $_[2], $_[3] ], $_[0]); }

sub setup_type_info {}

sub strip_mime_header {
	my ($class, $buf) = @_;
	$buf =~ s/^MIME: ([^\n]+)\n//;
	return ($1, $buf);
}

sub _get_mime {
	my ($class, $fh) = @_;
	# Invoking file(2) command on $fh through IPC::Run3 doesn't work in
	# Apache.
	my $mm = File::MMagic->new;
	bless $fh, 'FileHandle';
	my $res = $mm->checktype_filehandle($fh);
	seek($fh, 0, 0) or confess "Unable to seek";
	return $res;
}

sub _dbh_write {
	my ($dbh, $lo_fd, $buf, $rlen) = @_;
	my $wlen = $dbh->func($lo_fd, $buf, $rlen, 'lo_write');
	defined($wlen) or confess "# Unable to lo_write $rlen";
	confess "# short write $rlen > $wlen" if $rlen != $wlen;
}

sub _open_lo {
	my ($class, $dbh, $lo) = @_;
	confess "We should be in transaction" if $dbh->{AutoCommit};
	if ($lo) {
		$dbh->func($lo, 'lo_unlink') or confess "error: lo_unlink $lo";
		$dbh->do("select lo_create(?)", undef, $lo);
	} else {
		$lo = $dbh->func($dbh->{pg_INV_WRITE}, 'lo_creat')
			or confess "# Unable to lo_creat";
	}
	my $lo_fd = $dbh->func($lo, $dbh->{'pg_INV_WRITE'}, 'lo_open');
	defined($lo_fd) or confess "# Unable to lo_open $lo";
	return ($lo, $lo_fd);
}

sub _parse_arg {
	my ($class, $arg, $msg) = @_;
	my ($a, $loid) = ref($arg) && ref($arg) eq 'ARRAY' ? @$arg : ($arg);
	confess "No $msg is given" unless $a;
	return ($a, $loid);
}

sub import_lo_from_string {
	my ($class, $dbh, $stra, $with_mime) = @_;
	my ($str, $loid) = $class->_parse_arg($stra, "string");
	if ($with_mime) {
		my $mime = File::MMagic->new->checktype_contents($str)
				or confess "No mime";
		$str = "MIME: $mime\n$str";
	}
	my ($lo, $lo_fd) = $class->_open_lo($dbh, $loid);
	_dbh_write($dbh, $lo_fd, $str, length $str);
	$dbh->func($lo_fd, 'lo_close') or confess "Unable to close $lo";
	return $lo;
}

sub import_lo_object {
	my ($class, $dbh, $fha, $with_mime) = @_;
	my ($fh, $loid) = $class->_parse_arg($fha, "filehandle");
	my $mime = $class->_get_mime($fh) if ($with_mime);
	my ($buf, $rlen, $wlen);
	my ($lo, $lo_fd) = $class->_open_lo($dbh, $loid);
	if ($mime) {
		$buf = "MIME: $mime\n";
		_dbh_write($dbh, $lo_fd, $buf, length $buf);
	}
	while (($rlen = sysread($fh, $buf, 4096 * 16))) {
		_dbh_write($dbh, $lo_fd, $buf, $rlen);
	}
	$dbh->func($lo_fd, 'lo_close') or confess "Unable to close $lo";
	return $lo;
}

sub export_lo_to_string {
	my ($class, $dbh, $loid) = @_;;
        my $lo_fd = $dbh->func($loid, $dbh->{'pg_INV_READ'}, 'lo_open');
        defined($lo_fd) or confess "# Unable to lo_open $loid";
        my ($buf, $ct) = ('', '');
        $dbh->func($lo_fd, $buf, 4096, 'lo_read');
        ($ct, $buf) = HTML::Tested::ClassDBI::Upload->strip_mime_header($buf);
        my $res = $buf;
        while ($dbh->func($lo_fd, $buf, 4096, 'lo_read')) {
                $res .= $buf;
        }
	$dbh->func($lo_fd, 'lo_close') or confess "Unable to close $loid";
	return ($res, $ct);
}

sub update_column {
	my ($self, $setter, $root, $name) = @_;
	my $val = $root->$name or return;
	my $lo = $self->import_lo_object($self->[0]->db_Main, $val, $self->[2]);
	$setter->($self->[1], $lo);
}

sub get_column_value {}

1;
