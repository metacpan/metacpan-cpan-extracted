package Mail::Sender::Easy;

use strict;
use warnings;

use Carp;
use Mail::Sender;
use File::Spec;

my $hostname_code = sub {
    require POSIX;
    return (POSIX::uname())[1];  
};

if(!eval {
        require Sys::Hostname::FQDN;
        $hostname_code = \&Sys::Hostname::FQDN::fqdn;
        return 1;
}){
    eval {
       require Net::Domain;
       $hostname_code = \&Net::Domain::hostfqdn;
    }
}

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(email);

use version;our $VERSION = qv('0.0.5');

sub email { Mail::Sender->new()->easy(shift()); }

sub Mail::Sender::easy {
    my($sndr, $mail_ref) = @_;

    my $text        = delete $mail_ref->{'_text'};
    my $html        = delete $mail_ref->{'_html'};
    my $attachments = delete $mail_ref->{'_attachments'};

    my $text_info   = ref $mail_ref->{'_text_info'} eq 'HASH' 
                      ? delete $mail_ref->{'_text_info'} : {};
    delete $mail_ref->{'_text_info'} if exists $mail_ref->{'_text_info'};
    delete $text_info->{$_} for qw(ctype disposition msg);

    my $html_info   = ref $mail_ref->{'_html_info'} eq 'HASH'        
                      ? delete $mail_ref->{'_html_info'} : {};
    delete $mail_ref->{'_html_info'} if exists $mail_ref->{'_html_info'};
    delete $html_info->{$_} for qw(ctype disposition msg);

    my $time = time;
    my $user = $^O eq 'MSWin32' ? "(Windows: $<)" : getpwuid($<);
    my $eusr = $^O eq 'MSWin32' ? "(Windows: $>)" : getpwuid($>);
    my $file = File::Spec->rel2abs($0);
    my $host = $hostname_code->();
 
    my @siteheaders = (
        qq{X-Mailer: use SimpleMood; - Sent via the email() function or easy() method of Mail/Sender/Easy.pm and/or SimpleMood.pm both by Daniel Muey.},
        qq{X-Mailer: Sent via $file ($0) on $host by uid $< ($user) / euid $> ($eusr) at $time (unix epoch)},
    );
    push @siteheaders, qq(X-Mailer: SMTP Auth provided by (object data) $sndr->{'authid'}) if $sndr->{'authid'};
    push @siteheaders, qq(X-Mailer: SMTP Auth provided by (hashref arg) $mail_ref->{'authid'}) if $mail_ref->{'authid'};

    croak q{You must specify the "_text" key.} if !defined $text;

    eval {
        local $Mail::Sender::SITE_HEADERS = join("\015\012", @siteheaders) || '';
        
        if($html) {
            $mail_ref->{'multipart'} = 'mixed';
            $sndr->OpenMultipart($mail_ref);
            $sndr->Part({
                'ctype' => 'multipart/alternative'
            });

            $sndr->Part({
                %{ $text_info }, 
                'ctype'       => 'text/plain', 
                'disposition' => 'NONE', 
#               'msg'         => "$text$CRLF" 
            });
            $sndr->SendLineEnc($text);

            $sndr->Part({
                %{ $html_info },
                'ctype'       => 'text/html',  
                'disposition' => 'NONE', 
#               'msg'         => "$html$CRLF" 
            });
            $sndr->SendLineEnc($html);

            $sndr->EndPart('multipart/alternative');
        } 
        elsif(!$html && $attachments) {
            $sndr->OpenMultipart($mail_ref);
            $sndr->Body({
                %{ $text_info },
                'ctype'       => 'text/plain',
                'disposition' => 'NONE',
#               'msg'   => $text,
            });
            $sndr->SendLineEnc($text);
        } 
        else {
            $sndr->Open({
                %{ $text_info },
                %{ $mail_ref },
            });
            $sndr->SendLineEnc($text);
        }

        if(defined $attachments && ref $attachments eq 'HASH') {
            for my $attach (keys %{ $attachments }) {

                $attachments->{ $attach }{'description'} = $attach 
                    if !defined $attachments->{ $attach }{'description'};
                $attachments->{ $attach }{'ctype'}       = 'text/plain' 
                    if !defined $attachments->{ $attach }{'ctype'};
                $attachments->{ $attach }{'_disptype'}   = $attach 
                    if !defined $attachments->{ $attach }{'_disptype'};

                my $disp = qq(attachment; filename="$attach"; ) 
                           . qq(type=$attachments->{ $attach }{'_disptype'});
		if(defined $attachments->{ $attach }{'_inline'} && $html) {
                    $disp = qq(inline; filename="$attach";\r\nContent-ID: )
                            . qq(<$attachments->{ $attach }{'_inline'}>);
                } 

                if($attachments->{ $attach }{'msg'}) {
                    $sndr->Part({
                        'description' => 
                            $attachments->{ $attach }{'description'},
                        'ctype'       => $attachments->{ $attach }{'ctype'},
                        'encoding'    => 'Base64',
                        'disposition' => $disp,
                        'msg'         => $attachments->{ $attach }{'msg'},
                     });
                } 
                elsif($attachments->{ $attach }{'file'}) {
                    $sndr->Attach({ 
                        'description' => 
                            $attachments->{ $attach }{'description'},
                        'ctype'       => $attachments->{ $attach }{'ctype'},
                        'encoding'    => 'Base64',
                        'disposition' => $disp,
                        'file'        => $attachments->{ $attach }{'file'},
                    });
                }  
                else { 
                    Carp::carp q(Attachment data needs either 'msg' or )
                               . qq('file' specified in $attach - Message )
                               . q(still sent *pending other errors* but )
                               . qq(attachment not created.\n); 
                }
            }
        }
        $sndr->Close();
    };

    if($@ || $Mail::Sender::Error) {
        if($Mail::Sender::Error) {
            $@ .= $@ ? qq(\nMail::Sender::Error: $Mail::Sender::Error) 
                     : qq(Mail::Sender::Error: $Mail::Sender::Error);
        }
        return;
    }
    return 1;
}

