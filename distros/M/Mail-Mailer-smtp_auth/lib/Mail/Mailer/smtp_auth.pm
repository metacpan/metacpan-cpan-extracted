package Mail::Mailer::smtp_auth;

use warnings;
use strict;
use vars qw(@ISA $VERSION);
use Net::SMTP_auth;
use Mail::Util qw(mailaddress);
use Carp;

$VERSION = '0.02';

require Mail::Mailer::rfc822;
@ISA = qw(Mail::Mailer::rfc822);

sub can_cc { 0 }

sub exec {
    my($self, $exe, $args, $to) = @_;
    my %opt   = @$args;
    my $host  = $opt{Server} || undef;
    $opt{Debug} ||= 0;

    # for Net::SMTP_auth we do not really exec
    my $smtp = Net::SMTP_auth->new($host, %opt)
	or return undef;

    if ($opt{Auth}) {
       $smtp->auth(@{$opt{Auth}})
           or return undef;
    }

    ${*$self}{'sock'} = $smtp;

    $smtp->mail(mailaddress());
    my $u;
    foreach $u (@$to) {
	$smtp->to($u);
    }
    $smtp->data;
    untie(*$self) if tied *$self;
    tie *$self, 'Mail::Mailer::smtp_auth::pipe',$self;
    $self;
}

sub set_headers {
    my($self,$hdrs) = @_;
    $self->SUPER::set_headers({
	From => "<" . mailaddress() . ">",
	%$hdrs,
	'X-Mailer' => "Mail::Mailer[v$Mail::Mailer::VERSION] Net::SMTP_auth[v$Net::SMTP_auth::VERSION]"
    })
}

sub epilogue {
    my $self = shift;
    my $sock = ${*$self}{'sock'};
    $sock->dataend;
    $sock->quit;
    delete ${*$self}{'sock'};
    untie(*$self);
}

sub close {
    my($self, @to) = @_;
    my $sock = ${*$self}{'sock'};
    if ($sock && fileno($sock)) {
        $self->epilogue;
        # Epilogue should destroy the SMTP filehandle,
        # but just to be on the safe side.
        if ($sock && fileno($sock)) {
            close $sock
                or croak 'Cannot destroy socket filehandle';
        }
    }
    1;
}

package Mail::Mailer::smtp_auth::pipe;

sub TIEHANDLE {
    my $pkg = shift;
    my $self = shift;
    my $sock = ${*$self}{'sock'};
    return bless \$sock;
}

sub PRINT {
    my $self = shift;
    my $sock = $$self;
    $sock->datasend( @_ );
}

__END__

=head1 NAME

Mail::Mailer::smtp_auth - a Net::SMTP_auth wrapper for Mail::Mailer

=head1 SYNOPSIS

    use Mail::Mailer;
    
    $mailer = new Mail::Mailer 'smtp_auth' , (
        Server => $server ,
        Auth   => [ $auth_type, $user, $pass ]
    );

    $mailer->open(\%headers);

    print $mailer $body;

    $mailer->close;

=head1 DESCRIPTION

The code is almost a copy of Mail::Mailer::smtp but use Net::SMTP_auth instead Net::SMTP.

for more details, please perldoc Mail::Mailer and perldoc Net::SMTP_auth

=head1 EXPLAINATION

As C<$auth_type> you can specify any of: 'PLAIN', 'LOGIN', 'CRAM-MD5' etc.

=head1 SEE ALSO

L<Mail::Mailer>, L<Net::SMTP_auth>

=head1 AUTHOR

Fayland, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006, 2008 Fayland, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Mail::Mailer::smtp_auth
