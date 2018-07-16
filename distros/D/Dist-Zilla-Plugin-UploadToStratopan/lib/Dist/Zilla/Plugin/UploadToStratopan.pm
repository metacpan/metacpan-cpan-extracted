package Dist::Zilla::Plugin::UploadToStratopan;

our $VERSION = '0.013';

use Moose;
use Mojo::UserAgent;
use Mojo::DOM;

with 'Dist::Zilla::Role::Releaser';

# ABSTRACT: Automate Stratopan releases with Dist::Zilla

has agent => (
    is      => 'ro',
    isa     => 'Str',
    default => 'stratopan-uploader/' . $VERSION
);

has repo => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has stack => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'master',
    required => 1
);

has recurse => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has _strato_base => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://stratopan.com'
);

has _ua => (
    is         => 'ro',
    isa        => 'Mojo::UserAgent',
    lazy_build => 1
);

has _username => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1
);

has _password => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1
);

sub _build__username {
    my $self = shift;

    return $self->zilla->chrome->prompt_str("Stratopan username: ");
}

sub _build__password {
    my $self = shift;
    return $self->zilla->chrome->prompt_str("Stratopan password: ",
        { noecho => 1 });
}

sub _build__ua {
    my $self = shift;

    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name($self->agent);
    return $ua;
}

sub _login {
    my $self = shift;

    my $ua = $self->_ua;

    my $tx = $ua->post(
        $self->_strato_base . '/signin',
        form => {
            login    => $self->_username,
            password => $self->_password
        }
    );

    # stratopan redirects on a post (302)
    # and returns some div alert thing when posting - also returning a
    # 200
    if (my $error = $tx->res->dom->at('div#page-alert p')) {
        $self->log_fatal($error->text);
    }

}

sub _assert_stack {
    my ($self) = @_;

    my $stack_uri = sprintf '%s/%s/%s/%s',
        $self->_strato_base, $self->_username, $self->repo, $self->stack;

    my $tx = $self->_ua->get($stack_uri);

    if ($tx->res->code == 200) {
        return $stack_uri;
    }
    $self->log_fatal(
        sprintf(
            "Stack %s does not exist in repo '%s', create it first",
            $self->stack, $self->repo
        )
    );

}

sub release {
    my ($self, $tarball) = @_;

    $tarball = "$tarball";    # stringify object
    $self->log_fatal("No tarball found with name $tarball") unless $tarball;

    $self->_login;
    my $ua = $self->_ua;

    my $submit_url = join('/', $self->_assert_stack, qw(stack add));

    $self->log(["uploading %s to %s", $tarball, $submit_url]);

    my $tx = $ua->post(
        $submit_url,
        form => {
            recurse => $self->recurse,
            message => "Uploaded by " . __PACKAGE__,
            archive => { file => $tarball }
        }
    );

    if ($tx->res->code == 302) {
        return $self->log("success.");
    }
    $self->log_fatal($tx->res->dom->at('div#page-alert p')->text);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::UploadToStratopan - Automate Stratopan releases with Dist::Zilla

=head1 VERSION

version 0.013

=head1 SYNOPSIS

In your C<dist.ini>:

    [UploadToStratopan]
    repo    = myrepo
    stack   = master
    recurse = 1 ;defaults to 0

=head1 DESCRIPTION

This is a Dist::Zilla releaser plugin which will automatically upload your
completed build tarball to Stratopan.

The module will prompt you for your Stratopan username (NOT email) and password.

Currently, it works by posting the file to Stratopan's "Add" form; when the
Stratopan REST API becomes available, this module will be updated to use it
instead.

=head1 NAME

Dist::Zilla::Plugin::UploadToStratopan - Automate Stratopan releases with Dist::Zilla

=head1 ATTRIBUTES

=head2 agent

The HTTP user agent string to use when talking to Stratopan. The default
is C<stratopan-uploader/$VERSION>.

=head2 repo

The name of the Stratopan repository. Required.

=head2 stack

The name of the stack within your repository to which you want to upload. The
default is C<master>.

=head2 recurse

Recursively pull all prerequisites too when true, defaults to only uploading
the intented modules

=head1 METHODS

=head2 release

Release the modeule

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mike Friedman

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mike Friedman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
