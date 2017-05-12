## ----------------------------------------------------------------------------

sub GetString
	{
	my ($prompt, $default) = @_ ;

	printf ("%s [%s]", $prompt, $default) ;
	chop ($_ = <STDIN>) ;
	if (!/^\s*$/)
	    {return $_ ;}
	else
    	{
        if ($_ eq "")
	        {return $default ;}
	    else
            { return "" ; }
    
        }
    }

## ----------------------------------------------------------------------------

sub GetYesNo
	{
	my ($prompt, $default) = @_ ;
	my ($value) ;

	do
	    {
	    $value = lc (GetString ($prompt . "(y/n)", ($default?"y":"n"))) ;
	    }
	until (($value cmp "j") == 0 || ($value cmp "y") == 0 || ($value cmp "n" ) == 0) ;

	return ($value cmp "n") != 0 ;
	}

