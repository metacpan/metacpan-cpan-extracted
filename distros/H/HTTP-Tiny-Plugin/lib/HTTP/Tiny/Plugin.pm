package HTTP::Tiny::Plugin;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-14'; # DATE
our $DIST = 'HTTP-Tiny-Plugin'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use parent 'HTTP::Tiny';

if ($ENV{HTTP_TINY_PLUGINS}) {
    require JSON::PP;
    __PACKAGE__->set_plugins(@{
        JSON::PP::decode_json($ENV{HTTP_TINY_PLUGINS})
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
        $class = "HTTP::Tiny::Plugin::$class"
            unless $class =~ /\AHTTP::Tiny::Plugin::/;
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

    my $status;
    for my $p (@plugins) {
        next unless $p->[0]->can($hook);
        local $r->{config} = $p->[1];
        local $r->{hook} = $hook;
        $status = $p->[0]->$hook($r);
        unless ($opts->{all}) {
            last unless $status == -1;
        }
        last if $status == 98 || $status == 99;
    }
    $status // -1;
}

sub request {
    my $r = {http=>$_[0], ua=>$_[0], argv=>[@_]};
    my $self = shift;

    goto RETURN_RESPONSE
        if $self->_run_hooks('before_request_once', {all=>1}, $r) == 99;

    while (1) {
        $r->{response} = $self->SUPER::request(@_)
            unless $self->_run_hooks('before_request', {all=>1}, $r) == 99;
        last unless $self->_run_hooks('after_request', {all=>1}, $r) == 98;
    }

  RETURN_RESPONSE:
    $r->{response};
}

1;
# ABSTRACT: HTTP::Tiny with plugins

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Plugin - HTTP::Tiny with plugins

=head1 VERSION

This document describes version 0.003 of HTTP::Tiny::Plugin (from Perl distribution HTTP-Tiny-Plugin), released on 2020-08-14.

=head1 SYNOPSIS

 # set plugins to use, globally
 use HTTP::Tiny::Plugin Retry=>{retries=>3, retry_delay=>2}, 'Cache';

 my $res;
 $res = HTTP::Tiny::Plugin->new->get("http://www.example.com/");       # will retry a few times if failed
 $res = HTTP::Tiny::Plugin->request(GET => "http://www.example.com/"); # will get cached response

 # to set plugins locally
 {
     my @old_plugins = HTTP::Tiny::Plugin->set_plugins(Retry=>{max_attempts=>3, delay=>2}, 'Cache');
     # do stuffs
     HTTP::Tiny::Plugin->set_plugins(@old_plugins);
 }

=head1 DESCRIPTION

B<EARLY RELEASE, THINGS MIGHT STILL CHANGE A LOT>.

HTTP::Tiny::Plugin allows you to extend functionalities of L<HTTP::Tiny> using
plugins instead of subclassing. This makes it easy to combine several
functionalities together. (Ironically, HTTP::Tiny::Plugin itself is a subclass
of HTTP::Tiny, but the plugins need not be.)

=head2 Plugins

A plugin should be module named under C<HTTP::Tiny::Plugin::>, e.g.
L<HTTP::Tiny::Plugin::Cache>, L<HTTP::Tiny::Plugin::Log>,
HTTP::Tiny::Plugin::Some::Other::Name, etc.

Plugins are used either via import arguments to HTTP::Tiny::Plugin:

 use HTTP::Tiny::Plugin Retry=>{retries=>3, retry_delay=>2}, 'Cache';

or via calling L</set_plugins>.

=head2 Hooks

Plugin can define zero or more hooks (as methods with the same name as the hook)
that will be executed during various stages.

=head2 Hook arguments

Hooks will be called with argument C<$r>, a hash that contains various
information. Keys that are common for all hooks:

=over

=item * config

Hash.

=item * http

Object. The HTTP::Tiny object.

=item * ua

Like C<http>.

=item * hook

The current hook name.

=item * argv

Array. Arguments passed to hook-related method. For example, for
L</before_request> and L</after_request> hooks, C<argv> will contain arguments
(C<@_>) passed to C<request()>.

=item * response

Hash. The HTTP::Tiny response. Hooks can modify this.

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

=item * before_request_once

Will be called before C<request()> (and before L</before_request> hook). All
plugins will be called. Stage will interpret 99 (skip calling C<request()>).
When request is skipped, request() will return undef.

When an L</after_request> plugin returns 98 (repeat), this hook will not be
repeated, but L</before_request> hook will.

=item * before_request

Will be called before C<request()>. All plugins will be called. Stage will
interpret 99 (skip calling C<request()>, including skipping L</after_request>).
When request is skipped, request() will return undef.

See also: L</before_request_once>.

=item * after_request

Will be called after C<request()>. All plugins will be called. Stage will
interpret 98 (repeat calling C<request()>, including the L</before_request> hook
but not the L</before_request_once> hook).

=back

=head1 METHODS

=head2 set_plugins

Usage:

 HTTP::Tiny::Plugin->set_plugins('Plugin1', 'Plugin2'=>{arg=>val, ...}, ...);

Class method. Set plugins to use (and replace the previous set of plugins used).
Will return a list containing previous set of plugins.

Argument is a list of plugin names, with/without the C<HTTP::Tiny::Plugin::>
prefix. After each plugin name, an optional hashref can be specified to
configure the plugin.

=head1 ENVIRONMENT

=head2 HTTP_TINY_PLUGINS

A JSON-encoded array. If set, will call L</set_plugins> with the decoded value.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Plugin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Plugin>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Plugin>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny>

L<LWP::UserAgent::Plugin>

L<HTTP::Tiny::Patch::Plugin>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
