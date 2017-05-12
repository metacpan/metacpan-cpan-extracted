# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::SendMail;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);

our $VERSION = 0.995;

use Maplat::Helpers::DateStrings;
use Mail::Sendmail;
use MIME::QuotedPrint;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{webpath}, "get");
    return;
}

sub get {
    my ($self, $cgi) = @_;
    
    my $th = $self->{server}->{modules}->{templates};
    
    my @recievers = $cgi->param("reciever[]");
    my $subject = $cgi->param("subject") || "";
    my $mailtext = $cgi->param("mailtext") || "";
    my $mustupdate = $cgi->param("submitform") || "0";
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pagetitle},
        webpath        =>  $self->{admin}->{webpath},
        subject     =>  $th->quote($subject),
        mailtext   =>  $th->quote($mailtext),
    );
    
    if($webdata{userData}->{type} ne "admin") {
        return (status  =>  404);
    }
    
    if($mustupdate) {
        my $ok = 1;
        my $statustext = "";
        foreach my $reciever (@recievers) {
            my ($tmpok, $tmpstatustext) = $self->sendMail($reciever, $subject, $mailtext, "text/plain");
            if(!$tmpok) {
                $ok = 0;
                $statustext .= $tmpstatustext . "<br>";
            }
        }
        if($ok) {
            $statustext = "All send!";
        }
        $webdata{statustext} = $statustext;
        if($ok) {
            $webdata{statuscolor} = "oktext";
        } else {
            $webdata{statuscolor} = "errortext";
        }
    }
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $sth = $dbh->prepare_cached("SELECT username, email_addr
                                      FROM users
                                      ORDER BY username")
                or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);
    my @users;
    while((my $user = $sth->fetchrow_hashref)) {
        if (grep {$_ eq $user->{email_addr}} @recievers) {
            $user->{checked} = 1;
        }

        push @users, $user;
    }
    $webdata{users} = \@users;
    
    
    my $template = $th->get("sendmail", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


sub sendMail {
    my ($self, $reciever, $subject, $message, $contenttype) = @_;
    
        my %mail = (
                To              => $reciever,
                From            => $self->{sender},
                Subject         => $self->{subject_prefix} . " " . $subject,
                Message         => $message,
                Server          => $self->{mailserver},
                Port            => $self->{mailport},
                'X-Mailer'      => $self->{mailer_id},
                'content-type'  => $contenttype,      
                );
    
    if(defined($self->{Cc})) {
        $mail{Cc} = $self->{Cc};
    }
    if(defined($self->{Bcc})) {
        $mail{Bcc} = $self->{Bcc};
    }
    
    if(!sendmail(%mail)) {
        return (0, "Can't send status mail: " . $Mail::Sendmail::error); ## no critic (Variables::ProhibitPackageVars)
    } else {
        return (1, "Status mail sent");
    }
}

1;
__END__

=head1 NAME

Maplat::Web::SendMail - send mails to Maplat users

=head1 SYNOPSIS

This modules provides a web interface to send mails to all maplat users

=head1 DESCRIPTION

With this module, you can provide a simple webinterface to admin users to
send mails to some or all maplat users.

=head1 Configuration

        <module>
                <modname>sendmail</modname>
                <pm>SendMail</pm>
                <options>
                        <pagetitle>Sendmail</pagetitle>
                        <webpath>/admin/sendmail</webpath>
                        <mailserver>mail</mailserver>
                        <mailport>25</mailport>
                        <mailer_id>Maplat Notification System</mailer_id>
                        <sender>noreply@gmail.com</sender>
                        <!--<Cc>rene.schickbauer@gmail.com</Cc>-->
                        <subject_prefix>[Maplat]</subject_prefix>
                        <db>maindb</db>
                </options>
        </module>

=head2 get

The Sendmail form.

=head2 sendMail

Internal function.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::PostgresDB as "db"

=head1 SEE ALSO

Maplat::Web
Maplat::Web::PostgresDB

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
