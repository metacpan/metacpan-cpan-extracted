package HealthCheck::Diagnostic;

# ABSTRACT: A base clase for writing health check diagnositics
use version;
our $VERSION = 'v1.9.2'; # VERSION

use 5.010;
use strict;
use warnings;

use Carp;
use Time::HiRes qw< gettimeofday tv_interval >;

my $rfc3339_timestamp = qr/^(?:
    (?P<year>[0-9]{4})-
    (?P<month>1[0-2]|0[1-9])-
    (?P<day>3[01]|0[1-9]|[12][0-9])
    [tT ]
    (?P<hour>2[0-3]|[01][0-9]):
    (?P<minute>[0-5][0-9]):
    (?P<second>[0-5][0-9]|60)
    (?: \. (?P<ms>[0-9]+) )?
    (?<tz> [-+][0-9]{2}:[0-9]{2} | [zZ] )
)$/x;

#pod =head1 SYNOPSIS
#pod
#pod     package HealthCheck::Diagnostic::Sample;
#pod     use parent 'HealthCheck::Diagnostic';
#pod
#pod     # Required implementation of the check
#pod     # or you can override the 'check' method and avoid the
#pod     # automatic call to 'summarize'
#pod     sub run {
#pod         my ( $class_or_self, %params ) = @_;
#pod
#pod         # will be passed to 'summarize' by 'check'
#pod         return { %params, status => 'OK' };
#pod     }
#pod
#pod You can then either instantiate an instance and run the check.
#pod
#pod     my $diagnostic = HealthCheck::Diagnostic::Sample->new( id => 'my_id' );
#pod     my $result     = $diagnostic->check;
#pod
#pod Or as a class method.
#pod
#pod     my $result = HealthCheck::Diagnostic::Sample->check();
#pod
#pod Set C<runtime> to a truthy value in the params for check and the
#pod time spent checking will be returned in the results.
#pod
#pod     my $result = HealthCheck::Diagnostic::Sample->check( runtime => 1 );
#pod
#pod =head1 DESCRIPTION
#pod
#pod A base class for writing Health Checks.
#pod Provides some helpers for validation of results returned from the check.
#pod
#pod This module does not require that an instance is created to run checks against.
#pod If your code requires an instance, you will need to verify that yourself.
#pod
#pod Results returned by these checks should correspond to the GSG
#pod L<Health Check Standard|https://grantstreetgroup.github.io/HealthCheck.html>.
#pod
#pod Implementing a diagnostic should normally be done in L<run>
#pod to allow use of the helper features that L</check> provides.
#pod
#pod =head1 REQUIRED METHODS
#pod
#pod =head2 run
#pod
#pod     sub run {
#pod         my ( $class_or_self, %params ) = @_;
#pod         return { %params, status => 'OK' };
#pod     }
#pod
#pod A subclass must either implement a C<run> method,
#pod which will be called by L</check>
#pod have its return value passed through L</summarize>,
#pod or override C<check> and handle all validation itself.
#pod
#pod See the L</check> method documentation for suggestions on when it
#pod might be overridden.
#pod
#pod =head1 METHODS
#pod
#pod =head2 new
#pod
#pod     my $diagnostic
#pod         = HealthCheck::Diagnostic::Sample->new( id => 'my_diagnostic' );
#pod
#pod =head3 ATTRIBUTES
#pod
#pod Attributes set on the object created will be copied into the result
#pod by L</summarize>, without overriding anything already set in the result.
#pod
#pod =over
#pod
#pod =item collapse_single_result
#pod
#pod If truthy, will collapse a single sub-result into the current result,
#pod with the child result overwriting the values from the parent.
#pod
#pod For example:
#pod
#pod     {   id      => "my_id",
#pod         label   => "My Label",
#pod         runbook => "https://grantstreetgroup.github.io/HealthCheck.html",
#pod         results => [ {
#pod             label  => "Sub Label",
#pod             status => "OK",
#pod         } ]
#pod     }
#pod
#pod Collapses to:
#pod
#pod     {   id      => "my_id",
#pod         label   => "Sub Label",
#pod         runbook => "https://grantstreetgroup.github.io/HealthCheck.html",
#pod         status  => "OK",
#pod     }
#pod
#pod
#pod =item tags
#pod
#pod An arrayref used as the default set of tags for any checks that don't
#pod override them.
#pod
#pod =back
#pod
#pod Any other parameters are included in the "Result" hashref returned.
#pod
#pod Some recommended things to include are:
#pod
#pod =over
#pod
#pod =item id
#pod
#pod The unique id for this check.
#pod
#pod =item label
#pod
#pod A human readable name for this check.
#pod
#pod =item runbook
#pod
#pod A runbook link to help troubleshooting if the status is not OK.
#pod
#pod =back
#pod
#pod =cut

