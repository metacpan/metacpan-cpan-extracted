package EntityModel::Template;
{
  $EntityModel::Template::VERSION = '0.102';
}
use EntityModel::Class {
	include_path	=> { type => 'array', subclass => 'string' }
};

=head1 NAME

EntityModel::Template - template handling for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Template;
use Template::Stash;
use File::Basename;
use Tie::Cache::LRU;
use DateTime;
use POSIX qw/floor/;

tie my %LONG_DATE_HASH, 'Tie::Cache::LRU', 5000;
tie my %SHORT_DATE_HASH, 'Tie::Cache::LRU', 5000;

our $BasePath = '.';

BEGIN {
# Convenience functions so we can do something.arrayref and be sure to get back something FOREACH-suitable
	$Template::Stash::LIST_OPS->{ arrayref } = sub {
		my $list = shift;
		return $list;
	};
	$Template::Stash::HASH_OPS->{ arrayref } = sub {
		my $hash = shift;
		return [ $hash ];
	};
# hashops since we have datetime object... in theory.
	#$Template::Stash::HASH_OPS->{ msDuration } = sub {
	#	my $v = shift;
	#	return DateTime::Format::Duration->new(pattern => '%H:%M:%S.%3N')->format_duration($v);
	#};
	$Template::Stash::HASH_OPS->{ from_now } = sub {
		my $v = shift;
		return from_now($v);
	};
	$Template::Stash::HASH_OPS->{ 'ref' } = sub {
		my $scalar = shift;
		return ref $scalar;
	};
	$Template::Stash::SCALAR_OPS->{ arrayref } = sub {
		my $scalar = shift;
		return [ $scalar ];
	};
	$Template::Stash::SCALAR_OPS->{ trim } = sub {
		my $scalar = shift;
		$scalar =~ s/^\s+//ms;
		$scalar =~ s/\s+$//ms;
		return $scalar;
	};
	$Template::Stash::SCALAR_OPS->{ js } = sub {
		my $str = join('', @_);
		$str =~ s/"/\\"/ms;
		return '"' . $str . '"';
	};
}

sub new {
	my $class = shift;
	my $self = bless { data => { } }, $class;
	my %args = @_;
	if(defined(my $include = delete $args{include_path})) {
		$include = [ $include ] unless ref $include;
		$self->include_path->push($_) for @$include;
	}

	# We want access to _ methods, such as _view, so disable this.
	undef $Template::Stash::PRIVATE;

	my %cfg = (
		INCLUDE_PATH	=> [ $self->include_path->list ],
		INTERPOLATE	=> 0,
		ABSOLUTE	=> 0,
		RELATIVE	=> 0,
		RECURSION	=> 1,
		AUTO_RESET	=> 0,
		STAT_TTL	=> 15,
		COMPILE_EXT	=> '.ttc',
		COMPILE_DIR	=> '/tmp/ttc',
		CACHE_SIZE	=> 4096,
		PRE_DEFINE	=> {
#				cfg		=> \%EntityModel::Config::Current,
#				imageHost	=> 'http://' . EntityModel::Config::ImageHost,
#				scriptHost	=> 'http://' . EntityModel::Config::ScriptHost,
		},
		FILTERS		=> {
			long_date	=> [
				sub {
					my ($context, @args) = @_;
					return sub {
						return long_date(shift, @args);
					}
				}, 1
			],
			short_date	=> [
				sub {
					my ($context, @args) = @_;
					return sub {
						return short_date(shift, @args);
					}
				}, 1
			],
			ymd_date	=> [
				sub {
					my ($context, @args) = @_;
					return sub {
						return ymd_date(shift, @args);
					}
				}, 1
			],
			tidy_ymd	=> [
				sub {
					my ($context, @args) = @_;
					return sub {
						return tidy_ymd(shift, @args);
					}
				}, 1
			],
			from_now	=> [
				sub {
					my ($context, @args) = @_;
					return sub {
						return from_now(shift, @args);
					}
				}, 1
			],
			#as_duration => [
			#	sub {
			#		my ($context, @args) = @_;
			#		return sub {
			#			return as_duration(shift, @args);
			#		}
			#	}, 1
			#],
		},
	);
	#$cfg{CONTEXT} = new Template::Timer(%cfg) if EntityModel::Config::Debug;
	my $tmpl = Template->new(%cfg) or die Template->error;
	$self->{ template } = $tmpl;
	return $self;
}

=head2 from_now

Duration from/since now

=cut

sub from_now {
	my $v = shift;
	return ' ' unless $v;

	$v = DateTime->from_epoch(epoch => $1) if !ref($v) && $v =~ /^(\d+(?:\.\d*))$/;
	my $delta = $v->epoch - time;
	my $neg;
	if($delta < 0) {
		$neg = 1;
		$delta = -$delta;
	}
	my @p;
	my @match = (
		second => 60,
		minute => 60,
		hour => 24,
		day => 30,
		month => 12,
		year => 0
	);
	while($delta && @match) {
		my $k = shift @match;
		my $m = shift @match;
		my $unit = $m ? ($delta % $m) : $delta;
		$delta = floor($delta / $m) if $m;
		unshift @p, "$unit $k" . ($unit != 1 ? 's' : '');
	}

# Don't show too much resolution
	@p = @p[0..1] if @p > 2;
	my $pattern = join(', ', @p);

	return $pattern . ($neg ? ' ago' : ' from now');
}

=head2 long_date

