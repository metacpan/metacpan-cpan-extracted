package JaM::Drop;

use vars qw ( $DEBUG $VERBOSE @ISA );

@ISA = qw ( JaM::Debug );

use strict;
use MIME::Parser;
use Date::Manip;
use MIME::WordDecoder;
use Storable qw( freeze );
use JaM::Filter::IO;
use JaM::Folder;
use JaM::Mail;
use JaM::Debug;

$DEBUG = 0;
$VERBOSE = 0;

my $MOZ_STATUS_DELETED = hex("0008");
my $MOZ_STATUS_READ    = hex("0001");

sub new {
	my $class = shift;
	
	my %par = @_;
	my  ($dbh, $fh, $folder_id, $abort_file, $type) =
	@par{'dbh','fh','folder_id','abort_file','type'};

	my $wd = MIME::WordDecoder::ISO_8859->new('1');
	$wd->handler ('*', "KEEP");
	
	$type ||= 'input';
	
	my $self = bless {
		dbh => $dbh,
		fh => $fh,
		wd => $wd,
		folder_id => $folder_id,
		abort_file => $abort_file,
		cnt => 0,
		type => $type,
	}, $class;
	
	JaM::Folder->init ( dbh => $dbh );
	
	$self->init_filter;
	
	return $self;
}

sub dbh 	{ shift->{dbh}		}
sub wd		{ shift->{wd}		}
sub filter_sub	{ shift->{filter_sub}	}
sub abort_file 	{ shift->{abort_file}	}
sub type 	{ shift->{type}		}

sub filter_error { my $s = shift; $s->{filter_error}
		   = shift if @_; $s->{filter_error}	}

sub folder_id	{ my $s = shift; $s->{folder_id}
		  = shift if @_; $s->{folder_id}	}

sub fh		{ my $s = shift; $s->{fh}
		  = shift if @_; $s->{fh}	}

sub progress_callback	{ my $s = shift; $s->{progress_callback}
		          = shift if @_; $s->{progress_callback} }

sub drop_mails {
	my $self = shift;

	my $dbh = $self->dbh;
	my $fh  = $self->fh;
	
	my $callback = $self->progress_callback;
	
	open (TMP, "> /tmp/mailer.tmp")
		or die "can't write /tmp/mailer.tmp";
	
	my $from = <$fh>;
	my $last_line = $from;
	print TMP $from;

	my $abort_file = $self->abort_file;

	my $nr = 0;
	my ($mail_id, $folder_id);
	while (<$fh>) {
		return if -f $abort_file;
		if ( $last_line eq "\n" and /^From / ) {
			close TMP;
			open (TMP, "/tmp/mailer.tmp")
				or die "can't read /tmp/mailer.tmp";
			($mail_id, $folder_id) = $self->drop_mail (
				fh  => \*TMP
			);
			close TMP;
			
			&$callback($folder_id, $nr)
				if $callback and $nr % 10 == 0 and $folder_id;
			++$nr;

			open (TMP, "> /tmp/mailer.tmp")
				or die "can't write /tmp/mailer.tmp";
		}
		print TMP;
		$last_line = $_;
	}

	# letzte message verarbeiten
	close TMP;
	open (TMP, "/tmp/mailer.tmp")
		or die "can't read /tmp/mailer.tmp";
	$self->drop_mail (
		fh  => \*TMP
	);
	close TMP;
}

