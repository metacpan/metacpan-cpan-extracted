
package Ham::APRS::DeviceID;

=head1 NAME

Ham::APRS::DeviceID - APRS device identifier

=head1 SYNOPSIS

  use Ham::APRS::FAP qw(parseaprs);
  use Ham::APRS::DeviceID;
  use Data::Dumper;
  
  my $aprspacket = 'OH2RDP>APZMDR,OH2RDG*,WIDE:!6028.51N/02505.68E#PHG7220/RELAY,WIDE, OH2AP Jarvenpaa';
  my %packet;
  my $retval = parseaprs($aprspacket, \%packet);
  if ($retval == 1) {
  	Ham::APRS::DeviceID::identify(\%packet);
  	
  	if (defined $packet{'deviceid'}) {
  	    print Dumper($packet{'deviceid'});
  	}
  }

=head1 ABSTRACT

This module attempts to identify the manufacturer, model and 
software version of an APRS transmitter. It looks at details found
in the parsed APRS packet (as provided by Ham::APRS::FAP) and updates
the hash with the identification information, if possible.

The module comes with a device identification database, which is
simply a copy of the YAML master file maintained separately
at: L<https://github.com/hessu/aprs-deviceid>

=head1 DESCRIPTION

Unless a debugging mode is enabled, all errors and warnings are reported
through the API (as opposed to printing on STDERR or STDOUT), so that
they can be reported nicely on the user interface of an application.

This module requires a reasonably recent L<Ham::APRS::FAP> module,
L<YAML::Tiny> to load the device identification database and
L<File::ShareDir> for finding it.

=head1 EXPORT

None by default.

=head1 FUNCTION REFERENCE

=cut

use strict;
use warnings;

#use Data::Dumper;

require Exporter;
use YAML::Tiny;
use File::ShareDir ':ALL';

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Ham::APRS::FAP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
##our %EXPORT_TAGS = (
##	'all' => [ qw(
##
##	) ],
##);

our @EXPORT_OK = (
##	@{ $EXPORT_TAGS{'all'} },
	'&identify',
);

##our @EXPORT = qw(
##	
##);

our $VERSION = '2.02';

# Preloaded methods go here.

# no debugging by default
my $debug = 0;

my %result_messages = (
	'unknown' => 'Unsupported packet format',
	'no_dstcall' => 'Packet has no destination callsign',
	'no_format' => 'Packet has no defined format',
	'mice_no_comment' => 'Mic-e packet with no comment defined',
	'mice_no_deviceid' => 'Mic-e packet with no device identifier in comment',
	'no_id' => 'No device identification found',
);

# these functions are used to report warnings and parser errors
# from the module

sub _a_err($$;$)
{
	my ($rethash, $errcode, $val) = @_;
	
	$rethash->{'deviceid_resultcode'} = $errcode;
	$rethash->{'deviceid_resultmsg'}
		= defined $result_messages{$errcode}
		? $result_messages{$errcode} : $errcode;
	
	$rethash->{'deviceid_resultmsg'} .= ': ' . $val if (defined $val);
	
	if ($debug > 0) {
		warn "Ham::APRS::DeviceID ERROR $errcode: " . $rethash->{'deviceid_resultmsg'} . "\n";
	}
	
	return 0;
}

sub _a_warn($$;$)
{
	my ($rethash, $errcode, $val) = @_;
	
	push @{ $rethash->{'deviceid_warncodes'} }, $errcode;
	
	if ($debug > 0) {
		warn "Ham::APRS::DeviceID WARNING $errcode: "
		    . (defined $result_messages{$errcode}
		      ? $result_messages{$errcode} : $errcode)
		    . (defined $val ? ": $val" : '')
		    . "\n";
	}
	
	return 0;
}


=over

=item debug($enable)

Enables (debug(1)) or disables (debug(0)) debugging.

When debugging is enabled, warnings and errors are emitted using the warn() function,
which will normally result in them being printed on STDERR. Succesfully
printed packets will be also printed on STDOUT in a human-readable
format.

When debugging is disabled, nothing will be printed on STDOUT or STDERR -
all errors and parsing results need to be collected from the returned
hash reference.

