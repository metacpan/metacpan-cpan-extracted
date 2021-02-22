package Log::FreeSWITCH::Line::Data;

use strict;
use warnings;

use English;
use Error::Pure::Always;
use Error::Pure qw(err);
use Mo qw(builder is required);

our $VERSION = 0.07;

has date => (
	'is' => 'ro',
	'required' => 1,
);
has datetime_obj => (
	'is' => 'ro',
	'builder' => '_datetime',
);
has file => (
	'is' => 'ro',
	'required' => 1,
);
has file_line => (
	'is' => 'ro',
	'required' => 1,
);
has message => (
	'is' => 'ro',
);
has raw => (
	'is' => 'rw',
);
has time => (
	'is' => 'ro',
	'required' => 1,
);
has type => (
	'is' => 'ro',
	'required' => 1,
);

# Create DateTime object.
sub _datetime {
	my $self = shift;
	eval {
		require DateTime;
	};
	if ($EVAL_ERROR) {
		err "Cannot load 'DateTime' class.",
			'Error', $EVAL_ERROR;
	}
	my ($year, $month, $day) = split m/-/ms, $self->date;
	my ($hour, $min, $sec_mili) = split m/:/ms, $self->time;
	my ($sec, $mili) = split m/\./ms, $sec_mili;
	if (! defined $mili) {
		$mili = 0;
	}
	my $dt = eval {
		DateTime->new(
			'year' => $year,
			'month' => $month,
			'day' => $day,
			'hour' => $hour,
			'minute' => $min,
			'second' => $sec,
			'nanosecond' => $mili * 1000,
		);
	};
	if ($EVAL_ERROR) {
		err 'Cannot create DateTime object.',
			'Error', $EVAL_ERROR;
	}
	return $dt;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Log::FreeSWITCH::Line::Data - Data object which represents FreeSWITCH log line.

=head1 SYNOPSIS

 use Log::FreeSWITCH::Line::Data;

 my $obj = Log::FreeSWITCH::Line::Data->new(%params);
 my $date = $obj->date;
 my $datetime_o = $obj->datetime_obj;
 my $file = $obj->file;
 my $file_line = $obj->file_line;
 my $message = $obj->message;
 my $raw = $obj->raw($raw);
 my $time = $obj->time;
 my $type = $obj->type;

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<date>

 Date of log entry.
 Format of date is 'YYYY-MM-DD'.
 It is required.

=item * C<file>

 File in log entry.
 It is required.

=item * C<file_line>

 File line in log entry.
 It is required.

=item * C<message>

 Log message.

=item * C<raw>

 Raw FreeSWITCH log entry.

=item * C<time>

 Time of log entry.
 Format of time is 'HH:MM:SS'.
 It is required.

=item * C<type>

 Type of log entry.
 It is required.

=back

=item C<date()>

 Get log entry date.
 Returns string with date in 'YYYY-MM-DD' format.

=item C<datetime_obj()>

 Get DateTime object.
 Returns DateTime object.

=item C<file()>

 Get file in log entry.
 Returns string.

=item C<file_line()>

 Get file line in log entry.
 Returns string.

=item C<message()>

 Get log message.
 Returns string.

=item C<raw($raw)>

 Get or set raw FreeSWITCH log entry.
 Returns string.

=item C<time()>

 Get log entry time.
 Returns string with time in 'HH:MM:SS' format.

=item C<type()>

 Get log entry type.
 Returns string.

=back

=head1 ERRORS

 new():
         date required
         file required
         file_line required
         time required
         type required

 datetime_obj():
         Cannot create DateTime object.
                 Error: %s
         Cannot load 'DateTime' class.
                 Error: %s

=head1 EXAMPLE

 use strict;
 use warnings;

 use Log::FreeSWITCH::Line::Data;

 # Object.
 my $data_o = Log::FreeSWITCH::Line::Data->new(
         'date' => '2014-07-01',
         'file' => 'sofia.c',
         'file_line' => 4045,
         'message' => 'inbound-codec-prefs [PCMA]',
         'time' => '13:37:53.973562',
         'type' => 'DEBUG',
 );

 # Print out informations.
 print 'Date: '.$data_o->date."\n";

 # Output:
 # Date: 2014-07-01

=head1 DEPENDENCIES

L<DateTime>,
L<English>,
L<Error::Pure::Always>,
L<Error::Pure>,
L<Mo>.

=head1 SEE ALSO

=over

=item L<Log::FreeSWITCH::Line>

FreeSWITCH log line parsing and serializing.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Log-FreeSWITCH-Line>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2014-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.07

=cut
