package Email::PST::Win32;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use Win32::OLE;

has filename            => (isa => 'Str', is => 'rw', default => '');
has display_name        => (isa => 'Str', is => 'rw', default => 'My PST File'); 
has current_folder_path => (isa => 'Str', is => 'rw', default => '');
has instance_counter    => (isa => 'Int', is => 'rw', default => 0);
has count_per_session   => (isa => 'Int', is => 'rw', default => 1000);

has current_rdo_folder  => (
	isa       => 'Win32::OLE',
	is        => 'rw',
	predicate => 'has_current_rdo_folder',
	clearer   => 'clear_current_rdo_folder'
);

has rdo_session => (
	isa       => 'Win32::OLE',
	is        => 'rw',
	lazy      => 1,
	default   => sub { $_[0]->new_rdo_session },
	clearer   => 'clear_rdo_session',
	predicate => 'has_rdo_session'
);

has rdo_pst_store => (
	isa     => 'Win32::OLE',
	is      => 'rw',
	lazy    => 1,
	default => sub { $_[0]->logon_rdo_pst_store },
	clearer => 'clear_rdo_pst_store'
);

sub relogon_rdo_pst_store {
	my $self = shift;
	$self->current_folder_path('');
	$self->clear_current_rdo_folder;
	$self->close;
	$self->rdo_session( $self->new_rdo_session );
	$self->rdo_pst_store( $self->logon_rdo_pst_store );
}

sub new_rdo_session {
	my $self = shift;
	my $ses;
	try   { $ses = new Win32::OLE('Redemption.RDOSession') };
	catch { die "caught exception $_" };
	return $ses;
}

sub close {
	my $self = shift;
	try { $self->rdo_session->Logoff };
	$self->clear_rdo_session;
}

sub logon_rdo_pst_store {
	my $self = shift;
	my $session = $self->rdo_session;
	unless ($session) {die};
	my $pst;
	try   { $pst = $session->LogonPstStore($self->filename, 1, $self->display_name, "", 0); }
	catch { die "caught exception $_" };
	return $pst;
};

sub add_mime_file {
	my ($self,$file_path,$folder_path,$type) = @_;

	$self->instance_counter( $self->instance_counter + 1 );
	if ( $self->count_per_session > 0 ) {
		$self->relogon_rdo_pst_store if $self->instance_counter % $self->count_per_session == 0;
	}

	$folder_path = $self->fix_folder_path($folder_path);
	$type
		= $type && (lc $type eq 'note' || lc $type eq 'ipm.note')
		? 'IPM.Note' : 'IPM.Post';
	
	my $rdo_folder
		= $folder_path eq $self->current_folder_path && $self->has_current_rdo_folder
		? $self->current_rdo_folder
		: $self->get_rdo_folder_from_path( $folder_path, 1 );
	
	if ($rdo_folder) {
		my $rdo_msg = $rdo_folder->Items->add( $type );
		$rdo_msg->Import($file_path, 1024); # 1024 = olRFC822
		$rdo_msg->Save;
	} else {
		die "could not get rdo_folder";
	}
}

sub fix_folder_path {
	my ($self,$path) = @_;
	$path||='';
	$path =~ s|\\|/|g;
	$path =~ s|/+|/|g;
	$path =~ s|\A/||;
	$path = $path ? "__ROOT__/$path" : '__ROOT__';
	return $path;
}

sub get_rdo_folder_from_path {
	my ($self,$path,$load) = @_;

	my $pst = $self->rdo_pst_store;
	unless ($pst && $path) {die};

	my @folders = map {{folder_name=>$_}} split '/', $path;
	for my $i (0..$#folders) {
		if ($i==0) {
			$folders[0]{rdo_folder} = $pst->IPMRootFolder;
			next;
		}

		die "Could not get parent folder" unless
		my $parent_folder = $folders[$i - 1]{rdo_folder};

		die "Could not get folder name" unless
		my $folder_name = $folders[$i]{folder_name}||'';

		if (
			my $folder = $parent_folder->Folders( $folder_name ) ||
			$parent_folder->Folders->Add( $folder_name )
		) {
			$folders[$i]{rdo_folder} = $folder;
		} else {
			die "Could not get folder for path $path";
		}
	}
	if ($load) {
		$self->current_folder_path( $path );
		$self->current_rdo_folder( $folders[-1]{rdo_folder} );
	}

	return $folders[-1]{rdo_folder};
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Email::PST::Win32 - Writing and updating PST files using
Outlook Redemption on Windows

=head1 SYNOPSIS

	# Open an existing or new PST file

	my $pst = Email::PST::Win32->new(
		filename     => 'path/to/file.pst',
		display_name => 'My PST File',
	);

	# Add an MIME file to the PST

	my $file_path   = 'c://path/to/source/Inbox/Important/1.eml';
	my $folder_path = 'Inbox/Important';
	my $type        = index(lc $file_path, 'drafts')>0 ? 'note' : 'post';
	$pst->add_mime_file( $file_path, $folder_path, $type );

	# Errors may occur when high numbers of items are added.
	# A count_per_session > 0 will determine when to close and
	# reopen the PST file. The default value is 1000.

	$pst->count_per_session( 2000 );

	# Get number of MIME files added

	my $count = $pst->instance_counter;
	
	# Close the PST file

	$pst->close;
	
=head1 DESCRIPTION

This is a wrapper for using the Outlook Redemption
(L<http://www.dimastr.com/redemption/>) library to create and update PST
files. However, while Outlook Redemption is a general purpose library,
this module is currently limited to creating and updating PST files with
MIME files located on the file system. Additional capabilties may be added
in the future.

=head2 Requirements

This module requires Win32::OLE and Outlook Redemption.

=head1 SEE ALSO

L<http://www.dimastr.com/redemption/> (Outlook Redemption)

=head1 AUTHOR

John Wang <johncwang@gmail.com>, L<http://johnwang.com> 

=head1 COPYRIGHT

Copyright (c) 2009-2015 John Wang E<lt>johncwang@gmail.comE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
