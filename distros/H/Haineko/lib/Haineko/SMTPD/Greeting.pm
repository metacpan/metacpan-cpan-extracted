package Haineko::SMTPD::Greeting;
use strict;
use warnings;
use Class::Accessor::Lite;

my $rwaccessors = [
    'dsn',          # (Integer) Support DSN or not
    'size',         # (Integer) Max message size
    'auth',         # (Integer) Support SMTP-AUTH
    'mechanism',    # (ArrayRef) SMTP-AUTH Mechanisms
    'feature',      # (ArrayRef) Greeting message lines
    'greeting',     # (String) The first line of EHLO response
    'starttls',     # (Integer) STARTTLS suppored or not
    'pipelining'    # (Integer) PIPELINING supported or not
];
my $roaccessors = [];
my $woaccessors = [];
Class::Accessor::Lite->mk_accessors( @$rwaccessors );

sub new {
    my $class = shift;
    my $greet = [ @_ ];
    my $feats = {
        'dsn'        => undef,
        'size'       => undef,
        'auth'       => undef,
        'feature'    => [],
        'starttls'   => undef,
        'greeting'   => q(),
        'mechanism'  => [],
        'pipelining' => undef,
    };

    $feats->{'greeting'} = shift @$greet;
    chomp $feats->{'greeting'};

    for my $e ( @$greet ) {
        chomp $e;

        if( $e =~ /SIZE (?<SIZE>\d+)/ ) {
            # 250-SIZE 26214400
            $feats->{'size'} = int $+{'SIZE'};

        } elsif( $e =~ /AUTH (?<MECHS>.+)\z/ ) {
            # 250-AUTH LOGIN PLAIN CRAM-MD5
            $feats->{'auth'} = 1;
            $feats->{'mechanism'} = [ split( ' ', $+{'MECHS'} ) ];

        } elsif( $e =~ /PIPELINING/ ) {
            # 250-PIPELINING
            $feats->{'pipelining'} = 1;

        } elsif( $e =~ /STARTTLS/ ) {
            # 250-STARTTLS
            $feats->{'starttls'} = 1;

        } elsif( $e =~ /DSN/ ) {
            # 250-DSN
            $feats->{'dsn'} = 1;
        }

        push @{ $feats->{'feature'} }, $e;
    }

    return bless $feats, __PACKAGE__;
}

sub mechs {
    my $self = shift;
    my $mech = shift || return 0;

    return 1 if grep { uc $mech eq $_ } @{ $self->{'mechanism'} };
    return 0;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Greeting - Create an EHLO response object

=head1 SYNOPSIS

    use Haineko::SMTPD::Greeting;
    my $r = [ 
        '250-PIPELINING', '250-DSN', '250-STARTTLS', '250-SIZE 26214400',
        '250-AUTH PLAIN CRAM-MD5', '250-8BITMIME', ...
    ];
    my $g = Haineko::SMTPD::Greeting->new( @$r );

    print $e->dsn;      # 1
    print $e->auth;     # 1
    print $e->starttls; # 1
    print $e->size;     # 26214400


=head1 CLASS METHODS

=head2 C<B<new( I<@{EHLO Response lines}> )>>

C<new()> is a constructor of Haineko::SMTPD::Greeting

    my $r = [ 
        '250-PIPELINING', '250-DSN', '250-STARTTLS', '250-SIZE 26214400',
        '250-AUTH PLAIN CRAM-MD5', '250-8BITMIME', ...
    ];
    my $g = Haineko::SMTPD::Greeting->new( @$r );

=head1 INSTANCE METHODS

=head2 C<B<mechs( I<SMTP-AUTH MECHANISM>) >>

C<mechs()> returns whether specified SMTP-AUTH mechanism is available or not.

    print $g->mechs( 'CRAM-MD5' );      # 1
    print $g->mechs( 'LOGIN' );         # 0
    print $g->mechs( 'DIGETST-MD5' );   # 0

=head1 REPOSITORY

Https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
