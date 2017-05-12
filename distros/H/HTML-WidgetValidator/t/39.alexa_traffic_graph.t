use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'AlexaTrafficGraph' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Alexa Traffic Graph 1
--- input
<script type="text/javascript" 
	src="http://widgets.alexa.com/traffic/javascript/graph.js"></script>
--- expected
Alexa Traffic Graph

=== Alexa Traffic Graph 2
--- input
<script type="text/javascript">/*
<![CDATA[*/

   // USER-EDITABLE VARIABLES
   // enter up to 3 domains, separated by a space
   var sites      = ['hatena.ne.jp']; 
   var opts = {
      width:      380,  // width in pixels (max 400)
      height:     300,  // height in pixels (max 300)
      type:       'r',  // "r" Reach, "n" Rank, "p" Page Views 
      range:      '7d', // "7d", "1m", "3m", "6m", "1y", "3y", "5y", "max" 
      bgcolor:    'e6f3fc' // hex value without "#" char (usually "e6f3fc")
   };
   // END USER-EDITABLE VARIABLES	
   AGraphManager.add( new AGraph(sites, opts) );
	
//]]></script>
--- expected
Alexa Traffic Graph

=== Alexa Traffic Graph 3
--- input
<script type="text/javascript" 
	src="http://widgets.alexa.com/traffic/javascript/graph.js"></script>
--- expected
Alexa Traffic Graph

=== Alexa Traffic Graph 4
--- input
<script type="text/javascript">/*
<![CDATA[*/

   // USER-EDITABLE VARIABLES
   // enter up to 3 domains, separated by a space
   var sites      = ['hatena.ne.jp fc2.com ameblo.jp']; 
   var opts = {
      width:      380,  // width in pixels (max 400)
      height:     300,  // height in pixels (max 300)
      type:       'r',  // "r" Reach, "n" Rank, "p" Page Views 
      range:      '6m', // "7d", "1m", "3m", "6m", "1y", "3y", "5y", "max" 
      bgcolor:    'e6f3fc' // hex value without "#" char (usually "e6f3fc")
   };
   // END USER-EDITABLE VARIABLES	
   AGraphManager.add( new AGraph(sites, opts) );
	
//]]></script>
--- expected
Alexa Traffic Graph

=== Alexa Traffic Graph 5
--- input
<script type="text/javascript" 
	src="http://widgets.alexa.com/traffic/javascript/graph.js"></script>
--- expected
Alexa Traffic Graph

=== Alexa Traffic Graph 6
--- input
<script type="text/javascript">/*
<![CDATA[*/

   // USER-EDITABLE VARIABLES
   // enter up to 3 domains, separated by a space
   var sites      = ['hatena.ne.jp ameblo.jp']; 
   var opts = {
      width:      380,  // width in pixels (max 400)
      height:     300,  // height in pixels (max 300)
      type:       'p',  // "r" Reach, "n" Rank, "p" Page Views 
      range:      'max', // "7d", "1m", "3m", "6m", "1y", "3y", "5y", "max" 
      bgcolor:    'e6f3fc' // hex value without "#" char (usually "e6f3fc")
   };
   // END USER-EDITABLE VARIABLES	
   AGraphManager.add( new AGraph(sites, opts) );
	
//]]></script>
--- expected
Alexa Traffic Graph


=== Alexa Traffic Graph 7
--- input
<script type="text/javascript" 
	src="http://widgets.alexa.com/traffic/javascript/graph.js"></script>
--- expected
Alexa Traffic Graph

=== Alexa Traffic Graph 8
--- input
<script type="text/javascript">/*
<![CDATA[*/

   // USER-EDITABLE VARIABLES
   // enter up to 3 domains, separated by a space
   var sites      = ['hatena.ne.jp']; 
   var opts = {
      width:      380,  // width in pixels (max 400)
      height:     300,  // height in pixels (max 300)
      type:       'r',  // "r" Reach, "n" Rank, "p" Page Views 
      range:      '1m', // "7d", "1m", "3m", "6m", "1y", "3y", "5y", "max" 
      bgcolor:    'e6f3fc' // hex value without "#" char (usually "e6f3fc")
   };
   // END USER-EDITABLE VARIABLES	
   AGraphManager.add( new AGraph(sites, opts) );
	
//]]></script>
--- expected
Alexa Traffic Graph


=== Alexa Traffic Graph 9
--- input
<script type="text/javascript">/*
<![CDATA[*/

   // USER-EDITABLE VARIABLES
   // enter up to 3 domains, separated by a space
   var sites      = ['http://www.hatena.ne.jp/']; 
   var opts = {
      width:      380,  // width in pixels (max 400)
      height:     300,  // height in pixels (max 300)
      type:       'p',  // "r" Reach, "n" Rank, "p" Page Views 
      range:      '1m', // "7d", "1m", "3m", "6m", "1y", "3y", "5y", "max" 
      bgcolor:    'e6f3fc' // hex value without "#" char (usually "e6f3fc")
   };
   // END USER-EDITABLE VARIABLES	
   AGraphManager.add( new AGraph(sites, opts) );
	
//]]></script>
--- expected
Alexa Traffic Graph
