#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '5.13';

#----------------------------------------------------------
# Additional Modules

use lib qw|. ./lib|;

#use CGI::Carp			qw(fatalsToBrowser);

use Labyrinth;

#----------------------------------------------------------

my $lab = Labyrinth->new();
$lab->run('config/settings.ini');

1;

__END__