sub drop_mail {
	my $self = shift;
	my %par = @_;
	my  ($fh, $folder_id, $status, $entity, $data) =
	@par{'fh','folder_id','status','entity','data'};
	
	$folder_id ||= $self->folder_id;

	my $dbh = $self->dbh;

	if ( not $entity ) {
		# parse mail
		my $parser = new MIME::Parser;
		$parser->output_to_core(1);
		$entity = $parser->parse($fh) if $fh;
		$entity = $parser->parse_data($data) if $data;
	}

	# Get abstract information from head
	my $head = $entity->head;

	my $moz_status = hex($head->get ('X-Mozilla-Status'));

	return if $moz_status & $MOZ_STATUS_DELETED;
	$status = $moz_status & $MOZ_STATUS_READ ? 'R' : 'N' if $moz_status;
	$status ||= 'N';

	my ($from, @to, $to, @cc, $cc);
	chomp ($from = $head->get ('From', 0) );
	$from = $self->word_decode ($from);
	
	@to = $head->get ('To');
	$to = join (",",@to);
	$to =~ s/[\n\r]//g;
	$to = $self->word_decode ($to);

	@cc = $head->get ('Cc');
	$cc = join (",",@cc);
	$cc =~ s/[\n\r]//g;
	$cc = $self->word_decode ($cc);

	my $subject;
	chomp ($subject = $head->get ('Subject', 0) );
	$subject = $self->word_decode ($subject);
	my $date;
	chomp ($date = $head->get ('Date', 0) );
	$date = ParseDate ($date);
	$date =~ s/(\d\d\d\d)(\d\d)(\d\d)(\d\d:\d\d):(\d\d)/$1-$2-$3 $4/;

	# apply mail filters
	if ( not $folder_id ) {
		$folder_id = $self->apply_filter (
			entity => $entity,
			subject => $subject,
			from => $from,
		);
	}

	$self->{cnt}++;
	$VERBOSE && print "[$self->{cnt}] Subject: $subject ($folder_id) ($status)\n";

	# store abstract information in database
	$dbh->do (
		"insert into Mail
		 (subject, sender, head_to, head_cc, date, folder_id, status)
		 values
		 (?, ?, ?, ?, ?, ?, ?)", {},
		$subject,
		$from || '<>',
		$to || '<>',
		$cc,
		$date || '1970-01-01',
		$folder_id,
		$status
	);
	my $mail_id = $dbh->{'mysql_insertid'};

	# update Folder statistics
	my $folder = JaM::Folder->by_id($folder_id);
	$folder->mail_sum($folder->mail_sum + 1);
	$folder->mail_read_sum($folder->mail_read_sum + 1) if $status eq 'R';
	$folder->save;

	# store Entity in database
	$dbh->do (
		"insert into Entity
		 (mail_id, data)
		 values
		 (?, ?)", {},
		 $mail_id,
		 freeze ($entity),
	);

	return ($mail_id, $folder_id);
}

sub word_decode {
	my $self = shift;
	my ($line) = @_;
        $line = $self->wd->decode($line);
	$line =~ s/\r?\n/ /g;
	return $line;
}

sub init_filter {
	my $self = shift;
	
	my $dbh = $self->dbh;
	
	my $apply = JaM::Filter::IO::Apply->init (
		dbh => $dbh,
		type => $self->type,
	);
	
	if ( $apply->error ) {
		$self->filter_error($apply->error);
	} else {
		$self->{filter_sub} = $apply->sub;
	}
	
	1;
}		 

sub apply_filter {
	my $self = shift;
	my %par = @_;
	my  ($entity, $subject, $from) =
	@par{'entity','subject','from'};
	
	my $jam_entity = JaM::Entity->new ($entity);
	
	my $to   = $jam_entity->joined_head ('to');
	my $cc   = $jam_entity->joined_head ('cc');
	my $from = $jam_entity->joined_head ('from');

	my %h = (
		tofromcc => "$to $from $cc",
		tocc     => "$to $cc",
		to       => $to,
		from     => $from,
		cc       => $cc,
		subject  => $subject,
		entity   => $entity
	);
	my $sub = $self->filter_sub;
	my ($action, $folder_id) = &$sub (\%h);
	
	if ( not $folder_id ) {
		$folder_id = 2;
		$folder_id = 3 if $self->type eq 'output';
	}
	
	return $folder_id;
}

1;
