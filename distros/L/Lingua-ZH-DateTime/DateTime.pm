package Lingua::ZH::DateTime;
###########################################################
#		Zhongwen Date&Time
###########################################################
#	Copyright (c) 2005-2006  hoowa sun & Meng.H P.R.China
#
#	See COPYRIGHT section in pod text below for usage and distribution rights.
#
#	<hoowa.sun@gmail.com>
#	www.perlchina.org
#	last modify 2006-2-21
###########################################################
$Lingua::ZH::DateTime::VERSION='0.01';

use strict;
use vars qw/$locale $charset $lc_string $dt_string/;
	
$dt_string = {
	'gb2312'	=>	{
					'year'=>'Äê',
					'month'=>'ÔÂ',
					'day'=>'ÈÕ',
	},
	'big5'		=>	{
	}
}; 
$lc_string = {
	'china'	=>	{
		'month'=>	{
				'jan'	=>	'1',	'feb'	=>	'2',	'mar'	=>	'3',
				'apr'	=>	'4',	'may'	=>	'5',	'jun'	=>	'6',
				'Jul'	=>	'7',	'aug'	=>	'8',	'sep'	=>	'9',
				'sept'	=>	'9',	'oct'	=>	'10',	'nov'	=>	'11',
				'dec'	=>	'12'
		},
		'day' => {
				'1'		=>	'1',	'2'		=>	'2',	'3'		=>	'3',
				'4'		=>	'4',	'5'		=>	'5',	'6'		=>	'6',
				'7'		=>	'7',	'8'		=>	'8',	'9'		=>	'9',
				'10'	=>	'10',	'11'	=>	'11',	'12'	=>	'12',
				'13'	=>	'13',	'14'	=>	'14',	'15'	=>	'15',
				'16'	=>	'16',	'17'	=>	'17',	'18'	=>	'18',
				'19'	=>	'19',	'20'	=>	'20',	'21'	=>	'21',
				'22'	=>	'22',	'23'	=>	'23',	'24'	=>	'24',
				'25'	=>	'25',	'26'	=>	'26',	'27'	=>	'27',
				'28'	=>	'28',	'29'	=>	'29',	'30'	=>	'30',
				'31'	=>	'31'		
		},
		'hour' => {
				'1'		=>	'1',	'2'		=>	'2',	'3'		=>	'3',
				'4'		=>	'4',	'5'		=>	'5',	'6'		=>	'6',
				'7'		=>	'7',	'8'		=>	'8',	'9'		=>	'9',
				'10'	=>	'10',	'11'	=>	'11',	'12'	=>	'12',
				'13'	=>	'13',	'14'	=>	'14',	'15'	=>	'15',
				'16'	=>	'16',	'17'	=>	'17',	'18'	=>	'18',
				'19'	=>	'19',	'20'	=>	'20',	'21'	=>	'21',
				'22'	=>	'22',	'23'	=>	'23',	'24'	=>	'24'	
		}	
	}
};


sub new {
	my $self = {};
	my (undef,%args) = @_;
	$locale = $args{'locale'} if ($args{'locale'});
	$charset = $args{'charset'} if ($args{'charset'});

	bless $self;
	return $self;
}

##############################
#  METHOD
sub set {
	my $self = shift;
	my %args = @_;
	$locale = $args{'locale'} if($args{'locale'});
	$charset = $args{'charset'} if ($args{'charset'}) ;
	
	return(1);
}

sub convert {
my $self = shift;
my %args = @_;
my ($week,$year,$mon,$day,$hour,$min,$sec,$date,$time);

	if (!$args{'asctime'}) {
		$args{'asctime'}	=	localtime();
	}

	($week,$mon,$day,$time,$year) = split(/\s+/,$args{'asctime'});
	($hour,$min,$sec) = split(/:/,$time);
	$mon = lc($mon);
	$hour =~ s/^0//;

   $args{'output'} = "datetime" if(!$args{'output'});
   $locale = "china" if(!$locale);
   $charset = "gb2312" if(!$charset);

   if ($locale eq 'china') {
	  
	    $date = $year . $dt_string->{$charset}{"year"} .
			    $lc_string->{$locale}{'month'}{$mon} . $dt_string->{$charset}{"month"} .
			    $lc_string->{$locale}{'day'}{$day} . $dt_string->{$charset}{"day"};
	  
	    $time = $lc_string->{$locale}{'hour'}{$hour} . ":$min:$sec";
   }

  

#return value
return $date if($args{'output'} eq 'date');
return $time if($args{'output'} eq 'time');
return "$date $time" if($args{'output'} eq 'datetime');
}


=head1 NAME

Lingua::ZH::DateTime - convert time to chinese format.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module can convert asctime to chinese format in your locale.
you can select china singapore hongkong taiwan locale and gb2312/big5 charset.
asctime is ASC C standard format will from C<localtime> like this:

	$asctime = localtime();

=head1 METHOD

=head2 new

	my $zdt = new Lingua::ZH::DateTime(locale=>'china',charset=>'gb2312');

Instantiates a new object.

=head2 set

	my $zdt->set(locale=>'china',charset=>'gb2312');

set locale and charset encode.

=over 2

=item * locale -> china only now.

=item * charset -> gb2312 only now.

=back

=head2 convert

	$zdt->convert(asctime=>'Thu Oct 13 04:54:34 1994',output=>'date');

=over 2

=item * ctime -> input asctime data.

=item * output -> output in 3 types: date,time,datetime.

=back

=head1 AUTHORS

Lingua::ZH::DateTime by hoowa sun and Meng.H.

=head1 COPYRIGHT

The Lingua::ZH::DateTime module is Copyright (c) 2005-2006 hoowa sun & Meng.H
P.R.China. All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

The Lingua::ZH::DateTime is free Open Source software.

IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 SUPPORT

http://www.perlchina.org

=cut

1;
