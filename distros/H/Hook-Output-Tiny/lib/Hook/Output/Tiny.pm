package Hook::Output::Tiny;
use strict;
use warnings;

our $VERSION = '1.02';

use Carp qw(croak);

BEGIN {
    # Auto generate the stdout() and stderr() methods, and their private
    # helper counterparts

    no strict 'refs';

    for ('stdout', 'stderr') {
        my $sub_name = $_; # We need to make a copy

        # Public

        *$_ = sub {
            my ($self) = @_;

            if (! wantarray) {
                warn "Calling $sub_name() in non-list context is deprecated!\n";
            }
            return defined $self->{$sub_name}{data}
                ? split /\n/, $self->{$sub_name}{data}
                : @{[ () ]}; # Empty list
        };

        # Private

        my $private_sub_name = "_$sub_name";

        *$private_sub_name = sub {
            my ($self) = @_;

            my $HANDLE = uc $sub_name;
            open $self->{$sub_name}{handle}, '>&', $HANDLE
              or croak("can't hook " . uc $sub_name . ": $!");
            close $HANDLE;
            open $HANDLE, '>>', \$self->{$sub_name}{data} or croak($!);
        };
    }
}
sub new {
    my %struct = map { $_ => {_struct()} } qw(stderr stdout);
    return bless \%struct, $_[0];
}
sub hook {
    my ($self, $handle) = @_;
    $_ eq 'stderr' ? $self->_stderr : $self->_stdout for _handles($handle);
}
sub unhook {
    my ($self, $handle) = @_;

    for (_handles($handle)) {
        no strict 'refs'; # To allow a string as STDOUT/STDERR bareword handles
        close uc $_;
        open uc $_, '>&', $self->{$_}{handle} or croak($!);
    }
}

# Commenting out include() and exclude(). They're to be used to filter the
# output. They have no docs nor tests yet.

#sub include {
#    my ($self, $include) = @_;
#
#    if (defined $include) {
#        if (ref $include ne 'ARRAY') {
#            croak("include() requires an array of regex objects sent in");
#        }
#        if (! defined $include->[0]) {
#            croak("include() requires at least one regex object within the array reference");
#        }
#        for (@$include) {
#            if (ref $_ ne 'REGEX') {
#                croak("include()'s array reference must only contain regex objects");
#            }
#        }
#        $self->{include} = $include;
#    }
#
#    return $self->{include} // [];
#}
#sub exclude {
#    my ($self, $exclude) = @_;
#
#    if (defined $exclude) {
#        if (ref $exclude ne 'ARRAY') {
#            croak("exclude() requires an array of regex objects sent in");
#        }
#        if (! defined $exclude->[0]) {
#            croak("exclude() requires at least one regex object within the array reference");
#        }
#        for (@$exclude) {
#            if (ref $_ ne 'REGEX') {
#                croak("exclude()'s array reference must only contain regex objects");
#            }
#        }
#        $self->{exclude} = $exclude;
#    }
#
#    return $self->{exclude} // [];
#}
sub flush {
    my ($self, $handle) = @_;
    delete $self->{$_}{data} for _handles($handle);
}
sub write {
    my ($self, $fn, $handle) = @_;
    if ($fn eq 'stderr' || $fn eq 'stdout'){
        croak("write() requires a file name sent in before the handle\n");
    }

    for (_handles($handle)){
        open my $wfh, '>>', $fn or croak($!);
        print $wfh $self->{$_}{data};
        close $wfh;
        $self->flush($_);
    }
}
sub _struct {
     return (handle => *fh, data => '');
}
sub _handles {
    my ($handle) = @_;
    my $sub = (caller(1))[3];
    _check_param($sub, $handle) if $handle;
    return $handle ? ($handle) : qw(stderr stdout);
}
sub _check_param {
    # validates the $handle param
    my ($sub, $handle) = @_;
    if (! grep {$handle eq $_} qw(stderr stdout)){
        croak(
            "$sub() either takes 'stderr', 'stdout' or no params\n" .
            "You supplied '$handle'\n"
        );
    }
}

1;
__END__

=head1 NAME

Hook::Output::Tiny - Easily enable/disable trapping of STDOUT/STDERR

=for html
<a href="https://github.com/stevieb9/p5-hook-output-tiny/actions"><img src="https://github.com/stevieb9/p5-hook-output-tiny/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/=?branch=master'><img src='https://coveralls.io/repos/stevieb9/p5-hook-output-tiny/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Hook::Output::Tiny;

    my $trap = Hook::Output::Tiny->new;

    # trap either

    $trap->hook('stdout');
    ...
    my @out = $trap->stdout;

    $trap->hook('stderr');
    ...
    my @err = $trap->stderr;

    # untrap either

    $trap->unhook('stdout');
    $trap->unhook('stderr');

    # trap/untrap both simultaneously

    $trap->hook;

    print "blah!\n"; # STDOUT
    warn  "blah!\n"; # STDERR

    $trap->unhook;

    # delete all entries from both (can specify individually)

    $trap->flush;

    # append to a file (can specify individually)

    $trap->write('file.txt');

=head1 DESCRIPTION

Extremely lightweight mechanism for trapping C<STDOUT>, C<STDERR> or both.

We save the captured output internally, so on long running applications, memory
usage may become an issue if you don't C<flush()> out or C<write()> out the data.

There are many modules that perform this task. I wrote this one as a learning
exercise, and to make it as small and as simple as possible.

=head1 METHODS

=head2 new

Returns a new L<Hook::Output::Tiny> instance.

=head2 hook

You can send in either C<'stdout'> or C<'stderr'> and we'll trap that data.

If you don't specify an option, we'll trap both (the data remains separated).

=head2 unhook

Send in either C<'stdout'> or C<'stderr'>. If not specified, we'll untrap
both.

=head2 stdout

Returns a list of all the C<STDOUT> entries that have been trapped.

Calling this method in non-list context now throws a warning, and is now
deprecated and will be removed in a future release.

=head2 stderr

Returns a list of all the C<STDERR> entries that have been trapped.

Calling this method in non-list context now throws a warning, and is now
deprecated and will be removed in a future release.

=head2 write($filename, $handle)

Writes to C<$filename> the entries in C<$handle>, where C<$handle> is either
C<stdout> or C<stderr>. If no C<$handle> is specified, we'll write out both
handles to the same file.

We then C<flush()> (ie. delete) the respective handle data until the next
C<write()> or C<flush()>.

=head2 flush

Deletes all data for the handles. Send in either C<'stdout'> or C<'stderr'> to
specify which to delete, otherwise we'll delete both.

=head1 EXAMPLE

Testing scenario...

    use Foo::Bar;
    use Hook::Output::Tiny;
    use Test::More;

    my $output = Hook::Output::Tiny->new;
    my $thing = Foo::Bar->new;

    $output->hook;

    $thing->do;

    $output->unhook;

    is ($thing->do(), 1, "thing() ok");
    is ($output->stdout, 2, "got expected STDOUT");
    is ($output->stderr, 0, "got no STDERR");

    my @stdout = $output->stdout;

    like ($stdout[0], qr/do() called/, "STDOUT ok");
    is ($stdout[1], 'did', "STDOUT said do() 'did'");

    $output->hook;

    $thing->error;

    $output->unhook;

    @stderr = $output->stderr;

    like ($stderr[0], qr/error/, "error() errored properly");

=head1 SEE ALSO

L<Capture::Tiny>, the de-facto in-core standard.

L<IO::CaptureOutput>

L<IO::Capture::Output>

L<Hook::Output::File>

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hook::Output::Tiny

=head1 LICENSE AND COPYRIGHT

Copyright 2023 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
