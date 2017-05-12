package Mail::Sendmail::Enhanced;

use 5.008;

use strict;
use warnings;

use Encode qw(decode encode);

use Mail::Sendmail '0.79_16';
use MIME::Base64;

our $VERSION = '0.03';

################################################################################

sub new
{
    my ( $this ) = ( shift );

    my $mail = {};
    bless ( $mail, $this );

    while ( my $key = shift ) {
        if ( ref ( $key ) eq 'HASH' ) {
            foreach my $k (sort keys %{$key} ) {
                $mail->{$k} = $$key{$k};
            }
        } else {
            my $value = shift;
            $mail->{$key} = $value;
        }
    }

    $mail->{smtp}     ||= '';
    $mail->{from}     ||= '';
    $mail->{charset}  ||= 'utf-8';
    $mail->{type}     ||= 'text/plain';

    $mail->{user}     ||= '';
    $mail->{pass}     ||= '';
    $mail->{method}   ||= 'LOGIN';
    $mail->{required} ||= 1;

    $mail->{to}       ||= '';
    $mail->{cc}       ||= '';
    $mail->{subject}  ||= 'No subject defined';
    $mail->{message}  ||= 'No message defined!';

    $mail->{attachments}          ||= {};
    $mail->{attachments_size_max} ||=  0; #no limit "-1" means no attachment allowed

    $mail->{commit}   ||= 0;

    $mail->send() if $mail->{commit};

    return $mail;
}

################################################################################

