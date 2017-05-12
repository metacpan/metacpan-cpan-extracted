package Email::Forward::Dispatch;
use 5.008005;
use strict;
use warnings;
use Email::MIME;
use Module::Pluggable::Object;

our $VERSION = "0.04";

my $id = 0;
sub new {
    my ($class,%args) = @_;

    my $default_hook = "";
    unless ($args{hooks_dir}) {
        $args{is_forward_cb}   or die 'you must register is_forward_cb!';
        $args{forward_cb} or die 'you must register forward_cb!';

        {
            $default_hook = "Email::Forward::Dispatch::Hooks::Default".$id++;
            no strict 'refs'; ## no critic.
            push @{"$default_hook\::ISA"}, 'Email::Forward::Dispatch::Hooks';
            *{"$default_hook\::is_forward"}   = sub { my ($class, $parsed) = @_;  $args{is_forward_cb}->($default_hook,$parsed); };
            *{"$default_hook\::forward"} = sub { my ($class, $parsed) = @_;  $args{forward_cb}->($default_hook,$parsed); };
        }
    }

    my $mail = $args{mail} || do {local $/; <STDIN>; } || die 'you must set mail option or STDIN !';

    my $self = bless +{
        email         => Email::MIME->new($mail),
        hooks_dir     => $args{hooks_dir} || 'Email::Forward::Dispatch::Hooks',
        default_hook => $default_hook,   
    }, $class;
}

sub default_hook { $_[0]->{default_hook} }

sub run {
    my ($self) = @_;

    my @hooks = $self->fetch_hooks();

    if (my $default_hook = $self->{default_hook}) {
        $default_hook->is_forward($self->{email})
            and $default_hook->forward($self->{email});
    }else{
        for my $hook (@hooks) {
            next unless $hook->is_forward($self->{email});

            $hook->forward($self->{email});
        }
    }
}

sub fetch_hooks {
    my $self = shift;

    my @hooks = Module::Pluggable::Object->new(
        require     => 1,
        search_path => $self->{hooks_dir},
    )->plugins;
}

1;
__END__

=encoding utf-8

=head1 NAME

Email::Forward::Dispatch - use ~/.forward plaggerable

=head1 SYNOPSIS

    # in /home/hirobanex/script.pl
    use Email::Forward::Dispatch;

    my $dispatcher = Email::Forward::Dispatch->new(
        is_forward_cb   => sub { ($_[1]->header('To') =~ /hirobanex\@gmail\.com/) ? 1 : 0 },
        forward_cb      => sub { print $_[1]->header('To') },
    );

    or 

    my $dispatcher = Email::Forward::Dispatch->new(
        mail      => scalar do {local $/; <STDIN>; },
        hooks_dir => "MyMailNotify::Hooks",
    );

    $dispatcher->run;


    #in /home/hirobanex/.forward
    "|exec /home/hirobanex/script.pl"

=head1 DESCRIPTION

Email::Forward::Dispatch is Email forward utility tool. 

=head1 LICENSE

Copyright (C) Hiroyuki Akabane.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyuki Akabane E<lt>hirobanex@gmail.comE<gt>

=for stopwords plaggerable

=cut

