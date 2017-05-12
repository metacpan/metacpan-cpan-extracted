#!/usr/bin/perl
use Device::Kiln;
use Device::Kiln::Orton;
use strict;
use CGI;      # or any other CGI:: form handler/decoder
use CGI::Ajax;
use Template;
use Data::Dumper;

  my %action_table = (
    graph_rm => \&graph_rm,
    main_rm => \&main_rm,
    test_rm => \&test
  );



my $meter = Device::Kiln->new({
		width => 1024,
		height => 800,
	});





my $cgi = new CGI;
my $rm = $cgi->param("rm") || "main";
$rm .= "_rm";

&{ $action_table{$rm} }($cgi,$meter);


sub graph_rm ($$){	

	my ($cgi,$meter) = @_;
	
	my $cone = $cgi->param("cone");
	
	print $cgi->header({-type=>'image/svg+xml'});
#	print $meter->graph( {
#			cone => $cone,
#			warmuptime => $cgi->param("warmuptime"),
#			warmuptemp => $cgi->param("warmuptemp"),
#			warmupramp => $cgi->param("warmupramp"),
#			fullgraph => 0,
#		});

	print $meter->graph({$cgi->Vars})
	
}	
		
sub main_rm  ($$) {
	
	my ($cgi,$meter) = @_;
	
	my $pjx = new CGI::Ajax( 'exported_func' => \&update );
	print $pjx->build_html( $cgi, \&Show_HTML);
}

sub update {
	
}

sub test ($$){
	
	my ($cgi,$meter) = @_;
	
	print $meter->{test} . "\n";
	
}

sub debug {
	
	my $msg = shift;
	
	open( my $dfh, ">>", "/tmp/kilnserver.dbg");
	print $dfh (scalar localtime) . " : " . $msg . "\n";
	close($dfh);
	
}

#<object data='/cgi-bin/kilngraph.pl?rm=graph' id='kilngraph' type='image/svg+xml' width=1024 height=600 >

sub Show_HTML {
    my $html = "
    <HTML>
	<head>
	<script type='text/javascript'>
		
		
	function newImage(){
		if(document.images){
			var cone = params.cone.value;
			var conerate = params.conerate.value;
			var warmuptime = params.warmuptime.value;
			var warmuptemp = params.warmuptemp.value;
			var warmupramp = params.warmupramp.value;
			var fireuprate = params.fireuprate.value;
			document.getElementById('kilngraph').src = '/cgi-bin/kilngraph.pl?rm=graph&'
				 + 'cone=' + cone + '&'
				 + 'conerate=' + conerate + '&'
				 + 'warmuptime=' + warmuptime + '&'
				 + 'warmuptemp=' + warmuptemp + '&'
				 + 'warmupramp=' + warmupramp + '&'
				 + 'fireuprate=' + fireuprate + '&'
				 + Date.parse(new Date().toString());
		
		} 
		
	}
	
	function cycle() {
		newImage();
		setTimeout(cycle,15000);
	}
	
	
	</script>
	</head>
	<body onload='cycle()'>
	<div id='resultdiv'></div>
	<form name='params' >
	<TABLE BORDER=1>
	<TR>
	<TD>
	Warm Up Temp <select name=warmuptemp onchange='newImage()'>
	<option value=100>100
	<option value=150>150
	<option value=200>200
	</select>
	</TD>
	<TD>
	Warm Up Ramp <select name=warmupramp onchange='newImage()'>
	<option value=100>100
	<option value=150>150
	<option value=200>200
	<option value=250>250
	<option value=300>300
	</select> C/Hour
	</TD>
	<TD>
	Warm Up Time <select name=warmuptime onchange='newImage()'>
	<option value=30>30
	<option value=60>60
	<option value=90>90
	<option value=120>120
	</select> Minutes
	</TD>
	</TR>
	<TR>
	<TD>
	Fire Up Rate <select name=fireuprate onchange='newImage()'>
	<option value=150>150
	<option value=200>200
	<option value=300>300
	<option value=400>400
	</select> C/Hour
	</TD>
	<TD>
	Last 100C(Degrees C/hour) <select name=conerate onchange='newImage()'>
	<option value=15>15</option>
	<option value=60>60</option>
	<option value=150>150</option>
	</select>
	</TD>
	<TD>
	Cone 	<select name=cone onchange='newImage()'>";
	
	my $cones = Device::Kiln::Orton->hashref();
		foreach my $coneconfig ( 
			sort { $cones->{$a}->{seqnum} <=> $cones->{$b}->{seqnum} }  keys %$cones 
	) {
		
		$html .= "<option value = '$coneconfig'>$coneconfig\n";
	}
	
	$html .= "
	</select>
	</TD>
	</TR>
	</TABLE>
	</form>


	<BR>

<TABLE BORDER=1>
<TR>
<TD>
	<iframe id='kilngraph' width=1024 height=600 >
	</iframe>
</TD>
<TD VALIGN=TOP>
	<TABLE VALIGN='top'>
	<TR>
	<TD>
	<B>Time</B>
	</TD>
	<TD>
	<B>Temp</B>
	</TD>
	</TR>
	<TR>
	<TD>
	</TD>
	<TD>
	</TD>
	</TR>
	</TABLE
</TD>
</TR>
</TABLE>
</HTML>
 	";
    return $html;
}