package Hubot::Robot;
$Hubot::Robot::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

use Pod::Usage;

use AnyEvent;
use AnyEvent::HTTPD;
use AnyEvent::HTTP::ScopedClient;

use Hubot::User;
use Hubot::Brain;
use Hubot::Listener;
use Hubot::TextListener;

has 'name'  => ( is => 'rw', isa => 'Str' );
has 'alias' => ( is => 'rw', isa => 'Str' );
has 'mode'  => ( is => 'rw', isa => 'Str', default => '' );
has 'adapter' => ( is => 'rw' );
has 'brain' => (
    is      => 'ro',
    isa     => 'Hubot::Brain',
    default => sub { Hubot::Brain->new }
);
has '_helps' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => { helps => 'elements', addHelp => 'push', }
);
has '_commands' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => { commands => 'elements', addCommand => 'push', }
);
has '_listeners' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Hubot::Listener]',
    default => sub { [] },
    handles => { listeners => 'elements', addListener => 'push', }
);

## Ping Watcher
has 'pw'    => ( is => 'rw' );
has 'httpd' => ( is => 'rw' );

sub BUILD {
    my $self = shift;

    $self->setupHerokuPing;
    $self->loadAdapter( $self->adapter );
}

sub setupHerokuPing {
    my $self = shift;

    my $httpd = AnyEvent::HTTPD->new( port => $ENV{PORT} || 8080, host => $ENV{HUBOT_HTTPD_ADDRESS} || '0.0.0.0' );
    $httpd->reg_cb(
        '/hubot/ping' => sub {
            my ( $httpd, $req ) = @_;
            $req->respond( { content => ['text/plain', "pong"] } );
        }
    );

    $self->httpd($httpd);

    my $herokuUrl = $ENV{HEROKU_URL} || return;
    $herokuUrl =~ s{/?$}{/hubot/ping};

    $self->pw(
        AE::timer 0,
        120,
        sub {
            AnyEvent::HTTP::ScopedClient->new($herokuUrl)
                ->post( sub { print "Keep alive ping!\n" if $ENV{DEBUG} } );
        }
    );
}

sub loadAdapter {
    my ( $self, $adapter ) = @_;

    $adapter = "Hubot::Adapter::" . ucfirst($adapter);
    eval "require $adapter; 1";
    if ($@) {
        print STDERR "Cannot load adapter $adapter - $@\n";
    }
    else {
        $self->adapter( $adapter->new( { robot => $self } ) );
    }
}

sub run { shift->adapter->run }

sub userForId {
    my ( $self, $id, $options ) = @_;
    my $user = $self->brain->{data}{users}{$id};
    unless ($user) {
        $user = Hubot::User->new( { id => $id, %$options } );
        $self->brain->{data}{users}{$id} = $user;
    }

    my $options_room = $options->{room} || '';
    if ( $options_room
        && ( !$user->{room} || $user->{room} ne $options_room ) )
    {
        $user = Hubot::User->new( { id => $id, %$options } );
        $self->brain->{data}{users}{$id} = $user;
    }

    return $user;
}

sub userForName {
    my ( $self, $name ) = @_;
    my $result;
    for my $k ( keys %{ $self->brain->{data}{users} } ) {
        my $userName = $self->brain->{data}{users}{$k}{name};
        if ( lc $userName eq lc $name ) {
            $result = $self->brain->{data}{users}{$k};
        }
    }

    return $result;
}

sub usersForFuzzyRawName {
    my ( $self, $fuzzyName ) = @_;
    my $lowerFuzzyName = lc $fuzzyName;
    my @users;
    while ( my ( $key, $user ) = each %{ $self->brain->{data}{users} || {} } )
    {
        if ( lc( $user->{name} ) =~ m/^$lowerFuzzyName/ ) {
            push @users, $user;
        }
    }

    return @users;
}

sub usersForFuzzyName {
    my ( $self, $fuzzyName ) = @_;
    my @matchedUsers   = $self->usersForFuzzyRawName($fuzzyName);
    my $lowerFuzzyName = lc $fuzzyName;
    for my $user (@matchedUsers) {
        return $user if lc( $user->{name} ) eq $lowerFuzzyName;
    }

    return @matchedUsers;
}

sub shutdown {
    my $self = shift;
    $self->brain->close;
    $self->adapter->close;
}

sub loadHubotScripts {
    my ( $self, $scripts ) = @_;
    ## TODO: Debug Message
    # print "Loading hubot-scripts\n" if $ENV{DEBUG};
    for my $script (@$scripts) {
        $self->loadFile($script);
    }
}

sub loadFile {
    my ( $self, $script ) = @_;
    my $full = "Hubot::Scripts::$script";
    eval "require $full; 1";
    $full->load($self);
    if ($@) {
        print STDERR "Unable to load $full: $@\n";
    }
    else {
        $self->parseHelp($full);
    }
}

sub parseHelp {
    my ( $self, $module ) = @_;
    $module =~ s{::}{/}g;
    my $fullpath = $INC{ $module . '.pm' };

    open my $fh, '>', \my $usage or die "Couldn't open filehandle: $!\n";
    pod2usage(
        { -input => $fullpath, -output => $fh, -exitval => 'noexit', } );

    $usage =~ s/^Usage://;
    $usage =~ s/(^\s+|\s+$)//gm;
    $self->addHelp($_) for split( /\n/, $usage );

    $module =~ s{Hubot/Scripts/}{};
    $self->addCommand($module);
}