sub new {
    my ($class, @params) = @_;

    # Allow either a hashref or even-sized list of params
    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    bless \%params, $class;
}

#pod =head2 collapse_single_result
#pod
#pod Read only accessor for the C</collapse_single_result> attribute.
#pod
#pod =cut

sub collapse_single_result {
    return unless ref $_[0]; return shift->{collapse_single_result};
}

#pod =head2 tags
#pod
#pod Read only accessor that returns the list of tags registered with this object.
#pod
#pod =cut

sub tags { return unless ref $_[0]; @{ shift->{tags} || [] } }

#pod =head2 id
#pod
#pod Read only accessor that returns the id registered with this object.
#pod
#pod =cut

sub id { return unless ref $_[0]; return shift->{id} }

#pod =head2 label
#pod
#pod Read only accessor that returns the label registered with this object.
#pod
#pod =cut

sub label { return unless ref $_[0]; return shift->{label} }

#pod =head2 runbook
#pod
#pod Read only accessor that returns the runbook registered with this object.
#pod
#pod =cut

sub runbook { return unless ref $_[0]; return shift->{runbook} }

#pod =head2 check
#pod
#pod     my %results = %{ $diagnostic->check(%params) }
#pod
#pod This method is what is normally called by the L<HealthCheck> runner,
#pod but this version expects you to implement a L</run> method for the
#pod body of your diagnostic.
#pod This thin wrapper
#pod makes sure C<%params> is an even-sided list (possibly unpacking a hashref)
#pod before passing it to L</run>,
#pod trapping any exceptions,
#pod and passing the return value through L</summarize> unless a falsy
#pod C<summarize_result> parameter is passed.
#pod
#pod This could be used to validate parameters or to modify the the return value
#pod in some way.
#pod
#pod     sub check {
#pod         my ( $self, @params ) = @_;
#pod
#pod         # Require check as an instance method
#pod         croak("check cannot be called as a class method") unless ref $self;
#pod
#pod         # Allow either a hashref or even-sized list of params
#pod         my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
#pod             ? %{ $params[0] } : @params;
#pod
#pod         # Validate any required parameters and that they look right.
#pod         my $required_param = $params{required} || $self->{required};
#pod         return {
#pod             status => 'UNKNOWN',
#pod             info   => 'The "required" parameter is required',
#pod         } unless $required_param and ref $required_param == 'HASH';
#pod
#pod         # Calls $self->run and then passes the result through $self->summarize
#pod         my $res = $self->SUPER::check( %params, required => $required_param );
#pod
#pod         # Modify the result after it has been summarized
#pod         delete $res->{required};
#pod
#pod         # and return it
#pod         return $res;
#pod     }
#pod
#pod =cut

sub check {
    my ( $class_or_self, @params ) = @_;

    # Allow either a hashref or even-sized list of params
    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    my $class = ref $class_or_self || $class_or_self;
    croak("$class does not implement a 'run' method")
        unless $class_or_self->can('run');

    my $summarize
        = exists $params{summarize_result}
        ? $params{summarize_result}
        : 1;

    local $@;
    my $start = $params{runtime} ? [ gettimeofday ] : undef;
    my @res = eval { $class_or_self->run(%params) };
    @res = { status => 'CRITICAL', info => "$@" } if $@;

    if ( @res == 1 && ( ref $res[0] || '' ) eq 'HASH' ) { }    # noop, OK
    elsif ( @res % 2 == 0 ) { @res = {@res}; }
    else {
        carp("Invalid return from $class\->run (@res)");
        @res = { status => 'UNKNOWN' };
    }

    $res[0]->{runtime} = sprintf "%.03f", tv_interval($start) if $start;

    return $res[0] unless $summarize;
    return $class_or_self->summarize(@res);
}