1;

__END__

=head1 NAME

Mail::Sender::Easy - Super Easy to use simplified interface to Mail::Sender's excellentness

=head1 SYNOPSIS

    use Mail::Sender::Easy qw(email);

    email({
        %mail_sender_config,
        _text => 'Hello World',
    }) or die "email() failed: $@";

=head1 DESCRIPTION

Easy "email() or die $@" interface to Mail::Sender.

See "EXTENDED DESCRIPTION" and "DISCUSSION OF THE NAMESPACE" for more info.

Also adds more detailed info to the X-Mailer header to track usage.

=head2 Function: email()

    email(\%email) or die "Email error: $@";

    if(email(\%email)) {
        log_sent_emails(\%email);
        print "Your email has been sent!\n";
    }
    else {
        log_failed_email($@, \%email);
        print "Sorry, I could not send your email!\n";
    }


=head2 Method: $sender->easy()

Same hashref as email() but called with a Mail::Sender object you created previously:

my $sender = Mail::Sender->new();

$sender->easy(\%email) or die "Email error: $@";

=head2 \%email

The keys to this hash are the keys described in L<Mail::Sender>'s docs in the "Parameters" Section with the addition of 3 new ones:

=head3 _text

The value is the text/plain part of the message, its the only required one.

=head3 _html

The value is the text/html part of the message, it is not required.

=head3 _text_info

Value is a hashref of additonal args to Mail::Sender->Part() for text in text and html emails, Mail::Sender->Body() in text with attachement.
ctype, disposition, msg are ignored since they are set by other means.

The perfect place to set 'encoding' and 'charset'

=head3 _html_info

Value is a hashref of additonal args to Mail::Sender->Part() for html. 
ctype, disposition, msg are ignored since they are set by other means.

The perfect place to set 'encoding' and 'charset'

=head3 _attachments

Encoding of attachments is always Base64.
The value of this key is a hash reference. 

In that hashref each key is a filename, not the entire path, just the filename, to be attached. The value is another hashref described below. (Don't panic, its not as complex as it sounds at this point, see the EXAMPLE to see what I mean.)

=head4 _attachments => { 'file.name' => { this hash is described here }, }

You *must* specify the "file" key or the "msg" key, the "msg" key takes precedence. 

The keys are:

=over 4

=item file

Path to the file to attach.

    'file' => '/home/foo/docs/fiddle.txt',

Makes the attachment via Mail::Sender::Attach()

=item msg

Contents of the file (instead of using a path)

    'msg' => $fiddle_txt_content,

Makes the attachment via Mail::Sender::Part()

=item ctype

Content type of the attachement

    'ctype' => 'image/png',

Mail::Sender will guess if not specified but its a good idea to specify it.

Defaults to text/plain

=item description

Short textual description or title of this file:

    'description' => 'Fiddle Info',

Defaults to the filename you used for this hashref's key (IE "file.name" from the "this hash described here" header).

=item _disptype

Short textual description of the type of file:

    '_disptype' => 'Text Document',

Defaults to the filename you used for this hashref's key (IE "file.name" from the "this hash described here" header).

=item _inline

The value is used as its "cid" and makes it attached inline

    '_inline' => 'fiddlepic1',

in the html section:

   <img src="cid:fiddlepic1" />

If not specified its not "inline", its just attached :)

