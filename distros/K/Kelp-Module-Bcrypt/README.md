# TITLE

Kelp::Module::Bcrypt - Bcrypt your passwords

# SYNOPSIS

```perl
# conf/config.pl
{
    modules_init => {
        Bcrypt => {
            cost => 6,
            salt => 'secret salt passphrase'
        }
    };
};

# lib/MyApp.pm
...

  sub some_soute {
    my $self             = shift;
    my $crypted_password = $self->bcrypt($plain_password);
}

sub another_route {    # Maybe a bridge?
    my $self = shift;
    if ( $self->bcrypt($plain_password) eq $crypted_passwrod ) {
        ...;
    }
}
```

# TITLE

This module adds bcrypt to your Kelp app

# REGISTERED METHODS

## bcrypt( $text )

Returns the bcrypted `$text`.

# AUTHOR

Stefan G - mimimal <at< cpan.org

# SEE ALSO

[Kelp](https://metacpan.org/pod/Kelp), [Crypt::Eksblowfish::Bcrypt](https://metacpan.org/pod/Crypt::Eksblowfish::Bcrypt)

# LICENSE

Perl
