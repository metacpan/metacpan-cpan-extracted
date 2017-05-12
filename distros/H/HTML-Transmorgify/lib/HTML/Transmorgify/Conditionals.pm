package HTML::Transmorgify::Conditionals;
use Parse::RecDescent;

{ my $ERRORS;


package Parse::RecDescent::HTML::Transmorgify::Conditionals;
use strict;
use vars qw($skip $AUTOLOAD  );
@Parse::RecDescent::HTML::Transmorgify::Conditionals::ISA = ();
$skip = '\s*';

	use Carp qw(confess);

	our @rtmp;

	sub db
	{
		require Data::Dumper;
		print Data::Dumper::Dumper((caller(1))[3], @_);
	}

	my $allowed_funcs = \%HTML::Transmorgify::allowed_functions;
	sub run
	{
		return $_[0] unless ref $_[0];
		return $_[0]->();
	}

	sub binary
	{
		
		my ($t1, $op, $t2) = @_;
		confess if ref $op;
		my $eval = "sub { \$_[0] $op \$_[1] }";
		$allowed_funcs->{$op} ||= eval $eval or die "eval $eval: $@";
		return sub {
			$allowed_funcs->{$op}->(run($t1), run($t2));
		};
	}

	sub unary
	{
		
		my ($op, $t1) = @_;
		confess if ref $op;
		my $eval = "sub { $op \$_[0] }";
		$allowed_funcs->{$op} ||= eval $eval or die "eval $eval: $@";
		return sub {
			$allowed_funcs->{$op}->(run($t1));
		};
	}
		
	sub assoc
	{
		
		my ($r, @ops) = @_;
		while (my ($op, $term) = splice(@ops, 0, 2)) {
			confess if ref $op;
			my $eval = "sub { \$_[0] $op \$_[1] }";
			$allowed_funcs->{$op} ||= eval $eval or die "eval $eval: $@";
			my $left = $r;
			$r = sub {
				$allowed_funcs->{$op}->(run($left), run($term));
			};
		}
		return $r;
	}

	sub left
	{
		
		assoc(@{$_[1]});
	}

	sub right
	{
		
		assoc(reverse @{$_[1]});
	}

	sub nonassoc
	{
		
		die if @{$_[1]} > 3;
		left(@_);
	}
;


{
local $SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*Parse::RecDescent::HTML::Transmorgify::Conditionals::AUTOLOAD   = sub
{
    no strict 'refs';
    $AUTOLOAD =~ s/^Parse::RecDescent::HTML::Transmorgify::Conditionals/Parse::RecDescent/;
    goto &{$AUTOLOAD};
}
}

push @Parse::RecDescent::HTML::Transmorgify::Conditionals::ISA, 'Parse::RecDescent';
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr2
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr2"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr2]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr2},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr5 expr2op expr5>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr5 expr2op expr5>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr2});
        %item = (__RULE__ => q{expr2});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr5 expr2op expr5>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr2},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr5]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr2},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr5})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr5($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr5]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr2},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr5]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr5}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr2op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr2},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr2op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr2op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr2op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr2},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr2op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr2op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr5]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr2},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr5})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr5($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr5]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr2},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr5]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr5}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr5 expr2op expr5>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr2},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr5 expr2op expr5>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr2},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr5 expr2op expr5>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr2},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr2},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr2},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr15op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr15op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr15op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr15op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/(\\*|\\/|%|x)/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/(\\*|\\/|%|x)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr15op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr15op});
        %item = (__RULE__ => q{expr15op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/(\\*|\\/|%|x)/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr15op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(\*|\/|%|x))/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/(\\*|\\/|%|x)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr15op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr15op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr15op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr15op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr15a
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr15a"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr15a]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr15a},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'-', or expr16});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['-' expr16]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr15a});
        %item = (__RULE__ => q{expr15a});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['-']},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\-/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [expr16]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr15a},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr16})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr16($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr16]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr15a},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr16]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr16}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  binary(0, '-', $item[1]) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: ['-' expr16]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [expr16]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr15a});
        %item = (__RULE__ => q{expr15a});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [expr16]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr15a},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr16($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr16]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr15a},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr16]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr16}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [expr16]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr15a},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr15a},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr15a},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr15a},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr10
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr10"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr10]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr10},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr11 expr10op expr11>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr11 expr10op expr11>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr10},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr10});
        %item = (__RULE__ => q{expr10});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr11 expr10op expr11>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr10},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr11]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr10},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr11})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr11($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr11]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr10},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr11]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr10},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr11}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr10op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr10},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr10op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr10op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr10op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr10},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr10op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr10},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr10op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr11]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr10},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr11})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr11($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr11]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr10},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr11]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr10},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr11}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr11 expr10op expr11>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr10},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr11 expr10op expr11>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr10},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr10},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr11 expr10op expr11>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr10},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr10},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr10},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr10},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr10},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr15
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr15"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr15]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr15},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr15a expr15op expr15a>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr15a expr15op expr15a>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr15},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr15});
        %item = (__RULE__ => q{expr15});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr15a expr15op expr15a>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr15},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr15a]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr15},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr15a})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr15a($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr15a]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr15},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr15a]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr15a}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr15op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr15},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr15op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr15op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr15op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr15},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr15op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr15op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr15a]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr15},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr15a})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr15a($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr15a]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr15},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr15a]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr15a}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr15a expr15op expr15a>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr15},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr15a expr15op expr15a>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr15a expr15op expr15a>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr15},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr15},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr15},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr15},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr15},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr11
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr11"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr11]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr11},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr12 expr11op expr12>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr12 expr11op expr12>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr11},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr11});
        %item = (__RULE__ => q{expr11});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr12 expr11op expr12>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr11},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr12]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr11},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr12})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr12($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr12]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr11},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr12]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr11},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr12}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr11op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr11},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr11op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr11op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr11op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr11},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr11op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr11},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr11op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr12]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr11},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr12})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr12($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr12]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr11},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr12]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr11},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr12}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr12 expr11op expr12>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr11},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr12 expr11op expr12>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr11},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr11},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  nonassoc(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr12 expr11op expr12>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr11},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr11},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr11},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr11},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr11},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr12op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr12op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr12op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr12op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/(<|>|<=|>=|lt|gt|le|ge)/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/(<|>|<=|>=|lt|gt|le|ge)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr12op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr12op});
        %item = (__RULE__ => q{expr12op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/(<|>|<=|>=|lt|gt|le|ge)/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr12op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(<|>|<=|>=|lt|gt|le|ge))/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr12op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/(<|>|<=|>=|lt|gt|le|ge)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr12op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr12op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr12op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr12op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr12op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr8
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr8"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr8]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr8},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr9 expr8op expr9>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr9 expr8op expr9>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr8},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr8});
        %item = (__RULE__ => q{expr8});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr9 expr8op expr9>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr8},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr9]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr8},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr9})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr9($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr9]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr8},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr9]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr8},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr9}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr8op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr8},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr8op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr8op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr8op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr8},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr8op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr8},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr8op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr9]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr8},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr9})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr9($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr9]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr8},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr9]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr8},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr9}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr9 expr8op expr9>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr8},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr9 expr8op expr9>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr8},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr8},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr9 expr8op expr9>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr8},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr8},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr8},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr8},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr8},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr5
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr5"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr5]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr5},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'not', or expr6});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['not' expr6]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr5});
        %item = (__RULE__ => q{expr5});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['not']},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "not"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying subrule: [expr6]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr5},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr6})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr6($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr6]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr5},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr6]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr6}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  unary('not', $item[2]) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: ['not' expr6]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [expr6]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr5});
        %item = (__RULE__ => q{expr5});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [expr6]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr5},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr6($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr6]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr5},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr6]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr6}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [expr6]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr5},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr5},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr5},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr5},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr14
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr14"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr14]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr14},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr15 expr14op expr15>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr15 expr14op expr15>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr14},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr14});
        %item = (__RULE__ => q{expr14});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr15 expr14op expr15>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr14},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr15]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr14},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr15})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr15($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr15]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr14},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr15]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr14},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr15}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr14op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr14},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr14op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr14op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr14op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr14},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr14op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr14},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr14op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr15]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr14},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr15})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr15($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr15]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr14},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr15]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr14},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr15}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr15 expr14op expr15>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr14},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr15 expr14op expr15>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr14},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr14},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr15 expr14op expr15>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr14},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr14},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr14},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr14},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr14},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr6
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr6"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr6]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr6},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{expr7});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [expr7 '?' expr7 ':' expr6]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr6});
        %item = (__RULE__ => q{expr6});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [expr7]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr6},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr7($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr7]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr6},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr7]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr7}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['?']},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'?'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "?"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying subrule: [expr7]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr6},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr7})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr7($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr7]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr6},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr7]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr7}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [':']},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{':'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = ":"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying subrule: [expr6]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr6},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr6})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr6($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr6]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr6},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr6]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr6}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  sub { run($item[1]) ? run($item[3]) : run($item[5]) } };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [expr7 '?' expr7 ':' expr6]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [expr7]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr6});
        %item = (__RULE__ => q{expr6});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [expr7]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr6},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr7($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr7]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr6},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr7]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr7}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [expr7]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr6},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr6},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr6},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr6},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr13op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr13op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr13op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr13op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/(<<|>>)/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/(<<|>>)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr13op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr13op});
        %item = (__RULE__ => q{expr13op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/(<<|>>)/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr13op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(<<|>>))/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr13op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/(<<|>>)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr13op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr13op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr13op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr13op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr13op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr8op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr8op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr8op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr8op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'&&'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['&&']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr8op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr8op});
        %item = (__RULE__ => q{expr8op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['&&']},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr8op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "&&"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr8op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: ['&&']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr8op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr8op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr8op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr8op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr8op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::macro
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/<macro (?: [^'">] | '[^'<>]*' | "[^"<>]*" )* >/x});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/<macro (?: [^'">] | '[^'<>]*' | "[^"<>]*" )* >/x]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro});
        %item = (__RULE__ => q{macro});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/<macro (?: [^'">] | '[^'<>]*' | "[^"<>]*" )* >/x]}, Parse::RecDescent::_tracefirst($text),
                      q{macro},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:<macro (?: [^'">] | '[^'<>]*' | "[^"<>]*" )* >)/x)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {
		
		my $buf = HTML::Transmorgify::compile($HTML::Transmorgify::modules, \$item[1]);
		$return = sub {
			local(@rtmp) = ( '' );
			run($buf, \@rtmp);
			return $rtmp[0];
		};
	};
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/<macro (?: [^'">] | '[^'<>]*' | "[^"<>]*" )* >/x]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{macro},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr16op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr16op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr16op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr16op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/(=~|\\!~)/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/(=~|\\!~)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr16op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr16op});
        %item = (__RULE__ => q{expr16op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/(=~|\\!~)/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr16op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(=~|\!~))/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr16op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/(=~|\\!~)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr16op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr16op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr16op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr16op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr16op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr10op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr10op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr10op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr10op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/(\\&)/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/(\\&)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr10op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr10op});
        %item = (__RULE__ => q{expr10op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/(\\&)/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr10op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(\&))/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr10op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/(\\&)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr10op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr10op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr10op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr10op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr10op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr11op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr11op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr11op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr11op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/(==|\\!=|<=>|eq|ne|cmp)/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/(==|\\!=|<=>|eq|ne|cmp)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr11op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr11op});
        %item = (__RULE__ => q{expr11op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/(==|\\!=|<=>|eq|ne|cmp)/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr11op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(==|\!=|<=>|eq|ne|cmp))/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr11op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/(==|\\!=|<=>|eq|ne|cmp)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr11op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr11op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr11op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr11op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr11op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::function
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"function"};
    
    Parse::RecDescent::_trace(q{Trying rule: [function]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{function},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[A-Za-z_](?:\\w|::(?=[^:]))*/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[A-Za-z_](?:\\w|::(?=[^:]))*/ '(' <leftop: expr /,/ expr> ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{function});
        %item = (__RULE__ => q{function});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[A-Za-z_](?:\\w|::(?=[^:]))*/]}, Parse::RecDescent::_tracefirst($text),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[A-Za-z_](?:\w|::(?=[^:]))*)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying terminal: ['(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'('})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\(/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr /,/ expr>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{function},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{<leftop: expr /,/ expr>})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr]},
                  Parse::RecDescent::_tracefirst($text),
                  q{function},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{function},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying terminal: [/,/]}, Parse::RecDescent::_tracefirst($text),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{/,/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:,)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN2__}=$current_match;
        

            pop @item;
            if (defined $1) {push @item, $item{'expr(s)'}=$1; $backtrack=1;}
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr]},
                  Parse::RecDescent::_tracefirst($text),
                  q{function},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{function},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr /,/ expr>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{function},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr /,/ expr>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{'expr(s)'}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{')'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { 
		
		die unless $allowed_funcs->{$item[1]};
		$return = sub {
			$allowed_funcs->{$item[1]}->( map { run($_) } @item[3..$#item] );
		};
	};
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[A-Za-z_](?:\\w|::(?=[^:]))*/ '(' <leftop: expr /,/ expr> ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{function},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{function},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{function},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{function},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr7op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr7op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr7op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr7op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'||'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['||']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr7op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr7op});
        %item = (__RULE__ => q{expr7op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['||']},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr7op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "||"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr7op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: ['||']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr7op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr7op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr7op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr7op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr7op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::term
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"term"};
    
    Parse::RecDescent::_trace(q{Trying rule: [term]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{term},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'(', or constant, or macro, or function});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['(' expr ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{term});
        %item = (__RULE__ => q{term});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\(/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [expr]},
                  Parse::RecDescent::_tracefirst($text),
                  q{term},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{term},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{')'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $return = $item[2] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: ['(' expr ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [constant]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{term});
        %item = (__RULE__ => q{term});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [constant]},
                  Parse::RecDescent::_tracefirst($text),
                  q{term},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::constant($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [constant]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{term},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [constant]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{constant}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $return = $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [constant]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{term});
        %item = (__RULE__ => q{term});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro]},
                  Parse::RecDescent::_tracefirst($text),
                  q{term},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::macro($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{term},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $return = $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [function]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{term});
        %item = (__RULE__ => q{term});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [function]},
                  Parse::RecDescent::_tracefirst($text),
                  q{term},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::function($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [function]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{term},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [function]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{function}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $return = $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [function]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{term},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{term},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{term},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{term},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr13
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr13"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr13]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr13},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr14 expr13op expr14>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr14 expr13op expr14>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr13},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr13});
        %item = (__RULE__ => q{expr13});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr14 expr13op expr14>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr13},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr14]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr13},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr14})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr14($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr14]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr13},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr14]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr13},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr14}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr13op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr13},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr13op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr13op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr13op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr13},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr13op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr13},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr13op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr14]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr13},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr14})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr14($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr14]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr13},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr14]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr13},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr14}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr14 expr13op expr14>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr13},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr14 expr13op expr14>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr13},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr13},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr14 expr13op expr14>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr13},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr13},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr13},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr13},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr13},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr17op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr17op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr17op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr17op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/(\\*\\*)/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/(\\*\\*)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr17op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr17op});
        %item = (__RULE__ => q{expr17op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/(\\*\\*)/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr17op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(\*\*))/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr17op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/(\\*\\*)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr17op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr17op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr17op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr17op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr17op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr17
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr17"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr17]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr17},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: term expr17op term>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: term expr17op term>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr17},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr17});
        %item = (__RULE__ => q{expr17});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: term expr17op term>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr17},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [term]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr17},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{term})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::term($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [term]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr17},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [term]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr17},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{term}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr17op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr17},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr17op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr17op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr17op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr17},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr17op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr17},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr17op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [term]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr17},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{term})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::term($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [term]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr17},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [term]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr17},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{term}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: term expr17op term>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr17},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: term expr17op term>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr17},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr17},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: term expr17op term>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr17},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr17},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr17},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr17},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr17},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr2 expr_op expr2>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr2 expr_op expr2>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr});
        %item = (__RULE__ => q{expr});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr2 expr_op expr2>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr2]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr2})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr2($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr2]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr2]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr2}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr_op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr_op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr_op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr_op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr_op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr_op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr2]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr2})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr2($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr2]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr2]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr2}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr2 expr_op expr2>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr2 expr_op expr2>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr2 expr_op expr2>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr12
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr12"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr12]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr12},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr13 expr12op expr13>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr13 expr12op expr13>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr12},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr12});
        %item = (__RULE__ => q{expr12});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr13 expr12op expr13>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr12},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr13]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr12},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr13})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr13($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr13]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr12},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr13]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr12},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr13}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr12op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr12},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr12op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr12op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr12op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr12},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr12op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr12},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr12op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr13]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr12},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr13})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr13($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr13]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr12},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr13]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr12},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr13}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr13 expr12op expr13>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr12},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr13 expr12op expr13>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr12},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr12},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  nonassoc(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr13 expr12op expr13>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr12},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr12},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr12},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr12},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr12},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr16
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr16"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr16]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr16},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr17 expr16op expr17>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr17 expr16op expr17>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr16},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr16});
        %item = (__RULE__ => q{expr16});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr17 expr16op expr17>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr16},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr17]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr16},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr17})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr17($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr17]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr16},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr17]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr16},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr17}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr16op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr16},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr16op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr16op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr16op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr16},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr16op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr16},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr16op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr17]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr16},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr17})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr17($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr17]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr16},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr17]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr16},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr17}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr17 expr16op expr17>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr16},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr17 expr16op expr17>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr16},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr16},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr17 expr16op expr17>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr16},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr16},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr16},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr16},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr16},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr2op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr2op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr2op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr2op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'and'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['and']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr2op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr2op});
        %item = (__RULE__ => q{expr2op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['and']},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr2op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "and"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr2op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  return $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: ['and']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr2op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr2op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr2op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr2op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr2op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr_op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr_op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr_op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr_op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/or|xor/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/or|xor/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr_op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr_op});
        %item = (__RULE__ => q{expr_op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/or|xor/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr_op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:or|xor)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr_op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/or|xor/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr_op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr_op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr_op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr_op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr_op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr7
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr7"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr7]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr7},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr8 expr7op expr8>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr8 expr7op expr8>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr7},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr7});
        %item = (__RULE__ => q{expr7});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr8 expr7op expr8>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr7},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr8]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr7},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr8})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr8($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr8]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr7},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr8]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr7},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr8}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr7op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr7},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr7op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr7op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr7op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr7},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr7op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr7},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr7op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr8]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr7},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr8})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr8($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr8]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr7},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr8]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr7},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr8}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr8 expr7op expr8>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr7},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr8 expr7op expr8>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr7},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr7},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr8 expr7op expr8>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr7},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr7},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr7},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr7},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr7},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::constant
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"constant"};
    
    Parse::RecDescent::_trace(q{Trying rule: [constant]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{constant},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/ -? (?: \\d+ (?: \\.\\d+ )? | (?: \\.\\d+) ) (?:[eE]-?\\d+)? /x, or ''', or '"'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/ -? (?: \\d+ (?: \\.\\d+ )? | (?: \\.\\d+) ) (?:[eE]-?\\d+)? /x]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{constant});
        %item = (__RULE__ => q{constant});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/ -? (?: \\d+ (?: \\.\\d+ )? | (?: \\.\\d+) ) (?:[eE]-?\\d+)? /x]}, Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?: -? (?: \d+ (?: \.\d+ )? | (?: \.\d+) ) (?:[eE]-?\d+)? )/x)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/ -? (?: \\d+ (?: \\.\\d+ )? | (?: \\.\\d+) ) (?:[eE]-?\\d+)? /x]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [''' /[^"]*/ '"']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{constant});
        %item = (__RULE__ => q{constant});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [''']},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "'"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying terminal: [/[^"]*/]}, Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{/[^"]*/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[^"]*)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying terminal: ['"']},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'"'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\"/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[2] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [''' /[^"]*/ '"']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['"' /[^']*/ ''']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{constant});
        %item = (__RULE__ => q{constant});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['"']},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\"/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying terminal: [/[^']*/]}, Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{/[^']*/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[^']*)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying terminal: [''']},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'''})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "'"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[2] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: ['"' /[^']*/ ''']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{constant},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{constant},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{constant},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{constant},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr9op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr9op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr9op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr9op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/(\\||\\^)/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/(\\||\\^)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr9op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr9op});
        %item = (__RULE__ => q{expr9op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/(\\||\\^)/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr9op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(\||\^))/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr9op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/(\\||\\^)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr9op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr9op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr9op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr9op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr9op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::conditional
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"conditional"};
    
    Parse::RecDescent::_trace(q{Trying rule: [conditional]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{conditional},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{expr});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [expr /\\Z/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{conditional},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{conditional});
        %item = (__RULE__ => q{conditional});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [expr]},
                  Parse::RecDescent::_tracefirst($text),
                  q{conditional},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{conditional},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{conditional},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [/\\Z/]}, Parse::RecDescent::_tracefirst($text),
                      q{conditional},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{/\\Z/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\Z)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{conditional},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [expr /\\Z/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{conditional},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{conditional},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{conditional},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{conditional},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{conditional},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr14op
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr14op"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr14op]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr14op},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/(\\+|-|\\.)/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/(\\+|-|\\.)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr14op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr14op});
        %item = (__RULE__ => q{expr14op});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/(\\+|-|\\.)/]}, Parse::RecDescent::_tracefirst($text),
                      q{expr14op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(\+|-|\.))/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr14op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  $item[1] };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [/(\\+|-|\\.)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr14op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr14op},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr14op},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr14op},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr14op},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::HTML::Transmorgify::Conditionals::expr9
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"expr9"};
    
    Parse::RecDescent::_trace(q{Trying rule: [expr9]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{expr9},
                  $tracelevel)
                    if defined $::RD_TRACE;

    
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  defined($_[2]) && $_[2];
    my $_noactions = defined($_[3]) && $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: expr10 expr9op expr10>});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<leftop: expr10 expr9op expr10>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{expr9},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{expr9});
        %item = (__RULE__ => q{expr9});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying operator: [<leftop: expr10 expr9op expr10>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr9},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [expr10]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr9},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr10})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr10($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr10]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr9},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr10]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr9},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr10}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr9op]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr9},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr9op})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr9op($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr9op]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr9},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr9op]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr9},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr9op}} = $_tok;
        push @item, $_tok;
        
        }

            $backtrack=1;
            
            
        Parse::RecDescent::_trace(q{Trying subrule: [expr10]},
                  Parse::RecDescent::_tracefirst($text),
                  q{expr9},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{expr10})->at($text);
        unless (defined ($_tok = Parse::RecDescent::HTML::Transmorgify::Conditionals::expr10($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [expr10]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr9},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [expr10]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{expr9},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{expr10}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          unless (@item) { undef $_tok; last }
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=1)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: expr10 expr9op expr10>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{expr9},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: expr10 expr9op expr10>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr9},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{__DIRECTIVE1__}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr9},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {  left(@item) };
        unless (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        $item{__ACTION1__}=$_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [<leftop: expr10 expr9op expr10>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{expr9},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{expr9},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{expr9},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
                      $return . q{])}, "",
                      q{expr9},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{expr9},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}
}
package HTML::Transmorgify::Conditionals; sub new { my $self = bless( {
                 '_precompiled' => 1,
                 'localvars' => '',
                 'startcode' => '',
                 'namespace' => 'Parse::RecDescent::HTML::Transmorgify::Conditionals',
                 'rules' => {
                              'expr2' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'expr5',
                                                               'expr2op'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => 0,
                                                                        'strcount' => 0,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'op' => [],
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'expected' => '<leftop: expr5 expr2op expr5>',
                                                                                              'min' => 1,
                                                                                              'name' => '',
                                                                                              'max' => 100000000,
                                                                                              'leftarg' => bless( {
                                                                                                                    'subrule' => 'expr5',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 93
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                              'rightarg' => bless( {
                                                                                                                     'subrule' => 'expr5',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 93
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'type' => 'leftop',
                                                                                              'op' => bless( {
                                                                                                               'subrule' => 'expr2op',
                                                                                                               'matchrule' => 0,
                                                                                                               'implicit' => undef,
                                                                                                               'argcode' => undef,
                                                                                                               'lookahead' => 0,
                                                                                                               'line' => 93
                                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                            }, 'Parse::RecDescent::Operator' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 94,
                                                                                              'code' => '{  left(@item) }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'expr2',
                                                  'vars' => '',
                                                  'line' => 93
                                                }, 'Parse::RecDescent::Rule' ),
                              'expr15op' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '(\\*|\\/|%|x)',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/(\\\\*|\\\\/|%|x)/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 160,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 161,
                                                                                                 'code' => '{  $item[1] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'expr15op',
                                                     'vars' => '',
                                                     'line' => 160
                                                   }, 'Parse::RecDescent::Rule' ),
                              'expr15a' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'expr16'
                                                               ],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => 0,
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '-',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'-\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 163
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'subrule' => 'expr16',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => 163
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 164,
                                                                                                'code' => '{  binary(0, \'-\', $item[1]) }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' ),
                                                                 bless( {
                                                                          'number' => 1,
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'subrule' => 'expr16',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => 165
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 166,
                                                                                                'code' => '{  $item[1] }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => 165
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'expr15a',
                                                    'vars' => '',
                                                    'line' => 163
                                                  }, 'Parse::RecDescent::Rule' ),
                              'expr10' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'expr11',
                                                                'expr10op'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'op' => [],
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'expected' => '<leftop: expr11 expr10op expr11>',
                                                                                               'min' => 1,
                                                                                               'name' => '',
                                                                                               'max' => 100000000,
                                                                                               'leftarg' => bless( {
                                                                                                                     'subrule' => 'expr11',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 127
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                               'rightarg' => bless( {
                                                                                                                      'subrule' => 'expr11',
                                                                                                                      'matchrule' => 0,
                                                                                                                      'implicit' => undef,
                                                                                                                      'argcode' => undef,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'line' => 127
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'type' => 'leftop',
                                                                                               'op' => bless( {
                                                                                                                'subrule' => 'expr10op',
                                                                                                                'matchrule' => 0,
                                                                                                                'implicit' => undef,
                                                                                                                'argcode' => undef,
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 127
                                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                             }, 'Parse::RecDescent::Operator' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 128,
                                                                                               'code' => '{  left(@item) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'expr10',
                                                   'vars' => '',
                                                   'line' => 127
                                                 }, 'Parse::RecDescent::Rule' ),
                              'expr15' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'expr15a',
                                                                'expr15op'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'op' => [],
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'expected' => '<leftop: expr15a expr15op expr15a>',
                                                                                               'min' => 1,
                                                                                               'name' => '',
                                                                                               'max' => 100000000,
                                                                                               'leftarg' => bless( {
                                                                                                                     'subrule' => 'expr15a',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 157
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                               'rightarg' => bless( {
                                                                                                                      'subrule' => 'expr15a',
                                                                                                                      'matchrule' => 0,
                                                                                                                      'implicit' => undef,
                                                                                                                      'argcode' => undef,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'line' => 157
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'type' => 'leftop',
                                                                                               'op' => bless( {
                                                                                                                'subrule' => 'expr15op',
                                                                                                                'matchrule' => 0,
                                                                                                                'implicit' => undef,
                                                                                                                'argcode' => undef,
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 157
                                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                             }, 'Parse::RecDescent::Operator' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 158,
                                                                                               'code' => '{  left(@item) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'expr15',
                                                   'vars' => '',
                                                   'line' => 157
                                                 }, 'Parse::RecDescent::Rule' ),
                              'expr11' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'expr12',
                                                                'expr11op'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'op' => [],
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'expected' => '<leftop: expr12 expr11op expr12>',
                                                                                               'min' => 1,
                                                                                               'name' => '',
                                                                                               'max' => 100000000,
                                                                                               'leftarg' => bless( {
                                                                                                                     'subrule' => 'expr12',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 133
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                               'rightarg' => bless( {
                                                                                                                      'subrule' => 'expr12',
                                                                                                                      'matchrule' => 0,
                                                                                                                      'implicit' => undef,
                                                                                                                      'argcode' => undef,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'line' => 133
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'type' => 'leftop',
                                                                                               'op' => bless( {
                                                                                                                'subrule' => 'expr11op',
                                                                                                                'matchrule' => 0,
                                                                                                                'implicit' => undef,
                                                                                                                'argcode' => undef,
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 133
                                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                             }, 'Parse::RecDescent::Operator' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 134,
                                                                                               'code' => '{  nonassoc(@item) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'expr11',
                                                   'vars' => '',
                                                   'line' => 133
                                                 }, 'Parse::RecDescent::Rule' ),
                              'expr12op' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '(<|>|<=|>=|lt|gt|le|ge)',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/(<|>|<=|>=|lt|gt|le|ge)/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 142,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 143,
                                                                                                 'code' => '{  $item[1] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'expr12op',
                                                     'vars' => '',
                                                     'line' => 142
                                                   }, 'Parse::RecDescent::Rule' ),
                              'expr8' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'expr9',
                                                               'expr8op'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => 0,
                                                                        'strcount' => 0,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'op' => [],
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'expected' => '<leftop: expr9 expr8op expr9>',
                                                                                              'min' => 1,
                                                                                              'name' => '',
                                                                                              'max' => 100000000,
                                                                                              'leftarg' => bless( {
                                                                                                                    'subrule' => 'expr9',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 115
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                              'rightarg' => bless( {
                                                                                                                     'subrule' => 'expr9',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 115
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'type' => 'leftop',
                                                                                              'op' => bless( {
                                                                                                               'subrule' => 'expr8op',
                                                                                                               'matchrule' => 0,
                                                                                                               'implicit' => undef,
                                                                                                               'argcode' => undef,
                                                                                                               'lookahead' => 0,
                                                                                                               'line' => 115
                                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                            }, 'Parse::RecDescent::Operator' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 116,
                                                                                              'code' => '{  left(@item) }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'expr8',
                                                  'vars' => '',
                                                  'line' => 115
                                                }, 'Parse::RecDescent::Rule' ),
                              'expr5' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'expr6'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => 0,
                                                                        'strcount' => 1,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => 'not',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'not\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 99
                                                                                            }, 'Parse::RecDescent::InterpLit' ),
                                                                                     bless( {
                                                                                              'subrule' => 'expr6',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 99
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 100,
                                                                                              'code' => '{  unary(\'not\', $item[2]) }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 1,
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'expr6',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 101
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 102,
                                                                                              'code' => '{  $item[1] }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => 101
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'expr5',
                                                  'vars' => '',
                                                  'line' => 99
                                                }, 'Parse::RecDescent::Rule' ),
                              'expr14' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'expr15',
                                                                'expr14op'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'op' => [],
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'expected' => '<leftop: expr15 expr14op expr15>',
                                                                                               'min' => 1,
                                                                                               'name' => '',
                                                                                               'max' => 100000000,
                                                                                               'leftarg' => bless( {
                                                                                                                     'subrule' => 'expr15',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 151
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                               'rightarg' => bless( {
                                                                                                                      'subrule' => 'expr15',
                                                                                                                      'matchrule' => 0,
                                                                                                                      'implicit' => undef,
                                                                                                                      'argcode' => undef,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'line' => 151
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'type' => 'leftop',
                                                                                               'op' => bless( {
                                                                                                                'subrule' => 'expr14op',
                                                                                                                'matchrule' => 0,
                                                                                                                'implicit' => undef,
                                                                                                                'argcode' => undef,
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 151
                                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                             }, 'Parse::RecDescent::Operator' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 152,
                                                                                               'code' => '{  left(@item) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'expr14',
                                                   'vars' => '',
                                                   'line' => 151
                                                 }, 'Parse::RecDescent::Rule' ),
                              'expr6' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'expr7',
                                                               'expr6'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => 0,
                                                                        'strcount' => 2,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'expr7',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 104
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => '?',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'?\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 104
                                                                                            }, 'Parse::RecDescent::InterpLit' ),
                                                                                     bless( {
                                                                                              'subrule' => 'expr7',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 104
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => ':',
                                                                                              'hashname' => '__STRING2__',
                                                                                              'description' => '\':\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 104
                                                                                            }, 'Parse::RecDescent::InterpLit' ),
                                                                                     bless( {
                                                                                              'subrule' => 'expr6',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 104
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 105,
                                                                                              'code' => '{  sub { run($item[1]) ? run($item[3]) : run($item[5]) } }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 1,
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'expr7',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 106
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 107,
                                                                                              'code' => '{  $item[1] }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => 106
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'expr6',
                                                  'vars' => '',
                                                  'line' => 104
                                                }, 'Parse::RecDescent::Rule' ),
                              'expr13op' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '(<<|>>)',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/(<<|>>)/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 148,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 149,
                                                                                                 'code' => '{  $item[1] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'expr13op',
                                                     'vars' => '',
                                                     'line' => 148
                                                   }, 'Parse::RecDescent::Rule' ),
                              'expr8op' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => 0,
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '&&',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'&&\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 118
                                                                                              }, 'Parse::RecDescent::InterpLit' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 119,
                                                                                                'code' => '{  $item[1] }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'expr8op',
                                                    'vars' => '',
                                                    'line' => 118
                                                  }, 'Parse::RecDescent::Rule' ),
                              'macro' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => 0,
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 1,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '<macro (?: [^\'">] | \'[^\'<>]*\' | "[^"<>]*" )* >',
                                                                                              'hashname' => '__PATTERN1__',
                                                                                              'description' => '/<macro (?: [^\'">] | \'[^\'<>]*\' | "[^"<>]*" )* >/x',
                                                                                              'lookahead' => 0,
                                                                                              'rdelim' => '/',
                                                                                              'line' => 205,
                                                                                              'mod' => 'x',
                                                                                              'ldelim' => '/'
                                                                                            }, 'Parse::RecDescent::Token' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 206,
                                                                                              'code' => '{
		
		my $buf = HTML::Transmorgify::compile($HTML::Transmorgify::modules, \\$item[1]);
		$return = sub {
			local(@rtmp) = ( \'\' );
			run($buf, \\@rtmp);
			return $rtmp[0];
		};
	}'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'macro',
                                                  'vars' => '',
                                                  'line' => 205
                                                }, 'Parse::RecDescent::Rule' ),
                              'expr16op' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '(=~|\\!~)',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/(=~|\\\\!~)/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 171,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 172,
                                                                                                 'code' => '{  $item[1] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'expr16op',
                                                     'vars' => '',
                                                     'line' => 171
                                                   }, 'Parse::RecDescent::Rule' ),
                              'expr10op' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '(\\&)',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/(\\\\&)/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 130,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 131,
                                                                                                 'code' => '{  $item[1] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'expr10op',
                                                     'vars' => '',
                                                     'line' => 130
                                                   }, 'Parse::RecDescent::Rule' ),
                              'expr11op' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '(==|\\!=|<=>|eq|ne|cmp)',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/(==|\\\\!=|<=>|eq|ne|cmp)/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 136,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 137,
                                                                                                 'code' => '{  $item[1] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'expr11op',
                                                     'vars' => '',
                                                     'line' => 136
                                                   }, 'Parse::RecDescent::Rule' ),
                              'function' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'expr'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 2,
                                                                           'dircount' => 1,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 2,
                                                                           'actcount' => 1,
                                                                           'op' => [],
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '[A-Za-z_](?:\\w|::(?=[^:]))*',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/[A-Za-z_](?:\\\\w|::(?=[^:]))*/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 189,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'pattern' => '(',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'(\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 189
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'expected' => '<leftop: expr /,/ expr>',
                                                                                                 'min' => 1,
                                                                                                 'name' => '\'expr(s)\'',
                                                                                                 'max' => 100000000,
                                                                                                 'leftarg' => bless( {
                                                                                                                       'subrule' => 'expr',
                                                                                                                       'matchrule' => 0,
                                                                                                                       'implicit' => undef,
                                                                                                                       'argcode' => undef,
                                                                                                                       'lookahead' => 0,
                                                                                                                       'line' => 189
                                                                                                                     }, 'Parse::RecDescent::Subrule' ),
                                                                                                 'rightarg' => bless( {
                                                                                                                        'subrule' => 'expr',
                                                                                                                        'matchrule' => 0,
                                                                                                                        'implicit' => undef,
                                                                                                                        'argcode' => undef,
                                                                                                                        'lookahead' => 0,
                                                                                                                        'line' => 189
                                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                                 'hashname' => '__DIRECTIVE1__',
                                                                                                 'type' => 'leftop',
                                                                                                 'op' => bless( {
                                                                                                                  'pattern' => ',',
                                                                                                                  'hashname' => '__PATTERN2__',
                                                                                                                  'description' => '/,/',
                                                                                                                  'lookahead' => 0,
                                                                                                                  'rdelim' => '/',
                                                                                                                  'line' => 189,
                                                                                                                  'mod' => '',
                                                                                                                  'ldelim' => '/'
                                                                                                                }, 'Parse::RecDescent::Token' )
                                                                                               }, 'Parse::RecDescent::Operator' ),
                                                                                        bless( {
                                                                                                 'pattern' => ')',
                                                                                                 'hashname' => '__STRING2__',
                                                                                                 'description' => '\')\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 189
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 190,
                                                                                                 'code' => '{ 
		
		die unless $allowed_funcs->{$item[1]};
		$return = sub {
			$allowed_funcs->{$item[1]}->( map { run($_) } @item[3..$#item] );
		};
	}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'function',
                                                     'vars' => '',
                                                     'line' => 189
                                                   }, 'Parse::RecDescent::Rule' ),
                              'expr7op' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => 0,
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '||',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'||\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 112
                                                                                              }, 'Parse::RecDescent::InterpLit' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 113,
                                                                                                'code' => '{  $item[1] }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'expr7op',
                                                    'vars' => '',
                                                    'line' => 112
                                                  }, 'Parse::RecDescent::Rule' ),
                              'term' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'expr',
                                                              'constant',
                                                              'macro',
                                                              'function'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => 0,
                                                                       'strcount' => 2,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '(',
                                                                                             'hashname' => '__STRING1__',
                                                                                             'description' => '\'(\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 180
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'subrule' => 'expr',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 180
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'pattern' => ')',
                                                                                             'hashname' => '__STRING2__',
                                                                                             'description' => '\')\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 180
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 181,
                                                                                             'code' => '{  $return = $item[2] }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' ),
                                                              bless( {
                                                                       'number' => 1,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'constant',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 182
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 183,
                                                                                             'code' => '{  $return = $item[1] }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => 182
                                                                     }, 'Parse::RecDescent::Production' ),
                                                              bless( {
                                                                       'number' => 2,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'macro',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 184
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 185,
                                                                                             'code' => '{  $return = $item[1] }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => 184
                                                                     }, 'Parse::RecDescent::Production' ),
                                                              bless( {
                                                                       'number' => 3,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'function',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 186
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 187,
                                                                                             'code' => '{  $return = $item[1] }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => 186
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'term',
                                                 'vars' => '',
                                                 'line' => 180
                                               }, 'Parse::RecDescent::Rule' ),
                              'expr13' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'expr14',
                                                                'expr13op'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'op' => [],
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'expected' => '<leftop: expr14 expr13op expr14>',
                                                                                               'min' => 1,
                                                                                               'name' => '',
                                                                                               'max' => 100000000,
                                                                                               'leftarg' => bless( {
                                                                                                                     'subrule' => 'expr14',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 145
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                               'rightarg' => bless( {
                                                                                                                      'subrule' => 'expr14',
                                                                                                                      'matchrule' => 0,
                                                                                                                      'implicit' => undef,
                                                                                                                      'argcode' => undef,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'line' => 145
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'type' => 'leftop',
                                                                                               'op' => bless( {
                                                                                                                'subrule' => 'expr13op',
                                                                                                                'matchrule' => 0,
                                                                                                                'implicit' => undef,
                                                                                                                'argcode' => undef,
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 145
                                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                             }, 'Parse::RecDescent::Operator' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 146,
                                                                                               'code' => '{  left(@item) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'expr13',
                                                   'vars' => '',
                                                   'line' => 145
                                                 }, 'Parse::RecDescent::Rule' ),
                              'expr17op' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '(\\*\\*)',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/(\\\\*\\\\*)/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 177,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 178,
                                                                                                 'code' => '{  $item[1] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'expr17op',
                                                     'vars' => '',
                                                     'line' => 177
                                                   }, 'Parse::RecDescent::Rule' ),
                              'expr17' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'term',
                                                                'expr17op'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'op' => [],
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'expected' => '<leftop: term expr17op term>',
                                                                                               'min' => 1,
                                                                                               'name' => '',
                                                                                               'max' => 100000000,
                                                                                               'leftarg' => bless( {
                                                                                                                     'subrule' => 'term',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 174
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                               'rightarg' => bless( {
                                                                                                                      'subrule' => 'term',
                                                                                                                      'matchrule' => 0,
                                                                                                                      'implicit' => undef,
                                                                                                                      'argcode' => undef,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'line' => 174
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'type' => 'leftop',
                                                                                               'op' => bless( {
                                                                                                                'subrule' => 'expr17op',
                                                                                                                'matchrule' => 0,
                                                                                                                'implicit' => undef,
                                                                                                                'argcode' => undef,
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 174
                                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                             }, 'Parse::RecDescent::Operator' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 175,
                                                                                               'code' => '{  left(@item) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'expr17',
                                                   'vars' => '',
                                                   'line' => 174
                                                 }, 'Parse::RecDescent::Rule' ),
                              'expr' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'expr2',
                                                              'expr_op'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => 0,
                                                                       'strcount' => 0,
                                                                       'dircount' => 1,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'op' => [],
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'expected' => '<leftop: expr2 expr_op expr2>',
                                                                                             'min' => 1,
                                                                                             'name' => '',
                                                                                             'max' => 100000000,
                                                                                             'leftarg' => bless( {
                                                                                                                   'subrule' => 'expr2',
                                                                                                                   'matchrule' => 0,
                                                                                                                   'implicit' => undef,
                                                                                                                   'argcode' => undef,
                                                                                                                   'lookahead' => 0,
                                                                                                                   'line' => 87
                                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                             'rightarg' => bless( {
                                                                                                                    'subrule' => 'expr2',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 87
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                             'hashname' => '__DIRECTIVE1__',
                                                                                             'type' => 'leftop',
                                                                                             'op' => bless( {
                                                                                                              'subrule' => 'expr_op',
                                                                                                              'matchrule' => 0,
                                                                                                              'implicit' => undef,
                                                                                                              'argcode' => undef,
                                                                                                              'lookahead' => 0,
                                                                                                              'line' => 87
                                                                                                            }, 'Parse::RecDescent::Subrule' )
                                                                                           }, 'Parse::RecDescent::Operator' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 88,
                                                                                             'code' => '{  left(@item) }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'expr',
                                                 'vars' => '',
                                                 'line' => 87
                                               }, 'Parse::RecDescent::Rule' ),
                              'expr12' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'expr13',
                                                                'expr12op'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'op' => [],
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'expected' => '<leftop: expr13 expr12op expr13>',
                                                                                               'min' => 1,
                                                                                               'name' => '',
                                                                                               'max' => 100000000,
                                                                                               'leftarg' => bless( {
                                                                                                                     'subrule' => 'expr13',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 139
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                               'rightarg' => bless( {
                                                                                                                      'subrule' => 'expr13',
                                                                                                                      'matchrule' => 0,
                                                                                                                      'implicit' => undef,
                                                                                                                      'argcode' => undef,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'line' => 139
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'type' => 'leftop',
                                                                                               'op' => bless( {
                                                                                                                'subrule' => 'expr12op',
                                                                                                                'matchrule' => 0,
                                                                                                                'implicit' => undef,
                                                                                                                'argcode' => undef,
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 139
                                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                             }, 'Parse::RecDescent::Operator' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 140,
                                                                                               'code' => '{  nonassoc(@item) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'expr12',
                                                   'vars' => '',
                                                   'line' => 139
                                                 }, 'Parse::RecDescent::Rule' ),
                              'expr16' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'expr17',
                                                                'expr16op'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'op' => [],
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'expected' => '<leftop: expr17 expr16op expr17>',
                                                                                               'min' => 1,
                                                                                               'name' => '',
                                                                                               'max' => 100000000,
                                                                                               'leftarg' => bless( {
                                                                                                                     'subrule' => 'expr17',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 168
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                               'rightarg' => bless( {
                                                                                                                      'subrule' => 'expr17',
                                                                                                                      'matchrule' => 0,
                                                                                                                      'implicit' => undef,
                                                                                                                      'argcode' => undef,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'line' => 168
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'type' => 'leftop',
                                                                                               'op' => bless( {
                                                                                                                'subrule' => 'expr16op',
                                                                                                                'matchrule' => 0,
                                                                                                                'implicit' => undef,
                                                                                                                'argcode' => undef,
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 168
                                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                             }, 'Parse::RecDescent::Operator' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 169,
                                                                                               'code' => '{  left(@item) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'expr16',
                                                   'vars' => '',
                                                   'line' => 168
                                                 }, 'Parse::RecDescent::Rule' ),
                              'expr2op' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => 0,
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => 'and',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'and\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 96
                                                                                              }, 'Parse::RecDescent::InterpLit' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 97,
                                                                                                'code' => '{  return $item[1] }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'expr2op',
                                                    'vars' => '',
                                                    'line' => 96
                                                  }, 'Parse::RecDescent::Rule' ),
                              'expr_op' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => 0,
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 1,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => 'or|xor',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'description' => '/or|xor/',
                                                                                                'lookahead' => 0,
                                                                                                'rdelim' => '/',
                                                                                                'line' => 90,
                                                                                                'mod' => '',
                                                                                                'ldelim' => '/'
                                                                                              }, 'Parse::RecDescent::Token' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 91,
                                                                                                'code' => '{  $item[1] }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'expr_op',
                                                    'vars' => '',
                                                    'line' => 90
                                                  }, 'Parse::RecDescent::Rule' ),
                              'expr7' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'expr8',
                                                               'expr7op'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => 0,
                                                                        'strcount' => 0,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'op' => [],
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'expected' => '<leftop: expr8 expr7op expr8>',
                                                                                              'min' => 1,
                                                                                              'name' => '',
                                                                                              'max' => 100000000,
                                                                                              'leftarg' => bless( {
                                                                                                                    'subrule' => 'expr8',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 109
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                              'rightarg' => bless( {
                                                                                                                     'subrule' => 'expr8',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 109
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'type' => 'leftop',
                                                                                              'op' => bless( {
                                                                                                               'subrule' => 'expr7op',
                                                                                                               'matchrule' => 0,
                                                                                                               'implicit' => undef,
                                                                                                               'argcode' => undef,
                                                                                                               'lookahead' => 0,
                                                                                                               'line' => 109
                                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                            }, 'Parse::RecDescent::Operator' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 110,
                                                                                              'code' => '{  left(@item) }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'expr7',
                                                  'vars' => '',
                                                  'line' => 109
                                                }, 'Parse::RecDescent::Rule' ),
                              'constant' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => ' -? (?: \\d+ (?: \\.\\d+ )? | (?: \\.\\d+) ) (?:[eE]-?\\d+)? ',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/ -? (?: \\\\d+ (?: \\\\.\\\\d+ )? | (?: \\\\.\\\\d+) ) (?:[eE]-?\\\\d+)? /x',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 198,
                                                                                                 'mod' => 'x',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 199,
                                                                                                 'code' => '{  $item[1] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => 1,
                                                                           'strcount' => 2,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '\'',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'\'\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 200
                                                                                               }, 'Parse::RecDescent::InterpLit' ),
                                                                                        bless( {
                                                                                                 'pattern' => '[^"]*',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/[^"]*/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 200,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'pattern' => '"',
                                                                                                 'hashname' => '__STRING2__',
                                                                                                 'description' => '\'"\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 200
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 201,
                                                                                                 'code' => '{  $item[2] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 200
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => 2,
                                                                           'strcount' => 2,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '"',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'"\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 202
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'pattern' => '[^\']*',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/[^\']*/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 202,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'pattern' => '\'',
                                                                                                 'hashname' => '__STRING2__',
                                                                                                 'description' => '\'\'\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 202
                                                                                               }, 'Parse::RecDescent::InterpLit' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 203,
                                                                                                 'code' => '{  $item[2] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 202
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'constant',
                                                     'vars' => '',
                                                     'line' => 198
                                                   }, 'Parse::RecDescent::Rule' ),
                              'expr9op' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => 0,
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 1,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '(\\||\\^)',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'description' => '/(\\\\||\\\\^)/',
                                                                                                'lookahead' => 0,
                                                                                                'rdelim' => '/',
                                                                                                'line' => 124,
                                                                                                'mod' => '',
                                                                                                'ldelim' => '/'
                                                                                              }, 'Parse::RecDescent::Token' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 125,
                                                                                                'code' => '{  $item[1] }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'expr9op',
                                                    'vars' => '',
                                                    'line' => 124
                                                  }, 'Parse::RecDescent::Rule' ),
                              'conditional' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'expr'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => 0,
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 1,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'expr',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 84
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => '\\Z',
                                                                                                    'hashname' => '__PATTERN1__',
                                                                                                    'description' => '/\\\\Z/',
                                                                                                    'lookahead' => 0,
                                                                                                    'rdelim' => '/',
                                                                                                    'line' => 84,
                                                                                                    'mod' => '',
                                                                                                    'ldelim' => '/'
                                                                                                  }, 'Parse::RecDescent::Token' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 85,
                                                                                                    'code' => '{  $item[1] }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'conditional',
                                                        'vars' => '',
                                                        'line' => 84
                                                      }, 'Parse::RecDescent::Rule' ),
                              'expr14op' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '(\\+|-|\\.)',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/(\\\\+|-|\\\\.)/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 154,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 155,
                                                                                                 'code' => '{  $item[1] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'expr14op',
                                                     'vars' => '',
                                                     'line' => 154
                                                   }, 'Parse::RecDescent::Rule' ),
                              'expr9' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'expr10',
                                                               'expr9op'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => 0,
                                                                        'strcount' => 0,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'op' => [],
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'expected' => '<leftop: expr10 expr9op expr10>',
                                                                                              'min' => 1,
                                                                                              'name' => '',
                                                                                              'max' => 100000000,
                                                                                              'leftarg' => bless( {
                                                                                                                    'subrule' => 'expr10',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 121
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                              'rightarg' => bless( {
                                                                                                                     'subrule' => 'expr10',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 121
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'type' => 'leftop',
                                                                                              'op' => bless( {
                                                                                                               'subrule' => 'expr9op',
                                                                                                               'matchrule' => 0,
                                                                                                               'implicit' => undef,
                                                                                                               'argcode' => undef,
                                                                                                               'lookahead' => 0,
                                                                                                               'line' => 121
                                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                            }, 'Parse::RecDescent::Operator' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 122,
                                                                                              'code' => '{  left(@item) }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'expr9',
                                                  'vars' => '',
                                                  'line' => 121
                                                }, 'Parse::RecDescent::Rule' )
                            },
                 '_AUTOTREE' => undef,
                 '_check' => {
                               'thisoffset' => '',
                               'itempos' => '',
                               'prevoffset' => '',
                               'prevline' => '',
                               'prevcolumn' => '',
                               'thiscolumn' => ''
                             },
                 '_AUTOACTION' => undef
               }, 'Parse::RecDescent' );
}