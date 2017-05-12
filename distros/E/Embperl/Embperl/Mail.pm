###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Mail.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Mail ;


require Embperl ;
require Embperl::Constant ;


use strict ;
use vars qw(
    @ISA
    $VERSION
    ) ;


@ISA = qw(Embperl);


$VERSION = '2.1.0';


sub _quote_hdr
    {
    my $chunk    = shift;
    my $encoding = shift ;

    return $chunk unless ($encoding && ($chunk =~ /[\x80-\xff]/)) ;

    $chunk =~ s{
		([^0-9A-Za-z])
	       }{
		   join("" => map {sprintf "=%02X", $_} unpack("C*", $1))
	       }egox;
    return "=?$encoding?Q?$chunk?=";
    }





sub Execute

    {
    my ($req) = @_ ;

    my $data ;
    my @errors ;

    $req -> {options} ||= &Embperl::Constant::optKeepSpaces      | &Embperl::Constant::optReturnError;
    
    $req -> {syntax}  ||= 'EmbperlBlocks' ; 
    $req -> {escmode} ||= 0 ;
    $req -> {output}   = \$data ;
    $req -> {errors} ||= \@errors ;

    if ($Embperl::req)
        {
        $Embperl::req -> execute_component ($req) ;
        }
    else
        {
        Embperl::Execute ($req) ;
        }

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

        my $from =  $req -> {from} || $ENV{'EMBPERL_MAILFROM'} || 'WWW-Server\@' . ($ENV{SERVER_NAME} || 'localhost') ;
        $smtp->mail($from);

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
            @$cc = split (/\s*;\s*/, $req -> {'cc'}) if ($req -> {'cc'}) ;
            }

        my $bcc ;
        if (ref ($req -> {'bcc'}))
            {
            $bcc = $req -> {'bcc'} ;
            }
        else
            {
            $bcc = [] ;
            @$bcc = split (/\s*;\s*/, $req -> {'bcc'}) if ($req -> {'bcc'}) ;
            }

        my $enc     = $req->{headerencoding} || 'iso-8859-1';
        my $headers = $req->{mailheaders} ;        
        $smtp -> to (@$to, @$cc, @$bcc) ;

        $smtp->data() or die "smtp data failed" ;
        $smtp->datasend("Reply-To: " . _quote_hdr($req->{'reply-to'}, $enc) . "\n") or die "smtp data failed"  if ($req->{'reply-to'}) ;
        $smtp->datasend("From: " . _quote_hdr($from, $enc) . "\n") if ($from) ;
        $smtp->datasend("To: " . _quote_hdr(join (', ', @$to), $enc) . "\n")  or die "smtp datasend failed" ;
        $smtp->datasend("Cc: " . _quote_hdr(join (', ', @$cc), $enc) . "\n")  or die "smtp datasend failed" if ($req -> {'cc'}) ;
        $smtp->datasend("Subject: " . _quote_hdr($req->{subject}, $enc) . "\n") or die "smtp datasend failed" ;
        $smtp->datasend("Date: " . _quote_hdr(Embperl::get_date_time(), $enc) . "\n") or die "smtp datasend failed" ;
        if (ref ($headers) eq 'ARRAY')
            {
            foreach (@$headers)
                {
                next unless (/^(.*?):\s*(.*?)$/) ;
                $smtp->datasend("$1: " . _quote_hdr($2, $enc) . "\n") or die "smtp datasend failed" ;
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

Embperl::Mail - Sends results from Embperl via E-Mail


=head1 SYNOPSIS


 use Embperl::Mail ;
    
 Embperl::Mail::Execute ({inputfile => 'template.epl',
                                subject   => 'Test Embperl::Mail::Execute',
                                to        => 'email@foo.org'}) ;


=head1 DESCRIPTION

I<Embperl::Mail> uses I<Embperl> to process a page template and send
the result out via EMail. Currently only plain text mails are supported. A later 
version may add support for HTML mails. Because of that fact, normal I<Embperl>
HTML processing is disabled per Default (see L<options> below).

=head2 Execute

The C<Execute> function can handle all the parameter that C<Embperl::Execute>
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


=item headerencoding (2.0b9+)

Tells Embperl::Mail which charset definition to include in any header
that contains character code 128-255 and therfore needs encoding. 
Defaults to iso-8859-1. Pass
empty string to turn encoding of header fields of.

=item mailhost

Specifies which host to use as SMTP server.
Default is B<localhost>.

=item mailhelo

Specifies which host/domain to use in the HELO/EHLO command.
A reasonable default is normally chosen by I<Net::SMTP>, but
depending on your installation it may necessary to set it
manualy.

=item maildebug

Set to 1 to enable debugging of mail transfer.

=item options

If no C<options> are given the following are used per default: 
B<optDisableHtmlScan>, B<optRawInput>, B<optKeepSpaces>, B<optReturnError>

=item escmode

In contrast to normal I<Embperl> escmode defaults to zero (no escape)

=item errors

As in C<Embperl::Execute> you can specify an array ref, which returns
all the error messages from template processing. If you don't specify 
this parameter C<Execute> will die when an error occurs.

=back

=head2 Configuration

Some default values could be setup via environment variables.

B<IMPORTANT:> For now Embperl::Mail does B<not> honour the Embperl
configuration directives in your httpd.conf. Only values set via the
environment are accepted (e.g. via SetEnv or PerlSetEnv).


=head2 EMBPERL_MAILHOST

Specifies which host to use as SMTP server.
Default is B<localhost>.

=head2 EMBPERL_MAILHELO

Specifies which host/domain to use in the HELO/EHLO command.
A reasonable default is normally chosen by I<Net::SMTP>, but
depending on your installation it may necessary to set it
manualy.

=head2 EMBPERL_MAILFROM 

Specifies which the email address that is used as sender.
Default is B<www-server@server_name>.

=head2 EMBPERL_MAILDEBUG 

Debug setting for Net::SMTP. Default is 0.

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Net::SMTP
