package IOD::Counter::Simple;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-22'; # DATE
our $DIST = 'IOD-Counter-Simple'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

sub new {
    my ($class, %args) = @_;

    my $path = delete $args{path};
    $path //= do {
        $ENV{HOME} or die "HOME not defined, can't set default for path";
        "$ENV{HOME}/counter.iod";
    };

    unless (-f $path) {
        log_trace "Creating IOD counter file '$path' ...";
        open my $fh, ">>", $path or die "Can't open IOD counter file '$path': $!";
    }

    my $section = delete($args{section}) // 'counter';

    require Config::IOD;
    my $iod = Config::IOD->new(
        ignore_unknown_directives => 1,
    );

    die "Unknown constructor argument(s): ".join(", ", sort keys %args)
        if keys %args;
    bless {
        iod => $iod,
        path => $path,
        section => $section,
    }, $class;
}

sub dump {
    require File::Flock::Retry;

    my ($counter) = @_;

    my $lock = File::Flock::Retry->lock($counter->{path});
    my $doc = $counter->{iod}->read_file($counter->{path});
    $lock->release;

    my  %counters;
    $doc->each_key(
        sub {
            my (undef, %cbargs) = @_;
            next unless $cbargs{section} eq $counter->{section};
            $counters{ $cbargs{key} } = $cbargs{raw_value} + 0;
        });

    \%counters;
}

sub get {
    require File::Flock::Retry;

    my ($self, %args) = @_;

    my $counter = delete($args{counter}) // 'default';
    die "Unknown constructor argument(s): ".join(", ", sort keys %args)
        if keys %args;

    my $lock = File::Flock::Retry->lock($self->{path});
    my $doc = $self->{iod}->read_file($self->{path});
    $lock->release;

    my  %counters;
    $doc->get_value($self->{section}, $counter);
}

sub increment {
    require File::Flock::Retry;
    require File::Slurper;

    my ($self, %args) = @_;

    my $counter = delete($args{counter}) // 'default';
    my $increment = delete($args{increment}) // 1;
    my $dry_run = delete($args{-dry_run});
    die "Unknown constructor argument(s): ".join(", ", sort keys %args)
        if keys %args;

    my $lock = File::Flock::Retry->lock($self->{path});
    my $doc = $self->{iod}->read_file($self->{path});
    my $val;
    if ($doc->key_exists($self->{section}, $counter)) {
        $val = $doc->get_value($self->{section}, $counter) // 0;
        $val += $increment;
        $doc->set_value({create_section=>1}, $self->{section}, $counter, $val)
            unless $dry_run;
    } else {
        $val = 0;
        $val += $increment;
        $doc->insert_key({create_section=>1}, $self->{section}, $counter, $val)
            unless $dry_run;
    }

    File::Slurper::write_binary($self->{path}, $doc->as_string);
    $lock->release;

    $val;
}

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'A simple counter using IOD/INI file',
    description => <<'_',

This module provides simple counter using IOD/INI file as the storage. You can
increment or get the value of a counter using a single function call or a single
CLI script invocation.

_
};

our %argspecs_common = (
    path => {
        summary => 'IOD/INI file',
        description => <<'_',

If not specified, will default to $HOME/counter.iod. If file does not exist,
will be created.

_
        schema => 'filename*',
        pos => 1,
    },
    section => {
        summary => 'INI section name where the counters are put',
        schema => 'str*',
        default => 'counter',
        description => <<'_',

Counters are put as parameters in a specific section in the IOD/INI file, e.g.:

    [counter]
    counter1=1
    counter2=5

This argument customizes the section name.

_
    },
);

our %argspec_counter = (
    counter => {
        summary => 'Counter name, defaults to "default" if not specified',
        description => <<'_',

Note that counter name must be valid IOD/INI parameter name.

_
        schema => 'str*',
        pos => 0,
    },
);

$SPEC{increment_iod_counter} = {
    v => 1.1,
    summary => 'Increment a counter in an IOD/INI file and return the new incremented value',
    description => <<'_',

The first time a counter is created, it will be set to 0 then incremented to 1,
and 1 will be returned. The next increment will increment the counter to two and
return it.

If dry-run mode is chosen, the value that is returned is the value had the
counter been incremented, but the counter will not be actually incremented.

_
    args => {
        %argspecs_common,
        %argspec_counter,
        increment => {
            summary => 'Specify by how many should the counter be incremented',
            schema => 'int*',
            default => 1,
            cmdline_aliases => {i=>{}},
        },
    },
    features => {
        dry_run => 1,
    },
};
sub increment_iod_counter {
    my %args = @_;

    my $obj = __PACKAGE__->new(
        path => $args{path},
        section => $args{section},
    );
    [200, "OK",
     $obj->increment(counter => $args{counter}, increment => $args{increment}, -dry_run=>$args{-dry_run})];
}

$SPEC{dump_iod_counters} = {
    v => 1.1,
    summary => 'Return all the counters in the IOD/INI file as a hash',
    description => <<'_',
_
    args => {
        %argspecs_common,
    },
};
sub dump_iod_counters {
    my %args = @_;

    my $obj = __PACKAGE__->new(
        path => $args{path},
        section => $args{section},
    );
    [200, "OK",
     $obj->dump()];
}

$SPEC{get_iod_counter} = {
    v => 1.1,
    summary => 'Get the current value of a counter in an IOD/INI file',
    description => <<'_',

Undef (exit code 1 in CLI) can be returned if counter does not exist.

_
    args => {
        %argspecs_common,
        %argspec_counter,
    },
    features => {
        dry_run => 1,
    },
};
sub get_iod_counter {
    my %args = @_;

    my $obj = __PACKAGE__->new(
        path => $args{path},
        section => $args{section},
    );

    my $val = $obj->get(counter => $args{counter});
    [200, "OK", $val, {'cmdline.exit_code'=>defined $val ? 0:1}];
}

