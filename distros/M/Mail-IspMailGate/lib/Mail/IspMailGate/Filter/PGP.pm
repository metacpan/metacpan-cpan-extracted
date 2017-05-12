# -*- perl -*-
#

package Mail::IspMailGate::Filter::PGP;

require 5.004;
use strict;

require Mail::IspMailGate::Filter;
require MIME::Decoder::PGP;

MIME::Decoder::PGP->install('x-pgp');


@Mail::IspMailGate::Filter::PGP::ISA = qw(Mail::IspMailGate::Filter::InOut);

sub getSign { "X-ispMailGate-PGP"; };

#####################################################################
#
#   Name:     mustFilter
#
#   Purpose:  determines wether this message must be filtered and
#             allowed to modify $self the message and so on
#
#   Inputs:   $self   - This class
#             $entity - the whole message
#
#   Returns:  1 if it must be, else 0
#
#####################################################################

sub mustFilter ($$) {
    my($self, $entity) = @_;
    if (!$self->SUPER::mustFilter($entity)) {
	return 0;
    }

    if ($self->{'recDirection'} eq 'pos') {
	if (!$self->{'uid'}) {
	    return 0;
	}
    } else {
	my($head) = $entity->head();
	my($uid) = $head->mime_attr('X-ispMailGate-PGP.uid');
	if (!$uid  ||  !$self->{'passPhrases'}->{$uid}) {
	    return 0;
	}
    }

    return 1;
}


#####################################################################
#
#   Name:     filterFile
#
#   Purpse:   do the filter process for one file. Compress it or 
#             uncompress it. the direction will be guessed, if this
#             fails the initial one will be used
#             If the direction is 'neg' the packer will
#             be guessed. Only if this fails the 'packer' attribute will
#             be tried
#
#   Inputs:   $self   - This class
#             $attr   - hash-ref to filter attribute
#                       1. 'body'
#                       2. 'parser'
#                       3. 'head'
#                       4. 'globHead'
#
#   Returns:  error message, if any
#
#####################################################################

sub filterFile ($$) {
    my ($self, $attr) = @_;

    my ($ret);
    if($ret = $self->SUPER::filterFile($attr)) {
	return $ret;
    }

    my($head) = $attr->{'head'};
    $head->delete('Content-Transfer-Encoding');
    if ($self->{'recDirection'} eq 'pos') {
	#
	#   All we do is setting the encoding type to x-pgp.
	#   MIME::Decoder::PGP will do the rest.
	#
	$head->mime_attr("Content-Transfer-Encoding", "x-pgp");
	$head->mime_attr("Content-Transfer-Encoding.uid", $self->{'uid'});
    } else {
	#
	#   All we do is resetting the encoding type.
	#
	my ($type) = split('/', $head->get("Content-Type"));
	if ($type eq 'text'  ||  $type eq 'message') {
	    $head->set('Content-Transfer-Encoding', 'quoted-printable');
	} else {
	    $head->set('Content-Transfer-Encoding', 'base64');
	}
    }
	   
    '';
}


sub IsEq ($$) {
    my($self, $cmp) = @_;
    $self->SUPER::IsEq($cmp)  &&
	($self->{'direction'} eq 'neg'  ||
	 $self->{'uid'} eq $cmp->{'uid'});
}


sub hookFilter ($$) {
    my($self, $entity) = @_;
    my($head) = $entity->head;
    if ($self->{'recDirection'} eq 'pos') {
	$head->mime_attr($self->getSign(), $self->{'recDirection'});
	$head->mime_attr($self->getSign() . ".uid", $self->{'uid'});
    } else {
	$head->delete($self->getSign());
    }
    delete $self->{'recDirection'};
    '';
}


sub new ($$) {
    my($class, $attr) = @_;
    my($self) = $class->SUPER::new($attr);
    my $cfg = $Mail::IspMailGate::Config::config;
    if ($self) {
	if (!exists($self->{'uid'})) {
	    $self->{'uid'} = $cfg->{'pgp'}->{'uid'};
	}
	if (!exists($self->{'passPhrases'})) {
	    $self->{'passPhrases'} = $cfg->{'pgp'}->{'uids'};
	}
    }

    $self;
}


1;


__END__

=pod

