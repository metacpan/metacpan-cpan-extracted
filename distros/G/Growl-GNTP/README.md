# NAME

Growl::GNTP - Perl implementation of GNTP Protocol (Client Part)

# SYNOPSIS

    use Growl::GNTP;
    my $growl = Growl::GNTP->new(AppName => "my perl app");
    $growl->register([
        { Name => "foo", },
        { Name => "bar", },
    ]);
    
    $growl->notify(
        Name => "foo",
        Title => "my notify",
        Message => "my message",
        Icon => "http://www.example.com/my-face.png",
    );

# DESCRIPTION

Growl::GNTP is Perl implementation of GNTP Protocol (Client Part)

# CONSTRUCTOR

- new ( ARGS )

    Initialize Growl::GNTP object. You can set few parameter of
    IO::Socket::INET. and application name will be given 'Growl::GNTP' if you
    does not specify it.

    >         PeerHost                # 'localhost'
    >         PeerPort                # 23053
    >         Timeout                 # 5
    >         AppName                 # 'Growl::GNTP'
    >         AppIcon                 # ''
    >         Password                # ''
    >         PasswordHashAlgorithm   # 'MD5'
    >         EncryptAlgorithm        # ''

# OBJECT METHODS

- register ( \[ARGS\] )

    Register notification definition. You should be specify ARRAY reference of
    HASH reference like a following.

        {
            Name        => 'MY_GROWL_NOTIFY',
            DisplayName => 'My Growl Notify',
            Enabled     => 'True',
            Icon        => ''
        }

- notify ( ARGS )

    Notify item. You should be specify HASH reference like a following.

        {
            Name                => 'Warn', # name of notification
            Title               => 'Foo!',
            Message             => 'Bar!',
            Icon                => 'http://www.example.com/myface.png',
            CallbackTarget      => '', # Used for causing a HTTP/1.1 GET request exactly as specificed by this URL. Exclusive of CallbackContext
            CallbackContextType => time, # type of the context
            CallbackContext     => 'Time',
            CallbackFunction    => sub { warn 'callback!' }, # should only be used when a callback in use, and CallbackContext in use.
            ID                  => '', # allows for overriding/updateing an existing notification when in use, and discriminating between alerts of the same Name
            Custom              => { CustomHeader => 'value' }, # These will be added as custom headers as X-KEY : value, where 'X-' is prefixed to the key
            Priority            => 0,  # -2 .. 2 low -> severe
            Sticky              => 'False'
        }

    And callback function is given few arguments.

        CallbackFunction => sub {
            my ($result, $type, $context, $id, $timestamp) = @_;
            print "$result: $context ($type)\n";
        }

- wait ( WAIT\_ALL )

    Wait callback items. If WAIT\_ALL is not 0, this function wait all callbacks
    as CLICK, CLOSED, TIMEOUT.

- subscribe ( ARGS )

    Subscribe notification. You should be specify HASH reference like a following.

        {
            Port => 23054,
            Password => 'secret',
            CallbackFunction => sub {
                my ($Title, $Message) = @_;
                print decode_utf8($Title),",",decode_utf8($Message),"\n";
            },
        }

# AUTHOR

Yasuhiro Matsumoto <mattn.jp@gmail.com>

# SEE ALSO

[Net::Growl](https://metacpan.org/pod/Net::Growl), [Net::GrowlClient](https://metacpan.org/pod/Net::GrowlClient), [Mac::Growl](https://metacpan.org/pod/Mac::Growl),
`http://www.growlforwindows.com/gfw/help/gntp.aspx`

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