sub send
{
    my ( $self, $ARG ) = ( shift, shift );

    return 'No address! Please set [to] or/and [cc] fileds.' unless $ARG->{to} || $ARG->{cc} || $self->{to} || $self->{cc};

    my $charset  = $ARG->{charset} || $self->{charset} || 'utf-8';
    my $type     = $ARG->{type}    || $self->{type}    || 'text/plain';
    my $subject  = $ARG->{subject} || $self->{subject} || '';
    my $message  = $ARG->{message} || $self->{message} || '';

    my $boundary = "====" . time() . "====";

    # Email subject is encoded using proper character encoding.
    # original "encode_qp" function contains up to 2 arguments,
    # but in a case of character set it is needed to start every
    # new line with a statemant of the encoding, so - as a the
    # third parameter - the charset is sent to the function.

    my $flnoc = 67;
    my $nlnoc = 78;
    my $bol   = " =?$charset?Q?";
    my $eol   = "?=\n";

    {
        # this part consider multibyte characters and keep that folding
        # does  not  divide  the  multibyte  characters  into  two lines.
        # The  reason  is  that  some  email clients are not able to put
        # together these separated bytes into one character.
        require bytes;


        my $t_subject = decode( $charset, $subject ) if $charset;

        if ( bytes::length($t_subject) > length($t_subject) || $t_subject =~ /[^\0-\xFF]/ ) {

            $subject = '';
            my $t_string = ''; # substring of $t_subject which is testing if can be added to $subject
            my $t_length =  0; # the length of $t_subject

            my $t_return = ''; # $t_string which match to the condition
            my $t_result = ''; # encoded string of $t_string
            my $t_number =  0; # number of row of the folded "Subject" field
            while ( $t_subject ) {
                foreach(0..$flnoc) {
                    $t_string = substr($t_subject,0,$_);
                    $t_result = encode_qp(encode($charset,$t_string),{bol=>$bol,eol=>$eol,flnoc=>0,nlnoc=>0,charset=>$charset,});

                    #checking if encoded string $t_result of the tested substring $t_string satisfies length condition:
                    # and if yes we go out with the last good value $t_return and $t_subject get shorter by $t_length
                    last if length( $t_result ) > ($t_number ? $nlnoc : $flnoc);
                    $t_return = $t_result;
                    $t_length = length($t_string);
                }
                $subject = $subject.$t_return;
                $t_subject = substr( $t_subject, $t_length );
                $t_number++;
            }

        } else {
            $subject = encode_qp( $subject , { bol=>$bol, eol=>$eol, flnoc=>$flnoc, nlnoc=>$nlnoc, charset=>$charset, } );
        }
    }

    $subject = substr($subject,1);

    my %mail = (
    'X-Mailer'     => "This is Perl Mail::Sendmail::Enhanced version $Mail::Sendmail::Enhanced::VERSION",
    'Content-Type' => "multipart/mixed; charset=$charset; boundary=\"$boundary\"",
    'Smtp'         => ($ARG->{smpt}|| $self->{smtp}     ),
    'From'         => ($ARG->{from}|| $self->{from}     ),
    'To'           => ($ARG->{to}  || $self->{to} || '' ),
    'Cc'           => ($ARG->{cc}  || $self->{cc} || '' ),
    'Subject'      =>  $subject,
    auth           => {
                        user     => ($ARG->{user}    || $self->{user}     ),
                        pass     => ($ARG->{pass}    || $self->{pass}     ),
                        method   => ($ARG->{method}  || $self->{method}   ),
                        required => ($ARG->{required}|| $self->{required} ),
                      },
    );

    $boundary = '--'.$boundary;
    $mail{'Message'} = "$boundary\n"
    ."Content-Type: $type; charset=$charset; format=flowed\n"
    ."Content-Transfer-Encoding: 8bit\n\n"
    ."$message\n";

#    ."Content-Transfer-Encoding: quoted-printable\n\n"
#    .encode_qp( $ARG->{'message'}, {} )."\n";

    $ARG->{attachments}          ||= $self->{attachments} || {};
    $ARG->{attachments_size_max} ||= $self->{attachments_size_max} || 0; #no limit "-1" means no attachment allowed

    $ARG->{attachments_size_max}=~s/[B ]//g;
    if ( $ARG->{attachments_size_max} =~ /^(-\d+)$|^(\d+)(|k|K|m|M|t|T)?\s*$/ )
    {
        if ( $1 ) { $ARG->{attachments_size_max} = $1

        } else {

            $ARG->{attachments_size_max} =                      $2 if $3 eq 'B' || !$3;
            $ARG->{attachments_size_max} =               1000 * $2 if $3 eq 'k';
            $ARG->{attachments_size_max} =               1024 * $2 if $3 eq 'K';
            $ARG->{attachments_size_max} =        1000 * 1000 * $2 if $3 eq 'm';
            $ARG->{attachments_size_max} =        1024 * 1024 * $2 if $3 eq 'M';
            $ARG->{attachments_size_max} = 1000 * 1000 * 1000 * $2 if $3 eq 't';
            $ARG->{attachments_size_max} = 1024 * 1024 * 1024 * $2 if $3 eq 'T';
        }
    }
    else {
      return 'Malform in attachments_size_max='.$ARG->{attachments_size_max}.'! Accepted form is: positive or negative integer plus optional one of the letters: (k,K,m,M,t,T).'
    }

    return "Attachments are not allowed whereas some are preperad to send!" if %{$ARG->{attachments}} && $ARG->{attachments_size_max} < 0;
    # attachment files are packed one by one into the message part each divided by boundary

    # checking attachments:
    foreach my $fileName ( sort keys %{$ARG->{attachments}} ) {

           my $fileLocation = $ARG->{attachments}->{$fileName};

        # if does not exists:
        return "Attachment does not exists! [$fileLocation]" unless -f $fileLocation;

        # if it is too big:
        my $size = -s $fileLocation || 0;
        return "Attachment too big! [$fileLocation: $size > ".$ARG->{attachments_size_max}."B max.]"
            if $ARG->{attachments_size_max} > 0 && $size > $ARG->{attachments_size_max};
    }


    foreach my $fileName ( sort keys %{$ARG->{attachments}} ) {
        my $fileLocation = $ARG->{attachments}->{$fileName};
        if (open (my $F, $fileLocation )) {
            my $input_record_separator = $/;
            binmode $F; undef $/;
            my $attachment = encode_base64(<$F>);
            close $F;
            $/ = $input_record_separator;

            $mail{'Message'} .= "$boundary\n"
            ."Content-Type: application/octet-stream; name=\"$fileName\"\n"
            ."Content-ID: <$fileName>\n"
            ."Content-Transfer-Encoding: base64\n"
            ."Content-Disposition: attachment; filename=\"$fileName\"\n\n"
            ."$attachment\n";
        }
    }

    $mail{'Message'} .= "$boundary--\n";


    return $Mail::Sendmail::error unless sendmail( %mail );

    return;
}