Long date format filter.

=cut

sub long_date {
	my ($v, $fmt) = @_;
	return ' ' unless $v;
	unless ($LONG_DATE_HASH{$v}) {
		my $dt;
		if($v =~ m/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?$/) {
			my ($year, $month, $day, $hour, $minute, $second, $us) = ($1, $2, $3, $4, $5, $6, $7);
			$dt = DateTime->new(
				year		=> $year,
				month		=> $month,
				day		=> $day,
				hour		=> $hour,
				minute		=> $minute,
				second		=> $second,
				nanosecond	=> 1000 * ($us // 0)
			);
		} else {
			$dt = DateTime->from_epoch(epoch => $v);
		}
		$LONG_DATE_HASH{$v} = $dt->strftime('%e %b %Y, %l:%M %P');
	}
	return $LONG_DATE_HASH{$v};
}

=head2 short_date

Short date format filter.

=cut

sub short_date {
	my ($v, $fmt) = @_;
	return ' ' unless $v;
	unless ($SHORT_DATE_HASH{$v}) {
		my $dt;
		if($v =~ m/^(\d+)-(\d+)-(\d+)/) {
			my ($year, $month, $day) = ($1, $2, $3);
			$dt = DateTime->new(
				year		=> $year,
				month		=> $month,
				day		=> $day,
			);
		} else {
			$dt = DateTime->from_epoch(epoch => $v);
		}
		my $suffix = 'th';
		if(($dt->day % 10) == 1 && ($dt->day != 11)) {
			$suffix = 'st';
		} elsif(($dt->day % 10) == 2 && ($dt->day != 12)) {
			$suffix = 'nd';
		} elsif(($dt->day % 10) == 3 && ($dt->day != 13)) {
			$suffix = 'rd';
		}
		$SHORT_DATE_HASH{$v} = $dt->strftime("%d$suffix %b");
	}
	return $SHORT_DATE_HASH{$v};
}

=head2 ymd_date

YMD date filter

=cut

sub ymd_date {
	my ($v, $fmt) = @_;
	return ' ' unless $v;
	my $dt;
	if($v =~ m/^(\d+)-(\d+)-(\d+)/) {
		my ($year, $month, $day) = ($1, $2, $3);
		return sprintf("%04d-%02d-%02d", $year, $month, $day);
	} else {
		$dt = DateTime->from_epoch(epoch => $v);
	}
	return $dt->strftime('%Y-%m-%d');
}

=head2 tidy_ymd

YMD date filter

=cut

sub tidy_ymd {
	my ($v, $fmt) = @_;
	return ' ' unless $v;
	my $dt;
	if($v =~ m/^(\d+)-(\d+)-(\d+)/) {
		my ($year, $month, $day) = ($1, $2, $3);
		return sprintf("%04d-%02d-%02d", $year, $month, $day);
	} else {
		$dt = DateTime->from_epoch(epoch => $v);
		return $dt->strftime('%Y-%m-%d');
	}
}

=head2 as_duration

Convert duration to MM:SS representation.

=cut

sub as_duration {
	my ($v, $fmt) = @_;
	return ' ' unless $v;

	return sprintf('%02d:%02d', int($v / 60), int($v % 60));
}

=head2 template

Return the TT2 object, created as necessary.

=cut

sub template { shift->{template} }

=head2 as_text

Return template output as text.

=cut

sub as_text {
	my ($self, $template, $newData) = @_;
	$newData ||= {};
	my %data = ( %{ $self->{data} }, %$newData );
	my $output;
	my $tt = $self->template;
	$tt->process($template, \%data, \$output) || die 'Failed template: ' . $tt->error;
	return $output;
}

sub process_template {
	my $self = shift;
	my $tmpl = shift;
	my $tt = $self->template;
	$tt->process($tmpl, undef, \my $output) or die "Failed template: " . $tt->error;
	return $self;
}

=head2 processHTML

Process HTML data.

=cut

sub processHTML {
	my ($self, $template, $newData) = @_;
	my $data = { %{$self->{data}}, %$newData };

	my $tt = $self->template;
	my $output;
	$tt->process($template, $data, \$output) || die 'Failed template: ' . $tt->error;
	if(0) {
		my $origSize = length($output);
		$output =~ s/<!--(.*?)-->//g;
		my $tidy = HTML::Tidy->new({
			tidy_mark		=> 0,
			'preserve-entities'	=> 1,
			wrap			=> 160,
			'char-encoding'		=> 'utf8',
			indent			=> 0
		});
		$output = $tidy->clean($output);
		my $finalSize = length($output);
		logDebug("From %d to %d: %3.2f%%", $origSize, $finalSize, (100.0 * $finalSize/$origSize));
	}
	return $output;
}

=head2 output

Generate output via Apache2 print.

=cut

sub output {
	my ($self, $template, $newData, $r) = @_;
	my $data = { %{$self->{data}}, %$newData };

	logInfo("Output");
	my $output = $self->processHTML($template, $data);
	if($r) {
		$r->content_type('text/html') if $r;
		$r->no_cache(1);
		$r->setLifetime(0);
		$r->print($output);
	} else {
		print $output;
	}
}

=head2 error

Handle any TT2 error messages.

=cut

sub error {
	my $self = shift;
	return $self->template->error;
}

sub addData {
	my ($self, $data) = @_;
	foreach (keys %$data) {
		$self->{data}->{ $_ } = $data->{$_};
	}
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
