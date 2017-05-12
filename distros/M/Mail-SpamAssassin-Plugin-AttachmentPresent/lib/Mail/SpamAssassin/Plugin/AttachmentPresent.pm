# <@LICENSE>
#   Copyright 2016 Web2All B.V.
#
#   This Plugin is free software; you can redistribute 
#   it and/or modify it under the same terms as Perl 5.18.1.
#
#   you may not use this file except in compliance with the License.
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# </@LICENSE>

# Version control:
# $Revision: 218 $
# $Author: merijn $
# $Date: 2017-03-01 11:11:37 +0100 (Wed, 01 Mar 2017) $

=head1 NAME

Mail::SpamAssassin::Plugin::AttachmentPresent - SpamAssassin plugin to score mail based on attachments 
including attachments inside archives.

=head1 SYNOPSIS

  loadplugin Mail::SpamAssassin::Plugin::AttachmentPresent
  body RULENAME eval:attachmentpresent_archive_count()
  body RULENAME eval:attachmentpresent_file_count()

=head1 DESCRIPTION

Get information about attached files, including inside archives.
Only supports Zip right now.

=head1 CONFIGURATION

None

=head1 INSTALL

=over

=item Install the required Perl modules:

  Encode::MIME::Header;
  Archive::Zip
  IO::String
  Mail::SpamAssassin::Plugin::AttachmentPresent

Should already be installed by spamassassin

=item Configure spamassassin

Typically in local.cf, include lines:
  loadplugin Mail::SpamAssassin::Plugin::AttachmentPresent

  body HAS_JS_FILES eval:attachmentpresent_file_count('js')
  describe HAS_JS_FILES The e-mail has attached javascript files (or inside archives)
  score HAS_JS_FILES 0.001

=back

=cut

package Mail::SpamAssassin::Plugin::AttachmentPresent;

use strict;
use warnings;

use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::Logger;

use Encode;
use Encode::MIME::Header;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use IO::String;

use base qw(Mail::SpamAssassin::Plugin);
our $VERSION = '1.05';

our $LOG_FACILITY = 'AttachmentPresent';

# Fields:
# mailsa - Mail::SpamAssassin instance
sub new {
  my ($class, $mailsa) = @_;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new($mailsa);
  bless($self, $class);
  
  Mail::SpamAssassin::Logger::add_facilities($LOG_FACILITY);
  
  $self->register_eval_rule('attachmentpresent_archive_count');
  $self->register_eval_rule('attachmentpresent_file_count');
  
  return $self;
}


sub l {
  Mail::SpamAssassin::Logger::dbg("$LOG_FACILITY: " . join('', @_));
}

sub _zip_error_handler(){
  l("_zip_error_handler: ".$_[0]);
}

sub _build_attachment_tree {
  my ($self,$pms) = @_;
  
  # init storage
  $pms->{'attachment_data'}={
    'files' => [],
    'archives' => []
  };
  l('_build_attachment_tree');
  # $pms->{msg} Mail::SpamAssassin::Message
  foreach my $part ($pms->{msg}->find_parts(qr/.*/, 1)) {
    # $part Mail::SpamAssassin::Message::Node
    # now we get all parts which are leaves (so text parts and attachments, not multiparts)
    l('_build_attachment_tree->part');
    # we ignore all parts which are part of the text body
    
    # For zipfiles, find out whats in them
    # Content-Type: application/zip;
    # Content-Transfer-Encoding: base64
    my $ctt = $part->get_header('content-type') || '';
    # Mail::SpamAssassin::Message::Node has _decode_header() method, but it doesnt decode 
    # Content-* headers and thus the filename in the Content-Type header is not decoded :(
    $ctt=Encode::decode('MIME-Header', $ctt);
    # $ctt might contain wide characters now

    my $cte = lc($part->get_header('content-transfer-encoding') || '');
    
    l('_build_attachment_tree->part: content-type: '.$ctt);
    
    # consider the attachment a file if it has a name
    my $attachment_filename='';
    if($ctt =~ m/name\s*=\s*"?([^";]*)"?/is){
      $attachment_filename=$1;
      # lets be sure and remove any whitespace from the end
      $attachment_filename =~ s/\s+$//;
      l('_build_attachment_tree->part: part has name '.$attachment_filename);
      push(@{$pms->{'attachment_data'}->{'files'}},$attachment_filename);
    }else{
      # fallback check in Content-Disposition header
      # some (spam) has Content-Disposition with filename but no filename in Content-Type,
      # but mail clients will still display the attachment.
      my $cdp = $part->get_header('content-disposition') || '';
      # Content-* headers and thus the filename in the Content-Type header is not decoded :(
      $cdp=Encode::decode('MIME-Header', $cdp);
      # $cdp might contain wide characters now
      if($cdp =~ m/name\s*=\s*"?([^";]*)"?/is){
        $attachment_filename=$1;
        # lets be sure and remove any whitespace from the end
        $attachment_filename =~ s/\s+$//;
        l('_build_attachment_tree->part: part has name (in Content-Disposition) '.$attachment_filename);
        push(@{$pms->{'attachment_data'}->{'files'}},$attachment_filename);
      }
    }
    
    # now process attachments
    
    # Zip
    if ($ctt =~ /zip/i && $cte =~ /^base64$/){
      # seems to be a zip attachment
      l('_build_attachment_tree->part found Zip archive: '.$ctt);
      # how much we grab? for now only 500kb, bigger files will just not
      # be properly parsed as zip files
      my $num_of_bytes=512000;
     
      my $zip_binary_head=$part->decode($num_of_bytes);
      # use Archive::Zip
      my $SH = IO::String->new($zip_binary_head);

      Archive::Zip::setErrorHandler( \&_zip_error_handler );
      my $zip = Archive::Zip->new();
      if($zip->readFromFileHandle( $SH ) != AZ_OK){
        l("_build_attachment_tree: cannot read zipfile $attachment_filename");
        # as we cannot read it its not a zip (or too big/corrupted)
        # so skip processing.
        next;
      }
      
      # ok seems to be a zip
      push(@{$pms->{'attachment_data'}->{'archives'}},$attachment_filename);
      
      # list all files in the zip file and add them as a file
      my @members = $zip->members();
      foreach my $member (@members){
        push(@{$pms->{'attachment_data'}->{'files'}},$member->fileName());
      }
    }

  }

}

