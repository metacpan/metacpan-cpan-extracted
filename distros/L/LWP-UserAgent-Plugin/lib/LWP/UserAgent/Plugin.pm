package LWP::UserAgent::Plugin;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-13'; # DATE
our $DIST = 'LWP-UserAgent-Plugin'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use parent 'LWP::UserAgent';

if ($ENV{LWP_USERAGENT_PLUGINS}) {
    require JSON::PP;
    __PACKAGE__->set_plugins(@{
        JSON::PP::decode_json($ENV{LWP_USERAGENT_PLUGINS})
      });
}

sub import {
    my $class = shift;
    $class->set_plugins(@_) if @_;
}

my @plugins;
sub set_plugins {
    my $class = shift;

    my @old_plugins = @plugins;
    @plugins = ();
    while (1) {
        last unless @_;
        my $arg = shift;
        my $class = ref $class eq 'ARRAY' ? $arg->[0] : $arg;
        $class = "LWP::UserAgent::Plugin::$class"
            unless $class =~ /\ALWP::UserAgent::Plugin::/;
        (my $class_pm = "$class.pm") =~ s!::!/!g;
        require $class_pm;
        my $config = ref $arg eq 'ARRAY' ? $arg->[1] :
            ref($_[0]) eq 'HASH' ? shift : {};
        push @plugins, [$class, $config];
    }
    @old_plugins;
}

sub _run_hooks {
    my ($self, $hook, $opts, $r) = @_;

    log_trace "[LWP::UserAgent::Plugin] -> running hook %s", $hook if $ENV{LWP_USERAGENT_PLUGIN_TRACE};

    my $status;
    for my $p (@plugins) {
        next unless $p->[0]->can($hook);
        log_trace "[LWP::UserAgent::Plugin]   -> handler from plugin %s", $p->[0] if $ENV{LWP_USERAGENT_PLUGIN_TRACE};
        local $r->{config} = $p->[1];
        local $r->{hook} = $hook;
        $status = $p->[0]->$hook($r);
        unless ($opts->{all}) {
            last unless $status == -1;
        }
        last if $status == 98 || $status == 99;
    }
    $status //= -1;
    log_trace "[LWP::UserAgent::Plugin] <- return hook %s, status %d", $hook, $status if $ENV{LWP_USERAGENT_PLUGIN_TRACE};
    $status;
}

sub request {
    my $r = {ua=>$_[0], argv=>[@_], method=>'request'};
    my $self = shift;

    while (1) {
        $r->{response} = $self->SUPER::request(@_)
            unless $self->_run_hooks('before_request', {all=>1}, $r) == 99;
        last unless $self->_run_hooks('after_request', {all=>1}, $r) == 98;
    }
    $r->{response};
}

sub mirror {
    my $r = {ua=>$_[0], argv=>[@_], method=>'mirror'};
    my $self = shift;

    while (1) {
        $r->{response} = $self->SUPER::mirror(@_)
            unless $self->_run_hooks('before_mirror', {all=>1}, $r) == 99;
        last unless $self->_run_hooks('after_mirror', {all=>1}, $r) == 98;
    }
    $r->{response};
}

1;
# ABSTRACT: LWP::UserAgent with plugins

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Plugin - LWP::UserAgent with plugins

=head1 VERSION

This document describes version 0.004 of LWP::UserAgent::Plugin (from Perl distribution LWP-UserAgent-Plugin), released on 2020-08-13.

=head1 SYNOPSIS

 # set plugins to use, globally
 use LWP::UserAgent::Plugin Retry=>{retries=>3, retry_delay=>2}, 'Cache';

 my $ua = LWP::UserAgent::Plugin->new;
 my $res;
 $res = $ua->get("http://www.example.com/"); # will retry a few times if failed
 $res = $ua->get("http://www.example.com/"); # will get cached response

 # to set plugins locally
 {
     my @old_plugins = LWP::UserAgent::Plugin->set_plugins(Retry=>{max_attempts=>3, delay=>2}, 'Cache');
     # do stuffs
     LWP::UserAgent::Plugin->set_plugins(@old_plugins);
 }

=head1 DESCRIPTION

B<EARLY RELEASE, THINGS MIGHT STILL CHANGE A LOT>.

