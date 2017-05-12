package EntityModel::Apache2::StartHandler;
BEGIN {
  $EntityModel::Apache2::StartHandler::VERSION = '0.001';
}
use EntityModel::Class {
	_version => '$Rev: 182 $'
};

use Time::HiRes qw/time/;

use Apache2::RequestRec;
use Apache2::Request;
use Apache2::RequestUtil;
use Apache2::Connection;
use Apache2::ConnectionUtil;

use Apache2::Const -compile => qw(OK DECLINED);

sub handler {
	my $r = shift;
  
	my $now = time;
	$r->pnotes('StartPoint' => $now);
	return Apache2::Const::OK;
}

1;

