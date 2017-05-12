=begin TODO

  - override "display" to accept V=UploadField
     => would redirect to attached file

  - support for multiple files under same field

=end TODO

=cut


package File::Tabular::Web::Attachments;
use base 'File::Tabular::Web';
use strict;
use warnings;

use File::Path;
use Scalar::Util qw/looks_like_number/;


#----------------------------------------------------------------------
sub app_initialize {
#----------------------------------------------------------------------
  my $self = shift;

  $self->SUPER::app_initialize;

  # field names specified as "upload fields" in config
  $self->{app}{upload_fields} = $self->{app}{cfg}->get('fields_upload');
}


#----------------------------------------------------------------------
sub open_data {
#----------------------------------------------------------------------
  my $self = shift;

  $self->SUPER::open_data;

  # upload fields must be present in the data file
  my %data_headers = map {$_ => 1} $self->{data}->headers;
  my @upld = keys %{$self->{app}{upload_fields}};
  my $invalid = join ", ", grep {not $data_headers{$_}} @upld;
  die "upload fields in config but not in data file: $invalid" if $invalid;
}


#----------------------------------------------------------------------
sub before_update { # 
#----------------------------------------------------------------------
  my ($self, $record) = @_;

  my @upld = keys %{$self->{app}{upload_fields}};

  # remember paths and names of old files (in case we must delete them later)
  foreach my $field (grep {$record->{$_}} @upld) {
    $self->{old_name}{$field} = $record->{$field};
    $self->{old_path}{$field} = $self->upload_fullpath($record, $field);
  }

  # call parent method
  $self->SUPER::before_update($record);

  # find out about next autoNum (WARN: breaks encapsulation of File::Tabular!)
  if ($self->{cfg}->get('fields_autoNum')) {
    $self->{next_autoNum} = $self->{data}{autoNum};
  }

  # now deal with file uploads
  foreach my $field (@upld) {
    if (my $remote_name = $self->param($field)) {
      $self->do_upload_file($record, $field, $remote_name);
    }
    else { # upload is "" ==> must restore old name in record
      $record->{$field} = $self->{old_name}{$field} || "";
    }
  };
}

#----------------------------------------------------------------------
sub do_upload_file { # 
#----------------------------------------------------------------------
  my ($self, $record, $field) = @_;

  my $remote_name = $self->param($field)
    or return;  # do nothing if empty

  my $src_fh;

  if ($self->{modperl}) {
    require Apache2::Request;
    require Apache2::Upload;
    my $req  = Apache2::Request->new($self->{modperl});
    my $upld = $req->upload($field) or die "no upload object for field $field";
    $src_fh = $upld->fh;
  }
  else {
    my @upld_fh = $self->{cgi}->upload($field); # may be an array 

    # TODO : some convention for deleting an existing attached file
    # if @upload_fh == 0 && $remote_name =~ /^( |del)/ {...}

    # no support at the moment for multiple files under same field
    @upld_fh < 2  or die "several files uploaded to $field";
    $src_fh = $upld_fh[0];
  }

  # compute server name and server path
  $record->{$field} 
                = $self->generate_upload_name($record, $field, $remote_name);
  my $path      = $self->upload_fullpath($record, $field);
  my $old_path  = $self->{old_path}{$field};

  # avoid clobbering existing files
  not -e $path or $path eq $old_path
    or die "upload $field : file $path already exists"; 

  # check that upload path is unique
  not exists $self->{results}{uploaded}{$path}
    or die "multiple uploads to same server location : $path";

  # remember new and old path
  $self->{results}{uploaded}{$path} = {field    => $field,
                                       old_path => $old_path};

  # do the transfer
  my ($dir) = ($path =~ m[^(.*)[/\\]]);
  -d $dir or mkpath $dir; # will die if can't make path
  open my $dest_fh, ">$path.new" or die "open >$path.new : $!";
  binmode($dest_fh), binmode($src_fh);
  my $buf;
  while (read($src_fh, $buf, 4096)) { print $dest_fh $buf;}

  $self->{msg} .= "file $remote_name uploaded to $path<br>";
}


