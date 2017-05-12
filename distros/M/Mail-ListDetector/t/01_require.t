#!/usr/bin/perl -w

use strict;
use Test::More tests => 17;

BEGIN {
	use_ok('Mail::ListDetector');
	use_ok('Mail::ListDetector::List');
	use_ok('Mail::ListDetector::Detector::Base');
	use_ok('Mail::ListDetector::Detector::Mailman');
	use_ok('Mail::ListDetector::Detector::Ezmlm');
	use_ok('Mail::ListDetector::Detector::Smartlist');
	use_ok('Mail::ListDetector::Detector::Majordomo');
	use_ok('Mail::ListDetector::Detector::RFC2369');
	use_ok('Mail::ListDetector::Detector::Listar');
	use_ok('Mail::ListDetector::Detector::Yahoogroups');
	use_ok('Mail::ListDetector::Detector::Ecartis');
	use_ok('Mail::ListDetector::Detector::RFC2919');
	use_ok('Mail::ListDetector::Detector::Fml');
	use_ok('Mail::ListDetector::Detector::CommuniGatePro');
	use_ok('Mail::ListDetector::Detector::Listbox');
	use_ok('Mail::ListDetector::Detector::Listserv');
	use_ok('Mail::ListDetector::Detector::CommuniGate');
}

