package HealthCheck;
use parent 'HealthCheck::Diagnostic';

# ABSTRACT: A health check for your code
use version;
our $VERSION = 'v1.9.1'; # VERSION

use 5.010;
use strict;
use warnings;

use Carp;

use Hash::Util::FieldHash;
use List::Util qw(any uniq);

# Create a place outside of $self to store the checks
# as everything in the self hashref will be copied into
# the result.
Hash::Util::FieldHash::fieldhash my %registered_checks;

#pod =head1 SYNOPSIS
#pod
#pod     use HealthCheck;
#pod
#pod     # a check can return a hashref containing anything at all,
#pod     # however some values are special.
#pod     # See the HealthCheck Standard for details.
#pod     sub my_check {
#pod         return {
#pod             anything => "at all",
#pod             id       => "my_check",
#pod             status   => 'WARNING',
#pod         };
#pod     }
#pod
#pod     my $checker = HealthCheck->new(
#pod         id      => 'main_checker',
#pod         label   => 'Main Health Check',
#pod         runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
#pod         tags    => [qw( fast cheap )],
#pod         checks  => [
#pod             sub { return { id => 'coderef', status => 'OK' } },
#pod             'my_check',          # Name of a method on caller
#pod         ],
#pod     );
#pod
#pod     my $other_checker = HealthCheck->new(
#pod         id      => 'my_health_check',
#pod         label   => "My Health Check",
#pod         runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
#pod         tags    => [qw( cheap easy )],
#pod         other   => "Other details to pass to the check call",
#pod     )->register(
#pod         'My::Checker',       # Name of a loaded class that ->can("check")
#pod         My::Checker->new,    # Object that ->can("check")
#pod     );
#pod
#pod     # It's possible to add ids, labels, and tags to your checks
#pod     # and they will be copied to the Result.
#pod     $other_checker->register( My::Checker->new(
#pod         id      => 'my_checker',
#pod         label   => 'My Checker',
#pod         runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
#pod         tags    => [qw( cheap copied_to_the_result )],
#pod     ) );
#pod
#pod     # You can add HealthCheck instances as checks
#pod     # You could add a check to itself to create an infinite loop of checks.
#pod     $checker->register( $other_checker );
#pod
#pod     # A hashref of the check config
#pod     # This whole hashref is passed as an argument
#pod     # to My::Checker->another_check
#pod     $checker->register( {
#pod         invocant    => 'My::Checker',      # to call the "check" on
#pod         check       => 'another_check',    # name of the check method
#pod         runbook     => 'https://grantstreetgroup.github.io/HealthCheck.html',
#pod         tags        => [qw( fast easy )],
#pod         more_params => 'anything',
#pod     } );
#pod
#pod     my @tags = $checker->tags;    # returns fast, cheap
#pod
#pod     my %result = %{ $checker->check( tags => ['cheap'] ) };
#pod        # OR run the opposite checks
#pod        %result = %{ $checker->check( tags => ['!cheap'] ) };
#pod
#pod     # A checker class or object just needs to have either
#pod     # a check method, which is used by default,
#pod     # or another method as specified in a hash config.
#pod     package My::Checker;
#pod
#pod     # Optionally subclass HealthCheck::Diagnostic
#pod     use parent 'HealthCheck::Diagnostic';
#pod
#pod     # and provide a 'run' method, the Diagnostic base class will
#pod     # pass your results through the 'summarize' helper that
#pod     # will add warnings about invalid values as well as
#pod     # summarizing multiple results.
#pod     sub run {
#pod         return {
#pod             id     => ( ref $_[0] ? "object_method" : "class_method" ),
#pod             status => "WARNING",
#pod         };
#pod     }
#pod
#pod     # Any checks *must* return a valid "Health Check Result" hashref.
#pod
#pod     # You can add your own check that doesn't call 'summarize'
#pod     # or, overload the 'check' helper in the parent class.
#pod     sub another_check {
#pod         my ($self, %params) = @_;
#pod         return {
#pod             id      => 'another_check',
#pod             label   => 'A Super custom check',
#pod             runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
#pod             status  => ( $params{more_params} eq 'fine' ? "OK" : "CRITICAL" ),
#pod         };
#pod     }
#pod
#pod C<%result> will be from the subset of checks run due to the tags.
#pod
#pod     $checker->check(tags => ['cheap']);
#pod
#pod     id      => "main_checker",
#pod     label   => "Main Health Check",
#pod     runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
#pod     tags    => [ "fast", "cheap" ],
#pod     status  => "WARNING",
#pod     results => [
#pod         {   id     => "coderef",
#pod             status => "OK",
#pod             tags   => [ "fast", "cheap" ]  # inherited
#pod         },
#pod         {   anything => "at all",
#pod             id       => "my_check",
#pod             status   => "WARNING",
#pod             tags     => [ "fast", "cheap" ] # inherited
#pod         },
#pod         {   id      => "my_health_check",
#pod             label   => "My Health Check",
#pod             tags    => [ "cheap", "easy" ],
#pod             status  => "WARNING",
#pod             results => [
#pod                 {   id     => "class_method",
#pod                     tags   => [ "cheap", "easy" ],
#pod                     status => "WARNING",
#pod                 },
#pod                 {   id     => "object_method",
#pod                     tags   => [ "cheap", "easy" ],
#pod                     status => "WARNING",
#pod                 },
#pod                 {   id     => "object_method_1",
#pod                     label  => "My Checker",
#pod                     tags   => [ "cheap", "copied_to_the_result" ],
#pod                     status => "WARNING",
#pod                 }
#pod             ],
#pod         }
#pod     ],
#pod
#pod There is also runtime support,
#pod which can be enabled by adding a truthy C<runtime> param to the C<check>.
#pod
#pod     $checker->check( tags => [ 'easy', '!fast' ], runtime => 1 );
#pod
#pod     id      => "my_health_check",
#pod     label   => "My Health Check",
#pod     runtime => "0.000",
#pod     runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
#pod     tags    => [ "cheap", "easy" ],
#pod     status  => "WARNING",
#pod     results => [
#pod         {   id      => "class_method",
#pod             runtime => "0.000",
#pod             tags    => [ "cheap", "easy" ],
#pod             status  => "WARNING",
#pod         },
#pod         {   id      => "object_method",
#pod             runtime => "0.000",
#pod             tags    => [ "cheap", "easy" ],
#pod             status  => "WARNING",
#pod         }
#pod     ],
#pod
#pod =head1 DESCRIPTION
#pod
#pod Allows you to create callbacks that check the health of your application
#pod and return a status result.
#pod
#pod There are several things this is trying to enable:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod A fast HTTP endpoint that can be used to verify that a web app can
#pod serve traffic.
#pod To this end, it may be useful to use the runtime support option,
#pod available in L<HealthChecks::Diagnostic>.
#pod
#pod =item *
#pod A more complete check that verifies all the things work after a deployment.
#pod
#pod =item *
#pod
#pod The ability for a script, such as a cronjob, to verify that it's dependencies
#pod are available before starting work.
#pod
#pod =item *
#pod
#pod Different sorts of monitoring checks that are defined in your codebase.
#pod
#pod =back
#pod
#pod Results returned by these checks should correspond to the GSG
#pod L<Health Check Standard|https://grantstreetgroup.github.io/HealthCheck.html>.
#pod
#pod You may want to use L<HealthCheck::Diagnostic> to simplify writing your
#pod check slightly.
#pod
#pod =head1 METHODS
#pod
#pod =head2 new
#pod
#pod     my $checker = HealthCheck->new( id => 'my_checker' );
#pod
#pod =head3 ATTRIBUTES
#pod
#pod =over
#pod
#pod =item checks
#pod
#pod An arrayref that is passed to L</register> to initialize checks.
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
    my ( $class, %params ) = @_;
    my $checks = delete $params{checks};
    my $self = bless {%params}, $class;
    return $checks ? $self->register($checks) : $self;
}