sub hear {
    my ( $self, $regex, $callback ) = @_;
    $self->addListener(
        new Hubot::TextListener(
            robot    => $self,
            regex    => $regex,
            callback => $callback
        )
    );
}

sub respond {
    my ( $self, $regex, $callback ) = @_;

    my $index = index "$regex", ':';
    my $stringRegex = substr "$regex", ( $index + 1 ), -1;
    my $first = substr $stringRegex, 0, 1;

    ## TODO: $^ 에 따른 분기; perl version 에 따라서 Regex object 의 modifier 위치가 달라짐
    my $modifiers    = '';
    my $modifiersLen = $index - 3;
    if ( $modifiersLen > 0 && length $stringRegex > 3 ) {
        $modifiers = substr $stringRegex, 3, $modifiersLen;
    }

    if ( $first eq '^' ) {
        print STDERR
            "Anchors don't work well with respond, perhaps you want to use 'hear'\n";
        print STDERR "The regex in question was $stringRegex\n";
    }

    my $newRegex;
    my $name = $self->name;
    if ( $self->alias ) {
        my $alias = $self->alias;
        $alias =~ s/[-[\]{}()\*+?.,\\^$|#\s]/\\$&/g;  # escape alias for regexp

        ## TODO: fix to generate correct regex
        ## qr/regex/$var 처럼 modifier 에 변수가 들어갈 수 없음
        ## 일단 modifiers 가 있다면 `i` 라고 가정하고 들어감 WTH..
        if ($modifiers) {
            $newRegex = qr/^(?:$alias[:,]?|$name[:,]?)\s*(?:$stringRegex)/i;
        }
        else {
            $newRegex = qr/^(?:$alias[:,]?|$name[:,]?)\s*(?:$stringRegex)/;
        }
    }
    else {
        if ($modifiers) {
            $newRegex = qr/^(?:$name[:,]?)\s*(?:$stringRegex)/i;
        }
        else {
            $newRegex = qr/^(?:$name[:,]?)\s*(?:$stringRegex)/;
        }
    }

    print "$newRegex\n" if $ENV{DEBUG};
    $self->addListener(
        new Hubot::TextListener(
            robot    => $self,
            regex    => $newRegex,
            callback => $callback
        )
    );
}

sub enter {
    my ( $self, $callback ) = @_;
    $self->addListener(
        Hubot::Listener->new(
            robot    => $self,
            matcher  => sub { ref(shift) eq 'Hubot::EnterMessage' ? 1 : () },
            callback => $callback
        )
    );
}

sub leave {
    my ( $self, $callback ) = @_;
    $self->addListener(
        Hubot::Listener->new(
            robot    => $self,
            matcher  => sub { ref(shift) eq 'Hubot::LeaveMessage' ? 1 : () },
            callback => $callback
        )
    );
}

sub whisper {
    my ( $self, $callback ) = @_;
    $self->addListener(
        Hubot::Listener->new(
            robot    => $self,
            matcher  => sub { ref(shift) eq 'Hubot::WhisperMessage' ? 1 : () },
            callback => $callback
        )
    );
}

sub notice {
    my ( $self, $callback ) = @_;
    $self->addListener(
        Hubot::Listener->new(
            robot    => $self,
            matcher  => sub { ref(shift) eq 'Hubot::NoticeMessage' ? 1 : () },
            callback => $callback
        )
    );
}

sub catchAll {
    my ( $self, $callback ) = @_;
    $self->addListener(
        Hubot::Listener->new(
            robot   => $self,
            matcher => sub { ref(shift) eq 'Hubot::CatchAllMessage' ? 1 : () },
            callback => sub {
                my $msg = shift;
                $msg->message( $msg->message->message );
                $callback->($msg);
            }
        )
    );
}

sub receive {
    my ( $self, $message ) = @_;
    my $results = [];
    for my $listener ( $self->listeners ) {
        eval $listener->call($message);
        last if $message->done;
        if ($@) {
            print STDERR "Unable to call the listener: $@\n";
            return 0;
        }
    }

    $self->receive( new Hubot::CatchAllMessage( message => $message ) )
        if ref($message) ne 'Hubot::CatchAllMessage';
}

sub http { AnyEvent::HTTP::ScopedClient->new( $_[1] ) }

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Robot

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    # Hubot::Robot has a CLI. named `hubot`
    $ perldoc hubot

    # make sure `hubot-scripts.json` is exist in current working directory
    use JSON::XS;
    use Cwd 'cwd';
    use Hubot::Robot;
    my $robot = Hubot::Robot->new({
        adapter => 'shell',
        name    => 'hubot'
    });

    $robot->adapter->on(
        'connected',
        sub {
            my $cwd = cwd();
            my $scriptsFile = "$cwd/hubot-scripts.json";
            if (-f $scriptsFile) {
                my $json = read_file($scriptsFile);
                my $scripts = decode_json($json);
                $robot->loadHubotScripts($scripts);
            }
        }
    );

    $robot->run;

=head1 DESCRIPTION

A customizable, kegerator-powered life embetterment robot.

The original hubot description is..

"This is a version of GitHub's Campfire bot, hubot. He's pretty cool."

this is hubot B<Perl> port.

=head1 SEE ALSO

=over

=item L<http://hubot.github.com/>

=item L<https://github.com/github/hubot>

=item L<hubot>

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
