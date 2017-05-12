# -*- perl -*-
#

package Mail::IspMailGate::Filter::Packer;

require 5.004;
use strict;

require Mail::IspMailGate::Filter;

@Mail::IspMailGate::Filter::Packer::ISA = qw(Mail::IspMailGate::Filter::InOut);

sub getSign { "X-ispMailGate-Packer"; };

#####################################################################
#
#   Name:     mustFilter
#
#   Purpose:   determines wether this message must be filtered and
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
    my $cfg = $Mail::IspMailGate::Config::config;

    if (!$self->SUPER::mustFilter($entity)) {
	return 0;
    }

    my($packer) = $self->{'packer'};
    my($direction) = $self->{'recDirection'};
    my($head) = $entity->head();
    if ($direction eq 'neg') {
	my $prevPack = $head->mime_attr('X-IspMailGate-Packer-Type');
	$prevPack = '' unless defined $prevPack;
	if(exists($cfg->{'packer'}->{$prevPack})) {
	    $packer=$prevPack;
	} else {
	    return 0;
	}
    } else {
	$head->mime_attr('X-IspMailGate-Packer-Type', $packer);
    }
    $self->{'recPacker'} = $packer;

    return 1;
}


#####################################################################
#
#   Name:     hookFilter
#
#   Purpse:   a function which is called after the filtering process
#
#   Inputs:   $self   - This class
#             $entity - the whole message
#
#   Returns:  errormessage if any
#
#####################################################################

