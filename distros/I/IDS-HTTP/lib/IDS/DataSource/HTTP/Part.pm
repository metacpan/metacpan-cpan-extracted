package IDS::DataSource::HTTP::Part;
use base qw(IDS::DataSource::HTTP);

=head1 IDS::DataSource::HTTP::Part

=head2 Introduction

A common superclass for parts of an HTTP request.  All real uses will
be through subclasses.

We expect descendents to:

=over

=item Whenever a string is loaded, parse then (no lazy evaluation).
This is because *we* have the function to return the tokens.

=item Parameters relating to parsing are in the "params" entry, which
is a hash reference.  It is initialized here.

=item An optional initializer follows the parameters to new.

=item Elements of self:

=over

=item data   => the data that caused the parse that we have

=item tokens => The results of the parse

=item params => parameters that may affect parsing

=back

=item The subclass must implement the following functions:
parse, empty

=back

=cut

use strict;
use warnings;
use Carp qw(cluck carp confess);
use IO::Handle;

$IDS::DataSource::HTTP::Part::VERSION     = "2.0";

sub new {
    my $proto  = shift;
    my $class = ref($proto) || $proto;
    my $self = { };
    (defined($class) && $class) or 
        confess *new{PACKAGE}, "::new is missing the class.";
    bless $self, $class;

    $self->default_parameters;
    my $source = $self->handle_parameters(@_);

    $self->init($source) if defined($source);

    return $self;
}

# init from a string
sub init {
    my $self  = shift;

    $self->empty();

    $self->{"data"} = shift;
    defined($self->{"data"}) or
        confess *init{PACKAGE} . "::init called without a string";

    $self->cleanup;
    $self->parse;
}

=over

=item parameters()
=item parameters(param)
=item parameters(param, value, ...)

=back

Set or retrieve the current parameters (individual or group).

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

=over

=item default_parameters()

Sets all of the default values for the parameters.  Normally called by
new() or one of its descendents.

=back

=cut

sub default_parameters {
    my $self = shift;

    ${$self->{"params"}}{"verbose"} = 0;
}

=over

=item handle_parameters($self, @_)

Handle the parameter string that IDS::Algorithm::new() will accept.
Extracted from new() for subclass usage.  Returns a filehandle if we
were called with a filehandle from which to load.

=back

=cut

sub handle_parameters {
    my $self = shift;
    my $loadfh;

    # This first case is for historical compatibility where the
    # parameters were a hash reference passed as the first argument.
    # This usage is now deprecated, and will hopefully eventually be
    # removed.
    my @params = @_;
    if ($params[0] =~ /^HASH/ && $#params == 1) {
	my ($params, $string) = @params;
	$self->parameters(%{$params});
	return $string;
    } elsif (defined($params[0])) {
	# If we have a non-zero even number of arguments,  we have
	# nothing but parameters
	if (scalar(@params) % 2 == 0) {
	    undef $loadfh;
	} else {
	    $loadfh = shift;
	}
    }
    $self->parameters(@params);
    return $loadfh;
}

=over

=item cleanup

Clean data to prepare for tokenizing.

=back

=cut

sub cleanup {
    my $self = shift;
    $self->{"data"} =~ s/\r//g;
    $self->{"data"} =~ s/\s+$//s; # any spaces at the end (is this valid?)
    $self->{"data"} =~ s/\n\s+/ /g;  # fix continuation lines

    # some %-escaped chars back to normal
    $self->{"data"} =~ s/%7E/~/g;
    #$self->{"data"} =~ s/%20/ /g;
    return $self;
}

=over

=item data()

Return the data used for the tokens we have.  If called in array mode,
we return the inidividual lines, otherwise the join of those line.

=back

=cut

sub data {
    my $self = shift;
    return wantarray ? @{$self->{"lines"}} : $self->{"data"};
}

=over

=item postdata()

Return the data part of a POST request.  Only has meaning in a POST
request.

=back

=cut

sub postdata {
    my $self = shift;

    return $self->{"postdata"};
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

Note that this function can remove values.
Note that this function can convert everything to lower case.
Both of these options are controlled by parameters, and neither affects
the internal version of the tokens.

=back

=cut

sub tokens {
    my $self  = shift;
    my @result;

    unless (defined($self->{"tokens"})) {
	cluck *tokens{PACKAGE}, "::tokens: no tokens for myself";
	$self->parse;
    }

    defined($self->{"tokens"}) or 
         return [];
#        confess *tokens{PACKAGE} .  "::tokens parsing produced no tokens!";

    # Easy cases are handled efficiently
    return $self->{"tokens"} if
	! wantarray && ${$self->{"params"}}{"with_values"} &&
	! ${$self->{"params"}}{"lc_only"};

    return @{$self->{"tokens"}} if
        wantarray && ${$self->{"params"}}{"with_values"} &&
	! ${$self->{"params"}}{"lc_only"};

    # we have handled the simple cases.  We're committed to making at
    # least one change to what we have stored.
    my @tokens = @{$self->{"tokens"}};

    map {
        s/:.*$// unless ${$self->{"params"}}{"with_values"};
	lc if ${$self->{"params"}}{"lc_only"};
    } @tokens;
    return wantarray ? @tokens : \@tokens;
}

=over

=item expand_pct(data)

Expand the %-substitutions.  This function currently does not handle
unicode and &-expansions.  Should it?

=back

=cut

sub expand_pct {
    my $self = shift;
    my $data = shift;

    while ($data =~ /%([0-9A-Fa-f]{2})/) {
        $data =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/e;
    }
    return $data;
}

=head2 Functions for subclasses

The followng functions are required in subclasses.

=over

=item parse()

Parse the structure and return the resulting tokens.

=back

=cut

sub parse {
    my $self  = shift;
    confess *parse{PACKAGE} .  "::parse missing in subclass " . ref($self);
}

=over

=item empty()

Delete all data in preparation for loading new data.

=back

=cut

sub empty {
    my $self  = shift;
    ref($self) eq *empty{PACKAGE} or
	confess *empty{PACKAGE} .  "::empty missing in subclass " . ref($self);
    undef $self->{"data"}, $self->{"postdata"}, $self->{"tokens"};
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