=back

=cut

sub debug($)
{
	my $dval = shift @_;
	if ($dval) {
		$debug = 1;
	} else {
		$debug = 0;
	}
}

#
# Prebaked responses for "legacy" devices, including the VX-8 which has a
# space (0x20) character as the last byte, which commonly gets eaten by
# UI-View
#
my %response = (
	'd7' => {
		'vendor' => 'Kenwood',
		'model' => 'TH-D7',
		'class' => 'ht',
		'messaging' => 1,
	},
	'd72' => {
		'vendor' => 'Kenwood',
		'model' => 'TH-D72',
		'class' => 'ht',
		'messaging' => 1,
	},
	'd700' => {
		'vendor' => 'Kenwood',
		'model' => 'TM-D700',
		'class' => 'rig',
		'messaging' => 1,
	},
	'd710' => {
		'vendor' => 'Kenwood',
		'model' => 'TM-D710',
		'class' => 'rig',
		'messaging' => 1,
	},
	'vx8' => {
		'vendor' => 'Yaesu',
		'model' => 'VX-8',
		'class' => 'ht',
		'messaging' => 1,
	},
	'unknown' => {
		'vendor' => 'Unknown',
		'model' => 'Other Mic-E',
	}
);

my %mice_codes;
my %fixed_dstcalls;
my @dstcall_regexps;

my %regexp_prefix;

#
# init: load YAML definitions
#

sub _load_tocalls(@)
{
	my(@tcl) = @_;
	
	foreach my $t (@tcl) {
		my $tocall = $t->{'tocall'};
		delete $t->{'tocall'};
		if ($tocall =~ /^[A-Z0-9]+$/) {
			$fixed_dstcalls{$tocall} = $t;
		} elsif ($tocall =~ /^([A-Z0-9]+)([n\?\*]+)([A-Z0-9]*)$/) {
			my $prefix = $1;
			my $r = $2; # glob (n for numbers, ?/* for single/multi)
			my $suffix = $3;
			$r =~ s/n/\\d/g;
			$r =~ s/\?/./g;
			$r =~ s/\*/.*/g;
			$r = $prefix . '(' . $r . $suffix . ')';
			push @dstcall_regexps, [ $r, $t ];
		} else {
			die "tocall '$tocall' too hard to parse";
		}
	}
	
}

sub _load_mice(@)
{
	my(@tcl) = @_;
	
	foreach my $t (@tcl) {
		my $suffix = $t->{'suffix'};
		delete $t->{'suffix'};
		$mice_codes{$suffix} = $t;
	}
	
}

sub _load()
{
	my $src = dist_file('Ham-APRS-DeviceID', 'tocalls.yaml');
	my $yaml = YAML::Tiny->new;
	my $c = YAML::Tiny->read($src);
	if (!defined $c) {
		die "Failed to read in $src: " . YAML::Tiny->errstr . "\n";
	}
	
	# get the first document of YAML
	$c = $c->[0];
	
	_load_tocalls(@{ $c->{'tocalls'} });
	_load_mice(@{ $c->{'mice'} });

}

#
# init code: compile the regular expressions to speed up matching
#

sub _compile_regexps()
{
	for (my $i = 0; $i <= $#dstcall_regexps; $i++) {
		my $dmatch = $dstcall_regexps[$i];
		my($regexp, $response) = @$dmatch;
		
		my $compiled = qr/^$regexp$/;
		$dstcall_regexps[$i] = [ $regexp, $response, $compiled ];
	}
}

#
# init: optimize regexps with an initial hash lookup
#