################################################################################

sub encode_qp
{
    ############################################################################
    # This  function is  an  exact copy of the that of the same  name from the
    # module:  "MIME::QuotedPrint::Perl" '1.00'  with  the  following changes:
    #   1. The second argument can be scalar - as previously -
    #      or hash which would contain more information
    #   2. There  are changes in counting character in each line in accordance
    #      with hash sent  to the function: it can be  different in first line
    #      and the next ones. It is so, because usually in the firs line there
    #      is some word (Subject for instance).
    # The behaviour of the function is identical with the original one in case
    # we send two scalar arguments only.
    ############################################################################

    # $res = text to be encoded
    my ( $res ) = ( shift );
    return '' unless $res;

    # The arguments can be sent in old way, when the second argument was the
    # end of character rows, or in a new way - as a hash:
    my %par = (
      bol   => " ",  # characters at the begining of each lines
      eol   => "\n", # characters at the end of each line
      flnoc => 68,   # first line number of characters, 0 = unlimit
      nlnoc => 78,   # next lines number of characters, 0 = unlimit
    );

    while ( my $key = shift ) {
        if ( ref ( $key ) eq 'HASH' ) {
            foreach my $k (sort keys %{$key} ) {
                next unless $k =~ /^(bol|charset|eol|flnoc|nlnoc)$/;
                next if $k eq 'flnoc' && $par{$k} !~ /^\d+$/;
                next if $k eq 'nlnoc' && $par{$k} !~ /^\d+$/;

                $par{$k} = $$key{$k};
            }
        } else { # you can only send - as a second scalar argument the "EOL"
                 # characters in accordance with the original function
            $par{eol} = $key;
        }
    }

    if ($] >= 5.006) {
        require bytes;
        if (bytes::length($res) > length($res) || ($] >= 5.008 && $res =~ /[^\0-\xFF]/))
        {
            require Carp;
            Carp::croak("The Quoted-Printable encoding is only defined for bytes");
        }
    }

    # usefull shorthands
    my $bol   = $par{bol};
    my $eol   = $par{eol};
    my $flnoc = $par{flnoc} - 0 - length($eol) - length($bol);
    my $nlnoc = $par{nlnoc} - 1 - length($eol) - length($bol);
    my $mid   = '';
    unless ( defined $bol ) { $mid = '='; $bol = '' }

    # Do not mention ranges such as $res =~ s/([^ \t\n!-<>-~])/sprintf("=%02X", ord($1))/eg;
    # since that will not even compile on an EBCDIC machine (where ord('!') > ord('<')).
    if (ord('A') == 193) { # EBCDIC style machine
        if (ord('[') == 173) {
            $res =~ s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp1047',$1))))/eg;  # rule #2,#3
            $res =~ s/([ \t]+)$/
              join('', map { sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp1047',$_)))) }
                   split('', $1)
              )/egm;                        # rule #3 (encode whitespace at eol)
        }
        elsif (ord('[') == 187) {
            $res =~ s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('posix-bc',$1))))/eg;  # rule #2,#3
            $res =~ s/([ \t]+)$/
              join('', map { sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('posix-bc',$_)))) }
                   split('', $1)
              )/egm;                        # rule #3 (encode whitespace at eol)
        }
        elsif (ord('[') == 186) {
            $res =~ s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp37',$1))))/eg;  # rule #2,#3
            $res =~ s/([ \t]+)$/
              join('', map { sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp37',$_)))) }
                   split('', $1)
              )/egm;                        # rule #3 (encode whitespace at eol)
        }
    }
    else { # ASCII style machine
        $res =~  s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord($1))/eg;  # rule #2,#3
    $res =~ s/\n/=0A/g unless length($eol);
        $res =~ s/([ \t]+)$/
          join('', map { sprintf("=%02X", ord($_)) }
               split('', $1)
          )/egm;                            # rule #3 (encode whitespace at eol)
    }

    return $res unless length($eol);

    # rule #5 (lines must be shorter than 76 chars, but we are not allowed
    # to break =XX escapes.  This makes things complicated :-( )
    my $brokenlines = "";

    $brokenlines .= "$bol$1$mid$eol" if $flnoc && $res =~ s/(.*?^[^\n]{$flnoc} (?:
         [^=\n]{2} (?! [^=\n]{0,1} $) # 75 not followed by .?\n
        |[^=\n]    (?! [^=\n]{0,2} $) # 74 not followed by .?.?\n
        |          (?! [^=\n]{0,3} $) # 73 not followed by .?.?.?\n
        ))//xsm;

    $brokenlines .= "$bol$1$mid$eol" while $nlnoc && $res =~ s/(.*?^[^\n]{$nlnoc} (?:
         [^=\n]{2} (?! [^=\n]{0,1} $) # 75 not followed by .?\n
        |[^=\n]    (?! [^=\n]{0,2} $) # 74 not followed by .?.?\n
        |          (?! [^=\n]{0,3} $) # 73 not followed by .?.?.?\n
        ))//xsm;

    $brokenlines .= "$bol$res$eol" if $res;

