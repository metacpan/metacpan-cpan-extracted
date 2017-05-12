#
#===============================================================================
#
#         FILE:  02-simple.t
#
#  DESCRIPTION:  Tests from Mail-Lite-1
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  07.05.2009 23:42:41 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 4;                      # last test to print


use Data::Dumper;
use YAML::Syck;

use Mail::Lite::Processor;

use File::Find;

chdir('..') if -d 'simple';

my @messages = @ARGV;
if ( not @messages ) {
    find(
	sub { 
	    -f $_ && $File::Find::name !~ m/.svn/ && m/\.msg$/ &&
	    ! m/^_/
		and push @messages, $File::Find::name
	},
	't/simple');
}

my ($rules) = LoadFile('t/simple/rules.yaml');

foreach my $message_fn (@messages) {
    my $message = slurp_file( $message_fn );

    my $dat_fn = substr($message_fn, 0, -4).q{.dat};

    my $matched_rules = [];

    $message = new Mail::Lite::Message( $message );
    $message->{x_filename} = $message_fn;

    Mail::Lite::Processor->process(
	message => $message,
	rules => $rules,
	handler => sub { push @$matched_rules, [ @_ ] },
    ); 

    if ( $ENV{OVERWRITE_DATA} ) {
	open my $fh, '>', $dat_fn;
	print $fh Dump( $matched_rules );
	close $fh;
    }
    is_deeply( $matched_rules, LoadFile( $dat_fn ), $message_fn );
}

sub slurp_file {
    open my $fh, '<', shift;
    local $/;
    <$fh>;
}
