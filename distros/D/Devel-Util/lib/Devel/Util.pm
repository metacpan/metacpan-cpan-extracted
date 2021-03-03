package Devel::Util;
use strict;
use warnings;
# use Scalar::Util;
# use Time::HiRes;
# use POSIX;
# use Carp;

use base 'Exporter';
our %EXPORT_TAGS = ( 
	all => [ qw(
		oiaw once_in_a_while
		dt do_time
		printr print_refresh
		forked
		tz timezone
	) ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

our $VERSION = '0.80';
our $QUIET;

$Carp::Internal{(__PACKAGE__)} = 1;

{
	my $pid = $$;
	sub forked () {
		$pid != $$
	}
}

sub printr;
sub print_refresh;
*print_refresh = *printr = _printr();

sub _printr {
	my $fh = shift || \*STDERR;
	my $former_str;
	my $str_len = 0;
	sub {
		return if $QUIET;
		my $str = shift;
		$str = sprintf($str, @_) if @_;
		# $str =~ s/[ \t]+$//;
		$str =~ s/[\r\b]//g;
		my $add_str;
		if ($str =~ /\n/) {
			($str, $add_str) = split(/\n/, $str, 2);
		}
		my $tr = $str_len - length($str);
		$str .= ' 'x$tr if $tr>0;
		$str_len -= $tr;
		if ($str =~ /[\b\r\n]/) {
			print $fh "\r$str";
			$str_len = length($str);
			$former_str = '';
		} else {
			if ($former_str) {
				($str^$former_str) =~ /^(\0{0,255})/;
				my $prefix_len = length($1);
				my $postfix_len = length($former_str) - $prefix_len;
				$former_str = $str;
				if ($prefix_len > $postfix_len) {
					$str = ("\b" x $postfix_len) . substr($str, $prefix_len)
				} else {
					$str = "\r$str";
				}
			} else {
				$former_str = $str;
				$str = "$str";
			}
			print $fh $str;
			if ($tr>0) {
				$former_str =~ s/ {$tr}$//;
				print $fh "\b"x$tr;
			}
			if (defined $add_str) {
				$former_str = $add_str;
				$str_len = length($add_str);
				print $fh "\n", $add_str;
			}
		}
	}
}

{
	no warnings 'uninitialized';
	my %last_times;
	sub oiaw (&;$) {
		require Time::HiRes;
		if (defined wantarray) {
			my $code = shift;
			my $delay = shift || 1;
			my $last_time = 0;
			sub {
				return unless Time::HiRes::time() - $last_time >= $delay || $_[0] && $_[0] eq '-force';
				$last_time = Time::HiRes::time();
				$code->(@_)
			}
		} else {
			my (undef, $file, $line) = caller;
			return if Time::HiRes::time() - $last_times{$file.$line} < ($_[1]||1);
			$last_times{$file.$line} = Time::HiRes::time();
			$_[0]->();
			1
		}
	}
}

sub tz (&$) {
	require POSIX;
	my ($block, $tz) = @_;
	my (@ret, $ret);
	{
		local $ENV{TZ} = $tz;
		POSIX::tzset();
		if (wantarray) {
			eval {@ret = $block->()}
		}
		elsif (defined wantarray) {
			eval {$ret = $block->()}
		}
		else {
			eval {$block->()}
		}
	}
	POSIX::tzset();
	die $@ if $@;
	wantarray ? @ret : $ret
}

{
	my $timestr = sub {
		my $d = shift;
		$d = 0 if $d<0;
		sprintf("%dm%.3fs", int($d/60), $d - 60*int($d/60))
	};
	sub dt (&;$) {
		require Time::HiRes;
		my $block = shift;
		my $name = shift || sprintf 'dt at %s line %d', (caller)[1,2];
		my ($t_elapsed_0, $t_elapsed_1, $t_user_0, $t_user_1, $t_sys_0, $t_sys_1);
		my @ret;
		my $ret;

		($t_user_0, $t_sys_0) = times;
		$t_elapsed_0 = Time::HiRes::time();
		if (wantarray) {
			@ret = $block->()
		}
		elsif (defined wantarray) {
			$ret = $block->()
		}
		else {
			$block->()
		}
		$t_elapsed_1 = Time::HiRes::time();
		($t_user_1, $t_sys_1) = times;

		printf STDERR ("\nTiming report for %s:\nreal    %s\nuser    %s\nsys     %s\n\n",
			$name,
			$timestr->($t_elapsed_1 - $t_elapsed_0),
			$timestr->($t_user_1 - $t_user_0),
			$timestr->($t_sys_1 - $t_sys_0),
		) unless $QUIET;
		
		wantarray ? @ret : $ret
	}
}

sub do_time (&;$);
*do_time = \&dt;

sub once_in_a_while (&;$);
*once_in_a_while = \&oiaw;

sub timezone (&$);
*timezone = \&tz;

1