sub _optimize_regexps()
{
	my @left;
	
	for (my $i = 0; $i <= $#dstcall_regexps; $i++) {
		my $dmatch = $dstcall_regexps[$i];
		my($regexp, $response, $compiled) = @$dmatch;
		
		if ($regexp =~ /^([^\(]{2,5})(\(.*)$/) {
			if (!defined $regexp_prefix{$1} ) {
				$regexp_prefix{$1} = [ $dmatch ];
			} else {
				push @{ $regexp_prefix{$1} }, $dmatch;
			}
		} else {
			push @left, $dmatch;
			warn "optimize: leaving $regexp over\n";
		}
	}
	
	@dstcall_regexps = @left;
}

_load();
_compile_regexps();
_optimize_regexps();

=over

=item identify($hashref)

Tries to identify the device.

=back

=cut

sub identify($)
{
	my($p) = @_;
	
	$p->{'deviceid_resultcode'} = '';
	
	return _a_err($p, 'no_format') if (!defined $p->{'format'});
	return _a_err($p, 'no_dstcall') if (!defined $p->{'dstcallsign'});
	
	if ($p->{'format'} eq 'mice') {
		#warn Dumper($p);
		#warn "comment: " . $p->{'comment'} . "\n";
		if (!defined $p->{'comment'}) {
			return _a_err($p, 'mice_no_comment');
		}
		if ($p->{'comment'} =~ s/^>(.*)=$/$1/) {
			$p->{'deviceid'} = $response{'d72'};
		} elsif ($p->{'comment'} =~ s/^>//) {
			$p->{'deviceid'} = $response{'d7'};
		} elsif ($p->{'comment'} =~ s/^\](.*)=$/$1/) {
			$p->{'deviceid'} = $response{'d710'};
		} elsif ($p->{'comment'} =~ s/^\]//) {
			$p->{'deviceid'} = $response{'d700'};
		} elsif ($p->{'comment'} =~ s/^`(.*)_\s*$/$1/) {
			# vx-8 has a space as the last character, which commonly gets eaten by ui-view,
			# so handle it with a relaxed regexp
			$p->{'deviceid'} = $response{'vx8'};
		} elsif ($p->{'comment'} =~ /^([`\'])(.*)(..)$/) {
			my($b, $s, $code) = ($1, $2, $3);
			
			if (defined $mice_codes{$code}) {
				$p->{'deviceid'} = $mice_codes{$code};
				$p->{'comment'} = $s;
			} else {
				$p->{'deviceid'} = $response{'unknown'};
				$p->{'comment'} = $s . $code;
			}
			$p->{'messaging'} = 1 if ($b eq '`');
		}
		
		if ($p->{'deviceid'}) {
			$p->{'messaging'} = 1 if ($p->{'deviceid'}->{'messaging'});
			return 1;
		}
		
		return _a_err($p, 'mice_no_deviceid');
	}
	
	if (defined $fixed_dstcalls{$p->{'dstcallsign'}}) {
		$p->{'deviceid'} = $fixed_dstcalls{$p->{'dstcallsign'}};
		return 1;
	}
	
	foreach my $len (5, 4, 3, 2) {
		my $prefix = substr($p->{'dstcallsign'}, 0, $len);
		if (defined $regexp_prefix{$prefix}) {
			foreach my $dmatch (@{ $regexp_prefix{$prefix} }) {
				my($regexp, $response, $compiled) = @$dmatch;
				#warn "trying '$regexp' against " . $p->{'dstcallsign'} . "\n";
				if ($p->{'dstcallsign'} =~ $compiled) {
					#warn "match!\n";
					my %copy = %{ $response };
					$p->{'deviceid'} = \%copy;
					
					if ($response->{'version_regexp'}) {
						#warn "version_regexp set: $1 from " . $p->{'dstcallsign'} . " using " . $regexp . "\n";
						$p->{'deviceid'}->{'version'} = $1;
						delete $p->{'deviceid'}->{'version_regexp'};
					}
					
					return 1;
				}
			}
		}
	}
	
	return _a_err($p, 'no_id');
}


1;
__END__


=head1 SEE ALSO

APRS tocalls list, L<http://aprs.org/aprs11/tocalls.txt>

APRS mic-e type codes, L<http://aprs.org/aprs12/mic-e-types.txt>

APRS specification 1.0.1, L<http://www.tapr.org/aprs_working_group.html>

APRS addendums, e.g. L<http://web.usna.navy.mil/~bruninga/aprs/aprs11.html>

The source code of this module - there are some undocumented features.

=head1 AUTHORS

Heikki Hannikainen, OH7LZB E<lt>hessu@hes.iki.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010-2015 by Heikki Hannikainen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
