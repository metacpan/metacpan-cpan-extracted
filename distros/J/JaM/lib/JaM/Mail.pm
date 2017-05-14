# $Id: Mail.pm,v 1.10 2001/09/02 11:15:25 joern Exp $

package JaM::Mail;

@ISA = qw ( JaM::Entity );

use strict;
use Data::Dumper;
use Time::Local;
use JaM::Folder;
use Storable qw ( thaw );
use MIME::WordDecoder;

my $WORD_DECODER = MIME::WordDecoder::ISO_8859->new('1');
$WORD_DECODER->handler ('*', "KEEP");

sub dbh 		{ shift->{dbh}				}
sub mail_id 		{ shift->{mail_id}			}
sub folder_id 		{ shift->{folder_id}			}

sub load {
	my $type = shift;
	my %par = @_;
	my  ($dbh, $mail_id) = @par{'dbh','mail_id'};
	
	my $sth = $dbh->prepare (
		"select subject, sender, UNIX_TIMESTAMP(date),
			folder_id, status, Entity.data
		 from   Mail, Entity
		 where  Mail.id = ? and Entity.mail_id=Mail.id"
	);
	$sth->execute ( $mail_id );

	my ($subject, $sender, $date,
	    $folder_id, $status, $entity) = $sth->fetchrow_array;

	$sth->finish;

	my $self = {
		dbh    		=> $dbh,
		mail_id		=> $mail_id,
		subject 	=> $subject,
		sender		=> $sender,
		date_time	=> $date,
		folder_id	=> $folder_id,
		status		=> $status,
		entity		=> thaw($entity),
	};
	
	return bless $self, $type;
}


sub status {
	my $self = shift;
	my ($new_status) = @_;

	return $self->{status} if not $new_status;
	my $old_status = $self->{status};
	
	return if $old_status eq $new_status;

	$self->{status} = $new_status;

	$self->dbh->do (
		"update Mail set status=? where id=?", {},
		$new_status, $self->mail_id
	);
	
	# update Folder statistics
	my $folder = JaM::Folder->by_id($self->folder_id);
	my $calc = $new_status eq 'R' ? +1 : -1;
	$folder->mail_read_sum($folder->mail_read_sum + $calc);
	$folder->save;

	1;
}

sub move_to_folder {
	my $self = shift;
	my %par = @_;
	my ($new_folder_id) = @par{'folder_id'};
	
	my $dbh           = $self->dbh;
	my $mail_id       = $self->mail_id;
	my $old_folder_id = $self->folder_id;
	
	return if $new_folder_id == $old_folder_id;
	
	# change folder_id for this mail
	$self->folder_id ( $new_folder_id );
	$dbh->do (
		"update Mail set folder_id = ? where id = ?", {},
		$new_folder_id, $mail_id
	);
	
	# update Folder statistics
	my $status = $self->status;

	# decrement values of old folder
	my $old_folder = JaM::Folder->by_id($old_folder_id);
	$old_folder->mail_sum($old_folder->mail_sum - 1);
	$old_folder->mail_read_sum($old_folder->mail_read_sum - 1) if $status eq 'R';
	$old_folder->save;

	# increment values of new folder
	my $new_folder = JaM::Folder->by_id($new_folder_id);
	$new_folder->mail_sum($new_folder->mail_sum + 1);
	$new_folder->mail_read_sum($new_folder->mail_read_sum + 1) if $status eq 'R';
	$new_folder->save;

	1;
}

sub delete {
	my $self = shift;
	
	$self->dbh->do (
		"delete from Mail where id=?", {},
		$self->mail_id
	);
	
	# update Folder statistics
	my $status = $self->status;

	# decrement values of folder
	my $folder = JaM::Folder->by_id($self->folder_id);
	$folder->mail_sum($folder->mail_sum - 1);
	$folder->mail_read_sum($folder->mail_read_sum - 1) if $status eq 'R';
	$folder->save;
	
	1;
}
	
package JaM::Entity;

sub entity		{ shift->{entity}				}
sub head 		{ shift->{entity}->head				}
sub body 		{ shift->{entity}->bodyhandle			}
sub filename 		{ shift->{entity}->head->recommended_filename	}
sub content_type 	{ shift->{entity}->head->mime_type		}
sub effective_type 	{ shift->{entity}->head->effective_type		}
sub content_length 	{ length(shift->body->as_string)		}
sub subject 		{ shift->head_get_decoded("subject")		}
sub date 		{ shift->head_get_decoded("date")		}

my $ENTITY_ID = 0;

sub entity_id {
	my $self = shift;
	return $self->{entity_id} if defined $self->{entity_id};
	return $self->{entity_id} = $ENTITY_ID++;
}

sub new {
	my $type = shift;
	my ($entity) = @_;
	my $self = {
		entity_id => $ENTITY_ID++,
		entity => $entity,
	};
	return bless $self, $type;
}

sub joined_head {
	my $self = shift;
	my $content = join (", ", $self->head->get ($_[0]));
	$content =~ s/\r?\n/ /g;
	$content =~ s/\s+$//;
	return $self->word_decode($content);
}

sub joined_head_with_nl {
	my $self = shift;
	return $self->word_decode(join (", ", $self->head->get ($_[0])));
}

sub head_get_decoded {
	my $self = shift;
	my $value = $self->word_decode($self->head->get(@_));
	$value =~ s/\s+$//;
	return $value;
}

sub head_get {
	return shift->head->get(@_);
}

sub word_decode {
	my $self = shift;
	my ($line) = @_;
        $line = $WORD_DECODER->decode($line);
	$line =~ s/\r?\n/ /g;
	return $line;
}

sub parts {
	my $self = shift;
	my @parts = $self->entity->parts;
	my @entities;
	foreach my $part ( @parts ) {
		push @entities, JaM::Entity->new($part);
	}
	return \@entities;
}

1;
