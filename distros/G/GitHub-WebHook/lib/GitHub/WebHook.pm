package GitHub::WebHook;
use strict;
use warnings;

our $VERSION = '0.11';

sub new { bless {}, $_[0] }

sub call {
    my ($self, $event, $id, $logger) = @_;
    $logger->{error}->("method call not implemented in ".ref $self);
    return;
}

1;
__END__

=head1 NAME

GitHub::WebHook - Collection of GitHub WebHook handlers

=head1 SYNOPSIS

Create new webhook handler (or use one of the existing L</MODULES>):

    package GitHub::WebHook::Example;
    use parent 'GitHub::WebHook';
    sub call {
        my ($payload, $event, $id, $logger) = @_;
        ...
        $logger->{info}->("processing some $event with $id");
        1; # success
    }

Build a receiver script with L<Plack::App::GitHub::WebHook>:

    use Plack::App::GitHub::WebHook;
    Plack::App::GitHub::WebHook->new( hook => 'Example' )->to_app;

=begin markdown
 
# STATUS
 
[![Build Status](https://travis-ci.org/nichtich/GitHub-WebHook.png)](https://travis-ci.org/nichtich/GitHub-WebHook)
[![Coverage Status](https://coveralls.io/repos/nichtich/GitHub-WebHook/badge.png?branch=master)](https://coveralls.io/r/nichtich/GitHub-WebHook?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/GitHub-WebHook.png)](http://cpants.cpanauthors.org/dist/GitHub-WebHook)

=end markdown

=head1 DESCRIPTION

GitHub::Webhook provides handlers that receive webhooks in L<GitHub
WebHooks|http://developer.github.com/webhooks/> format or similar forms.

The module can be used with L<Plack::App::GitHub::WebHook> to create webhook
receiver scripts, but it can also be used independently.

A Perl module in the GitHub::WebHook namespace is expected to implement a
method named C<call> which is called with the following parameters: 

=over

=item payload

The encoded webhook payload

=item event

The type of L<webhook event|https://developer.github.com/webhooks/#events> e.g.
C<pull>

=item id

A unique delivery ID

=item logger

A logger object as (possibly blessed) HASH reference with properties C<debug>,
C<info>, C<warn>, C<error>, C<fatal>, each being a CODE reference to send log
messages to.

=back

=head1 MODULES

=over

=item L<GitHub::WebHook::Run>

run a subprocess

=item L<GitHub::WebHook::Clone>

clone/pull from a git repository

=back

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
