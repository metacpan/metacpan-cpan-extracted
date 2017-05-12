#
# PurePerl implementation glue to '/usr/sbin/lfs'
#
# (C) 2010 Adrian Ulrich - <adrian.ulrich@id.ethz.ch>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#

package Lustre::LFS;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw();
$VERSION   = '0.01';


use constant LFS_BINARY => '/usr/bin/lfs';


########################################################################
# Parse output of getstripe (file information)
sub _parse_get_stripe_file {
	my($ioh) = @_;
	
	my $path = _lfs_get_path($ioh);
	my $obds = [];
	my $lmm  = { stripe_count=>undef, stripe_size=>undef, stripe_offset=>undef, pool_name=>undef };
	return $path unless defined $path;
	
	foreach my $line (@{_lfs_exec("getstripe", "--verbose", "--", $path)}) {
		if($line =~ /^(\d+): (\S+) (.+)$/) { # OBD information
			$obds->[$1] = { name=>$2, status=>$3 };
		}
		elsif($line =~ /^\s+(\d+)\s+(\d+)\s+(0x[0-9a-f]+)\s+(\d+)/) { # Information about OST
			if(exists($obds->[$1])) {
				$obds->[$1]->{objid} = $2;
				$obds->[$1]->{group} = $4;
				$lmm->{stripe_offset} = $1 unless defined($lmm->{stripe_offset});
			}
		}
		elsif($line =~ /lmm_(\S+):\s+(.+)$/) { # --verbose information >> add to $lmm if key exists
			$lmm->{$1} = $2 if exists($lmm->{$1});
		}
		# else: don't care
	}
	return { info=>$lmm, obds=>$obds };
}

########################################################################
# Parse directory stripe info
sub _parse_get_stripe_dir {
	my($ioh) = @_;
	my $path = _lfs_get_path($ioh);
	return $path unless defined $path;
	
	my $lmm  = { stripe_count=>undef, stripe_size=>undef, stripe_offset=>undef, pool_name=>undef, pool_name=>undef, inherit_default=>undef };
	foreach my $line (@{_lfs_exec("getstripe", "--", $path)}) {
		if($line =~ /^(\(Default\) )?stripe_count: ([0-9-]+) stripe_size: ([0-9-]+) stripe_offset: ([0-9-]+)/) {
			$lmm->{inherit_default} = ( $1 ? 1 : 0 );
			$lmm->{stripe_count}    = $2;
			$lmm->{stripe_size}     = $3;
			$lmm->{stripe_offset}   = $4;
			if($line =~ / pool: (.+)$/) {
				$lmm->{pool_name} = $1;
			}
			last; # no need to parse more
		}
	}
	return $lmm;
}


########################################################################
# Execute the lfs binary with perls open()||exec hack
sub _lfs_exec {
	my(@args) = @_;
	
	open(LFS, "-|") || exec(LFS_BINARY,@args);
	my @buff = <LFS>;
	close(LFS);
	return \@buff;
}

########################################################################
# Silent system() call
# FIXME: THIS SHOULD SET $!
sub _lfs_system {
	my(@args) = @_;
	
	open(OLD_E, ">&STDERR");    # Create a copy of STDERR and STDOUT
	open(OLD_S ,">&STDOUT");
	open(STDOUT, ">/dev/null"); # ..and redirect the default ones to /dev/null
	open(STDERR, ">/dev/null");
	
	my $rv = system(LFS_BINARY, @args);
	
	# .. and restore everything back.
	close(STDOUT);
	close(STDERR);
	open(STDOUT, ">&OLD_S");
	open(STDERR, ">&OLD_E");
	close(OLD_E);
	close(OLD_S);
	
	
	return $rv;
}

########################################################################
# Evil hack to get the filename of an open file-descriptor.
# This might crash and burn but the 'lfs' binary needs a path to work
sub _lfs_get_path {
	my($ioh) = @_;
	my $fno  = $ioh->fileno;
	my $path = undef;
	
	if(defined($fno) && defined($path = readlink("/proc/self/fd/$fno"))) {
		if($path =~ /(.+) \(deleted\)$/) {
			$path = $1;
		}
	}
	return $path;
}

1;

__END__

=head1 NAME

Lustre::LFS - Perl interface to lustres /usr/bin/lfs binary

=head1 SYNOPSIS

  use strict;
  use Lustre::LFS::File;
  use Lustre::LFS::Dir;
  
  my $fh = Lustre::LFS::File->new;
  $fh->open("> some.file") or die;
  print $fh "Hello World!\n";
  my $stripes = $fh->get_stripe;
  $fh->close;
  
=head1 DESCRIPTION

Internal module used by C<Lustre::LFS::File> and C<Lustre::LFS::Dir>

=head1 CONSTRUCTOR

=over 4

C<Lustre::LFS> should not be used directly, see C<Lustre::LFS::File> and C<Lustre::LFS::Dir>

=back

=head1 AUTHOR

Copyright (C) 2010, Adrian Ulrich E<lt>adrian.ulrich@id.ethz.chE<gt>

=head1 SEE ALSO

L<Lustre::Info>,
L<Lustre::LFS::File>,
L<Lustre::LFS::Dir>,
L<IO::File>,
L<IO::Handle>,
L<http://www.lustre.org>

=cut