#----------------------------------------------------------------------
sub after_update {
#----------------------------------------------------------------------
  my ($self, $record) = @_;

  my $uploaded = $self->{results}{uploaded};

  # rename uploaded files and delete old versions
  while (my ($path, $info) = each %$uploaded) {
    my $field    = $info->{field};
    my $old_path = $info->{old_path};

    $self->before_delete_attachment($record, $field, $old_path)
      if $old_path;

    rename "$path.new", "$path" or die "rename $path.new => $path : $!";

    if ($old_path) {
      if ($old_path eq $path) {
	$self->{msg} .= "old file $old_path has been replaced<br>";
      }
      else {
	my $unlink_ok = unlink $old_path;	
	$self->{msg} .= $unlink_ok ? "<br>removed old file $old_path<br>" 
                                   : "<br>remove $old_path : $^E<br>";
      }
    }
    $self->after_add_attachment($record, $field, $path);
  }
}




#----------------------------------------------------------------------
sub rollback_update { # undo what was done by "before_update"
#----------------------------------------------------------------------
  my ($self, $record) = @_;
  my $uploaded = $self->{results}{uploaded};
  foreach my $path (keys %$uploaded) {
    unlink("$path.new");
  }
}




#----------------------------------------------------------------------
sub after_delete {
#----------------------------------------------------------------------
  my ($self, $record)= @_;

  $self->SUPER::after_delete($record);

  # suppress files attached to deleted record
  my @upld = keys %{$self->{app}{upload_fields}};
  foreach my $field (@upld) {
    my $path = $self->upload_fullpath($record, $field) 
      or next;

    $self->before_delete_attachment($record, $path);
    my $unlink_ok = unlink "$path";	
    my $msg = $unlink_ok ? "was suppressed" : "couldn't be suppressed ($!)";
    $self->{msg} .= "<br>Attached file $path $msg";
  }
}


#----------------------------------------------------------------------
sub generate_upload_name {
#----------------------------------------------------------------------
  my ($self, $record, $field, $remote_name)= @_;

  # just keep the trailing part of the remote name
  $remote_name =~ s{^.*[/\\]}{};
  return $remote_name;
}


#----------------------------------------------------------------------
sub upload_path { 
#----------------------------------------------------------------------
  my ($self, $record, $field)= @_;

  return "" if not $record->{$field};

  # get the id of that record; if creating, cheat by guessing next autoNum
  my $autonum_char = $self->{data}{autoNumChar};
  (my $key = $self->key($record)) =~ s/$autonum_char/$self->{next_autoNum}/;

  my $dir = looks_like_number($key) ? sprintf "%05d/", int($key / 100)
                                    : "";

  return "${field}/${dir}${key}_$record->{$field}";
}


#----------------------------------------------------------------------
sub upload_fullpath { 
#----------------------------------------------------------------------
  my ($self, $record, $field)= @_;
  my $path = $self->upload_path($record, $field);
  return $path ? "$self->{app}{dir}$path" : "";
}


#----------------------------------------------------------------------
sub download { # default implementation; override in subclasses
#----------------------------------------------------------------------
  my ($self, $record, $field)= @_;

  return $self->upload_path($record, $field); # relative to app URL
}




sub after_add_attachment     {}
sub before_delete_attachment {}







1;

__END__


=head1 NAME

File::Tabular::Web::Attachments - Support for attached document in a File::Tabular::Web application

=head1 DESCRIPTION

This subclass adds support for attached documents in a 
L<File::Tabular::Web|File::Tabular::Web> application.
One or several fields of the tabular file may hold 
names of attached documents; these documents can be 
downloaded from or uploaded to the Web server.


=head2 Phases of file upload

When updating a record with attached files,
files are first transfered to temporary locations by the 
L</before_update> method.
Then the main record is updated as usual through the 
L<parent method|File::Tabular::Web/update>.
Finally, files are renamed to their final location
by the L</after_update> method.
If the update operation failed, files are destroyed
by the L</rollback_update> method.


=head1 CONFIGURATION FILE

There is one single addition to the configuration file.

=head2 [fields]

  upload <field_name_1>
  upload <field_name_2>
  ...

Declares C<< field_name_1 >>, C<< field_name_2 >>, etc. 
to be upload fields.


