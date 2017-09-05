package Mail::GPG::Result;

# $Id: Result.pm,v 1.8 2006/04/14 11:05:03 joern Exp $

use strict;

require Encode if $] >= 5.008;

sub get_mail_gpg                { shift->{mail_gpg}                     }

sub get_is_encrypted            { shift->{is_encrypted}                 }
sub get_enc_ok                  { shift->{enc_ok}                       }
sub get_enc_key_id              { shift->{enc_key_id}                   }
sub get_enc_mail                { shift->{enc_mail}                     }
sub get_enc_key_ids             { shift->{enc_key_ids}                  }
sub get_enc_mails               { shift->{enc_mails}                    }
sub get_is_signed               { shift->{is_signed}                    }
sub get_sign_ok                 { shift->{sign_ok}                      }
sub get_sign_state              { shift->{sign_state}                   }
sub get_sign_key_id             { shift->{sign_key_id}                  }
sub get_sign_mail               { shift->{sign_mail}                    }
sub get_sign_mail_aliases       { shift->{sign_mail_aliases}            }
sub get_sign_fingerprint        { shift->{sign_fingerprint}             }

sub set_is_encrypted            { shift->{is_encrypted}         = $_[1] }
sub set_enc_ok                  { shift->{enc_ok}               = $_[1] }
sub set_enc_key_id              { shift->{enc_key_id}           = $_[1] }
sub set_enc_mail                { shift->{enc_mail}             = $_[1] }
sub set_enc_key_ids             { shift->{enc_key_ids}          = $_[1] }
sub set_enc_mails               { shift->{enc_mails}            = $_[1] }
sub set_is_signed               { shift->{is_signed}            = $_[1] }
sub set_sign_ok                 { shift->{sign_ok}              = $_[1] }
sub set_sign_state              { shift->{sign_state}           = $_[1] }
sub set_sign_key_id             { shift->{sign_key_id}          = $_[1] }
sub set_sign_mail               { shift->{sign_mail}            = $_[1] }
sub set_sign_mail_aliases       { shift->{sign_mail_aliases}    = $_[1] }
sub set_sign_fingerprint        { shift->{sign_fingerprint}     = $_[1] }

sub get_gpg_stdout              { shift->{gpg_stdout}                   }
sub get_gpg_stderr              { shift->{gpg_stderr}                   }
sub get_gpg_status              { shift->{gpg_status}                   }
sub get_gpg_rc                  { shift->{gpg_rc}                       }

sub new {
    my $class = shift;
    my %par   = @_;
    my  ($mail_gpg, $gpg_stdout, $gpg_stderr, $gpg_status, $gpg_rc) =
    @par{'mail_gpg','gpg_stdout','gpg_stderr','gpg_status','gpg_rc'};

    #-- initialize reference attributes to prevent
    #-- dereferencing undef errors
    $gpg_stdout = \"" if not defined $gpg_stdout;
    $gpg_stderr = \"" if not defined $gpg_stderr;
    $gpg_status = \"" if not defined $gpg_status;

    my $self = bless {
        mail_gpg   => $mail_gpg,
        gpg_stdout => $gpg_stdout,
        gpg_stderr => $gpg_stderr,
        gpg_status => $gpg_status,
        gpg_rc     => $gpg_rc,
    }, $class;

    $self->analyze_result;

    return $self;
}

