package Mail::Audit::Attach;

# Copyright (c) 2002-2010 Christian Renz <crenz@web42.com>. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;
use vars qw($VERSION @ISA $ERROR);
use MIME::Entity;
use File::Spec;

$VERSION = '0.96';

@ISA = qw(MIME::Entity);

$ERROR = '';

# constructor

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = $opts{ENTITY};
    $self->{MAIL_AUDIT_OBJ} = $opts{CREATOR};

    bless $self, $class;
}

# properties

sub error {
    return $ERROR;
}

sub _set_error {
    my ($error) = @_;

    $ERROR = $error;

    return undef;
}

sub size {
    my $self = shift;
    my $body = $self->bodyhandle;

    if (defined($body->path)) {
	return -s $body->path;
    } else {
	return length($body->as_string);
    }
}

sub filename {
    my $self = shift;

    return $self->head->recommended_filename;
}

sub safe_filename {
    my $self = shift;
    my $filename = $self->filename;

    $filename =~ s,([/:;|]|\s|\\|\[|\])+,_,g;

    return ($filename || 'attachment');
}

# actions

sub remove {
    my $self = shift;

    return _remove_part($self->{MAIL_AUDIT_OBJ}, $self);
}

# Internal helper function that walks through MIME parts to remove a part.
sub _remove_part {
    my $msg = shift;
    my $part = shift;
    local $_;
    
    foreach ($msg->parts) {
	if ($_ == $part) {
	    $part->bodyhandle->purge;
	    $msg->parts([ grep { $_ != $part } $msg->parts ]);
	    return 1;
	} elsif ($_->parts > 0) {
	    return _remove_part($_, $part);
	}
    }

    return undef;
}

sub save {
    my $self = shift;
    my $location = shift || File::Spec->curdir;
    my $filename = $self->safe_filename;
    my $n = 1;
    local $_;

    if (-d $location) {
	$filename = File::Spec->catfile($location, $self->safe_filename);
    } else {
	$filename = $location;
    }

    if (-e $filename) {
	while (-e "$filename.$n") {
	    $n++;
	}

	$filename = "$filename.$n";
    }

    my $io = $self->open("r") 
	or return _set_error("Can't open internal bodyhandle");
    open(SAVE, ">$filename")
	or return _set_error("Can't save to '$filename': $!\n");
    while (defined($_ = $io->getline)) {
	print SAVE $_;
    }
    close(SAVE);
    $io->close;

    return $filename;
}

1;

package Mail::Audit;

use MIME::Entity;
use MIME::Head;

sub num_attachments {
    my $self = shift;
    my $count = 0;
    local $_;

    if (UNIVERSAL::isa($self, "MIME::Entity")) {
	foreach ($self->parts_DFS) {
	    $count++
		if (defined $_->head->recommended_filename());
	}

	return $count;
    } else {
	return 0;
    }
}

sub attachments {
# TODO: walk the tree ourself and save the parent instead of CREATOR.
    my $self = shift;
    local $_;

    if (UNIVERSAL::isa($self, "MIME::Entity")) {
	my @entities = grep { defined $_->head->recommended_filename } 
	                    $self->parts_DFS;
        my $attachments = [];
        foreach (@entities) {
	    push @$attachments, Mail::Audit::Attach->new(ENTITY => $_,
							 CREATOR => $self);
	}

        return $attachments;
    } else {
	return undef;
    }
}

sub remove_attachments {
    my $self = shift;
    my %opts = @_;

    if (UNIVERSAL::isa($self, "MIME::Entity")) {
	return _remove_attachments($self, %opts);
    } else {
	return undef;
    }
}

# Internal helper function that walks through MIME parts to remove
# attachments
sub _remove_attachments {
    my $msg = shift;
    my %opts = @_;
    my $count = 0;
    local $_;

    my @parts = $msg->parts;
    foreach my $part (@parts) {
	if (defined $part->head->recommended_filename()) {
	  COND: {
	      last COND if (defined($opts{mime_type}) &&
			    $part->mime_type !~ $opts{mime_type});
	      last COND if (defined($opts{filename}) &&
			    $part->filename !~ $opts{filename});
	      last COND if (defined($opts{bigger_than}) && 
			    $part->size >= $opts{smaller_than});
	      last COND if (defined($opts{bigger_than}) &&
			    $part->size <= $opts{bigger_than});

	      $part->bodyhandle->purge;
	      $msg->parts([ grep { $_ != $part } $msg->parts ]);
	      $count++;
	  }
        } elsif ($part->parts > 0) {
            $count += _remove_attachments($part, %opts);
        }
    }

    return $count;
}



1;

__END__

=encoding utf-8

=head1 NAME

Mail::Audit::Attach - Mail::Audit plugin for attachment handling.

