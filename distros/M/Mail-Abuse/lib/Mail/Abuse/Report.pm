package Mail::Abuse::Report;

require 5.005_62;

use Carp;
use strict;
use warnings;
use IO::File;
# use Config::Auto;
use Params::Validate qw(:all);
				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

				# Keys that we keep after a flush
our @Keep = qw/
    text
    debug
    config
    reader
    filters
    parsers
    processors
/;

=pod

=head1 NAME

Mail::Abuse::Report - Process an abuse report

=head1 SYNOPSIS

  use Mail::Abuse::Report;

  my $r = new Mail::Abuse::Report
    (
     -text		=> \$report_text,
     -reader		=> $reader,
     -filters		=> [ $f1, $f2, ... ],
     -parsers		=> [ $i1, $i2, ... ],
     -processors	=> [ $p1, $p2, ... ],
     -debug		=> 1,
     -config		=> $config_file,
     );

=head1 DESCRIPTION

This class encapsulates an abuse report and provides methods to
automate tasks such as extracting individual incidents from it, filtering the incidents, etc.

Each of the methods are described in detail, below:

=over

=item C<-E<gt>new(%args)>

Creates a new C<Mail::Abuse::Report> object. It accepts the following
arguments:

=over

=item C<-text>

Specifies the text that will be used to fill the report with. This is
incompatible with C<-reader>, so choose one and stick to it. Defaults
to C<undef>.

=item C<-reader>

Specifies the object (tipically a member of C<Mail::Abuse::Reader>)
that will be used to fetch the text of the next report. This is
incompatible with C<-text>, so pick one and stick to it. Defaults to
C<undef>.

=item C<-filters>

A reference to a list of objects that can filter incidents. Normally,
objects based on C<Mail::Abuse::Filter>. Defaults to no filters.

=item C<-parsers>

A reference to a list of objects that can parse incidents out of the
report text. Normally, objects based on
C<Mail::Abuse::Incident>. Defaults to no parsers.

=item C<-processors>

A reference to a list of objects that can process the incidents on the
report, normally objects based on the C<Mail::Abuse::Processor>
class. Defaults to no processors.

=item C<-debug>

A true value causes diagnostic messages to be sent via C<warn()>.

=item C<-config>

Specifies the name of the config file to fetch configuration items
from. Can be left unspecified.

=back

=cut

sub new
{
    my $type	= shift;
    my $class	= ref($type) || $type || 'Mail::Abuse::Report';

    croak "Invalid call to Mail::Abuse::Report::new"
	unless $class;

    my %self = validate_with
	(
	 params		=> \@_,
	 ignore_case	=> 1,
	 strip_leading	=> '-',
	 spec		=>
	 {
	     text =>
	     {
		 type		=> SCALARREF,
		 default	=> undef,
	     },
    
	     reader =>
	     {
		 type		=> OBJECT,
		 can		=> [ qw(read) ],
		 default	=> undef,
	     },

	     filters =>
	     {
		 type		=> ARRAYREF,
		 default	=> [],
	     },

	     parsers =>
	     {
		 type		=> ARRAYREF,
		 default	=> [],
	     },

	     processors =>
	     {
		 type		=> ARRAYREF,
		 default	=> [],
	     },

	     debug =>
	     {
		 type		=> SCALAR,
		 default	=> 0,
	     },

	     config =>
	     {
		 type		=> SCALAR,
		 default	=> undef,
		 callbacks	=>
		 {
		     'config file must be readable' => sub
		     {
			 defined $_[0] and -f $_[0];
		     },
		 },
	     },
	 },
	 );

    my $self = \%self;

    bless $self, $class;

    $self->load_config or return;

    $self->incidents([]);

    return $self;

}

sub load_config
{
    my $self = shift;
    my $config = $self->config;
    warn "M::A::Report: reading config" if $self->debug;
#    eval { $self->config(Config::Auto::parse($config, format => 'colon')) };
    $self->config({});

    my $fh = new IO::File $config;
    
    unless ($fh)
    {
	warn "M::A::Report: Failed to open $config: $!\n";
	return;
    }

    while (<$fh>)
    {
	chomp;
	s/\#.*$//g;
	next unless /^([^:]+):\s*(.*)$/;
	$self->config->{lc $1} = $2;
    }
    
    $fh->close;

    warn "Config read: $@\n" if $self->debug;
    return if $@;
    return $self;
}

=pod

=item C<-E<gt>next()>

When the object has a reader, fetches the next report text, parses it
with the incidents and filters the incidents and processes them with the
supplied processors.

Returns the report object if succesful or false otherwise.

If no reader has been supplied to the report object, the same text
will be analyzed over and over again.