sub analyze_result {
    my $self = shift;

    my ($is_signed,         $sign_ok,      $sign_state,
        $sign_key_id,       $sign_mail,    $sign_fingerprint,
        @sign_mail_aliases, $is_encrypted, $enc_ok,
        @enc_key_ids,       @enc_mails
    );

    my $gpg_status = $self->get_gpg_status;
    my $gpg_stderr = $self->get_gpg_stderr;

    while ( $$gpg_status && $$gpg_status =~ m{^\[GNUPG:\]\s+(.*)$}mg ) {
        my $line = $1;
        if ( $line =~ /^(GOOD|EXP|EXPKEY|REVKEY|BAD)SIG\s+([^\s]+)\s+(.*)/ ) {
            my ( $state, $key_id, $mail ) = ( $1, $2, $3 );
            $is_signed   = 1;
            $sign_state  = $state;
            $sign_key_id = $key_id;
            $sign_mail   = decode($mail);
            $sign_ok     = $sign_state eq 'GOOD';
        }
        elsif ( $line =~ /^ERRSIG\s+([^\s]+)/ ) {
            $is_signed   = 1;
            $sign_key_id = $1;
        }
        elsif ( $line =~ /^VALIDSIG\s+([^\s]+)/ ) {
            $sign_fingerprint = $1;
        }
        elsif ( $line =~ /^ENC_TO\s+([^\s]+)/ ) {
            push @enc_key_ids, decode($1);
            $enc_mails[ @enc_key_ids - 1 ] = "";
        }
        elsif ( $line =~ /^USERID_HINT\s+([^\s]+)\s+(.*)/ ) {
            my ( $hint_key_id, $hint_text ) = ( $1, $2 );
            my $i = 0;
            foreach my $key_id (@enc_key_ids) {
                if ( $key_id eq $hint_key_id ) {
                    $enc_mails[$i] = decode($hint_text);
                }
                ++$i;
            }
        }
        elsif ( $line =~ /^BEGIN_DECRYPTION/ ) {
            $is_encrypted = 1;
        }
        elsif ( $line =~ /^DECRYPTION_OKAY/ ) {
            $enc_ok = 1;
        }
    }

    @sign_mail_aliases = $$gpg_stderr =~ /^gpg:\s+aka\s+"(.*?)"/mg;

    if ( !$self->get_mail_gpg->get_use_long_key_ids ) {
        for ( $sign_key_id, @enc_key_ids ) {
            $_ = substr( $_, -8, 8 ) if defined $_;
        }
    }

    $self->set_is_signed( $is_signed               || 0 );
    $self->set_sign_ok( $sign_ok                   || 0 );
    $self->set_sign_state( $sign_state             || "" );
    $self->set_sign_key_id( $sign_key_id           || "" );
    $self->set_sign_mail( $sign_mail               || "" );
    $self->set_sign_fingerprint( $sign_fingerprint || "" );
    $self->set_sign_mail_aliases( \@sign_mail_aliases );
    $self->set_is_encrypted( $is_encrypted || '0' );

    $self->set_enc_ok( $enc_ok || 0 );
    $self->set_enc_key_ids( \@enc_key_ids );
    $self->set_enc_mails( \@enc_mails );
    $self->set_enc_key_id( $enc_key_ids[0] || "" );
    $self->set_enc_mail( $enc_mails[0]     || "" );

    return $self;
}

sub decode {
    my ($str) = @_;
    return $str if not defined $str;
    $str =~ s/\\x(..)/chr(hex($1))/eg;
    eval { $str = Encode::decode("utf-8", $str, Encode::FB_CROAK) }
        if $] >= 5.008;
    return $str;
}

sub as_string {
    my $self        = shift;
    my %par         = @_;
    my ($no_stdout) = $par{'no_stdout'};

    my ( $method, $string );
    foreach my $attr (
        qw (is_encrypted enc_ok enc_key_id enc_mail
        enc_key_ids enc_mails
        is_signed sign_ok sign_state sign_key_id
        sign_fingerprint sign_mail sign_mail_aliases
        sign_trust gpg_rc )
        ) {
        if ( $attr eq 'sign_mail_aliases' ) {
            foreach my $value ( @{ $self->get_sign_mail_aliases } ) {
                $string
                    .= sprintf( "%-18s: %s\n", "sign_mail_alias", $value );
            }
        }
        elsif ( $attr eq 'enc_key_ids' ) {
            foreach my $value ( @{ $self->get_enc_key_ids } ) {
                $string .= sprintf( "%-18s: %s\n", "enc_key_ids", $value );
            }
        }
        elsif ( $attr eq 'enc_mails' ) {
            foreach my $value ( @{ $self->get_enc_mails } ) {
                $string .= sprintf( "%-18s: %s\n", "enc_mails", $value );
            }
        }
        else {
            $method = "get_$attr";
            my $value = $self->$method;
            $value = "" unless defined $value;
            $string .= sprintf( "%-18s: %s\n", $attr, $value );
        }
    }

    my $stdout = ${ $self->get_gpg_stdout };
    my $stderr = ${ $self->get_gpg_stderr };
    my $status = ${ $self->get_gpg_status };

    for ( $stdout, $stderr, $status ) {
        next unless $_;
        s/\n/\n                    /g;
        s/\s+$//;
    }

    $string .= sprintf( "%-18s: %s\n", "gpg_stdout", $stdout || '' )
        if not $no_stdout;
    $string .= sprintf( "%-18s: %s\n", "gpg_stderr", $stderr || '' );
    $string .= sprintf( "%-18s: %s\n", "gpg_status", $status || '' );

    return $string;
}

sub as_short_string {
    my $self = shift;

    my $string;

    if ( $self->get_is_encrypted ) {
        $string .= "ENC("
            . $self->get_enc_mail . ", "
            . $self->get_enc_key_id . ", "
            . ( $self->get_enc_ok ? "OK" : "NOK" ) . ") - ";
    }
    else {
        $string .= "NOENC - ";
    }

    if ( $self->get_is_signed ) {
        $string .= "SIGN("
            . $self->get_sign_mail . ", "
            . $self->get_sign_key_id . ", "
            . $self->get_sign_state . ") - ";
    }
    else {
        $string .= "NOSIGN - ";
    }

    $string =~ s/ - $//;

    return $string;
}