=head1 FUNCTIONS

=over

=item $int = attachmentpresent_archive_count([$ext[, $more_than]])

Returns the amount of recognised archive files inside
this message. Currently only Zip files are recognised.
If the file could not be parsed because it was too big
or corrupted, its not counted.

Optionally you can filter on extension, where $ext should
be set to the extension to filter on. Eg. $ext='zip'

=cut

sub attachmentpresent_archive_count {
  my $self = shift;
  my $pms = shift;
  my $rendered = shift;# body tests: fully rendered message as array reference
  my $extension = shift;
  my $larger_than = shift || 0;

  l('attachmentpresent_archive_count ('.($extension ? $extension : 'all').')'.($larger_than ? ' more than '.$larger_than : ''));
  
  # make sure we have attachment data read in.
  if (!exists $pms->{'attachment_data'}) {
    $self->_build_attachment_tree($pms);
  }

  my $count=0;
  if($extension){
    foreach my $archive (@{$pms->{'attachment_data'}->{'archives'}}){
      if($archive =~ m/\.$extension$/i){
        $count++;
      }
    }
  }else{
    $count=scalar (@{$pms->{'attachment_data'}->{'archives'}});
  }
  
  l('attachmentpresent_archive_count actual count: '.$count);
  l('attachmentpresent_archive_count: '.(($count > $larger_than) ? 1 : 0));
  return (($count > $larger_than) ? 1 : 0);
}

=item $int = attachmentpresent_file_count([$ext[, $more_than]])

Returns the amount of files inside this message. It also
counts files inside recognised archive files. Currently only 
Zip files are recognised.

Optionally you can filter on extension, where $ext should
be set to the extension to filter on. Eg. $ext='js'

Optionally you can specify the minimum amount of files
(of the given type) which will be required to trigger the rule.
By default $more_than is 0, so at least one file of the
given type is needed, but you can set it to 4 if you want the 
rule to trigger when at least 5 files are present.

=cut

sub attachmentpresent_file_count {
  my $self = shift;
  my $pms = shift;
  my $rendered = shift;# body tests: fully rendered message as array reference
  my $extension = shift;
  my $larger_than = shift || 0;

  l('attachmentpresent_file_count ('.($extension ? $extension : 'all').')'.($larger_than ? ' more than '.$larger_than : ''));
  
  # make sure we have attachment data read in.
  if (!exists $pms->{'attachment_data'}) {
    $self->_build_attachment_tree($pms);
  }

  my $count=0;
  if($extension){
    foreach my $file (@{$pms->{'attachment_data'}->{'files'}}){
      if($file =~ m/\.$extension$/i){
        $count++;
        l('attachmentpresent_file_count found matching file: '.$file);
      }
    }
  }else{
    $count=scalar (@{$pms->{'attachment_data'}->{'files'}});
  }
  
  l('attachmentpresent_file_count actual count: '.$count);
  l('attachmentpresent_file_count: '.(($count > $larger_than) ? 1 : 0));
  return (($count > $larger_than) ? 1 : 0);
}

=back
=cut

1;