#print "$brokenlines\n";
    $brokenlines;
}

################################################################################

1;

################################################################################

=pod

=head1 NAME

    Mail::Sendmail::Enhanced v.0.03 - Pure Perl email sender with multibyte characters encoding and easy attachments managment

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use strict;
  use warnings;

  use Mail::Sendmail::Enhanced;

  # This part simulate the general setup of application mailer.
  # It sets smtp server and size limit of attachments (1MB)
  # This configuration is set by admin.
  my $mail = Mail::Sendmail::Enhanced-> new(
    charset     => 'cp1250',
    smtp        => 'Your SMTP server',
    from        => 'Your mail',
    user        => 'user',
    pass        => 'password',
    method      => 'LOGIN',
    required    => 1,
    attachments => {
      'name for email of the file1' => 'OS file1 location',
      'name for email of the file2' => 'OS file2 location',
    },
    attachments_size_max => '1MB',
    commit      => 0,
  );

  # This part simulate how clients can use the mailer.
  # Configuration here is set by clients themself.
  my @client = qw(John Henry Newman);
  for (@client) {

    my $lowercase = chr(185).chr(230).chr(234).chr(179).chr(241).chr(243).chr(156).chr(159).chr(191);
    my $uppercase = chr(165).chr(198).chr(202).chr(163).chr(209).chr(211).chr(140).chr(143).chr(175);

    print $mail-> send( {
      to    => 'author of the module: <wb@webswing.co.uk>',
      subject  => "Subject longer than 80 characters with Polish letters: lowercase: $lowercase and uppercase: $uppercase.",
      message  => "This is the message from $_ in the character encoding ".$mail->{charset}.".

      This is an example of mailing Polish letters in a header field named \"Subject\".
      Additionally this field is longer than 80 characters.

      Additional text:
      Polish lowercase letters: $lowercase
      Polish uppercase letters: $uppercase
      ",
    });
  }

  __END__

=head1 DESCRIPTION

Mail::Sendmail::Enhanced  is  an  enhanced   version  of  the module
L<Mail::Sendmail>. It is still pure Perl solution. In the module the
problem  of encoding  multibyte  characters in L<Mail::Sendmail> was
solved. Some procedure of sending  very easily a list of attachments
was prepared.

After preparing  multibyte  characters encoding and building message
with  attachments the  module calls  I<sendmail>  function  from the
L<Mail::Sendmail> module which does all the job.So please read there
in L<Mail::Sendmail> about how to set up connections to email servers.
This module behaves identically.

As already mentioned this adds two things:

1. Multibyte characters encoding - which uses refurbish and imported
function I<encode_qp> from the module L<MIME::QuotedPrint::Perl>.

The  problem  with  encoding  multibyte  characters  was that simple
implemented encoding -  especially  in the "Subject:" field of email
header - results  that some characters are  divided between two rows
when long  lines are folded.  Some email clients are not able to put
together these  separated bytes into  one character  and letters are
displeyed inproperly. The new encoding function keeps  bytes of  one
character in one folded row.