=head1 NAME

Mail::IspMailGate::Filter::PGP - Encrypt and decrypt mails with PGP

=head1 SYNOPSIS

 # Create a filter object
 my($scanner) = Mail::IspMailGate::Filter::VirScan->new({
     'uid' => 'Jochen Wiedmann <joe@ispsoft.de>'
 });

 # Call it for filtering the MIME entity $entity and pass it a
 # Mail::IspMailGate::Parser object $parser
 my($result) = $scanner->doFilter({
     'entity' => $entity,
     'parser' => $parser
     });
 if ($result) { die "Error: $result"; }

=head1 VERSION AND VOLATILITY

    $Revision 1.0 $
    $Date 1998/04/05 18:46:12 $

=head1 DESCRIPTION

This class implements an encrypting and decrypting filter based on PGP.
It is derived from the abstract base class Mail::IspMailGate::Filter.
For details of an abstract filter see L<Mail::IspMailGate::Filter>.

The PGP module is based on the MIME::Decoder::PGP module which is
using an external PGP binary. The filter module is designed for
installation on two servers: When sending mail from one server to
the other mails get automatically encrypted on the sending server
and decrypted on the receiving server. Of course both servers need
the IspMailGate package and PGP installed. Installation typically
includes creating an own secret and public key ring which is
specifically dedicated to IspMailGate.

=head1 INSTALLATION AND CUSTOMIZATION

=head2 Patching the MIME-tools

Unfortunately the current version of the MIME-tools (4.116, as of this
writing) has a minor bug that make the MIME::Decoder::PGP module unusable.
This bug was reported to Eryq, the MIME-tools author and will be fixed
in the next release. The patch is quite easy:

  *** /usr/lib/perl5/site_perl/MIME/ParserBase.pm Thu Feb 12 04:11:27 1998
  --- lib/MIME/ParserBase.pm      Thu Apr  9 12:22:44 1998
  ***************
  *** 518,523 ****
  --- 518,524 ----
              $ent->effective_type('application/octet-stream');
              $decoder = new MIME::Decoder 'binary';
          }
  +       $decoder->head($head);
  
          # Obtain a filehandle for reading the encoded information:
          #    We have two different approaches, based on whether or not we

In other words, just use your favourite text editor to edit the file
lib/MIME/ParserBase.pm of the MIME-tools distribution and add the
line marked with a plus sign as line 521. Then reinstall the MIME
modules.

=head2 Creating a key ring

Before starting to use the PGP module, you have to create a public and
private keyring of the ispmailgate user. If you already have an appropriate
keyring, this is done by copying the files C<pubring.pgp>, C<secring.pgp>
and C<randseed.bin> to the C<.pgp> subdirectory of the ispmailgate users
home directory. Note that your personal keyring is not appropriate.
An anonymous user representing your information (an "info" user, for example)
might be more appropriate.

