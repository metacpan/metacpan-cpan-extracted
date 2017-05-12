package EntityModel::LogHandler;
BEGIN {
  $EntityModel::LogHandler::VERSION = '0.001';
}
use EntityModel::Class {
};

=head1 NAME

EntityModel::Web::Apache2::LogHandler - class for handling Apache log requests

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Time::HiRes qw/time/;

use Apache2::RequestRec ();
use Apache2::Connection ();

use Fcntl qw(:flock);
use File::Spec::Functions qw(catfile);

use Apache2::Const -compile => qw(OK DECLINED);

sub handler {
	my $r = shift;
  
	my ($username) = ($r->uri =~ m|^/~([^/]+)|);

	my $start = $r->pnotes('StartPoint');
	my $diff = time - $start;
	my $entry = sprintf("%s [%s] '%s' %d %d %s\n",
		$r->connection->remote_ip,
		scalar(localtime),
		$r->uri,
		$r->status,
		$r->bytes_sent,
		$diff);

#	my $log_path = EntityModel::Config::BasePath . EntityModel::Config::LogAccess;
#	open my $fh, ">>$log_path" or die "can't open $log_path: $!";
#	flock $fh, LOCK_EX;
#	print $fh $entry;
#	close $fh;
	return Apache2::Const::OK;
}

1;