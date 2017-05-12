package Haineko::SMTPD::Address;
use feature ':5.10';
use strict;
use warnings;
use Class::Accessor::Lite;

my $rwaccessors = [];
my $roaccessors = [
    'address',  # (String) Email address
    'user',     # (String) local part of the email address
    'host',     # (String) domain part of the email address
];
my $woaccessors = [];
Class::Accessor::Lite->mk_accessors( @$roaccessors );


sub new {
    my $class = shift;
    my $argvs = { @_ }; 

    return undef unless defined $argvs->{'address'};

    if( $argvs->{'address'} =~ m{\A(?<localpart>[^@]+)[@](?<domainpart>[^@]+)\z} ) {

        $argvs->{'user'} = lc $+{'localpart'};
        $argvs->{'host'} = lc $+{'domainpart'};

        map { $argvs->{ $_ } =~ y{`'"<>}{}d } keys %$argvs;
        $argvs->{'address'} = sprintf( "%s@%s", $argvs->{'user'}, $argvs->{'host'} );

        return bless $argvs, __PACKAGE__

    } else {
        return undef;
    }
}

sub canonify {
    my $class = shift;
    my $email = shift;

    return q() unless defined $email;
    return q() if ref $email;

    # "=?ISO-2022-JP?B?....?="<user@example.jp>
    # no space character between " and < .
    $email =~ s/(?<C>.)"</$+{'C'}" </;

    my $canonified = q();
    my $addressset = [];
    my $emailtoken = [ split ' ', $email ];

    for my $e ( @$emailtoken ) {
        # Convert character entity; "&lt;" -> ">", "&gt;" -> "<".
        $e =~ s/&lt;/</g;
        $e =~ s/&gt;/>/g;
        $e =~ s/,\z//g;
    }

    if( scalar( @$emailtoken ) == 1 ) {
        # kijitora@example.jp
        push @$addressset, $emailtoken->[0];

    } else {
        foreach my $e ( @$emailtoken ) {
            # Kijitora cat <kijitora@example.jp>
            chomp $e;
            next unless $e =~ m{\A[<]?.+[@][-.0-9A-Za-z]+[.][A-Za-z]{2,}[>]?\z};
            push @$addressset, $e;
        }
    }

    if( scalar( @$addressset ) > 1 ) {
        # Get an <email address> from string
        $canonified = [ grep { $_ =~ m{\A[<].+[>]\z} } @$addressset ]->[0];
        $canonified = $addressset->[0] unless $canonified;

    } else {
        # kijitora@example.jp
        $canonified = shift @$addressset;
    }

    return q() unless defined $canonified;
    return q() unless $canonified;

    $canonified =~ y{<>[]():;}{}d;  # Remove brackets, colons
    $canonified =~ y/{}'"`//d;      # Remove brackets, quotations
    return $canonified;
}

sub damn {
    my $self = shift;
    my $addr = { 
        'user' => $self->user,
        'host' => $self->host,
        'address' => $self->address,
    };
    return $addr;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Addreess - Create an email address object

=head1 DESCRIPTION

Create an simple object containing a local-part, a domain-part, and an email
address.

=head1 SYNOPSIS

    use Haineko::SMTPD::Address;
    my $e = Haineko::Address->new( 'address' => 'kijitora@example.jp' );

    print $e->user;     # kijitora
    print $e->host;     # example.jp
    print $e->address;  # kijitora@example.jp

    print Data::Dumper::Dumper $e->damn;
    $VAR1 = {
          'user' => 'kijitora',
          'host' => 'example.jp',
          'address' => 'kijitora@example.jp'
        };

=head1 CLASS METHODS

=head2 C<B<new( 'address' => I<email-address> )>>

C<new()> is a constructor of Haineko::SMTPD::Address

    my $e = Haineko::SMTPD::Address->new( 'address' => 'kijitora@example.jp' );

=head2 C<B<canonify>( I<email-address> )>

C<canonify()> picks an email address only (remove a name and comments)

    my $e = HainekoSMTPD::::Address->canonify( 'Kijitora <kijitora@example.jp>' );
    my $f = HainekoSMTPD::::Address->canonify( '<kijitora@example.jp>' );
    print $e;   # kijitora@example.jp
    print $f;   # kijitora@example.jp

=head1 INSTANCE METHODS

=head2 C<B<damn>>

C<damn()> returns instance data as a hash reference

    my $e = Haineko::SMTPD::Address->new( 'address' => 'kijitora@example.jp' );
    my $f = $e->damn;

    print Data::Dumper::Dumper $f;
    $VAR1 = {
        'user' => 'kijitora',
        'host' => 'example.jp',
        'address' => 'kijitora@example.jp'
    };

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
