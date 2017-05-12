package IDS::DataSource;
$IDS::DataSource::VERSION = "1.0";

=head1 NAME

IDS::DataSource - A data source for the IDS test framework.

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp qw(cluck carp confess);
use IO::File;
use IDS::Utils qw(fh_or_stdout);

### It would be better to autoload the source based on what we need.
### However, for now we will load all possible ones.

use IDS::DataSource::HTTP;

$IDS::DataSource::VERSION     = "1.0";

=over

=item new()

=item new(params)

=item new(source, params)

Create the object for the data source.  If the parameters are supplied,
they are used; otherwise everything is defaults (unsurprisingly).  

If a data source is supplied, it is the source passed to a load operation.
A source may be a file name, file handle, or other source understood by
the IDS::DataSource subclass.

The parameters affect how the algorithm operates.  See the specific
source for most parameter information.  General parameters are
described below.

In simple cases, this function can be used instead of the subclass
version.

=back

=cut

# Part of the logic here seems kind of backwards, but we cannot load
# until parameters have been loaded.  Some of the parameters may affect
# how we load.
sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { };
    my $source;

    # necessary before we call handle_parameters.
    bless($self, $class);

    $self->default_parameters;
    $source = $self->handle_parameters(@_);

    $self->load($source) if defined($source);

    return $self;
}

=over

=item parameters()

=item parameters(param)

=item parameters(param, value, ...)

Set or retrieve the current parameters (individual or group).

=back

=cut

sub parameters {
    my $self = shift;

    return (wantarray ? %{$self->{"params"}} : $self->{"params"})
        if ($#_ == -1);

    return ${$self->{"params"}}{$_[0]} if ($#_ == 0);

    if ($#_ == 1) {
	my $old = ${$self->{"params"}}{$_[0]};
	${$self->{"params"}}{$_[0]} = $_[1];
	return $old;
    }

    scalar(@_) % 2 != 0 and confess "odd > 1 number of parameters passed to ",
        *parameters{PACKAGE}, ".  See documentation for proper usage.\n";

    for (my $i = 0; $i < $#_; $i+=2) {
	${$self->{"params"}}{$_[$i]} = $_[$i+1];
    }

    return 1;
}

=head2 Parameters

The following parameters are expected to be used (when the use makes
sense) by all subclasses.

=over

=item verbose

How much ``extra'' information to provide as we are working.  0 means
nothing other than warnings and errors.  Increasing values mean
increasing output, but these details are left to the subclasses.

=item msg_fh

Where warning and error messages go; nowhere if undefined.

=back

Additionally, subclasses may define their own parameters.

All subclasses must define all parameters to default values when new()
is called.  This is so the param_options can be properly handled.

=over

=item param_options()

These are options definitions for Getopt::Long.

=back

=cut

sub param_options {
    my $self = shift;

    return (
            "verbose!"        => \${$self->{"params"}}{"verbose"},
            "print_warnings!" => \${$self->{"params"}}{"print_warnings"},
	   );
}

=head2 Utility functions

These may be useful for subclasses.

=over

=item handle_parameters($self, @_)

Handle the parameter string that IDS::Algorithm::new() will accept.
Extracted from new() for subclass usage.  Returns a filehandle or filename
if we were called with a filehandle/filename from which to load.

=back

=cut

sub handle_parameters {
    my $self = shift;
    my $loadfh;

    if (defined($_[0])) {
	# If we have a non-zero even number of arguments,  we have
	# nothing but parameters
	if (scalar(@_) % 2 == 0) {
	    undef $loadfh;
	} else {
	    $loadfh = shift;
	}
    }
    $self->parameters(@_);
    return $loadfh;
}

=over

=item default_parmeters()

Set all of the parameters to default values.

=back

=cut

sub default_parameters {
    confess "IDS::source::default_parameters called; this function must be subclassed.\n";
}

=over

=item load()

Load a single instance from the source (filename or filehandle) provided.
This function must be implemented in the subclass.

=back

=cut

sub load {
    confess "IDS::source::load called; this function must be subclassed.\n";
}

=over

=item foreach(source, coderef, object)

Read a series of instances (from the source specified), and call the
function pointed to by coderef, which is associated with the object
provided.  This function may be overridden in the subclass.

The function to call is called as:

&$coderef($object, tokenref)

=back

=cut

sub foreach {
    my $self  = shift;
    my $fh = shift or
	cluck *foreach{PACKAGE} . "::foreach called without a filehandle";
    my $func = shift or
        cluck *foreach{PACKAGE} . "::foreach called without function ref";
    my $obj = shift or
	cluck *foreach{PACKAGE} . "::foreach called without object";

    my $n = 0;
    while ($self->read_next($fh)) {
	$n++;
        &$func($obj, scalar $self->tokens);
    }
    return $n;
}

=over

=item mesg(level, message)

=item mesg(level, message, separator, arrayref)

Print a message if the verbosity level warrants it.  If the separator
and array reference are provided, the array referenced is joined with
the separator provided and the result is appended to the message provided.

A message is produced only if the current verbosity level >= level.

=back

=cut

sub mesg {
    my $self  = shift;
    my $level  = shift;
    defined($level) or confess *mesg{PACKAGE} .
        "::mesg called without a level!";
    my $msg = shift or confess *mesg{PACKAGE} .
        "::mesg called without a message!";
    my $sep = shift;
    my $ref = shift;
    my $addendum;

    $addendum = defined($sep) && defined($ref) ? join($sep, @$ref) : "";

    my $fh = ${$self->{"params"}}{"msg_fh"};
    print $fh "$msg$addendum\n"
        if defined($fh) && ${$self->{"params"}}{"verbose"} >= $level;
}

=over

=item warn(message, arrayref, token)

Print a warning message, and optionally push a warning token on the
referenced array (if return_warnings is set).

=back

=cut

sub warn {
    my $self  = shift;
    my $pmsg = shift or confess *warn{PACKAGE} .
        "::warn called without a print message";
    my $tref = shift or confess *warn{PACKAGE} .
        "::warn called without a token list ref";
    my $token = shift;
    defined($token) or confess *warn{PACKAGE} .
        "::warn called without a token";
    my $fh = ${$self->{"params"}}{"msg_fh"};

#    ${$self->{"params"}}{"print_warnings"} and carp "WARNING: $pmsg";
    print $fh "WARNING: $pmsg\n"
        if defined($fh) && ${$self->{"params"}}{"print_warnings"};

    push @$tref, $token 
	if ${$self->{"params"}}{"return_warnings"};
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the response depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Test>, L<IDS::Algorithm>

=cut

1;
