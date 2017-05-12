package Log::FreeSWITCH::Line;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use Error::Pure qw(err);
use Log::FreeSWITCH::Line::Data;
use Readonly;
use Scalar::Util qw(blessed);

# Constants.
Readonly::Array our @EXPORT_OK => qw{parse serialize};
Readonly::Scalar our $LOG_REGEXP => qr{(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2}\.?\d*)\s+\[(\w+)\]\s+([^:]+):(\d+)\s+(.*)};
Readonly::Scalar our $SPACE => q{ };

# Version.
our $VERSION = 0.06;

# Parse FreeSWITCH log line.
sub parse {
	my $data = shift;
	my $data_o;
	if ($data =~ m/^$LOG_REGEXP$/ms) {
		$data_o = Log::FreeSWITCH::Line::Data->new(
			'date' => $1,
			'file' => $4,
			'file_line' => $5,
			'message' => $6,
			'raw' => $data,
			'time' => $2,
			'type' => $3,
		);
	} else {
		err 'Cannot parse data.',
			'Data', $data;
	}
	return $data_o;
}

# Serialize Log::FreeSWITCH::Line::Data object to FreeSWITCH log line.
sub serialize {
	my $data_o = shift;

	# Check object.
	if (! blessed($data_o) || ! $data_o->isa('Log::FreeSWITCH::Line::Data')) {
		err "Serialize object must be 'Log::FreeSWITCH::Line::Data' object.";
	}

	# Serialize.
	my $data = $data_o->date.
		$SPACE.$data_o->time.
		$SPACE.'['.$data_o->type.']'.
		$SPACE.$data_o->file.':'.$data_o->file_line.
		$SPACE;
	if (defined $data_o->message) {
		$data .= $data_o->message;
	}
	$data_o->raw($data);
	return $data;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Log::FreeSWITCH::Line - FreeSWITCH log line parsing and serializing.

=head1 SYNOPSIS

 use Log::FreeSWITCH::Line qw(parse serialize);
 my $data_o = parse($data);
 my $data = serialize($data_o);

=head1 SUBROUTINES

=over 8

=item C<parse($data)>

 Parse FreeSWITCH log line.
 Returns Log::FreeSWITCH::Line::Data object.

=item C<serialize($data_o)>

 Serialize Log::FreeSWITCH::Line::Data object to FreeSWITCH log line.
 Returns string.

=back

=head1 ERRORS

 parse():
         Cannot parse data.
                 Data: %s

 serialize():
         Serialize object must be 'Log::FreeSWITCH::Line::Data' object.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Module.
 use Data::Printer;
 use Log::FreeSWITCH::Line qw(parse);

 # Log record.
 my $data = '2014-07-01 13:37:53.973562 [DEBUG] sofia.c:4045 inbound-codec-prefs [PCMA]';

 # Parse.
 my $data_o = parse($data);

 # Dump.
 p $data_o;

 # Output:
 # Log::FreeSWITCH::Line::Data  {
 #     Parents       Mo::Object
 #     public methods (0)
 #     private methods (1) : _datetime
 #     internals: {
 #         date        "2014-07-01",
 #         file        "sofia.c",
 #         file_line   4045,
 #         message     "inbound-codec-prefs [PCMA]",
 #         raw         "2014-07-01 13:37:53.973562 [DEBUG] sofia.c:4045 inbound-codec-prefs [PCMA]",
 #         time        "13:37:53.973562",
 #         type        "DEBUG"
 #     }
 # }

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Module.
 use Log::FreeSWITCH::Line qw(serialize);
 use Log::FreeSWITCH::Line::Data;

 # Data.
 my $record = Log::FreeSWITCH::Line::Data->new(
         'date' => '2014-07-01',
         'file' => 'sofia.c',
         'file_line' => 4045,
         'message' => 'inbound-codec-prefs [PCMA]',
         'time' => '13:37:53.973562',
         'type' => 'DEBUG',
 );

 # Serialize and print to stdout.
 print serialize($record)."\n";

 # Output:
 # 2014-07-01 13:37:53.973562 [DEBUG] sofia.c:4045 inbound-codec-prefs [PCMA]

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Log::FreeSWITCH::Line::Data>,
L<Readonly>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Log::FreeSWITCH::Line::Data>

Data object which represents FreeSWITCH log line.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Log-FreeSWITCH-Line>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.06

=cut