=head1 WRITING TEMPLATES

=head2 Downloading attachments

To link to an attached file, use the L</download> method :

  [% FOREACH record IN found.records %]
    <A HREF="[% self.download(record, 'AttachedField') %]">
       download document [%- record.AttachedField -%]
    </A>
    <HR>
  [% END # FOREACH %]

=head2 Uploading attachments

To upload an attachment, use a input element of type C<FILE>,
within an HTML form encoded as C<multipart/form-data>. Since
HTML file input elements cannot have an initial value, it
may be a good practice to indicate if an attachment is already
present in this field and if so, insert a download link :

  [% SET record = found.records.0 %]
  <FORM METHOD="POST" ENCTYPE="MULTIPART/FORM-DATA">
    <INPUT NAME="Field1" VALUE="[% record.Field1 | html %]"><br>
    <INPUT NAME="Field2" VALUE="[% record.Field2 | html %]"><br>
    ..
    <INPUT NAME="AttachedField1" TYPE="FILE">
      [%- IF record.AttachedField1; # if an attachment is already present  -%]
       (current attachment :
        <A HREF="[% self.download(record, 'AttachedField1') %]">
         [%- record.AttachedField1 -%]
        </A>)

    ...
  </FORM>


=head1 METHODS

=head2 app_initialize

Calls the L<parent method|File::Tabular::Web/app_initialize>.
In addition, parses the C<upload> variable in C<< [fields] >> section,
putting the result in the hash ref
C<< $self->{app}{upload_fields} >>.


=head2 open_data

Calls the L<parent method|File::Tabular::Web/open_data>.
In addition, checks that fields declared as upload
fields are really present in the data.

=head2 before_update

Calls the L<parent method|File::Tabular::Web/before_update>.
In addition, uploads submitted files to a temporary location
in the application directory.

=head2 after_update

Calls the L<parent method|File::Tabular::Web/after_update>,
then renames the uploaded files to their final location.

=head2 rollback_update

Unlinks the uploaded files.


=head2 after_delete

Calls the L<parent method|File::Tabular::Web/after_delete>,
then suppresses files attached to the deleted record.


=head2 do_upload_file

Internal method for implementing the file transfer.
Checks that we are not going to clobber an existing
file on the server.


=head2 generate_upload_name

  my $name = $self->generate_upload_name($record, $field_name, $remote_name)

Returns the name that will be stored in the record field
for the attached document. The actual path for that
document on the server will be generated through
method L</upload_fullpath>.
The default implementation returns the last 
part of C<$remote_name> (removing initial directories).

=head2 upload_path

  my $path = $self->upload_path($record, $fieldname)

Returns a I<relative> path to the attached document.
The default implementation takes the numeric id of the record
(if any) and concatenates it with the name generated by
L</generate_upload_name>;
furthermore, this is put into subdirectories by ranges 
of 100 numbers : so for example file C<foo.txt> in 
record with id C<1234> will become
C<00012/1234_foo.txt>.
This behaviour may be redefined in subclasses.

=head3 upload_fullpath

  my $fullpath = $self->upload_fullpath($record, $fieldname)

Returns a full pathname to the attached document.
This is the location where the file is stored on the server.
The default value is the concatenation of 
C<< $self->{app}{dir} >> and C<< $self->upload_path($record, $field) >>.



=head3 download

  my $url = $self->download($record, $fieldname)

Returns an url to the attached document, relative
to the application url. So it can be used in templates
as follows

  [% IF record.fieldname %]
    <a href="[% self.download(record, 'fieldname') %]">
       Attached document : [% record.fieldname %]
    </a>
  [% END; # IF %]



=head2 hooks before / after adding or deleting attachments

  $self->after_add_attachment($record, $field, $path)
  $self->before_delete_attachment($record, $field, $path)

These methods are called each time an attachment is
added or deleted. The default implementation is empty.
Subclasses may add code for example for converting the file
or indexing it (see L<File::Tabular::Web::Attachments::Indexed>).



=head1 AUTHOR

Laurent Dami, C<< <laurent.d...@justice.ge.ch> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Laurent Dami, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
