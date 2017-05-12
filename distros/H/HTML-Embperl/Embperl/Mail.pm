###################################################################################
#
#   Embperl - Copyright (c) 1997-2000 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Mail.pm,v 1.33 2001/08/15 03:28:35 richter Exp $
#
###################################################################################


package HTML::Embperl::Mail ;


require HTML::Embperl ;

use Apache::Constants qw(&OPT_EXECCGI &DECLINED &OK &FORBIDDEN &NOT_FOUND) ;


use strict ;
use vars qw(
    @ISA
    $VERSION
    ) ;


@ISA = qw(HTML::Embperl);


$VERSION = '1.3.4';



sub Execute

    {
    my ($req) = @_ ;

    my $data ;
    my @errors ;

    $req -> {options} ||= &HTML::Embperl::optDisableHtmlScan | &HTML::Embperl::optRawInput | 
                          &HTML::Embperl::optKeepSpaces      | &HTML::Embperl::optReturnError;
    
    $req -> {escmode} ||= 0 ;
    $req -> {output}   = \$data ;
    $req -> {errors} ||= \@errors ;

    HTML::Embperl::Execute ($req) ;

    die "@errors" if (@errors) ;

    eval
        {
        require Net::SMTP ;
        
        $req -> {mailhost} ||= $ENV{'EMBPERL_MAILHOST'} || 'localhost' ;

        my $helo = $req -> {mailhelo} || $ENV{'EMBPERL_MAILHELO'} ;

        my $smtp = Net::SMTP->new($req -> {mailhost},
                                  Debug => ($req -> {maildebug} || $ENV{'EMBPERL_MAILDEBUG'} || 0),
                                  ($helo?(Hello => $helo):()) 
                                  ) or die "Cannot connect to mailhost $req->{mailhost}" ;

        my $from =  $req -> {from} || $ENV{'EMBPERL_MAILFROM'} ;
        $smtp->mail($from || "WWW-Server\@$ENV{SERVER_NAME}");

        my $to ;
        if (ref ($req -> {'to'}))
            {
            $to = $req -> {'to'} ;
            }
        else
            {
            $to = [] ;
            @$to = split (/\s*;\s*/, $req -> {'to'}) ;
            }

        my $cc ;
        if (ref ($req -> {'cc'}))
            {
            $cc = $req -> {'cc'} ;
            }
        else
            {
            $cc = [] ;
            @$cc = split (/\s*;\s*/, $req -> {'cc'}) ;
            }

        my $bcc ;
        if (ref ($req -> {'bcc'}))
            {
            $bcc = $req -> {'bcc'} ;
            }
        else
            {
            $bcc = [] ;
            @$bcc = split (/\s*;\s*/, $req -> {'bcc'}) ;
            }

        my $headers = $req->{mailheaders} ;        
        $smtp -> to (@$to, @$cc, @$bcc) ;

        $smtp->data() or die "smtp data failed" ;
        $smtp->datasend("Reply-To: $req->{'reply-to'}\n") or die "smtp data failed"  if ($req->{'reply-to'}) ;
        $smtp->datasend("From: $from\n") if ($from) ;
        $smtp->datasend("To: " . join (', ', @$to) . "\n")  or die "smtp datasend failed" ;
        $smtp->datasend("Cc: " . join (', ', @$cc) . "\n")  or die "smtp datasend failed" if ($req -> {'cc'}) ;
        $smtp->datasend("Subject: $req->{subject}\n") or die "smtp datasend failed" ;
        if (ref ($headers) eq 'ARRAY')
            {
            foreach (@$headers)
                {
                $smtp->datasend("$_\n") or die "smtp datasend failed" ;
                }
            }
        $smtp->datasend("\n")  or die "smtp datasend failed" ;
	# make sure we have only \n line endings (is made to \r\n by Net::SMTP)
        $data =~ s/\r//g ;
	$smtp->datasend($data)  or die "smtp datasend failed" ;
        $smtp->quit or die "smtp quit failed" ; 
        } ;

    if ($@)
        {
        die "$@" if (ref ($req -> {errors}) eq \@errors) ;

        push @{$req -> {errors}}, $@ ;
        }

    return ref ($req -> {errors})?@{$req -> {errors}}:0 ;
    }    


__END__

=head1 NAME

HTML::Embperl::Mail - Sends results from Embperl via E-Mail


=head1 SYNOPSIS


 use HTML::Embperl::Mail ;
    
 HTML::Embperl::Mail::Execute ({inputfile => 'template.epl',
                                subject   => 'Test HTML::Embperl::Mail::Execute',
                                to        => 'email@foo.org'}) ;


=head1 DESCRIPTION

I<HTML::Embperl::Mail> uses I<HTML::Embperl> to process a page template and send
the result out via EMail. Currently only plain text mails are supported. A later 
version may add support for HTML mails. Because of that fact, normal I<Embperl>
HTML processing is disabled per Default (see L<options> below).

=head2 Execute

The C<Execute> function can handle all the parameter that C<HTML::Embperl::Execute>
does. Addtionaly the following parameters are recognized:

=over 4

=item from

gives the sender e-mail address

=item to

gives the recipient address(es). Multiply addresses can either be separated by semikolon
or given as an array ref.

=item cc

gives the recipient address(es) which should receive a carbon copy. Multiply addresses can
either be separated by semikolon
or given as an array ref.

=item bcc

gives the recipient address(es) which should receive a blind carbon copy. Multiply addresses can
either be separated by semikolon
or given as an array ref.

=item subject

gives the subject line

=item reply-to

the given address is insert as reply address

=item mailheaders

Array ref of additional mail headers

=item mailhost

Specifies which host to use as SMTP server.
Default is B<localhost>.

=item mailhelo

Specifies which host/domain to use in the HELO/EHLO command.
A reasonable default is normaly choosen by I<Net::SMTP>, but
depending on your installation it may neccessary to set it
manualy.

=item maildebug

Set to 1 to enable debugging of mail transfer.

=item options

If no C<options> are given the following are used per default: 
B<optDisableHtmlScan>, B<optRawInput>, B<optKeepSpaces>, B<optReturnError>

=item escmode

In contrast to normal I<Embperl> escmode defaults to zero (no escape)

=item errors

As in C<HTML::Embperl::Execute> you can specify an array ref, which returns
all the error messages from template processing. If you don't specify 
this parameter C<Execute> will die when an error occurs.

=back

=head2 Configuration

Some default values could be setup via environement variables


=head2 EMBPERL_MAILHOST

Specifies which host to use as SMTP server.
Default is B<localhost>.

=head2 EMBPERL_MAILHELO

Specifies which host/domain to use in the HELO/EHLO command.
A reasonable default is normaly choosen by I<Net::SMTP>, but
depending on your installation it may neccessary to set it
manualy.

=head2 EMBPERL_MAILFROM 

Specifies which the email address that is used as sender.
Default is B<www-server@server_name>.

=head2 EMBPERL_MAILDEBUG 

Debug setting for Net::SMTP. Default is 0.

=head1 Author

G. Richter (richter@dev.ecos.de)

=head1 See Also

perl(1), HTML::Embperl, Net::SMTP
