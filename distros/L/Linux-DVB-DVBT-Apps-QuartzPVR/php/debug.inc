<?php

define('DEBUG_VERSION', "1.007") ;

define('SHOW_FILENAME', 	0x01) ;
define('SHOW_LINE', 		0x02) ;
define('SHOW_FUNCTION', 	0x04) ;
define('SHOW_ARGS', 		0x08) ;
define('SHOW_STACK', 		0x10) ;

define('SHOW_DEFAULT', 	SHOW_FILENAME|SHOW_LINE|SHOW_FUNCTION|SHOW_ARGS) ;
define('SHOW_MSG', 		0) ;

// Log filename
//$LOG_PATH = '/var/log/apache2/debug.log' ;
$LOG_PATH = '/tmp/php_debug.log' ;

// Stack level
$STACK_LEVEL=0;

$FUNC_SEP= "\n------------------------------------------------------------\n" ;

// File logging - low-level

//---------------------------------------------------------------------------
// log message
function debug_log_msg($msg)
{
	global $LOG_PATH;
	
	if (!$LOG_PATH) return ;

	if ($fp = fopen($LOG_PATH, 'a'))
	{
		fwrite($fp, $msg);
		fclose($fp);
	}
	else
	{
		//print "<pre>BUGGER!\n</pre>";
		
		// Unable to write to log file, so degrade gracefully
		$LOG_PATH = "" ;
		
	}
}

//---------------------------------------------------------------------------
// log a variable
function debug_log_var($var)
{
	$str = print_r($var, true) ;
	debug_log_msg($str) ;
}

//---------------------------------------------------------------------------
// log a variable with prefix & postfix messages
function debug_log_var_msg($prefix, $var, $postfix='')
{
	if ($prefix) debug_log_msg($prefix) ;

	$str = print_r($var, true) ;
	debug_log_msg($str) ;

	if ($postfix) debug_log_msg($postfix) ;
}


// Logging - higher-level

//---------------------------------------------------------------------------
// Set log filename and/or create empty file
function db_new($filename='', $mode='w', $stack=0)
{
	global $STACK_LEVEL ;
	global $LOG_PATH;
	
	// set filename if required
	if ($filename)
	{
		$LOG_PATH=$filename ;
	}
	
	// Set stack level if required
	if ($stack)
	{
		$STACK_LEVEL = $stack ;
	}
	
	// Create new file
	if ($fp = fopen($LOG_PATH, $mode))
	{
		if ($mode == 'a')
		{
			fwrite($fp, "-----------------------------------------\n") ;	
//			fwrite($fp, "$stack: $stack ($STACK_LEVEL)\n") ;	
 		}
		fclose($fp);
	}

}

//---------------------------------------------------------------------------
function db_log($msg, $prefix='', $postfix='', $stack_level=0, $show=SHOW_DEFAULT) 
{
		$bt = debug_backtrace() ;
		$line = 0 ;
		$file = '' ;
		$function = '[main]' ;
		$args = array();

		if (count($bt)>=(1+$stack_level)) 
		{
			$line = $bt[0+$stack_level]['line'] ;
			$file = $bt[0+$stack_level]['file'] ;
			$args = $bt[0+$stack_level]['args'] ;
			$function = $bt[0+$stack_level]['function'] ;
		}
		if ($stack_level>=1) 
		{
			$line = $bt[$stack_level-1]['line'] ;
			$file = $bt[$stack_level-1]['file'] ;
		}
//		if (count($bt)>=(2+$stack_level)) 
//		{
//			$function = $bt[1+$stack_level]['function'] ;
//		}
		
		
		if ($show & SHOW_FUNCTION)
		{
			if ($show & SHOW_ARGS)
			{
				$args = implode(", ", $args) ;
				$function .= "($args)" ;
			}
			$function .= ': ' ;
		}
		else
		{
			$function='';
		}
		
		$info = '' ;
		if ($show & SHOW_LINE)
		{
			$info .= ": $line " ;
		}
		if ($show & SHOW_FILENAME)
		{
			$info .= ": $file " ;
		}
		
//		print "$prefix$function$msg$postfix\t$info\n" ;
//$bt_str = print_r($bt, 1) ;
//debug_log_msg("backtrace: $bt_str\nStack: $stack_level\n") ;
		debug_log_msg("$prefix$function$msg$postfix\t$info\n") ;

		// Show stack trace if required
		if ($show & SHOW_STACK)
		{
			debug_log_msg("-- Stack --\n") ;
			$count = 1 ;
			for ($index = $stack_level; $index < sizeof($bt); $index++, $count++) 
			{
				$line = $bt[0+$index]['line'] ;
				$file = $bt[0+$index]['file'] ;
				$args = $bt[0+$index]['args'] ;
				$function = $bt[0+$index]['function'] ;
				if ($index>=1) 
				{
					$line = $bt[$index-1]['line'] ;
					$file = $bt[$index-1]['file'] ;
				}

				if ($show & SHOW_ARGS)
				{
					if (!is_array($args))
					{
						$args = array() ;
					}
				
					$args = implode(", ", $args) ;
					$function .= "($args)" ;
				}

				debug_log_msg("  $count : $function : $line : $file\n") ;
								
			}
			
			debug_log_msg("-----------\n\n") ;
		}
}

//---------------------------------------------------------------------------
function db_log_msg($msg, $show=SHOW_MSG) 
{
	global $STACK_LEVEL ;

	db_log($msg, '', '', $STACK_LEVEL ? $STACK_LEVEL : 2, $show) ;
}

//---------------------------------------------------------------------------
function db_log_var_msg($msg, $var, $show=SHOW_MSG) 
{
	global $STACK_LEVEL ;

	$var_str = print_r($var, 1) ;
	$msg .= $var_str ;
	db_log($msg, '', '', $STACK_LEVEL ? $STACK_LEVEL : 2, $show) ;
}

//---------------------------------------------------------------------------
function db_entry($msg='', $show=SHOW_DEFAULT) 
{
	global $STACK_LEVEL, $FUNC_SEP ;

	db_log($msg, $FUNC_SEP, "\n", $STACK_LEVEL ? $STACK_LEVEL : 2, $show) ;
}

//---------------------------------------------------------------------------
function db_exit($msg='', $postfix='', $show=SHOW_DEFAULT) 
{
	global $STACK_LEVEL, $FUNC_SEP ;

	db_log($msg, 'END ', $postfix, $STACK_LEVEL ? $STACK_LEVEL : 2, $show) ;
	db_log($FUNC_SEP, '', '', 0, SHOW_MSG) ;
}
	



?>