2. Simple attachments managment. List of attachments is a hash:

  attachments => {
    'name for email of the file1' => 'OS file1 location',
    'name for email of the file2' => 'OS file2 location',
  },

where  the keys are  the  attachments email names and the values are
OS locations.

It is possible to add some control to sending attachment. It is done
by the parameter B<attachments_size_max>. Possible values are:


  attachments_size_max => -1,         # Negative value means that sending attachments is forbidden.
                                      # Every try of sending them with this value negative is fatal one.

  attachments_size_max =>  0,         # No size limit of attachments

  attachments_size_max => '50 000 B', # Positive value is a maximum size of attachment.
                                      # When size is bigger then fatal error is return.
                                      # Spaces and the letter B (byte) are ignored.

                                      # shorthand for sizes: k, K, m, M:
  attachments_size_max => '100k',     # k = 1000,         so maximum =   100 000
  attachments_size_max => '100 K',    # K = 1024,         so maximum =   102 400
  attachments_size_max => '2 m',      # m = 1000x1000,    so maximum = 1 000 000
  attachments_size_max => '2M',       # M = 1024x1024,    so maximum = 1 048 576


=head1 INTERFACE

Interface L<Mail::Sendmail::Enhanced>, gets two methods:

=head2 new()

The method I<new> creates mail object.

=head2 send()

The method I<send> sends mail.

Arguments  of both  methods  are  the  same  and  discussed  earlier.
Dispersing  data  between  I<new>  and  I<send>  is  fully  optional.
Assuming that we have three hashes %n, %s and %d which fullfiled the
abstract equality:

    "%n + %s = %d"

all the three ways of sending email have the same effect:

    1. my $mail = Mail::Sendmail::Enhanced->new(%n); $mail->send(%s);

    2. my $mail = Mail::Sendmail::Enhanced->new(); $mail->send(%d);

    3. my $mail = Mail::Sendmail::Enhanced->new(%d); $mail->send();

This third way can be replaced by only one call with additional argument
"commit" with the value 1 (look back at the SYNOPSIS):

    commit => 1,

in that case email is sent at the end of the method I<new>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-sendmail-enhanced at rt.cpan.org>, or through
the web interface at  L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-Sendmail-Enhanced>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Waldemar Biernacki, C<< <wb at webswing.co.uk> >>

This program is free software; you can redistribute it and/or modify
it under the terms of the the Artistic License (2.0). You may obtain
a copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard  or Modified
Versions is governed by this Artistic License. By  using,  modifying
or distributing  the Package, you  accept  this license.  Do not use,
modify, or distribute the Package, if you do not accept this license.

If  your  Modified  Version has been derived from a Modified Version
made  by someone  other  than  you, you are nevertheless required to
ensure that your Modified Version complies with the  requirements of
this license.

This  license  does  not  grant  you  the right to use any trademark,
service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive,  worldwide,  free-of-charge
patent  license to make, have made, use, offer to sell, sell, import
and otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by
the  Package.  If  you  institute  patent  litigation  (including  a
cross-claim  or counterclaim)  against  any  party alleging that the
Package constitutes direct or contributory patent infringement, then
this Artistic License to you shall terminate  on the date  that such
litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS  PROVIDED  BY  THE  COPYRIGHT
HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT  ANY EXPRESS  OR IMPLIED
WARRANTIES. THE  IMPLIED WARRANTIES OF  MERCHANTABILITY, FITNESS FOR
A  PARTICULAR PURPOSE, OR  NON-INFRINGEMENT  ARE  DISCLAIMED  TO THE
EXTENT  PERMITTED  BY  YOUR  LOCAL  LAW. UNLESS  REQUIRED BY LAW, NO
COPYRIGHT  HOLDER  OR  CONTRIBUTOR  WILL  BE  LIABLE  FOR ANY DIRECT,
INDIRECT, INCIDENTAL, OR  CONSEQUENTIAL  DAMAGES  ARISING IN ANY WAY
OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

=head1 SEE ALSO

L<Mail::Sendmail>, L<MIME::QuotedPrint::Perl>

=cut