#pod =head2 summarize
#pod
#pod     %result = %{ $diagnostic->summarize( \%result ) };
#pod
#pod Validates, pre-formats, and returns the C<result> so that it is easily
#pod usable by HealthCheck.
#pod
#pod The attributes C<id>, C<label>, C<runbook>, and C<tags>
#pod get copied from the C<$diagnostic> into the C<result>
#pod if they exist in the former and not in the latter.
#pod
#pod The C<status> and C<info> are summarized when we have multiple
#pod C<results> in the C<result>. All of the C<info> values get appended
#pod together. One C<status> value is selected from the list of C<status>
#pod values.
#pod
#pod Used by L</check>.
#pod
#pod Carps a warning if validation fails on several keys, and sets the
#pod C<status> from C<OK> to C<UNKNOWN>.
#pod
#pod =over
#pod
#pod =item status
#pod
#pod Expects it to be one of C<OK>, C<WARNING>, C<CRITICAL>, or C<UNKNOWN>.
#pod
#pod Also carps if it does not exist.
#pod
#pod =item results
#pod
#pod Complains if it is not an arrayref.
#pod
#pod =item id
#pod
#pod Complains if the id contains anything but
#pod lowercase ascii letters, numbers, and underscores.
#pod
#pod =item timestamp
#pod
#pod Expected to look like an
#pod L<RFC 3339 timestamp|https://tools.ietf.org/html/rfc3339>
#pod which is a more strict subset of an ISO8601 timestamp.
#pod
#pod =back
#pod
#pod Modifies the passed in hashref in-place.
#pod
#pod =cut