sub get_sign_trust {
    my $self = shift;

    return $self->{sign_trust} if exists $self->{sign_trust};

    my $trust = $self->get_mail_gpg->get_key_trust(
        key_id => $self->get_sign_key_id );

    return $self->{sign_trust} = $trust;
}

1;

__END__


=head1 NAME

Mail::GPG::Result - Mail::GPG decryption and verification results

=head1 SYNOPSIS

  $result = $mg->verify (
    entity => $entity
  );
  
  ($decrypted_entity, $result) = $mg->decrypt (
    entity => $entity,
  );

  $long_string  = $result->as_string ( ... );
  $short_string = $result->as_short_string;

  $encrypted           = $result->get_is_encrypted;
  $decryption_ok       = $result->get_enc_ok;
  $encryption_key_id   = $result->get_enc_key_id;
  $encryption_mail     = $result->get_enc_mail;
  $enc_key_ids         = $result->get_enc_key_ids;
  $enc_mails           = $result->get_enc_mails;

  $signed              = $result->get_is_signed;
  $signature_ok        = $result->get_sign_ok;
  $signed_key          = $result->get_sign_key_id;
  $signed_fingerprint  = $result->get_sign_fingerprint;
  $trust               = $result->get_sign_trust;
  $signed_mail         = $result->get_sign_mail;
  $signed_mail_aliases = $result->get_sign_mail_aliases;

  $stdout_sref         = $result->get_gpg_stdout;
  $stderr_sref         = $result->get_gpg_stderr;
  $status_sref         = $result->get_gpg_status;
  $gpg_exit_code       = $result->get_gpg_rc;

=head1 DESCRIPTION

This class encapsulates decryption and verification results
of Mail::GPG. You never create objects of this class yourself,
they're all returned by Mail::GPG.

=head1 ATTRIBUTES

This class mainly has a bunch of attributes which reflect the
result of a Mail::GPG operation. You can read these attributes
with B<get>_attribute.

=over 4

=item B<is_encrypted>

Indicates whether an entity was encrypted or not.

=item B<enc_ok>

Indicates whether decryption of an entity was successful or not.

=item B<enc_key_id>

The recipient's key id of an encrypted mail. This is the first
key reported by gnupg in case the mail has more than one
recipient.

=item B<enc_mail>

The recipient's mail address of an encrypted mail. This is the first
mail address reported by gnupg in case the mail has more than one
recipient.

=item B<enc_key_ids>

This is an array reference of key ids in case the mail is encrypted
for several recipients.

=item B<enc_mails>

This is an array reference of the correspondent recipient mail adresses.
Entries may be empty, if gnugpg didn't report the mail address for
a specific key.

=item B<is_signed>

Indicates whether an entity was signed or not.

=item B<sign_ok>

Indicates whether the signature could be verified successfully or not.

=item B<sign_state>

Gives more details about the signature status. May have one of the following
valufes: GOOD, EXP, EXPKEY, REVKEY and BAD. Please refer to gnupg's DETAILS
file for details about the meaning of these values.

=item B<sign_key_id>

The key ID of the sender who signed an entity.

=item B<sign_fingerprint>

Key fingerprint of the sender who signed an entity.

=item B<sign_trust>

Returns how much you trust the signers key. Refer to Mail::GPG->get_key_trust
for a list of known levels and their meaning.

=item B<sign_mail>

The primary mail address of the sender who signed an entity.

=item B<sign_mail_aliases>

A reference to a list of the signer's mail alias addresses.

=item B<gpg_stdout>

This is reference to a scalar containing gpg's STDOUT output.

=item B<gpg_stderr>

This is reference to a scalar containing gpg's STDERR output.

=item B<gpg_rc>

Exit code of the gpg program. Don't rely on this, use the other
attributes to check wether operation was successful resp.
a verification went ok.

=back

=head1 METHODS

There are only two methods, both are for debugging purposes:

=head2 as_string

  $string = $result->as_string ( no_stdout => $no_stdout )

Returns a printable string version of the object.

=over 4

=item no_stdout

If this option is set, gpg's stdout is ommitted in the
string represenation.

=back

=head2 as_short_string

  $short_string = $result->as_short_string;
  
Returns a very short string representation, without any
gpg output, arranged in one line.

=head1 AUTHOR

Joern Reder <joern AT zyn.de>

=head1 COPYRIGHT

Copyright (C) 2004-2006 by Joern Reder, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Mail::GPG, perl(1).

=cut






