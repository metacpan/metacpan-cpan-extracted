package Gruntmaster::Opener;
use 5.014;
use warnings;

use parent qw/Exporter/;
use re '/s';

our @EXPORT = qw/handle_line/;
our @EXPORT_OK = @EXPORT;
our $VERSION = '6000.001';

use Date::Parse qw/str2time/;
use Gruntmaster::Data;

sub _analyze_request {
	s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg for @_; # From URI::Escape POD
	my ($req, $parms) = @_;
	return unless $parms =~ /contest=(\w+)/;
	my $ct = $1;
	return $req =~ m,/pb/(\w+), ? ($1, $ct) : ();
}

sub handle_line {
	my ($owner, $datetime, $request, $parms) = $_[0] =~
	  /(\w+)\s       # user
	   \[([^]]+)\]\s # date
	   "\w+\s        # request method
	   ([^" ?]+)     # URL (without query string)
	   [?]
	   ([^" ]+)\s    # query string
	   [^"]+"\s      # HTTP version
	   2             # response code starts with 2
	  /x or return;
	my ($pb, $ct) = _analyze_request $request, $parms or return;
	my $time = str2time $datetime;
	open_problem $ct, $pb, $owner, $time;
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::Opener - Populate opens table from NCSA access logs

=head1 SYNOPSIS

  use Gruntmaster::Opener;

  open my $fh, '<', '/var/log/apache2/access.log';
  handle_line $_ while <$fh>;

=head1 DESCRIPTION

Gruntmaster::Opener is the backend of the L<gruntmaster-opener> script
that reads NCSA-style access logs, finds lines that represent
successful requests to problems during contests, extracts data from
them and inserts it into the database.

B<handle_line>($line)

The only function in this module. Exported by default. Takes a single
parameter, a line from a logfile in NCSA common/combined format.

If the request described in the given line:

=over

=item *

Is successful (response code is 2xx)

=item *

Targets a problem (C</pb/something>)

=item *

Has a query parameter named C<contest>

=item *

Happened during the contest named in the C<contest> query parameter
(this restriction is enforced by the B<open_problem> function).

=back

an entry is added to the C<opens> table, using the B<open_problem>
function from L<Gruntmaster::Data>.

=head1 SEE ALSO

L<gruntmaster-opener>

=head1 AUTHOR

Marius Gavrilescu E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