=cut

sub next
{
    my $self = shift;

    $self->flush;
    
    if ($self->reader)
    {
	warn "Reading from reader object\n" if $self->debug;
	return unless $self->reader->read($self);
    }

    return unless $self->text;

    for my $i (@{$self->parsers})
    {
	warn "Parsing with parser $i\n" if $self->debug;
	my @incidents = $i->parse($self);
	warn scalar @incidents, " incidents found\n" if $self->debug;
	next unless @incidents;

	warn "init incidents: ", join(',', map { ref $_ } @incidents), "\n"
	    if $self->debug;
	
	for my $f (@{$self->filters})
	{
	    warn "Filtering with filter $f\n" if $self->debug;
	    @incidents = grep { $f->criteria($self, $_) } @incidents;
	    warn scalar @incidents, " incidents left\n" if $self->debug;
	}
	
	warn scalar @incidents, " final incidents left\n" if $self->debug;
	push @{$self->incidents}, @incidents;
    }

				# At this point, the incidents are
				# properly registered within the
				# object, so we can safely process
				# them

    for my $p (@{$self->processors})
    {
	warn "Processing with $p\n" if $self->debug;
	$p->process($self);
    }

    return $self;
}

=pod

=item C<-E<gt>flush()>

Discards all non-essential information from the object. It is meant to
be called before reusing the object to process a new report.

This method is automatically called by C<-E<gt>next>.

=cut

sub flush
{
    my $self = shift;

    warn "M::A::Report->flush" if $self->debug;

    for my $k (keys %$self)
    {
	next if grep { $k eq $_ } @Keep;
	warn "flush key $k\n" if $self->debug;;
	delete $self->{$k};
    }

    $self->incidents([]);

    return $self;
}

=pod

=back

Also, a number of acccessor methods are defined as follows:

=over

=item C<-E<gt>filters>

When invoked without arguments, returns a reference to the list of
filters (C<Mail::Abuse::Filter> objects) attached to this abuse
report. Calling the accessor with a list of objects will replace
whatever was the prior list.

The list can be manipulated, affecting the object directly.

=item C<-E<gt>incidents>

When invoked without arguments, returns a reference to the list of
incidents extracted from this report (C<Mail::Abuse::Incident>
objects). Calling the accessor with a reference to a list of objects
will replace whatever was the prior list.

The list can be manipulated, affecting the object directly.

=item C<-E<gt>parsers>

When invoked without arguments, returns a reference to the list of
parsers that are used in this report (C<Mail::Abuse::Incident>
objects). Calling the accessor with a reference to a list of objects
will replace whatever was the prior list.

The list can be manipulated, affecting the object directly.

=item C<-E<gt>processors>

When invoked without arguments, returns a reference to the list of
processors attached to this report (C<Mail::Abuse::Processor>
objects). Calling the accessor with a reference to a list of objects
will replace whatever was the prior list.

The list can be manipulated, affecting the object directly.

=item C<-E<gt>text>

Accepts a reference to a scalar containing the text of the report.

Returns a reference to the text of the report.

If the text is altered, you should call C<-E<gt>flush()> to avoid
insanity.

=item C<-E<gt>reader>

If passed a reader object, it will replace the one used for
initialization. Otherwise, will return the reader object passed to
C<-E<gt>new>.

=item C<-E<gt>config>

Returns a reference to a hash containing the configuration information
read-in by this report. It can be replaced by simply supplying a new
reference to a configuration hash.

=item C<-E<gt>debug>

Returns the debug level of the object. When set to true, debug
information is issued through C<warn>.

=cut

sub AUTOLOAD 
{
    no strict "refs";
    use vars qw($AUTOLOAD);
    my $method = $AUTOLOAD;
    $method =~ s/^.*:://;
    *$method = sub 
    { 
	my $self = shift;
	my $ret = $self->{$method};
	if (@_)
	{
	    $ret = $self->{$method};
	    $self->{$method} = shift;
	}
	return $ret;
    };
    goto \&$method;
}

1;

__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.2 with options

  -ACOXcfkn
	Mail::Abuse
	-v
	0.01

=back

=head1 LICENSE AND WARRANTY

This code is distributed under the same terms as Perl itself,
providing the exact same warranty.

=head1 LICENSE AND WARRANTY

This code and all accompanying software comes with NO WARRANTY. You
use it at your own risk.

This code and all accompanying software can be used freely under the
same terms as Perl itself.

=head1 LICENSE AND WARRANTY

This code and all accompanying software comes with NO WARRANTY. You
use it at your own risk.

This code and all accompanying software can be used freely under the
same terms as Perl itself.

=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