=head1 SYNOPSIS

  use Mail::Audit qw(Attach);

  my $mail = Mail::Audit->new;

  # ...

  my $num_attachment = $mail->num_attachments;
  my $attachments = $mail->attachments;

  remove_attachments(filename => "\.(exe|scr|pif)",
		     smaller_than => 20000);

  $mail->remove_attachments(mime_type => "text/html");

  foreach (@$attachments) {
      $_->save($attachdir) 
	  if ($_->mime_type =~ |^image/|);
      $_->remove 
	  if ($_->filename =~ |\.(vcf)$|);
  }

  $mail->make_singlepart; # if possible

=head1 DEFINITION

For the purpose of this plugin, an attachment is a MIME part that
has a filename. Files attached to non-MIME messages will not be
discovered.

=head1 DESCRIPTION

This is a Mail::Audit plugin which provides easy access to files
attached to mail messages. Besides Mail::Audit, it requires the
C<MIME::Entity> module.

=head2 CONSTRUCTOR

=over 4

=item C<new>

This constructor is called by L<Mail::Audit>; it should not be necessary
to create a Mail::Audit::Attach object manually.

=back

=head2 METHODS IN MAIL::AUDIT

=over 4

=item C<num_attachments>

Returns the number of attachments found

=item C<attachments>

Returns a reference to a list of attachment objects

=item C<error>

Returns a string with an error message (if an error ocurred).

=item C<remove_attachments>

Removes attachments from the mail that match the criteria specified
via the options, or all, if no options are specified. Currently, the
following options (hash keys) are supported:

=over 4

=item C<mime_type>

=item C<file_name>

Specify a regular expression; attachments whose MIME type or filename
matches this expression are removed.

=item C<smaller_than>

=item C<bigger_than>

Specify file size limits; attachments smaller or bigger than these
limits are removed.

=back

An attachment must match B<all> of the criteria to be removed. Returns
the number of attachments removed.

=back

=head2 ATTACHMENT PROPERTIES

The attachments are a subclass of C<MIME::Entity>. Check out
L<MIME::Entity|MIME::Entity> to learn about useful methods like
C<mime_type> or C<bodyhandle> that are inherited.

=over 4

=item C<size>

Returns the size of the attached file.

=item C<filename>

Returns the original filename given in the MIME headers.

=item C<safe_filename>

Returns the filename, with /\:;[]| and whitespace replaced by
underscores, or 'attachment' if the original filename is empty.

=back

=head2 ATTACHMENT ACTIONS

=over 4

=item C<remove>

Removes the attachment, ie. detaches the corresponding MIME entity and
purges the body data.

=item C<save($location)>

Saves the attachment as a file in C<$location>. If C<$location> is a
directory (ie if C<-d $location>), C<save> uses C<safe_filename> to
store the file inside that directory, else C<$location> is assumed to
be a fully-qualified path with filename.

In both cases, C<save> checks whether the target file exists and
appends '.n' to the filename, with n being an integer that leads to a
unique filename, if necessary.

Returns the filename used to save the file, or undef if an error
ocurred (you might want to take a look at
C<Mail::Audit::Attach::error> in that case).

Note that the attachment is not removed.

=back

=head2 ERROR FUNCTION

C<Mail::Audit::Attach::error> will return an error message if an
action failed (currently only set by C<save>).

=head1 HISTORY

=over 4

=item 0.96, 2010-02-28

    - Fixed POD bug introduced in 0.95
    - Upgraded to Makefile.PL in the style of Alexandr Ciornii (v0.21)

=item 0.95, 2010-02-26

    - Created GitHub repository
    - Fixed RT#19546: Added missing dependency MIME::Base64

=item 0.94  Sun Jun 05 23:00:00 2005

    - Updated distribution to more modern format.
    - Added POD tests.

=item 0.93  Sat Apr 14 00:30:00 2003

    - Mail::Audit->save died when passed an empty location. Fixed.
      location is now optional.
    - Now uses File::Spec for more portability
    - Introduced Mail::Audit::error (used by save)
    - Localized $_ where used

=item 0.92  Sat Feb  8 13:00:00 2003

	- Now relies on MIME::Head to recognize attachments.
	  "Never try to be too clever."
	- No more warnings.

=item 0.91  Thu Feb  6 22:30:00 2003

  - Now recognizes attachments with Content-Disposition inline,
    but a given filename. This became necessary because Netscape
   	Communicator and other clients send their attachments that way.

	  Thanks to Jeff Engelhardt and Vladimir Parkhaev for bringing
          this to my attention.

=item 0.90  Sat Jun  1 19:35:24 2002

	- original version; created by h2xs 1.19

=back

=head1 DEVELOPMENT NOTES

Please report any bugs using the CPAN RT system. The development repository for this module is hosted on GitHub: L<http://github.com/crenz/Mail-Audit-Attach/>.

=head1 AUTHOR

Christian Renz <crenz@web42.com>

=head1 LICENSE

Copyright (C) 2002-2010 Christian Renz <crenz@web42.com>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mail::Audit|Mail::Audit>. L<MIME::Entity|MIME::Entity>.

=cut