Like L<HTTP::Tiny::Plugin>, LWP::UserAgent::Plugin allows you to extend
functionalities of L<LWP::UserAgent> using plugins instead of subclassing. This
makes it easy to combine several functionalities together. (Ironically,
LWP::UserAgent::Plugin itself is a subclass of LWP::UserAgent, but the plugins
need not be.)

=head2 Plugins

A plugin should be module named under C<LWP::UserAgent::Plugin::>, e.g.
L<LWP::UserAgent::Plugin::Cache>, LWP::UserAgent::Plugin::Some::Other::Name,
etc.

Plugins are used either via import arguments to LWP::UserAgent::Plugin:

 use LWP::UserAgent::Plugin Retry=>{retries=>3, retry_delay=>2}, 'Cache';

or via calling L</set_plugins>.

=head2 Hooks

Plugin can define zero or more hooks (as methods with the same name as the hook)
that will be executed during various stages.

=head2 Hook arguments

Hooks will be called with argument C<$r>, a hash that contains various
information. Keys that are common for all hooks:

=over

=item * method

The related LWP::UserAgent method. For example, in C<before_request> and
C<after_request> hook, the value is C<request>.

=item * config

Hash.

=item * ua

Object. The LWP::UserAgent object.

=item * hook

The current hook name.

=item * hook

The hook name.

=item * argv

Array. Arguments passed to hook-related method. For example, for
L</before_request> and L</after_request> hooks, C<argv> will contain arguments
(C<@_>) passed to C<request()>.

=item * response

Object. The L<HTTP::Response> object. Hooks can modify this.

=back

=head2 Hook return value

Hooks can return an integer, which can be used to signal
declination/success/failure as well as flow control. The following values are
possible:

=over

=item * -1

Declare decline (i.e. try next hook).

=item * 0

Declare failure status (for the stage). For a stage that only wants a single
plugin to respond, this will stop hook execution for that stage and the next
plugin in line will not be called. For a stage that wants to execute all
plugins, this will still continue to the next plugin. The status of the
stage is from the status of the plugin called last.

=item * 1

Declare success/OK status (for the stage). For a stage that only wants a single
plugin to respond, this will stop hook execution for that stage and the next
plugin in line will not be called. For a stage that wants to execute all
plugins, this will still continue to the next plugin. The status of the stage is
from the status of the plugin called last.

=item * 99

Skip execution of hook-related method. For example, if we return 99 in
L</before_request> then C<request()> will be skipped.

Will also immediately stop hook execution for that stage.

=item * 98

Repeat execution of hook-related method. For example, if we return 98 in
L</after_request> then C<request()> will be repeated.

Will also immediately stop hook execution for that stage.

=back

=head2 List of available hooks

Below is the list of hooks in order of execution during a request:

=over

=item * before_request

Will be called before C<request()>. All plugins will be called. Stage will
interpret 99 (skip calling C<request()>).

=item * after_request

Will be called before C<request()>. All plugins will be called. Stage will
interpret 98 (repeat calling C<request()>).

=item * before_mirror

Will be called before C<mirror()>. All plugins will be called. Stage will
interpret 99 (skip calling C<mirror()>).

=item * after_mirror

Will be called before C<request()>. All plugins will be called. Stage will
interpret 98 (repeat calling C<mirror()>).

=back

=head1 METHODS

=head2 set_plugins

Usage:

 LWP::UserAgent::Plugin->set_plugins('Plugin1', 'Plugin2'=>{arg=>val, ...}, ...);

Class method. Set plugins to use (and replace the previous set of plugins used).
Will return a list containing previous set of plugins.

Argument is a list of plugin names, with/without the C<LWP::UserAgent::Plugin::>
prefix. After each plugin name, an optional hashref can be specified to
configure the plugin.

=head1 ENVIRONMENT

=head2 LWP_USERAGENT_PLUGIN_TRACE

Bool. If set to true, will produce more trace log statements.

=head2 LWP_USERAGENT_PLUGINS

A JSON-encoded array. If set, will call L</set_plugins> with the decoded value.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-Plugin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-UserAgent-Plugin>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Plugin>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<LWP::UserAgent>

L<HTTP::Tiny::Plugin>

L<LWP::UserAgent::Patch::Plugin>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
