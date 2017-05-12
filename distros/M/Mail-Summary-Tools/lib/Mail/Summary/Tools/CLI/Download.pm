#!/usr/bin/perl

package Mail::Summary::Tools::CLI::Download;
use base qw/App::Cmd::Subdispatch::DashedStyle Mail::Summary::Tools::CLI/;

use strict;
use warnings;

use constant plugin_search_path => __PACKAGE__;

sub config { $_[0]->app->config }

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::CLI::Download - Downlaad mailing list messages from archives

=head1 SYNOPSIS

	# see command line usage

=head1 DESCRIPTION

=cut


