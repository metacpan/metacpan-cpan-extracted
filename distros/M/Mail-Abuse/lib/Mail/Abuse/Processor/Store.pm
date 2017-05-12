package Mail::Abuse::Processor::Store;

require 5.005_62;

use Carp;
use strict;
use warnings;
use Data::Dumper;

use IO::File;
use File::Path;
use File::Spec;
use PerlIO::gzip;
use POSIX qw(strftime);
use Storable qw/nstore_fd/;
use Digest::MD5 qw/md5_hex/;

use base 'Mail::Abuse::Processor';

use constant ROOT	=> 'store root path';
use constant EMPTY	=> 'store empty path';
use constant MODE	=> 'store mode';
use constant DEBUG	=> 'debug store';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Processor::Store - Process a Mail::Abuse::Report

=head1 SYNOPSIS

  use Mail::Abuse::Processor::Store;

  use Mail::Abuse::Report;
  my $p = new Mail::Abuse::Processor::Store;
  my $report = new Mail::Abuse::Report (processors => [ $p ]);

  # ... other pieces of code that configure the report ...

=head1 DESCRIPTION

This class stores a processed report in a file hierarchy that is
composed using the smallest acceptable timestamp from the list of
incidents in a report.

If no incidents are found within a report, a special name is built
based on the report text.

The place where the files are created can be controlled with entries
in the configuration file. Currently, the following directives are
understood.

=over

=item B<store root path>

Points to the root of the tree where reports are to be
stored. Defaults to the current directory.

=item B<store empty path>

The name of the leaf where reports with no incidents are stored. This
is a subdir of B<store root path>. It defaults to the very creative
name, "empty".

=item B<store mode>

The mode in which to store abuse reports. The following modes are
supported.

=over

=item B<serialized>

This is the default, and uses L<Storable> to serialize the in-memory
C<Mail::Abuse::Report> object and store it in a flat file.

=item B<serialized-gz>

Just like B<serialized>, but the resulting file is compressed with the
equivalent of L<gzip>, using L<PerlIO::gzip>.

=item B<plain>

Store only the report text, as a flat file.

=item B<plain-gz>

Just like B<plain> but the resulting file is compressed on the fly
using L<PerlIO::gzip>.

=back

=item B<debug store>

If set to a true value, causes this module to emit debugging
information using C<warn()>.

=back

The following functions are implemented.

=over

=item C<process($report)>

Takes a C<Mail::Abuse::Report> object as an argument and performs the
processing action required.

The processed C<$report> will have the filename where the report was
stored, added in C<store_file>.

=cut

sub process
{
    my $self	= shift;
    my $rep	= shift;

    my $earliest = $rep->incidents->[0];

    my $path;
    my $file;
    
    unless ($self->root)
    {
	$self->root($rep->config->{&ROOT} || File::Spec->curdir());
	warn "Store: Root set to '" . $self->root . "'\n"
	    if $rep->config->{&DEBUG};
    }

    unless ($self->empty)
    {
	$self->empty($rep->config->{&EMPTY} || 'empty');
	warn "Store: Empty placeholder set to '" . $self->empty . "'\n"
	    if $rep->config->{&DEBUG};
    }

    if ($earliest)
    {
	for my $i (@{$rep->incidents})
	{
	    if ($i->time and $earliest->time and $i->time < $earliest->time) 
	    { 
		$earliest = $i; 
	    }
	    elsif (! defined $earliest->time)
	    {
		$earliest = $i;
	    }
	}

	if (defined $earliest->time)
	{
				# Build the pathname...
	    $path = File::Spec->catdir
		(
		 $self->root, split
		 (/:/, strftime("%Y:%m:%d", 
				(localtime($earliest->time))[0..5])
		  ),
		 );
	    
	    $file = File::Spec->catfile($path, md5_hex($ {$rep->text}));
	}
	else
	{
	    warn "Store: No incident has time!\n"
		if $rep->config->{&DEBUG};
	}
    }

    unless ($file and $path)
    {
	$path = File::Spec->catdir
	    (
	     $self->root,
	     $self->empty,
	     );

	$file = File::Spec->catfile($path, md5_hex($ {$rep->text}));
    }
    
    warn "Store: File name set to $file\n"
	if $rep->config->{&DEBUG};

    eval { mkpath [ $path ] };		# Create the target path...

    if ($@)
    {
	warn "Store: Failed to create dir $path: $!\n";
	return;
    }

    if (-f $file)
    {
	warn "Store: $file already exists. Not overriden\n";
	return 1;
    }

    $rep->store_file($file);

    my $fh = new IO::File;

    if (exists $rep->config->{&MODE}
	and $rep->config->{&MODE} =~ m/-gz$/)
    {
	unless ($fh->open($file, ">:gzip"))
	{
	    warn "Store: Failed to gz-open $file: $!\n";
	    return;
	}
    }
    else
    {
	unless ($fh->open($file, ">"))
	{
	    warn "Store: Failed to open $file: $!\n";
	    return;
	}
    }

    if (not exists $rep->config->{&MODE}
	or $rep->config->{&MODE} =~ m/^serialized/)
    {
	eval 
	{ 
	    nstore_fd($rep, $fh) 
		|| warn "Storable::nstore_fd failed with $!\n";
	};
	
	if ($@)
	{
	    warn "Store: Failed to nstore: $@\n";
	    return;
	}

    }
    elsif ($rep->config->{&MODE} =~ m/^plain/)
    {
	print $fh ${$rep->text};
    }

    unless ($fh->close)
    {
	warn "Failed to close $file: $!\n";
	return;
    }
    
    return 1;
}

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

This code and all accompanying software comes with NO WARRANTY. You
use it at your own risk.

This code and all accompanying software can be used freely under the
same terms as Perl itself.

=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
