#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Mail::Summary::Tools';

use ok 'Mail::Summary::Tools::ArchiveLink::Easy';
use ok 'Mail::Summary::Tools::ArchiveLink::GoogleGroups';
use ok 'Mail::Summary::Tools::ArchiveLink::Gmane';

use ok 'Mail::Summary::Tools::Summary';
use ok 'Mail::Summary::Tools::Summary::List';
use ok 'Mail::Summary::Tools::Summary::Thread';

use ok 'Mail::Summary::Tools::ThreadFilter';
use ok 'Mail::Summary::Tools::ThreadFilter::Util';

use ok 'Mail::Summary::Tools::Output::TT';

use ok 'Mail::Summary::Tools::Output::HTML';

use ok 'Mail::Summary::Tools::Downloader::NNTP';

use ok 'Mail::Summary::Tools::CLI';
use ok 'Mail::Summary::Tools::CLI::Context';
use ok 'Mail::Summary::Tools::CLI::Config';
use ok 'Mail::Summary::Tools::CLI::Create';
use ok 'Mail::Summary::Tools::CLI::Edit';
use ok 'Mail::Summary::Tools::CLI::ToText';
use ok 'Mail::Summary::Tools::CLI::ToHTML';
use ok 'Mail::Summary::Tools::CLI::Download';
use ok 'Mail::Summary::Tools::CLI::Download::nntp';