=back

The _disptype and _inline are used to build the actual "dispositon" part which is described in Mial::Sender's docs if you want to know the nitty gritty.

=head1 EXPORT

None by default. email() is exportable

=head1 EXAMPLE

Send an email via SMTP with authentication, on an alternate port, a plain text part, html part that has an inline smiley image, a PDF attachment, a high priority and read and delivery receipt request:

    use Mail::Sender::Easy qw(email);   

    email({
        'from'         => 'foo@bar.baz',
        'to'           => 'you@ddre.ss',
        'cc'           => 'your_pal@ddre.ss',
        'subject'      => 'Perl is great!',
        'priority'     => 2, # 1-5 high to low
        'confirm'      => 'delivery, reading',
        'smtp'         => '1.2.3.4',
        'port'         => 26,
        'auth'         => 'LOGIN',
        'authid'       => 'foo@bar.baz',
        'authpwd'      => 'protect_with_700_perms_or_get_it_from_input',
        '_text'        => 'Hello *World* :)',    
        '_html'        => 'Hello <b>World</b> <img src="cid:smile1" />',
        '_attachments' => {
            'smiley.gif' => {
                '_disptype'   => 'GIF Image',
                '_inline'     => 'smile1',
                'description' => 'Smiley',
                'ctype'       => 'image/gif',    
                'file'        => '/home/foo/images/smiley.gif',
            },
            'mydata.pdf' => {
                'description' => 'Data Sheet',  
                'ctype'       => 'application/pdf',
                'msg'         => $pdf_guts,
            },
        },
    }) or die "email() failed: $@";

=head1 EXTENDED DESCRIPTION

Mail::Sender is a great module. I have great respect for Jenda as you can tell from the list archives :)

Mail::Sender's one problem is its a bit cumbersome to use, with so many options and things to open, close, the whole thing, parts, multiparts etc etc., and several ways to check for successs. Its hard to remember what needs done at what point with what data to do what you want and then which way you check what data based on what was done to see if it worked or not.

This module's aim is to make all of that ``Easy'', Simple, User Friendly, etc etc (see "DISCUSSION OF THE NAMESPACE" below)

It does so by providing a single function (and method) to send mail based on an (IMHO) easier to work with hashref and returns true or false on success or failer and sets $@ to any errors.

The EXAMPLE section shows an ``email or die'' that will send an email using SMTP Auth on port 26 with text and html parts, the html part has a smiley gif embedded inline and a PDF attached and a high priority flag and read and delivery receipt requests. It will take you seconds to customize it to send that to yourself (and its ``Easy'' to understand what its going on without having to understand the intracacies of SMTP and MIME messages. Now try it with plain the Mail::Sender manpage. See? Much much ``Easy''ier to do, understand, troubelshoot, maintain, etc etc :)

=head1 DISCUSSION OF THE NAMESPACE

When first registering this name space I was told Easy and Simple are bad name spaces, but Simple did seem to describe it in the spirit of LWP::Simple (I'd missed Adam's response for some reason...)

L<http://www.xray.mpe.mpg.de/mailing-lists/modules/2005-12/msg00270.html>

And then starting in January:

L<http://www.xray.mpe.mpg.de/mailing-lists/modules/2006-01/msg00008.html>

So I registered "Simple" but was told that was still not going to fly despite the "LWP::Simple" in the previous thread.

L<http://www.xray.mpe.mpg.de/mailing-lists/modules/2006-01/msg00016.html>

After receiveing no further recommendation of a registerable NS as requested I attempted "Friendly" with a request that if that was no good to please recommend something that is proper and was met with stone cold silence as of this rant being typed Sat Jan 7 16:24:28 CST 2006.

L<http://www.xray.mpe.mpg.de/mailing-lists/modules/2006-01/msg00044.html>

So with no other option I decided to go with Easy (unregistered as recommended in one of the threads above) because:

=over 4

=item Its short

=item Its more accurate and descriptive than Simple even though it may not be perfect (and since no others were suggested)

"Simple" could mean easy to use, simple messages, not very intelligent, etc

=item I could not think of an alternative that was more accurate

=item No one gave me any alternative "valid" options

I asked for one but only got ""Easy" isn't good" 

I tried ;p

=item It was already done, so I didn't have to change the code

=back

So with all that in mind I'd like to put here an:

=head2 Open ended request to modules@perl.org

I'd like to request that either this name space be registered under my account or you suggest a name space that will be "registerable" and is short and descriptive of the module.

Thanks!

=head1 SEE ALSO

L<Mail::Sender>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