#pod =head2 register
#pod
#pod     $checker->register({
#pod         invocant => $class_or_object,
#pod         check    => $method_on_invocant_or_coderef,
#pod         more     => "any other params are passed to the check",
#pod     });
#pod
#pod Takes a list or arrayref of check definitions to be added to the object.
#pod
#pod Each registered check must return a valid GSG Health Check response,
#pod either as a hashref or an even-sized list.
#pod See the GSG Health Check Standard (linked in L</DESCRIPTION>)
#pod for the fields that checks should return.
#pod
#pod Rather than having to always pass in the full hashref definition,
#pod several common cases are detected and used to fill out the check.
#pod
#pod =over
#pod
#pod =item coderef
#pod
#pod If passed a coderef, this will be called as the C<check> without an C<invocant>.
#pod
#pod =item object
#pod
#pod If a blessed object is passed in
#pod and it has a C<check> method, use that for the C<check>,
#pod otherwise throw an exception.
#pod
#pod =item string
#pod
#pod If a string is passed in,
#pod check if it is the name of a loaded class that has a C<check> method,
#pod and if so use it as the C<invocant> with the method as the C<check>.
#pod Otherwise if our L<caller> has a method with this name,
#pod the L<caller> becomes the C<invocant> and this becomes the C<check>,
#pod otherwise throws an exception.
#pod
#pod =item full hashref of params
#pod
#pod The full hashref can consist of a C<check> key that the above heuristics
#pod are applied,
#pod or include an C<invocant> key that is used as either
#pod an C<object> or C<class name>.
#pod With the C<invocant> specified, the now optional C<check> key
#pod defaults to "check" and is used as the method to call on C<invocant>.
#pod
#pod All attributes other than C<invocant> and C<check> are passed to the check.
#pod
#pod =back
#pod
#pod =cut