1;
# ABSTRACT: A simple counter using IOD/INI file

__END__

=pod

=encoding UTF-8

=head1 NAME

IOD::Counter::Simple - A simple counter using IOD/INI file

=head1 VERSION

This document describes version 0.002 of IOD::Counter::Simple (from Perl distribution IOD-Counter-Simple), released on 2021-06-22.

=head1 SYNOPSIS

From Perl:

 use IOD::Counter::Simple qw(increment_iod_counter get_iod_counter);

 # increment and get the dafault counter
 my $res;
 $res = increment_iod_counter(); # => [200, "OK", 1]
 $res = increment_iod_counter(); # => [200, "OK", 2]

 # the content of ~/counter.iod file after the above:
 [counter]
 default=2

 # dry-run mode
 $res = increment_iod_counter(-dry_run=>1); # => [200, "OK (dry-run)", 3]
 $res = increment_iod_counter(-dry_run=>1); # => [200, "OK (dry-run)", 3]

 # specify IOD file path and counter name, and also the increment
 $res = increment_iod_counter(path=>"/home/ujang/myapp.iod", counter=>"counter1"); # => [200, "OK", 1]
 $res = increment_iod_counter(path=>"/home/ujang/myapp.iod", counter=>"counter1", increment=>10); # => [200, "OK", 11]
 $res = increment_iod_counter(path=>"/home/ujang/myapp.iod", counter=>"counter2"); # => [200, "OK", 1]

 # the content of /home/ujang/myapp.iod file after the above:
 [counter]
 counter1=11
 counter2=1

 # get the current value of counter
 $res = get_iod_counter();               # => [200, "OK", 3, {'cmdline.exit_code'=>0}]
 $res = get_iod_counter(counter=>'foo'); # => [200, "OK", undef, {'cmdline.exit_code'=>1}]

From command-line (install L<App::IODCounterSimpeUtils>):

 # increment the dafault counter
 % increment-iod-counter
 1
 % increment-iod-counter
 2

 # dry-run mode
 % increment-iod-counter --dry-run
 3
 % increment-iod-counter --dry-run
 3

 # specify IOD file path and counter name, and also the increment
 % increment-iod-counter ~/myapp.iod counter1
 1
 % increment-iod-counter ~/myapp.iod counter1 -i 10
 11

=head1 DESCRIPTION


This module provides simple counter using IOD/INI file as the storage. You can
increment or get the value of a counter using a single function call or a single
CLI script invocation.

=head1 FUNCTIONS


=head2 dump_iod_counters

Usage:

 dump_iod_counters(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return all the counters in the IODE<sol>INI file as a hash.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

IODE<sol>INI file.

If not specified, will default to $HOME/counter.iod. If file does not exist,
will be created.

=item * B<section> => I<str> (default: "counter")

INI section name where the counters are put.

Counters are put as parameters in a specific section in the IOD/INI file, e.g.:

 [counter]
 counter1=1
 counter2=5

This argument customizes the section name.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_iod_counter

Usage:

 get_iod_counter(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get the current value of a counter in an IODE<sol>INI file.

Undef (exit code 1 in CLI) can be returned if counter does not exist.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<counter> => I<str>

Counter name, defaults to "default" if not specified.

Note that counter name must be valid IOD/INI parameter name.

=item * B<path> => I<filename>

IODE<sol>INI file.

If not specified, will default to $HOME/counter.iod. If file does not exist,
will be created.

=item * B<section> => I<str> (default: "counter")

INI section name where the counters are put.

Counters are put as parameters in a specific section in the IOD/INI file, e.g.:

 [counter]
 counter1=1
 counter2=5

This argument customizes the section name.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 increment_iod_counter

Usage:

 increment_iod_counter(%args) -> [$status_code, $reason, $payload, \%result_meta]

Increment a counter in an IODE<sol>INI file and return the new incremented value.

The first time a counter is created, it will be set to 0 then incremented to 1,
and 1 will be returned. The next increment will increment the counter to two and
return it.

If dry-run mode is chosen, the value that is returned is the value had the
counter been incremented, but the counter will not be actually incremented.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<counter> => I<str>

Counter name, defaults to "default" if not specified.

Note that counter name must be valid IOD/INI parameter name.

=item * B<increment> => I<int> (default: 1)

Specify by how many should the counter be incremented.

=item * B<path> => I<filename>

IODE<sol>INI file.

If not specified, will default to $HOME/counter.iod. If file does not exist,
will be created.

=item * B<section> => I<str> (default: "counter")

INI section name where the counters are put.

Counters are put as parameters in a specific section in the IOD/INI file, e.g.:

 [counter]
 counter1=1
 counter2=5

This argument customizes the section name.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 METHODS

Aside from the functional interface, this module also provides the OO interface.

=head2 new

Constructor.

Usage:

 my $counter = IOD::Counter::Simple->new(%args);

Known arguments (C<*> marks required argument):

=over

=item * path

IOD file path, defaults to C<$HOME/counter.iod>.

=back

=head2 increment

Increment counter.

Usage:

 my $newval = $counter->increment(%args);

Arguments:

=over

=item * counter

Counter name, defaults to C<default>.

=item * increment

Increment, defaults to 1.

=back

=head2 get

Get current value of a counter.

Usage:

 my $val = $counter->get(%args);

Arguments:

=over

=item * counter

Counter name, defaults to C<default>.

=back

=head2 dump

Dump all counters as a hash.

Usage:

 my $counters = $counter->dump(%args);

Arguments:

=over

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/IOD-Counter-Simple>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-IOD-Counter-Simple>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=IOD-Counter-Simple>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<SQLite::Counter::Simple>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