Do not forget to set the file permissions the right way. For example you
might do the following:

    su
    mkdir ~ispmailgate/.pgp
    cp ~info/.pgp/pubring.pgp ~ispmailgate/.pgp
    cp ~info/.pgp/secring.pgp ~ispmailgate/.pgp
    cp ~info/.pgp/randseed.bin ~ispmailgate/.pgp
    chown -R ispmailgate ~ispmailgate/.pgp
    chgrp -R ispmailgate ~ispmailgate/.pgp
    chmod 755 ~ispmailgate/.pgp
    chmod 600 ~ispmailgate/.pgp/*

If you don't have an appropriate keyring, you can instead create a new
one. This is done with the following command:

    su - ispmailgate -c "pgp -kg"

PGP will ask you some questions, for example:

=over 4

=item RSA key size

I recommend using a value of 1024 bit; IspMailGate is not an interactive
application and it doesn't hurt, if encryption and decryption take a little
bit longer.

=item user ID

Choose an appropriate user ID for representing your organization, for
example

    FooBar Inc. <info@foobar.com>

Do not choose the same user ID's and or keyrings on both ends. For
example another user ID might be

    FooBar Inc., Department Stuttgart <info@stuttgart.foobar.com>

=item pass phrase

Enter a random word (you'll be asked to repeat it), note that what you
enter is usually not visible on the terminal. Remember this pass phrase
for later use!

=back

=head2 Configuring the PGP module

Next step is editing the Mail::IspMailGate::Config module. In particular
you have to enter values for the following variables:

=over 4

=item $cfg->{'pgp'}->{'uid'}

This is the default user ID for encrypting emails. (You might override
it with the C<uid> attribute of the Mail::IspMailGate::Filter::PGP
objects, see below.) Example:

    $PGP_UID = 'FooBar Inc. <info@foobar.com>';

=item $cfg->{'pgp'}->{'uids'}

This is a hash ref of user ID's that you want to encrypt automatically.
The hash keys are the user ID's, the hash values are the respective
pass phrases. Example:

    $PGP_UIDS = {
        'FooBar Inc. <info@foobar.com>' => 'foobar'
    };

=item $cfg->{'pgp'}->{'encrypt_command'}

A command template for encrypting messages. Example:

    $cfg->{'pgp'}->{'encrypt_command'} =
        '/usr/bin/pgp -fea $uid +verbose=0';

Note the use of single quotes to prevent expansion of the variable
$uid. This variable will be expanded my the MIME::Decoder module.

=item $cfg->{'pgp'}->{'decrypt_command'}

Likewise for decryption. Example:

    $cfg->{'pgp'}->{'decrypt_command'} =
        '/usr/bin/pgp -f +verbose=0';

You might miss a variable $pass or something sililar here, as
decryption requires a pass phrase. Pgp has no command line option
for setting the pass phrase (Security reasons, might be visible
in ps output), but it accepts an environment variable PGPPASS.
This variable gets set automatically.

=back

=head2 Creating filter rules

Recall the situation from above. We have the FooBar headquarters and
the department in Stuttgart. The headquarter might use the following
rule for encrypting mails to the department:

  { 'recipients' => '\\@stuttgart.foobar.com^',
    'filters' => [ Mail::IspMailGate::Filter::PGP->new({
	'uid' => 'FooBar Inc., Department Stuttgart'
	    . ' <info@stuttgart.foobar.com>',
        'direction' => 'pos'
	}) ]
  },
  { 'recipients' => '\\@stuttgart.foobar.com^',
    'filters' => [ Mail::IspMailGate::Filter::PGP->new({
        'direction' => 'neg'
	}) ]
  }

Likewise the following might be used at the department of Stuttgart:

  { 'recipients' => '\\@hq.foobar.com^',
    'filters' => [ Mail::IspMailGate::Filter::PGP->new({
	'uid' => 'FooBar Inc. <info@foobar.com>',
        'direction' => 'pos'
	}) ]
  },
  { 'recipients' => '\\@hq.foobar.com^',
    'filters' => [ Mail::IspMailGate::Filter::PGP->new({
        'direction' => 'neg'
	}) ]
  }

If you use multiple filters (for example the PGP filter might well be
used together with a compressing filter), note the following:

When encrypting a mail, the PGP filter *must* always be the last
filter, because what the filter does is mainly choosing a certain
type for the content-transfer-encoding. On the other hand, the PGP
filter must be the first one, when decrypting a mail. Thus the
headquarters setup for both compressing and decrypting mails from the
headquarter to the department in Stuttgart and vice versa might look
like this:

  { 'recipients' => '\\@stuttgart.foobar.com^',
    'filters' => [
        Mail::IspMailGate::Filter::Packer->new({
	    'packer' => 'gzip',
	    'direction' => 'pos'
            }),
        Mail::IspMailGate::Filter::PGP->new({
	    'uid' => 'FooBar Inc., Department Stuttgart'
	         . ' <info@stuttgart.foobar.com>',
            'direction' => 'pos'
	    })
        ]
  },
  { 'recipients' => '\\@stuttgart.foobar.com^',
    'filters' => [
        Mail::IspMailGate::Filter::PGP->new({
	    'uid' => 'FooBar Inc., Department Stuttgart'
	         . ' <info@stuttgart.foobar.com>',
            'direction' => 'neg'
	    })
        Mail::IspMailGate::Filter::Packer->new({
	    'packer' => 'gzip',
	    'direction' => 'neg'
            })
        ]
  }

=head1 SEE ALSO

L<ispMailGate>, L<Mail::IspMailGate::Filter>

=cut