sub register {
    my ($self, @checks) = @_;
    croak("register cannot be called as a class method") unless ref $self;
    return $self unless @checks;
    my $class = ref $self;

    @checks = @{ $checks[0] }
        if @checks == 1 and ( ref $checks[0] || '' ) eq 'ARRAY';

    # If the check that was passed in is just the name of a method
    # we are going to use our caller as the invocant.
    my $caller;
    my $find_caller = sub {
        my ( $i, $c ) = ( 1, undef );
        do { ($c) = caller( $i++ ) } while $c->isa(__PACKAGE__);
        $c;
    };

    foreach (@checks) {
        my $type = ref $_ || '';
        my %c
            = $type eq 'HASH'  ? ( %{$_} )
            : $type eq 'ARRAY' ? ( check => $class->register($_) )
            :                    ( check => $_ );

        croak("check parameter required") unless $c{check};

        # If it's not a coderef,
        # it must be the name of a method to call on an invocant.
        unless ( ( ref $c{check} || '' ) eq 'CODE' ) {

            # If they passed in an object or a class that can('check')
            # then we want to set that as the invocant so the check
            # runner does the right thing.
            if ( $c{check} and not $c{invocant} and do {
                    local $@;
                    eval { $c{check}->can('check') };
                } )
            {
                $c{invocant} = $c{check};
                $c{check}    = 'check';
            }

            # If they just passed in a method name,
            # we can see if the caller has that method.
            unless ($c{invocant}) {
                $caller ||= $find_caller->();

                if ($caller->can($c{check}) ) {
                    $c{invocant} = $caller;
                }
                else {
                    croak("Can't determine what to do with '$c{check}'");
                }
            }

            croak("'$c{invocant}' cannot '$c{check}'")
                unless $c{invocant}->can( $c{check} );
        }

        push @{ $registered_checks{$self} }, \%c;
    }

    return $self;
}

