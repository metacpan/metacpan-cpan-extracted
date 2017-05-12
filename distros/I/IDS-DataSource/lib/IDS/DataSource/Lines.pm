package IDS::DataSource::Lines;
use base qw(IDS::DataSource);

=head1 IDS::DataSource::Lines

=head2 Introduction

This class is a subclass of IDS::DataSource, and meets its interface
specification.

This class exists primarily as a template for new IDS::DataSource subclasses,
but it is fully-functional, if a little boring.

=cut

use strict;
use warnings;
use Carp qw(cluck carp confess);
use IO::Handle;

$IDS::DataSource::Lines::VERSION     = "1.0";

=over

=item load(source)

load exactly one request from a file, IO::Handle, or supplied string.
If a string is used, it is up to the caller to ensure that more than
one request is not in the string.

=back

=cut

sub load {
    my $self  = shift;
    my $source = shift;
    defined($source) or
        confess *load{PACKAGE} . "::load called without a source\n";

    $self->empty();
    if ($source->isa("IO::Handle")) {
	${$self->{"params"}}{"source"} = "IO::handle";
	$self->read_session($source);
    } elsif ($source =~ /\n/) {
	${$self->{"params"}}{"source"} = "Supplied string";
	$self->{"data"} = $source;
    } elsif (-f $source) {
	${$self->{"params"}}{"source"} = $source;
	my $fh = new IO::File("< $source");
	defined($fh) or carp "Unable to open $source: $!";
	$self->read_session($fh);
    } else {
        confess *load{PACKAGE} . "::load: I do not know what to do with '$source'\n";
    }
    $self->parse;
}

=over

=item read_session(filehandle)

Read an HTTP session (up to EOF or a blank line) from the filehandle
passed as an argument.

=back

=cut

sub read_session {
    my $self  = shift;
    my $fh = shift or 
        cluck *read_session{PACKAGE} .
	      "::read_session called without a filehandle";

    my $data = <$fh>;
    chomp($data);

    if (defined($data) && $data) {
	$self->load($data);
	return 1;
    } else {
	$self->warn(${$self->{"params"}}{"source"} . ": data was empty", [],"");
	return 0;
    }
}

=over

=item read_next(filehandle)

Read the next request from the list of files (filehandle containing
list of file names is argument).  

=back

=cut

# This function has to keep track of state, making it more complex than
# a loop in a caller.
sub read_next {
    my $self  = shift;
    my $fname_fh = shift;
    defined($fname_fh) or
        cluck *read_next{PACKAGE} . "::read_next called without a filehandle";
    
    my $fh = $self->{"current_fh"};

    # reset everything for the new request
    $self->empty();

    my $ret;
    do {
	# See if we are done.
	return undef if $fname_fh->eof && $fh->eof;

	# while we need another file and we have files in the list;
	# may run 0 times if there is more to read from the current
	# file.
	while (! (defined($fh) && ! $fh->eof) && ! $fname_fh->eof) {
	    $self->mesg(1, "Processed " . $self->{"fname"} . "\n")
	        if exists($self->{"fname"}) && defined($self->{"fname"});
	    $fh = $self->open_next($fname_fh);
	}
	# see if we ran out of filenames 
	return undef unless defined($fh);

	$self->{"session"}++;
	${$self->{"params"}}{"source"} = $self->{"fname"} . " request " .
	                                 $self->{"session"};
	$ret = $self->read_session($fh);
    } until ($ret);
    $self->{"current_fh"} = $fh;
    return 1;
}

# open_next is a utility function used by read_files; should not be
# called outside of this object
sub open_next {
    my $self  = shift;
    my $fname_fh = shift;
    my $fname;

    # skip blank or commented lines
    do {
	$fname = $fname_fh->getline;
	chomp $fname;
	# support comments in input
	$fname =~ s/\s*#.*$//;
    } while ($fname =~ /^$/ && ! $fname_fh->eof);
    $self->{"fname"} = $fname;
    $self->{"session"} = 0;
    $self->{"current_fh"} = new IO::File "$fname" or
	$self->warn("Unable to open $fname: $!\n", [], "");
    $self->mesg(1, "Opened $fname");
    return $self->{"current_fh"};
}

=over

=item data()

Return the data used for the tokens we have.  If called in array mode,
we return the individual lines, otherwise the join of those line.

=back

=cut

sub data {
    my $self = shift;
    return $self->{"data"};
}

=over

=item source()

=item source(value)

Set and/or get the data source.

=back

=cut

sub source {
    my $self = shift;
    if (defined($_[0])) {
        my $old = ${$self->{"params"}}{"source"};
	${$self->{"params"}}{"source"} = $_[0];
	return $old;
    } else {
	return ${$self->{"params"}}{"source"};
    }
}

=over

=item tokens()

Return the tokens that result from parsing the structure.  The tokens
can be returned as an array or a reference to the internal array holding
them (for efficiency).  Modify this referenced array at your own risk.

=back

=cut

sub tokens {
    my $self  = shift;

    my @tokens = ( $self->{"data"} );

    return wantarray ? @tokens : \@tokens;
}

sub empty {
    my $self  = shift;
    undef $self->{"data"};
}

=head2 Functions required by IDS::DataSource

=over

=item default_parameters()

Sets all of the default values for the parameters.  Normally called by
new() or one of its descendents.

=back

=cut

sub default_parameters {
    my $self = shift;
    my %params = (
    # general parameters
    # source			# filled in by IDS::DataSource::HTTP::read_session,
    				# it is the source of data,
    				# used when producing error/warn msgs
    "msg_fh" => $self->fh_or_stdout,# Where warning messages go; nowhere if undef
    "verbose" => 0,		# Print extra information; larger means more
    
    );
    $self->{"params"} = \%params;
}

=over

=item param_options()

Command-line option specifiers for our parameters for GetOpt::Long.

=back

=cut

sub param_options {
    my $self = shift;
    return (
        "lines_verbose=i" => \${$self->{"params"}}{"verbose"},
    );
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the reponse depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Algorithm>, L<IDS::DataSource>

=cut


1;
