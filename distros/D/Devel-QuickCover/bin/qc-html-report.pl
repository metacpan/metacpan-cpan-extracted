#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Devel::QuickCover::Report;
use Devel::QuickCover::Report::Html;

my $QC_DATABASE   = 'qc.dat';
my $QC_REPORT     = 'report';

GetOptions(
    'input=s'         => \$QC_DATABASE,
    'report=s'        => \$QC_REPORT,
);

my $report = Devel::QuickCover::Report->new;
my $html_report = Devel::QuickCover::Report::Html->new(
    directory   => $QC_REPORT,
);

$report->load($QC_DATABASE);
$html_report->add_report($report);

$html_report->render;

exit 0;