#pod =head2 check
#pod
#pod     my %results = %{ $checker->check(%params) }
#pod
#pod Calls all of the registered checks and returns a hashref of the results of
#pod processing the checks passed through L<HealthCheck::Diagnostic/summarize>.
#pod Passes the L</full hashref of params> as an even-sized list to the check,
#pod without the C<invocant> or C<check> keys.
#pod This hashref is shallow merged with and duplicate keys overridden by
#pod the C<%params> passed in.
#pod
#pod If there is both an C<invocant> and C<check> in the params,
#pod it the C<check> is called as a method on the C<invocant>,
#pod otherwise C<check> is used as a callback coderef.
#pod
#pod If only a single check is registered,
#pod the results from that check are merged with, and will override
#pod the L</ATTRIBUTES> set on the object instead of being put in
#pod a C<results> arrayref.
#pod
#pod Throws an exception if no checks have been registered.
#pod
#pod =head3 run
#pod
#pod Main implementation of the checker is here.
#pod
#pod Passes C<< summarize_result => 0 >> to each registered check
#pod unless overridden to avoid running C<summarize> multiple times.
#pod See L<HealthCheck::Diagnostic/check>.
#pod
#pod =cut

sub check {
    my ( $self, @params ) = @_;
    croak("check cannot be called as a class method") unless ref $self;
    croak("No registered checks") unless @{ $registered_checks{$self} || [] };
    $self->SUPER::check(@params);
}

#pod =head2 get_registered_tags
#pod
#pod Read-only accessor that returns the list of 'top-level' tags registered with
#pod this object. Sub-check tags are not included - only those which will result in
#pod checks being run when passed to L</check> on the given object.
#pod
#pod =cut