sub summarize {
    my ( $self, $result ) = @_;

    $self->_set_default_fields($result, qw(id label runbook tags));

    return $self->_summarize( $result, $result->{id} // 0 );
}

sub _set_default_fields {
    my ($self, $target, @fields) = @_;
    if ( ref $self ) {
        $target->{$_} = ($_ eq 'tags' ? [ $self->$_ ] : $self->$_) for (
            grep {
                !exists($target->{$_}) &&
                ($_ eq 'tags' ? scalar($self->$_) : defined($self->$_))
            }
            @fields
        );
    }
}

sub _summarize {
    my ($self, $result, $id) = @_;

    # Indexes correspond to Nagios Plugin Return Codes
    # https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/pluginapi.html
    state $forward = [ qw( OK WARNING CRITICAL UNKNOWN ) ];

    # The order of preference to inherit from a child. The highest priority
    # has the lowest number.
    state $statuses = { map { state $i = 1; $_ => $i++ } qw(
        CRITICAL
        WARNING
        UNKNOWN
        OK
    ) };

    my $status = uc( $result->{status} || '' );
    $status = '' unless exists $statuses->{$status};

    my @results;
    if ( exists $result->{results} ) {
        if ( ( ref $result->{results} || '' ) eq 'ARRAY' ) {
            @results = @{ $result->{results} };

            # Merge if there is only a single result.
            if ( @results == 1 and $self->collapse_single_result ) {
                my ($r) = @{ delete $result->{results} };
                %{$result} = ( %{$result}, %{$r} );

                # Now that we've merged, need to redo everything again
                return $self->_summarize($result, $id);
            }
        }
        else {
            my $disp
                = defined $result->{results}
                ? "invalid results '$result->{results}'"
                : 'undefined results';
            carp("Result $id has $disp");
        }
    }

    my %seen_ids;
    foreach my $i ( 0 .. $#results ) {
        my $r = $results[$i];
        $self->_summarize( $r, "$id-" . ( $r->{id} // $i ) );

        # If this result has an ID we have seen already, append a number
        if ( exists $r->{id} and my $i = $seen_ids{ $r->{id} // '' }++ ) {
            $r->{id} .= defined $r->{id} && length $r->{id} ? "_$i" : $i;
        }

        if ( defined( my $s = $r->{status} ) ) {
            $s = uc $s;
            $s = $forward->[$s] if $s =~ /^[0-3]$/;

            $status = $s
                if exists $statuses->{$s}
                and $statuses->{$s} < ( $statuses->{$status} // 5 );
        }
    }

    # If we've found a valid status in our children,
    # use that if we don't have our own.
    # Removing the // here will force "worse" status inheritance
    $result->{status} //= $status if $status;

    my @errors;

    if ( exists $result->{id} ) {
        my $rid = $result->{id};
        unless ( defined $rid and $rid =~ /^[a-z0-9_]+$/ ) {
            push @errors, defined $rid ? "invalid id '$rid'" : 'undefined id';
        }
    }

    if ( exists $result->{timestamp} ) {
        my $ts = $result->{timestamp};
        unless ( defined $ts and $ts =~ /$rfc3339_timestamp/ ) {
            my $disp_timestamp
                = defined $ts
                ? "invalid timestamp '$ts'"
                : 'undefined timestamp';
            push @errors, "$disp_timestamp";
        }
    }

    if ( not exists $result->{status} ) {
        push @errors, "missing status";
    }
    elsif ( not defined $result->{status} ) {
        push @errors, "undefined status";
    }
    elsif ( not exists $statuses->{ uc( $result->{status} // '' ) } ) {
        push @errors, "invalid status '$result->{status}'";
    }

    $result->{status} = 'UNKNOWN'
        unless defined $result->{status} and length $result->{status};

    if (@errors) {
        carp("Result $id has $_") for @errors;
        $result->{status} = 'UNKNOWN'
            if $result->{status}
            and $statuses->{ $result->{status} }
            and $statuses->{UNKNOWN} < $statuses->{ $result->{status} };
        $result->{info} = join "\n", grep {$_} $result->{info}, @errors;
    }

    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic - A base clase for writing health check diagnositics

=head1 VERSION

version v1.9.2

=head1 SYNOPSIS

    package HealthCheck::Diagnostic::Sample;
    use parent 'HealthCheck::Diagnostic';

    # Required implementation of the check
    # or you can override the 'check' method and avoid the
    # automatic call to 'summarize'
    sub run {
        my ( $class_or_self, %params ) = @_;

        # will be passed to 'summarize' by 'check'
        return { %params, status => 'OK' };
    }

You can then either instantiate an instance and run the check.

    my $diagnostic = HealthCheck::Diagnostic::Sample->new( id => 'my_id' );
    my $result     = $diagnostic->check;

Or as a class method.

    my $result = HealthCheck::Diagnostic::Sample->check();

Set C<runtime> to a truthy value in the params for check and the
time spent checking will be returned in the results.

    my $result = HealthCheck::Diagnostic::Sample->check( runtime => 1 );

=head1 DESCRIPTION

A base class for writing Health Checks.
Provides some helpers for validation of results returned from the check.

This module does not require that an instance is created to run checks against.
If your code requires an instance, you will need to verify that yourself.

Results returned by these checks should correspond to the GSG
L<Health Check Standard|https://grantstreetgroup.github.io/HealthCheck.html>.

Implementing a diagnostic should normally be done in L<run>
to allow use of the helper features that L</check> provides.

=head1 REQUIRED METHODS

=head2 run

    sub run {
        my ( $class_or_self, %params ) = @_;
        return { %params, status => 'OK' };
    }

A subclass must either implement a C<run> method,
which will be called by L</check>
have its return value passed through L</summarize>,
or override C<check> and handle all validation itself.

See the L</check> method documentation for suggestions on when it
might be overridden.

=head1 METHODS

=head2 new

    my $diagnostic
        = HealthCheck::Diagnostic::Sample->new( id => 'my_diagnostic' );

=head3 ATTRIBUTES

Attributes set on the object created will be copied into the result
by L</summarize>, without overriding anything already set in the result.

=over

=item collapse_single_result

If truthy, will collapse a single sub-result into the current result,
with the child result overwriting the values from the parent.

For example:

    {   id      => "my_id",
        label   => "My Label",
        runbook => "https://grantstreetgroup.github.io/HealthCheck.html",
        results => [ {
            label  => "Sub Label",
            status => "OK",
        } ]
    }

Collapses to:

    {   id      => "my_id",
        label   => "Sub Label",
        runbook => "https://grantstreetgroup.github.io/HealthCheck.html",
        status  => "OK",
    }

=item tags

An arrayref used as the default set of tags for any checks that don't
override them.

=back

Any other parameters are included in the "Result" hashref returned.

Some recommended things to include are:

=over

=item id

The unique id for this check.

=item label

A human readable name for this check.

=item runbook

A runbook link to help troubleshooting if the status is not OK.

=back

=head2 collapse_single_result

Read only accessor for the C</collapse_single_result> attribute.

=head2 tags

Read only accessor that returns the list of tags registered with this object.

=head2 id

Read only accessor that returns the id registered with this object.

=head2 label

Read only accessor that returns the label registered with this object.

=head2 runbook

Read only accessor that returns the runbook registered with this object.

=head2 check

    my %results = %{ $diagnostic->check(%params) }

This method is what is normally called by the L<HealthCheck> runner,
but this version expects you to implement a L</run> method for the
body of your diagnostic.
This thin wrapper
makes sure C<%params> is an even-sided list (possibly unpacking a hashref)
before passing it to L</run>,
trapping any exceptions,
and passing the return value through L</summarize> unless a falsy
C<summarize_result> parameter is passed.

This could be used to validate parameters or to modify the the return value
in some way.

    sub check {
        my ( $self, @params ) = @_;

        # Require check as an instance method
        croak("check cannot be called as a class method") unless ref $self;

        # Allow either a hashref or even-sized list of params
        my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
            ? %{ $params[0] } : @params;

        # Validate any required parameters and that they look right.
        my $required_param = $params{required} || $self->{required};
        return {
            status => 'UNKNOWN',
            info   => 'The "required" parameter is required',
        } unless $required_param and ref $required_param == 'HASH';

        # Calls $self->run and then passes the result through $self->summarize
        my $res = $self->SUPER::check( %params, required => $required_param );

        # Modify the result after it has been summarized
        delete $res->{required};

        # and return it
        return $res;
    }

=head2 summarize

    %result = %{ $diagnostic->summarize( \%result ) };

Validates, pre-formats, and returns the C<result> so that it is easily
usable by HealthCheck.

The attributes C<id>, C<label>, C<runbook>, and C<tags>
get copied from the C<$diagnostic> into the C<result>
if they exist in the former and not in the latter.

The C<status> and C<info> are summarized when we have multiple
C<results> in the C<result>. All of the C<info> values get appended
together. One C<status> value is selected from the list of C<status>
values.

Used by L</check>.

Carps a warning if validation fails on several keys, and sets the
C<status> from C<OK> to C<UNKNOWN>.

=over

=item status

Expects it to be one of C<OK>, C<WARNING>, C<CRITICAL>, or C<UNKNOWN>.

Also carps if it does not exist.

=item results

Complains if it is not an arrayref.

=item id

Complains if the id contains anything but
lowercase ascii letters, numbers, and underscores.

=item timestamp

Expected to look like an
L<RFC 3339 timestamp|https://tools.ietf.org/html/rfc3339>
which is a more strict subset of an ISO8601 timestamp.

=back

Modifies the passed in hashref in-place.

=head1 DEPENDENCIES

Perl 5.10 or higher.

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 SEE ALSO

L<Writing a HealthCheck::Diagnostic|writing_a_healthcheck_diagnostic>

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 - 2025 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
