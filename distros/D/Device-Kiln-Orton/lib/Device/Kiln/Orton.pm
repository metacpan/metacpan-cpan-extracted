package Device::Kiln::Orton;
use strict;
use Data::Dumper;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}



sub new
{
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    return $self;
}

sub conetemps {
	
	return (['15','60','150']);

};

sub arrayref {
	my @conearray;
	push @conearray, (
		[ '022','0','586','590' ],
		[ '021','0','600','617' ],
		[ '020','0','626','638' ],
		[ '019','656','678','695' ],
		[ '018','686','715','734' ],
		[ '017','705','738','763' ],
		[ '016','742','772','796' ],
		[ '015','750','791','818' ],
		[ '014','757','807','838' ],
		[ '013','807','837','861' ],
		[ '012','843','861','882' ],
		[ '011','857','875','894' ],
		[ '010','891','903','915' ],
		[ '09','907','920','930' ],
		[ '08','922','942','956' ],
		[ '07','962','976','987' ],
		[ '06','981','998','1013' ],
		[ '05½','1004','1015','1025' ],
		[ '05','1021','1031','1044' ],
		[ '04','1046','1063','1077' ],
		[ '03','1071','1086','1104' ],
		[ '02','1078','1102','1122' ],
		[ '01','1093','1119','1138' ],
		[ '1','1109','1137','1154' ],
		[ '2','1112','1142','1164' ],
		[ '3','1115','1152','1170' ],
		[ '4','1141','1162','1183' ],
		[ '5','1159','1186','1207' ],
		[ '5½','1167','1203','1225' ],
		[ '6','1185','1222','1243' ],
		[ '7','1201','1239','1257' ],
		[ '8','1211','1249','1271' ],
		[ '9','1224','1260','1280' ],
		[ '10','1251','1285','1305' ],
		[ '11','1272','1294','1315' ],
		[ '12','1285','1306','1326' ],
		[ '13','1310','1331','1348' ],
		[ '14','1351','1365','1384' ]
	);
	
	return @conearray;
}


sub hashref {
	
	
		
	my $temp;
	my $hashref;

	my @conearray = arrayref();
	my $coneno = 1;

	foreach my $cone (@conearray) {
		$hashref->{$cone->[0]}->{seqnum} = $coneno;
		$coneno=$coneno+1;
		foreach my $tempnum (1..3) {
			$hashref->{$cone->[0]}->{conetemps()->[$tempnum-1]} = $cone->[$tempnum];
		
		}
		
	}
	
	return $hashref;
}

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

Device::Kiln::Orton - Module for retrieving pyrometric cone charts

=head1 SYNOPSIS

  use Device::Kiln::Orton;
  
  my $cone_hashref = Device::Kiln::Orton->hashref();
  my @cone_arrayref = Device::Kiln::Orton->arrayref();


=head1 DESCRIPTION

retrieve a hash or array of pyrometric cone charts

array is returned as: 
		[cone,temp1,temp2,temp3],
		[cone2,temp1,temp2,temp3],
		.
		.
where temp1, temp2 and temp3 is the maximum cone temp
for the last 100C at a rate of 15,60 & 150 Degrees C
per hour respectively.


hash is returned as:

	{
		'conename' => {
			seqnum 	=> seqno,
			15		=> temp1,
			60		=> temp2
			150		=> temp3
		}
		.
		.
	}		


=head1 BUGS

Only does Celsius.

=head1 SUPPORT



=head1 AUTHOR

    David Peters
    CPAN ID: DAVIDP
    davidp@electronf.com
    http://www.electronf.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), http://www.ortonceramics.com/

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