sub get_registered_tags {
    my ($self) = @_;

    my @checks = @{ $registered_checks{$self} || [] };
    my @tags;
    for my $check (@checks) {
        $self->_set_check_response_defaults($check);
        push @tags, @{ $check->{_respond}{tags} || [] };
    }
    push @tags, @{ $self->{tags} // [] };

    return uniq sort @tags;
}

sub run {
    my ($self, %params) = @_;

    # If we are going to summarize things, no need for our children to
    $params{summarize_result} = 0 unless exists $params{summarize_result};

    my @results = $self->_run_checks(
        [
            grep { $self->should_run( $_, %params ) }
            @{ $registered_checks{$self} || [] }
        ],
        \%params,
    );

    return unless @results; # don't return undef, instead an empty list
    return $results[0] if @{ $registered_checks{$self} || [] } == 1;
    return { results => \@results };
}

sub _run_checks {
    my ( $self, $checks, $params ) = @_;

    return map { $self->_run_check( $_, $params ) } @$checks;
}

sub _run_check {
    my ( $self, $check, $params ) = @_;

    my %c = %{ $check };
    $self->_set_check_response_defaults(\%c);
    my $defaults = delete $c{_respond};
    my $i        = delete $c{invocant} || '';
    my $m        = delete $c{check}    || '';

    my @r;
    # Exceptions will probably not contain child health check's metadata,
    # as HealthCheck::Diagnostic->summarize would normally populate these
    # and was not called.
    # This could theoretically be a pain for prodsupport. If we find this
    # happening frequently, we should reassess our decision not to attempt
    # to call summarize here
    # (for fear of exception-catching magic and rabbitholes).
    {
        local $@;
        @r = eval { $i ? $i->$m( %c, %$params ) : $m->( %c, %$params ) };
        @r = { status => 'CRITICAL', info => $@ } if $@ and not @r;
    }

    @r
        = @r == 1 && ref $r[0] eq 'HASH' ? $r[0]
        : @r % 2 == 0                    ? {@r}
        : do {
            my $c = $i ? "$i->$m" : "$m";
            carp("Invalid return from $c (@r)");
            ();
        };

    if (@r) { @r = +{ %$defaults, %{ $r[0] } } }

    return @r;
}

sub _set_check_response_defaults {
    my ($self, $c) = @_;
    return if exists $c->{_respond};

    my %defaults;
    FIELD: for my $field ( qw(id label runbook tags) ) {
        if (exists $c->{$field}) {
            $defaults{$field} = $c->{$field};
            next FIELD;
        }

        if ( $c->{invocant} && $c->{invocant}->can($field) ) {
            my $val;
            if ( $field eq 'tags' ) {
                if (my @tags = $c->{invocant}->$field) {
                    $val = [@tags];
                }
            }
            else {
                $val = $c->{invocant}->$field;
            }

            if (defined $val) {
                $defaults{$field} = $val;
                next FIELD;
            }
        }

        # we only copy tags from the checker to the sub-checks,
        # and only if they don't exist.
        $self->_set_default_fields(\%defaults, $field)
            if $field eq 'tags';
    }

    # deref the tags, just in case someone decides to adjust them later.
    $defaults{tags} = [ @{ $defaults{tags} } ] if $defaults{tags};

    $c->{_respond} = \%defaults;
}


#pod =head1 INTERNALS
#pod
#pod These methods may be useful for subclassing,
#pod but are not intended for general use.
#pod
#pod =head2 should_run
#pod
#pod     my $bool = $checker->should_run( \%check, tags => ['apple', '!banana'] );
#pod
#pod Takes a check definition hash and paramters and returns true
#pod if the check should be run.
#pod Used by L</check> to determine which checks to run.
#pod
#pod Supported parameters:
#pod
#pod =over
#pod
#pod =item tags
#pod
#pod Tags can be either "positive" or "negative". A negative tag is indicated by a
#pod leading C<!>.
#pod A check is run if its tags match any of the passed in positive tags and none
#pod of the negative ones.
#pod If no tags are passed in, all checks will be run.
#pod
#pod If the C<invocant> C<can('tags')> and there are no tags in the
#pod L</full hashref of params> then the return value of that method is used.
#pod
#pod If a check has no tags defined, will use the default tags defined
#pod when the object was created.
#pod
#pod =back
#pod
#pod =cut

sub _has_tags {
    my ($self, $check, @want_tags) = @_;

    $self->_set_check_response_defaults($check);

    # Look at what the check responds to, not what was initially specified
    # (in case tags are inherited)
    my %have_tags = map { $_ => 1 } @{ $check->{_respond}{tags} || [] };

    return any { $have_tags{$_} } @want_tags;
}

sub should_run {
    my ( $self, $check, %params ) = @_;

    my (@positive_tags, @negative_tags);
    for my $tag ( @{ $params{tags} } ) {
        if ( $tag =~ /^!/ ) {
            push @negative_tags, substr($tag, 1);
        }
        else {
            push @positive_tags, $tag;
        }
    }

    return 0 if @negative_tags && $self->_has_tags($check, @negative_tags);
    return 1 unless @positive_tags;
    return $self->_has_tags($check, @positive_tags);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck - A health check for your code

=head1 VERSION

version v1.9.1

=head1 SYNOPSIS

    use HealthCheck;

    # a check can return a hashref containing anything at all,
    # however some values are special.
    # See the HealthCheck Standard for details.
    sub my_check {
        return {
            anything => "at all",
            id       => "my_check",
            status   => 'WARNING',
        };
    }

    my $checker = HealthCheck->new(
        id      => 'main_checker',
        label   => 'Main Health Check',
        runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
        tags    => [qw( fast cheap )],
        checks  => [
            sub { return { id => 'coderef', status => 'OK' } },
            'my_check',          # Name of a method on caller
        ],
    );

    my $other_checker = HealthCheck->new(
        id      => 'my_health_check',
        label   => "My Health Check",
        runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
        tags    => [qw( cheap easy )],
        other   => "Other details to pass to the check call",
    )->register(
        'My::Checker',       # Name of a loaded class that ->can("check")
        My::Checker->new,    # Object that ->can("check")
    );

    # It's possible to add ids, labels, and tags to your checks
    # and they will be copied to the Result.
    $other_checker->register( My::Checker->new(
        id      => 'my_checker',
        label   => 'My Checker',
        runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
        tags    => [qw( cheap copied_to_the_result )],
    ) );

    # You can add HealthCheck instances as checks
    # You could add a check to itself to create an infinite loop of checks.
    $checker->register( $other_checker );

    # A hashref of the check config
    # This whole hashref is passed as an argument
    # to My::Checker->another_check
    $checker->register( {
        invocant    => 'My::Checker',      # to call the "check" on
        check       => 'another_check',    # name of the check method
        runbook     => 'https://grantstreetgroup.github.io/HealthCheck.html',
        tags        => [qw( fast easy )],
        more_params => 'anything',
    } );

    my @tags = $checker->tags;    # returns fast, cheap

    my %result = %{ $checker->check( tags => ['cheap'] ) };
       # OR run the opposite checks
       %result = %{ $checker->check( tags => ['!cheap'] ) };

    # A checker class or object just needs to have either
    # a check method, which is used by default,
    # or another method as specified in a hash config.
    package My::Checker;

    # Optionally subclass HealthCheck::Diagnostic
    use parent 'HealthCheck::Diagnostic';

    # and provide a 'run' method, the Diagnostic base class will
    # pass your results through the 'summarize' helper that
    # will add warnings about invalid values as well as
    # summarizing multiple results.
    sub run {
        return {
            id     => ( ref $_[0] ? "object_method" : "class_method" ),
            status => "WARNING",
        };
    }

    # Any checks *must* return a valid "Health Check Result" hashref.

    # You can add your own check that doesn't call 'summarize'
    # or, overload the 'check' helper in the parent class.
    sub another_check {
        my ($self, %params) = @_;
        return {
            id      => 'another_check',
            label   => 'A Super custom check',
            runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
            status  => ( $params{more_params} eq 'fine' ? "OK" : "CRITICAL" ),
        };
    }

C<%result> will be from the subset of checks run due to the tags.

    $checker->check(tags => ['cheap']);

    id      => "main_checker",
    label   => "Main Health Check",
    runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
    tags    => [ "fast", "cheap" ],
    status  => "WARNING",
    results => [
        {   id     => "coderef",
            status => "OK",
            tags   => [ "fast", "cheap" ]  # inherited
        },
        {   anything => "at all",
            id       => "my_check",
            status   => "WARNING",
            tags     => [ "fast", "cheap" ] # inherited
        },
        {   id      => "my_health_check",
            label   => "My Health Check",
            tags    => [ "cheap", "easy" ],
            status  => "WARNING",
            results => [
                {   id     => "class_method",
                    tags   => [ "cheap", "easy" ],
                    status => "WARNING",
                },
                {   id     => "object_method",
                    tags   => [ "cheap", "easy" ],
                    status => "WARNING",
                },
                {   id     => "object_method_1",
                    label  => "My Checker",
                    tags   => [ "cheap", "copied_to_the_result" ],
                    status => "WARNING",
                }
            ],
        }
    ],

There is also runtime support,
which can be enabled by adding a truthy C<runtime> param to the C<check>.

    $checker->check( tags => [ 'easy', '!fast' ], runtime => 1 );

    id      => "my_health_check",
    label   => "My Health Check",
    runtime => "0.000",
    runbook => 'https://grantstreetgroup.github.io/HealthCheck.html',
    tags    => [ "cheap", "easy" ],
    status  => "WARNING",
    results => [
        {   id      => "class_method",
            runtime => "0.000",
            tags    => [ "cheap", "easy" ],
            status  => "WARNING",
        },
        {   id      => "object_method",
            runtime => "0.000",
            tags    => [ "cheap", "easy" ],
            status  => "WARNING",
        }
    ],

=head1 DESCRIPTION

Allows you to create callbacks that check the health of your application
and return a status result.

There are several things this is trying to enable:

=over

=item *

A fast HTTP endpoint that can be used to verify that a web app can
serve traffic.
To this end, it may be useful to use the runtime support option,
available in L<HealthChecks::Diagnostic>.

=item *
A more complete check that verifies all the things work after a deployment.

=item *

The ability for a script, such as a cronjob, to verify that it's dependencies
are available before starting work.

=item *

Different sorts of monitoring checks that are defined in your codebase.

=back

Results returned by these checks should correspond to the GSG
L<Health Check Standard|https://grantstreetgroup.github.io/HealthCheck.html>.

You may want to use L<HealthCheck::Diagnostic> to simplify writing your
check slightly.

=head1 METHODS

=head2 new

    my $checker = HealthCheck->new( id => 'my_checker' );

=head3 ATTRIBUTES

=over

=item checks

An arrayref that is passed to L</register> to initialize checks.

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

=head2 register

    $checker->register({
        invocant => $class_or_object,
        check    => $method_on_invocant_or_coderef,
        more     => "any other params are passed to the check",
    });

Takes a list or arrayref of check definitions to be added to the object.

Each registered check must return a valid GSG Health Check response,
either as a hashref or an even-sized list.
See the GSG Health Check Standard (linked in L</DESCRIPTION>)
for the fields that checks should return.

Rather than having to always pass in the full hashref definition,
several common cases are detected and used to fill out the check.

=over

=item coderef

If passed a coderef, this will be called as the C<check> without an C<invocant>.

=item object

If a blessed object is passed in
and it has a C<check> method, use that for the C<check>,
otherwise throw an exception.

=item string

If a string is passed in,
check if it is the name of a loaded class that has a C<check> method,
and if so use it as the C<invocant> with the method as the C<check>.
Otherwise if our L<caller> has a method with this name,
the L<caller> becomes the C<invocant> and this becomes the C<check>,
otherwise throws an exception.

=item full hashref of params

The full hashref can consist of a C<check> key that the above heuristics
are applied,
or include an C<invocant> key that is used as either
an C<object> or C<class name>.
With the C<invocant> specified, the now optional C<check> key
defaults to "check" and is used as the method to call on C<invocant>.

All attributes other than C<invocant> and C<check> are passed to the check.

=back

=head2 check

    my %results = %{ $checker->check(%params) }

Calls all of the registered checks and returns a hashref of the results of
processing the checks passed through L<HealthCheck::Diagnostic/summarize>.
Passes the L</full hashref of params> as an even-sized list to the check,
without the C<invocant> or C<check> keys.
This hashref is shallow merged with and duplicate keys overridden by
the C<%params> passed in.

If there is both an C<invocant> and C<check> in the params,
it the C<check> is called as a method on the C<invocant>,
otherwise C<check> is used as a callback coderef.

If only a single check is registered,
the results from that check are merged with, and will override
the L</ATTRIBUTES> set on the object instead of being put in
a C<results> arrayref.

Throws an exception if no checks have been registered.

=head3 run

Main implementation of the checker is here.

Passes C<< summarize_result => 0 >> to each registered check
unless overridden to avoid running C<summarize> multiple times.
See L<HealthCheck::Diagnostic/check>.

=head2 get_registered_tags

Read-only accessor that returns the list of 'top-level' tags registered with
this object. Sub-check tags are not included - only those which will result in
checks being run when passed to L</check> on the given object.

=head1 INTERNALS

These methods may be useful for subclassing,
but are not intended for general use.

=head2 should_run

    my $bool = $checker->should_run( \%check, tags => ['apple', '!banana'] );

Takes a check definition hash and paramters and returns true
if the check should be run.
Used by L</check> to determine which checks to run.

Supported parameters:

=over

=item tags

Tags can be either "positive" or "negative". A negative tag is indicated by a
leading C<!>.
A check is run if its tags match any of the passed in positive tags and none
of the negative ones.
If no tags are passed in, all checks will be run.

If the C<invocant> C<can('tags')> and there are no tags in the
L</full hashref of params> then the return value of that method is used.

If a check has no tags defined, will use the default tags defined
when the object was created.

=back

=head1 DEPENDENCIES

Perl 5.10 or higher.

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 SEE ALSO

L<HealthCheck::Diagnostic>

The GSG
L<Health Check Standard|https://grantstreetgroup.github.io/HealthCheck.html>.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 - 2024 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
