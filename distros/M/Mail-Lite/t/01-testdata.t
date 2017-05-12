#
#===============================================================================
#
#         FILE:  01-testdata.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06.05.2009 03:16:26 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 71;


use Data::Dumper;
use YAML::Syck;

use Mail::Lite::Processor;

use File::Find;

chdir('..') if -d 'data';

my @messages = @ARGV;

if ( not @messages ) {
    find(
	sub { 
	    -f $_ && m/^\d/ && $File::Find::name !~ m/.svn/ && ! m/\.dat$/
		and push @messages, $File::Find::name
	},
	't/data');
}

my ($rules) = LoadFile('t/data/rules.yaml');

#die Dumper $rules;

foreach my $message_fn (@messages) {
    my $dat_fn = $message_fn.q{.dat};
    
    my $message = slurp_file( $message_fn );

    $message = koi2win( $message );

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

sub koi2win {
    my ($val) = @_;

    $val or return '';
    $val =~ tr/бвчздецъйклмнопртуфхжигюыэшщяьасБВЧЗДЕЦЪЙКЛМНОПРТУФХЖИГЮЫЭЯЩШЬАСіЈ/А-яЁё/;

    # ukr chars
    $val =~ tr/¤¦§ґ¶·Ѕ/єіїЄІЇҐ/;
    $val =~ s/\xAD/ґ/gx;
    
    return $val;
}

