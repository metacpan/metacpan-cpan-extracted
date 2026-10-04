#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Handle;

my $home = tempdir( CLEANUP => 1 );
my $handle = Developer::Dashboard::Handle->new( cwd => $home );

my @ran;
{
    no warnings 'redefine';
    local *Developer::Dashboard::Handle::run = sub { my ( $self, $command, @args ) = @_; @ran = ( $command, @args ); return 'ran ' . $command };

    my $proxy = $handle->some_command->nested;
    isa_ok( $proxy, 'Developer::Dashboard::Handle::Proxy', 'a method chain on a handle is a proxy' );
    is( "$proxy", 'd2 proxy: some-command.nested', 'the proxy stringifies without executing' );

    my $code = \&{$proxy};
    is( ref $code, 'CODE', 'dereferencing the proxy as code yields a code reference' );
    is( $code->( 'one', 'two' ), 'ran some-command.nested', 'calling that code reference runs the whole chain through Handle::run' );
    is_deeply( \@ran, [ 'some-command.nested', '--one', 'two' ], 'the chain and the call arguments (translated to CLI flag form) are handed to run' );

    @ran = ();
    is( $proxy->(), 'ran some-command.nested', 'calling the proxy directly runs the chain with no extra arguments' );
    is_deeply( \@ran, ['some-command.nested'], 'only the chain is handed to run when there are no arguments' );
}

done_testing;

__END__

=pod

=head1 NAME

t/803-handle-proxy-code-deref-coverage.t - covers invoking a Developer::Dashboard::Handle::Proxy as a code reference

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It builds a method chain on a handle, stubs C<Handle::run>, and calls the proxy as a code reference so the code-dereference overload and the closure it returns both run in-process.

=head1 WHY IT EXISTS

It exists because that closure was only reached through CLI subprocesses, whose coverage is not recorded the same way on every host, so a non-root CI run reported one subroutine uncovered (Problem 20).

=head1 WHEN TO USE

Use this file when you change how a chained handle call is executed, or when a coverage run reports a Handle proxy subroutine as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/803-handle-proxy-code-deref-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/803-handle-proxy-code-deref-coverage.t

Run this coverage-gap test by itself while editing the d2 handle proxy.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/803-handle-proxy-code-deref-coverage.t

Confirm the closure behind the code-dereference overload is reported as covered.

=cut
