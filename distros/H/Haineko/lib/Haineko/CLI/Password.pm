package Haineko::CLI::Password;
use parent 'Haineko::CLI';
use strict;
use warnings;
use Try::Tiny;

sub options {
    return {
        'exec' => ( 1 << 0 ),
        'stdin'=> ( 1 << 1 ),
    };
}

sub make {
    my $self = shift;
    my $o = __PACKAGE__->options;

    return undef unless( $self->r & $o->{'exec'} );
    my $password01 = undef;
    my $password02 = undef;
    my $filehandle = undef;

    try {
        require Crypt::SaltedHash;
    } catch {
        $self->e( 'Cannot load "Crypt::SaltedHash"' );
    };

    if( $self->r & $o->{'stdin'} ) {
        # Read a password from STDIN
        require IO::Handle;
        $filehandle = IO::Handle->new;
        $self->e( 'Cannot open STDIN' ) unless $filehandle->fdopen( fileno(STDIN), 'r' );

        system('stty -echo');
        while(1) {
            # Password(1)
            printf( STDERR 'New password: ' );
            while( my $p = $filehandle->gets ) {
                $password01 = $p;
                last if length $password01;
            }
            printf( STDERR "\n" );
            chomp $password01;
            last if $self->validate( $password01 );
        }

        while(1) {
            # Password(2)
            printf( STDERR 'Re-type new password: ' );
            while( my $p = $filehandle->gets ) {
                $password02 = $p;
                last if length $password02;
            }
            printf( STDERR "\n" );
            chomp $password02;
            last if $password01 eq $password02;
            $self->e( 'Passwords dit not match', 1 );
        }
        system('stty echo');

    } else {
        # Password string is in the argument of -p option
        $password01 = $self->{'params'}->{'password'};
        $self->validate( $password01 );
    }

    my $methodargv = undef;
    my $saltedhash = undef;
    my $passwdhash = undef;
    my $credential = undef;

    $methodargv = { 'algorithm' => $self->{'params'}->{'algorithm'} };
    $saltedhash = Crypt::SaltedHash->new( %$methodargv );
    $saltedhash->add( $password01 );
    $passwdhash = $saltedhash->generate;

    if( length $self->{'params'}->{'username'} ) {
        $credential = sprintf( "%s: '%s'", $self->{'params'}->{'username'}, $passwdhash );
    } else {
        $credential = $passwdhash;
    }
    return $credential;
}

sub validate {
    my $self = shift;
    my $argv = shift;

    if( not length $argv ) {
        $self->e( 'Empty password is not permitted', 1 );
    } elsif( length $argv < 8 ) {
        $self->e( 'Password is too short < 8', 1 );
    } else {
        return 1;
    }

    return 0;
}

sub parseoptions {
    my $self = shift;
    my $opts = __PACKAGE__->options;

    my $r = 0;      # Run mode value
    my $p = {};     # Parsed options

    use Getopt::Long qw/:config posix_default no_ignore_case bundling auto_help/;
    Getopt::Long::GetOptions( $p,
        'algorithm|a=s',# Algorithm
        'help',         # --help
        'password|p=s', # Password string
        'user|u=s',     # Username
        'verbose|v+',   # Verbose
    );

    if( $p->{'help'} ) {
        # --help
        require Haineko::CLI::Help;
        my $o = Haineko::CLI::Help->new( 'command' => [ caller ]->[1] );
        $o->add( __PACKAGE__->help('s'), 'subcommand' );
        $o->add( __PACKAGE__->help('o'), 'option' );
        $o->add( __PACKAGE__->help('e'), 'example' );
        $o->mesg;
        exit(0);
    }

    if( defined $p->{'password'} ) {
        # Password string
        $self->{'params'}->{'password'} = $p->{'password'};

    } else {
        # Read a password from STDIN
        $r |= $opts->{'stdin'};
    }
    $self->{'params'}->{'username'} = $p->{'user'} // q();
    $self->{'params'}->{'algorithm'} = $p->{'algorithm'} // 'SHA-1';

    $self->v( $p->{'verbose'} );
    $r |= $opts->{'exec'};
    $self->r( $r );
    return $r;
}

sub help {
    my $class = shift;
    my $argvs = shift || q();

    my $commoption = [ 
        '-a, --algorithm <name>'    => 'Algorithm, if it omitted "SHA-1" will be used.',
        '-p, --password <str>'      => 'Password string',
        '-u, --user <name>'         => 'Username for Basic-Authentication',
        '-v, --verbose'             => 'Verbose mode.',
        '--help'                    => 'This screen',
    ];
    my $subcommand = [ 'pw' => 'Generate a new password for Basic-Authentication' ];
    my $forexample = [
        'hainekoctl pw',
        'hainekoctl pw -u username -p newpassword',
    ];

    return $commoption if $argvs eq 'o' || $argvs eq 'option';
    return $subcommand if $argvs eq 's' || $argvs eq 'subcommand';
    return $forexample if $argvs eq 'e' || $argvs eq 'example';
    return undef;
}

1;
__END__
=encoding utf8

=head1 NAME

Haineko::CLI::Password - Utility class for C<hainekoctl pw>

=head1 DESCRIPTION

Haineko::CLI::Password provide methods for generating a password used in Basic
Authentication like C<htpasswd> command of Apache.

=head1 SYNOPSIS

    use Haineko::CLI::Password;
    my $p = Haineko::CLI::Password->new();
    my $v = '';

    $p->parseoptions;   # Parse command-line options
    $v = $d->make;      # Generate password
    print $v;           # Print the password

=head1 INSTANCE METHODS

=head2 C<B<make()>>

C<make()> method update the contents of Haineko/CLI/Setup/Data.pm for setting up
files of Haineko. This method will be used by Haineko author only.

    my $p = Haineko::CLI::Password->new();
    $p->parseoptions;
    print $p->make;

=head2 C<B<validate()>>

C<validate()> is a validator of input password.

=head2 B<parseoptions()>

C<parseoptions()> method parse options given at command line and returns the 
value of run-mode.

=head2 C<B<help()>>

C<help()> prints help message of Haineko::CLI::Password for command line.

=head1 SEE ALSO

=over 2

=item *
L<Haineko::CLI> - Base class of Haineko::CLI::Password

=item *
L<bin/haineoctl> - Script of Haineko::CLI::* implementation

=back

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