sub hookFilter ($$) {
    my($self, $entity) = @_;
    my($direction) = $self->{'recDirection'};
    $self->SUPER::hookFilter($entity);
    if ($direction eq 'neg') {
	$entity->head()->delete('X-Ispmailgate-Packer-Type');
	$entity->head()->delete('X-Ispmailgate-Packer');
    }
    delete $self->{'recPacker'};
    '';
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

sub filterFile ($$$) {
    my ($self, $attr) = @_;
    my $cfg = $Mail::IspMailGate::Config::config;

    my ($ret) = 0;
    if($ret = $self->SUPER::filterFile($attr)) {
	return $ret;
    }
    my $head = $attr->{'head'};
    my $body = $attr->{'body'};
    my $parser = $attr->{'parser'};
    my $globHead = $attr->{'globHead'};
    my $ifile = $body->path();
    my $ofile = $parser->output_path($head);
    my $packer = $self->{'recPacker'};
    my $direction = $self->{'recDirection'};
    my $sign = '';

    if((!defined($packer)) || (!defined($direction))) {
	return "Invalid invoke";
    }
    return "Unknown packer: $packer"
	unless exists($cfg->{'packer'}->{$packer});
    my $cmd = $cfg->{'packer'}->{$packer}->{$direction};
    $cmd =~ s/\$(\w+)/$cfg->{$1}/g;

    if ($ret=system("$cmd " . quotemeta($ifile) . " >" . quotemeta($ofile))) {
	return $ret;
    } else {
	$body->path($ofile);
    }
    $self->setEncoding({('head' => $head, 'direction' => $direction)});
    '';
}

#####################################################################
#
#   Name:     setEncoding
#
#   Purpse:   set a reasonable encoding type, for the filtered mail
#
#   Inputs:   $self   - This class
#             $attr   - the attributes
#                       'head'
#                       'direction'
#
#   Returns:  error message, if any
#
#####################################################################

sub setEncoding ($$$) {
    my ($self, $attr) = @_;
    my ($head) = $attr->{'head'};
    my ($direction) = $attr->{'direction'};
    my ($actuEnc) = $head->mime_attr('Content-Transfer-Encoding');
    if (!defined($actuEnc)) {
	$actuEnc = '';
    }
    my ($prevEnc) = $head->mime_attr('X-ispMailGate-Packer-PEncoding');
    if (!defined($prevEnc)) {
	$prevEnc = '';
    }
    my ($newEnc) = '';

    if ($direction eq 'neg') {
	if ($prevEnc) {
	    $newEnc = $prevEnc;
	} else {
	    # Assume base64 to go the sure way
	    $newEnc = "base64";
	}
	$head->delete('X-IspMailgate-Packer-PEncoding');
    }  else {
	$newEnc = "base64";
	if ($actuEnc) {
	    $head->replace("X-ispMailGate-Packer-PEncoding", $actuEnc);
	} else {
	    # Assume base64 as encoding if not clear
	    $head->replace("X-ispMailGate-Packer-PEncoding", "base64");
	}
    }
    $head->replace("Content-Transfer-Encoding", $newEnc);

    '';
}


sub IsEq ($$) {
    my($self, $cmp) = @_;
    $cmp->isa('Mail::IspMailGate::Filter::Packer') &&
	$self->{'packer'} eq $cmp->{'packer'};
}

$Mail::IspMailGate::Filter::VERSION = "1.000";

1;

__END__

=pod

=head1 NAME

Mail::IspMailGate::Filter::Packer  - Compressing emails 

=head1 SYNOPSIS

 # Create a Packer object for compression
 my($packer) = Mail::IspMailGate::Filter::Packer->new({
     'packer' => 'gzip',
     'direction' => 'pos'
 });

 # Create a Packer object for decompression
 my($packer) = Mail::IspMailGate::Filter::Packer->new({
     'packer' => 'gzip',
     'direction' => 'neg'
 });

 # Create a Packer object for automatic compression/decompression
 my($packer) = Mail::IspMailGate::Filter::Packer->new({
     'packer' => 'gzip'
 });

 # Call the filter
 my($res) = $packer->doFilter({
     'entity' => $entity,  # the MIME::Entity which is to be filtered
     'parser' => $parser
 });


=head1 VERSION AND VOLATILITY

    $Revision 1.0 $
    $Date 1998/04/05 18:46:12 $

=head1 DESCRIPTION

This class is the Packer (compressing emails) derived from
L<Mail::IspMailGate::Filter> (refer to the manpage).
You can specify the attribute 'direction' with the constructor, so you can
force to act only in one direction: 'pos' only compressing and 'neg' only for
decompressing. If you specify no direction it will be guessed in the function
I<mustFilter>. If the message
has never been Filter by Packer it chooses 'pos', else it checks in which direction
this has happened and chooses the opposite. You can also specify the attribute 'packer'
in the constructor to set the comressor type for direction 'pos'.
The supported packer are configured in I<$cfg->{'packer'}> in each
direction with a template for the I<system()> command.
It overrides the function I<filterFile>, I<mustFilter>, I<hookFile> and
I<getSign>.


=head1 PUBLIC INTERFACE

=over 4

=item I<mustFilter ENTITY>

It determines the direction as described in DESCRIPTION and stores 
it in $self->{'recDirection'}. If the direction is 'neg' it also tries to
determine the packer which was used for the compressing to guarantee a correct
decompressing. If this failes it returns 0 and the email will not be decompressed. 
The same happens if this obejct has the attribute 'direction' and this attribute equals
the sign in the MIME-header which is set in I<hookFilter>. The packer which is to
use (if possible) is stored in $self->{'recPacker'}.

=item I<filterFile FILENAME>

Does the (de)compressing of a part of the MIME-message depending on 
$self->{'recDirection'} and $self->{'recPacker'}.

=item I<hookFilter ENTITY>

This function sets the direction in the header of the message as well which packer was
used.

=back

Additionaly we have the function:

=over 4

=item I<sub setEncoding ATTR>

Where the attribute 'direction' specifies in which direction Packer acts at the 
moment and 'head' is the head of a subpart of the whole entity. This function 
sets in 'head' the  'Content-Transfer-Encoding'. It is set to base64 if the 
direction is 'pos' else it restores the old one which is stored in 
'X-ispMailGate-Packer-PEncoding'. If this cannot be determined we assume base64. 
It is called by the overriden I<filterFile> to guarantee a correct encoding of
the email.

=cut







