<?php

#-----------------------------------------------------------------
define('VERSION', '7.07') ;
#-----------------------------------------------------------------

define('SERVER_DOWN', -111) ;

#==================================================================
# USES
#==================================================================
require_once('php/Config/SqlConstants.inc') ;
require_once('php/Classes/class.JsonApp.php') ;

#==================================================================
# Application Class
#==================================================================
class ListingsApp extends JsonApp
{
	var $irr_debug=0;
	var $list_debug=0;
	
	var $logging = 0;
	var $LOG_PATH = PHP_LOG ;
	var $DBG_REC = 0 ;
	
	var $NUM_PVRS = 1 ;
	var $PVRS = array( array('adapter'=>'0:0', 'name'=>'unknown') ) ;
	var $NUM_HOURS_DISPLAYED = 3 ;
	var $NUM_CHANS_DISPLAYED = 9 ;
	
	var $prog_fields   = array('pid', 'title', 'date', 'channel', 'start', 'duration', 'text', 'repeat', 'episode', 'num_episodes', 'adapter', 'genre', 'chan_type', 'tva_series') ;
	var $prog_record_fields   = array('adapter', 'record', 'multid',   'rid', 'priority') ;
	var $multirec_fields   = array('multid', 'date', 'start', 'duration', 'adapter') ;
	
	var $record_names = array(
		0 => '',
		1 => 'once',
		2 => 'weekly',
		3 => 'daily',
		4 => 'multi',
		5 => 'all',
	) ;

	#	0	: "pid", 
	#	1	: "chanid", 
	#	2	: "start_time", 
	#	3	: "start_date", 
	#	4	: "end_time", 
	#	5	: "end_date", 
	#	6	: "duration_mins", 
	#	7	: "title", 
	#	8	: "genre", 
	#	9	: "description", 
	#	10	: "record",			- NOTE: record is always 0 for _json_progs()
	#	11	: "adapter"
	#	12	: "tva_series"
	var $json_prog_fields   = array('pid', 'chanid', 'start', 'date', 'end', 'end_date', 'duration_mins', 'title', 'genre', 'text', 'record', 'adapter', 'tva_series') ; 

	# <standard prog fields>
	#	13	: "rid", 
	#	14	: "priority", 
	var $json_extended_prog_fields   = array('rid', 'priority') ; 

	#	0	: "multid", 
	#	1	: "start_time", 
	#	2	: "start_date", 
	#	3	: "end_time", 
	#	4	: "end_date", 
	#	5	: "duration_mins", 
	#	6	: "adapter"
	var $json_multirec_fields   = array('multid', 'start', 'date', 'end', 'end_date', 'duration_mins', 'adapter') ; 

	#	0	: "rid", 
	#	1	: "pid", 
	#	2	: "chanid", 
	#	3	: "start_time", 
	#	4	: "start_date", 
	#	5	: "end_time", 
	#	6	: "end_date", 
	#	7	: "duration_mins", 
	#	8	: "title", 
	#	9	: "record",
	#	10	: "priority",
	#	11	: "pathspec",
	#   12  : [progs array]
	var $json_recording_fields = array('rid', 'pid', 'chanid', 'start', 'date', 'end', 'end_date', 'duration_mins', 'title', 'record', 'priority', 'pathspec') ;
	
	
	#	0	: "rid", 
	#	1	: "pid", 
	#	2	: "chanid", 
	#	3	: "record",
	#	4	: "adapter",
	#	5	: "multid",
	#	6	: "multtype",
	var $json_sched_fields = array('rid', 'pid', 'chanid', 'record', 'adapter', 'multid', 'type') ;
	
	#	0	: "rid", 
	#	1	: "pid", 
	#	2	: "chanid", 
	#	3	: "record",
	var $json_iplay_fields = array('rid', 'pid', 'chanid', 'record') ;
	
	//	0	: "searchTitle", 
	//	1	: "searchDesc", 
	var $json_search_fields = array('title', 'desc', 'genre', 'channel', 'listingsType') ;
	var $sql_search_fields = array(
		'title'			=> 'title', 
		'desc'			=> 'text', 
		'genre'			=> 'genre', 
		'channel'		=> 'channels`.`channel', 
		'listingsType'	=> 'chan_type'
	) ;

	
	#	0	: "chanid", 
	#	1	: "name", 
	#	2	: "show", 
	#	3	: "iplay",
	#	4	: "type",
	#	5	: "display",
	var $json_chans_fields = array('chan_num', 'display_name', 'show', 'iplay', 'chan_type', 'display') ;
	
	#	0	: "pid", 
	#	1	: "rid", 
	#	2	: "rectype", 
	#	3	: "title", 
	#	4	: "text", 
	#	5	: "date", 
	#	6	: "start", 
	#	7	: "duration", 
	#	8	: "chanid", 
	#	9	: "adapter", 
	#	10	: "type",
	#	11	: "record"
	#	12	: "priority"
	#	13	: "file"
	#	14	: "filePresent"
	#	15	: "changed"
	#	16	: "status"
	var $json_recorded_fields   = array(
		'pid', 
		'rid', 
		'rectype', 
		'title', 
		'text', 
		'date', 
		'start', 
		'duration', 
		'chanid', 
		'adapter', 
		'type', 
		'record', 
		'priority',
		'file', 
		'filePresent', 
		'changed', 
		'status' 
	) ; 

	// Channel information - used by the other pages
	var $chaninfo = array() ;
	
	# Map from channel name to chanid
	var $chanids = array() ;

	# Map channel id to channel name
	var $chan_names = array() ;
	
	# Map channel id to channel supports iplay
	var $chan_iplay = array() ;
	
	# Map displayed channel name to broadcast channel name
	var $display_chan_names = array() ;
		
		
	#---------------------------------------------------------------------------------------------------
	# program comparison function
	static function cmp_prog($a, $b)
	{
		$cmp=0;	
	
		# Compare dates
		$a_timestamp = ListingsApp::date_to_timestamp($a['date'], $a['start']) ;		
		$b_timestamp = ListingsApp::date_to_timestamp($b['date'], $b['start']) ;
		$cmp = $a_timestamp - $b_timestamp ;
		
		if ($a_timestamp == $b_timestamp)
		{
			return 0 ;
		}
		return ($a_timestamp > $b_timestamp) ? +1 : -1 ; 		
	}

	#---------------------------------------------------------------------------------------------------
	static function date_to_timestamp($sqldate, $time)
	{
		list($year, $month, $day) = explode('-',$sqldate);
		list($hour, $min, $sec) = explode(':',$time);
		$timestamp = mktime($hour,$min,$sec, $month,$day,$year) ;
	
		return $timestamp ;
	}

  
	
	#========================================================================
	# App handler methods
	#========================================================================

	#----------------------------------
	# Show listing
	function page_handler() 
	{
		// Show template
$this->debug_log_msg("== Listings log=".$this->logging."=== \n") ;
if ($this->logging >= 2) $this->debug_log_msg("== Listings === \n") ;
	}


	#========================================================================
	# JSON methods
	#========================================================================

	#----------------------------------
	# Handle JSON request
	function json_handler() 
	{
		$this->json_extended_prog_fields = array_merge(
			$this->json_prog_fields, 
			$this->json_extended_prog_fields
		) ;
		
		// set debug flag
		$this->irr_debug = $this->params_array['dbg'] ;

if ($this->irr_debug) $this->debug_prt("params_array=", $this->params_array)  ;
				
		
		// Get params
		$json = $this->params_array['json'] ;
		$start_chan = $this->params_array['ch'] ;
		$listings_type = $this->params_array['t'] ;
		$display_date = $this->params_array['dt'] ;

		$START_TIME = $this->params_array['hr'] ;
		$START_TIMESTR = sprintf("%02d:00", $START_TIME) ;
		$START_MINS = $START_TIME * 60 ;
		$END_MINS = $START_MINS + ($this->NUM_HOURS_DISPLAYED * 60) ;

		$datetime = "$display_date $START_TIME:00:00" ;	
		$display_hours = $this->params_array['shw'] ;	

		$start_hour = $START_TIME ;
		$start = $START_TIMESTR ;

		$json_content = "" ;
		
		# recspec
		$recspec = $this->params_array['rec'] ;
		
		# escape spaces
		$recspec = str_replace(' ', '%20%', $recspec) ;
		
		
		
		# Set start date = MIN(display date, today)
		$start_date = $display_date ;
		$start_datetime = $datetime ;

		$today = date("Y-m-d") ;
$this->debug_prt("today=", $today)  ;
$this->debug_prt("start_date=", $start_date)  ;


		$start_dt = new DateTime($start_date);
		$today_dt = new DateTime($today);
$this->debug_prt("today=", $today_dt)  ;
$this->debug_prt("start_date=", $start_dt)  ;
		
		if ($today_dt < $start_dt)
		{
			$start_date = $today ;	
			$start_datetime = "$start_date $START_TIME:00:00" ;	
			
$this->debug_prt(" + today < start_date=", $start_date)  ;
		}
		

		// Create channel maps
		$this->channel_info($listings_type, $start_chan) ;
		
		// Grid
		if ($json == "init")
		{
			$json_content = $this->json_init($display_hours, $listings_type, $datetime, $display_date, $start_hour, $start) ;
		}		
		elseif ($json == "update")
		{
			$json_content = $this->json_update($display_hours, $listings_type, $datetime, $display_date, $start_hour, $start) ;
		}		
		elseif ($json == "rec")
		{
$this->debug_prt("record : ", $recspec)  ;
			$json_content = $this->json_record($recspec, $display_hours, $listings_type, $start_datetime, $start_date, $start_hour, $start) ;
		}		
		
		// RecList
		elseif ($json == "recList")
		{
			// List of requested recordings
			$json_content = $this->json_reclist($start_date) ;
		}		
		elseif ($json == "recListRec")
		{
if ($this->logging >= 2) $this->debug_log_msg("record : $recspec\n") ;
			$json_content = $this->json_recListRec($start_date, $recspec) ;
		}		

		// Recorded
		elseif ($json == "recorded")
		{
			// Set start date to 1 month ago
			$recorded_dt = date_sub($today_dt, new DateInterval("P1M")) ;
			$recorded_date = date_format($recorded_dt, 'Y-m-d') ;
			
			// List of recorded programs
			$json_content = $this->json_recorded($recorded_date) ;
		}		
		
		
		// SearchList
		elseif ($json == "srchList")
		{
			$searchParams = $this->searchParams() ;
			$json_content = $this->json_srchList($start_date, $searchParams) ;
		}		
		elseif ($json == "srchListRec")
		{
			$searchParams = $this->searchParams() ;
			$json_content = $this->json_srchListRec($start_date, $recspec, $searchParams) ;
		}		
		elseif ($json == "srchListFuzzyRec")
		{
			$searchParams = $this->searchParams() ;
			$json_content = $this->json_srchListFuzzyRec($start_date, $recspec, $searchParams) ;
		}		
		
		// Channels display
		elseif ($json == "chanSel")
		{
			$json_content = $this->json_chanSel() ;
		}		
		elseif ($json == "chanSelSet")
		{
			$chanSetting = $this->params_array['show'] ;
			$chanid = $this->params_array['chanid'] ;
			$json_content = $this->json_chanSelSet($chanid, $chanSetting) ;
		}		
		elseif ($json == "chanSelUp")
		{
			$json_content = $this->json_chanSelUp() ;
		}		
		
		// Scan
		elseif ($json == "scanInfo")
		{
			$json_content = $this->json_scanInfo() ;
		}		
		elseif ($json == "scanStart")
		{
			$scan_params = array() ;
			$scan_params['file'] = $this->params_array['file'] ;
			$scan_params['clean'] = $this->params_array['clean'] ;
			$scan_params['adapter'] = $this->params_array['adapter'] ;
			
			$json_content = $this->json_scanStart($scan_params) ;
		}		
		
		
		
		
		//== Reply ==
		if ($this->irr_debug) print "<pre>\n" ;
	
		// reply		
		header('Content-type: text/javascript') ;
		print "{\n" .
			"\"cmd\" : \"" . $json . "\",\n" .
			"\"version\" : \"" . VERSION . "\",\n" .
			"\"data\" : {\n" . $json_content . "}" .
			"}\n" ;

		if ($this->irr_debug) print "</pre>\n" ;
			
if ($this->logging) $this->debug_log_msg("JSON = {\n cmd : \"$json\",\n data : { \n$json_content } }\n") ;
		exit ;
	}
	
	#----------------------------------
	# Get channel information
	function channel_info($listings_type, $start_chan) 
	{
		$query = "SELECT * FROM `".TBL_CHANNELS."`" ;
		$result = $this->query($query) ;

		while ($entry = $this->next()) 
		{
			$chid = $entry['chan_num'] ;
			$entry['display'] = 1 ;
			if (($chid < $start_chan) || (strpos($entry['chan_type'], $listings_type) === false) )
			{
				$entry['display'] = 0 ;
			}
			
			$this->chaninfo[$chid] = $entry ;

			$name = $entry['channel'] ;
			$this->chan_names[$chid] = $name ;
			$this->chan_iplay[$chid] = $entry['iplay'] ;
			
			$display_name = $entry['display_name'] ;
			$this->display_chan_names[$display_name] = $name ;
			
			// reverse map
			$this->chanids[$name] = $chid ;
			$this->chanids[$display_name] = $chid ;
			
		}
$this->debug_prt("CHANINFO:", $this->chaninfo) ;
$this->debug_prt("CHANIDS:", $this->chanids) ;
	}

	//==========================================================================================================================
	// AJAX
	//==========================================================================================================================
	
	//== Grid ================================================================================================
	
	#----------------------------------
	# Init Javascript app
	function json_init($display_hours, $listings_type, $datetime, $date, $start_hour, $start) 
	{
		return $this->_json_data($display_hours, $listings_type, $datetime, $date, $start_hour, $start) ;
	}

	#----------------------------------
	# Update Javascript data
	function json_update($display_hours, $listings_type, $datetime, $date, $start_hour, $start) 
	{
		return $this->_json_data($display_hours, $listings_type, $datetime, $date, $start_hour, $start) ;
	}

	#----------------------------------
	# Change recording(s)
	function json_record($recspec, $display_hours, $listings_type, $datetime, $date, $start_hour, $start) 
	{
		# update recordings
		$msg_json = $this->record_mgr($date, 'rec', array($recspec) ) ;
		
		# Return new schedule
		$json_content = "" ;

		// Recording schedule
		$json_content .= "\"schedule\" : " . $this->_json_schedule() . ",\n" ;

		// Recording iplay schedule
		$json_content .= "\"iplay\" : " . $this->_json_iplay() . ",\n" ;

		// Recording multiplex containers
		$json_content .= "\"multirec\" : " . $this->_json_multirec($display_hours, $listings_type, $datetime, $date, $start) . "" ;

		if ($msg_json)
		{
			$json_content .= ",\n" ;
			$json_content .= "\"message\" : " . $msg_json ;
		}
		$json_content .= "\n" ;
		
		return $json_content ;
	}

	//== RecList ================================================================================================
	
	#----------------------------------
	# Return list of recording(s)
	function json_reclist($start_date) 
	{
		# Return schedule
		$json_content = "" ;

		// Recording schedule
		$json_content .= "\"recList\" : " . $this->_json_reclist($start_date) . "\n" ;
		####$json_content .= "\"recList\" : []\n" ;

		return $json_content ;
	}

	#----------------------------------
	# Return list of recording(s)
	function json_recListRec($start_date, $recspec) 
	{
		# update recordings
		$msg_json = $this->record_mgr($start_date, 'rec', array($recspec) ) ;
		
		# Return schedule
		$json_content = "" ;

		// Recording schedule
		$json_content .= "\"recList\" : " . $this->_json_reclist($start_date) . "" ;

		if ($msg_json)
		{
			$json_content .= ",\n" ;
			$json_content .= "\"message\" : " . $msg_json ;
		}
		$json_content .= "\n" ;

		return $json_content ;
	}

	//== SrchList ================================================================================================
	
	#----------------------------------
	# Return list of recording(s)
	function json_srchList($start_date, $searchParams) 
	{
		# Return schedule
		$json_content = "" ;

		// Search settings
		$json_content .= "\"srchSettings\" : " . $this->_json_srchSettings($searchParams) . ",\n" ;

		// Search results
		$json_content .= "\"srchList\" : " . $this->_json_srchList($start_date, $searchParams) . "\n" ;

		return $json_content ;
	}

	#----------------------------------
	# Change a program's recording level then return list of recording(s)
	function json_srchListRec($start_date, $recspec, $searchParams) 
	{
		# update recordings
		$msg_json = $this->record_mgr($start_date, 'rec', array($recspec) ) ;
		
		# Return schedule
		$json_content = "" ;

		// Search settings
		$json_content .= "\"srchSettings\" : " . $this->_json_srchSettings($searchParams) . ",\n" ;

		// Search results
		$json_content .= "\"srchList\" : " . $this->_json_srchList($start_date, $searchParams) . "" ;

		if ($msg_json)
		{
			$json_content .= ",\n" ;
			$json_content .= "\"message\" : " . $msg_json ;
		}
		$json_content .= "\n" ;

		return $json_content ;
	}

	#----------------------------------
	# Create a new fuzzy recording
	function json_srchListFuzzyRec($start_date, $recspec, $searchParams) 
	{
		# update recordings
		$msg_json = $this->record_mgr($start_date, 'rec', array($recspec) ) ;
		
		# Return json
		$json_content = "" ;
		
		## If the recording was created successfully, then jump to show the RecList
		if (!$msg_json)
		{
			$json_content .= "\"recList\" : " . $this->_json_reclist() . "\n" ;
		}
		else
		{
			## Otherwise, go back to search page (will show a dialog)
			
			// Search settings
			$json_content .= "\"srchSettings\" : " . $this->_json_srchSettings($searchParams) . ",\n" ;
	
			// Search results
			$json_content .= "\"srchList\" : " . $this->_json_srchList($start_date, $searchParams) . "" ;
	
			if ($msg_json)
			{
				$json_content .= ",\n" ;
				$json_content .= "\"message\" : " . $msg_json ;
			}
			$json_content .= "\n" ;
		}

		return $json_content ;
	}

	
	//== Recorded ================================================================================================
	
	#----------------------------------
	# Return list of recording(s)
	function json_recorded($start_date) 
	{
		# Return schedule
		$json_content = "" ;

		// Recording schedule
		$json_content .= "\"recorded\" : " . $this->_json_recorded($start_date) . "\n" ;

		return $json_content ;
	}

	
	
	//== ChanSel ================================================================================================
	
	#----------------------------------
	# Return list of channels
	function json_chanSel() 
	{
		# Return info
		$json_content = "" ;

		// channels
		$json_content .= "\"chanSel\" : " . $this->_json_chanSel() . "\n" ;

		return $json_content ;
	}

	#----------------------------------
	# Return list of channels after updating to match latest scan
	function json_chanSelUp() 
	{
		// Get server to update channels
		$this->chan_update_cmd() ;
		
		
		# Return info
		$json_content = "" ;

		// channels
		$json_content .= "\"chanSel\" : " . $this->_json_chanSel() . "\n" ;

		return $json_content ;
	}

	#----------------------------------
	# Return list of recording(s)
	function json_chanSelSet($chanid, $chanSetting) 
	{
		# update channel settings
		$query = "UPDATE `".TBL_CHANNELS."`
			SET `show`='$chanSetting'
			WHERE `chan_num`='$chanid'
		" ;
		$result = $this->query($query) ;
		
		$this->chaninfo[$chanid]["show"] = $chanSetting ;
		
	
		# Return info
		$json_content = "" ;

		// Channels list		
		$json_content .= "\"chans\" : " . $this->_json_chans($listings_type) . ",\n" ;
		
		// channels
		$json_content .= "\"chanSel\" : " . $this->_json_chanSel() . "\n" ;

		return $json_content ;
	}

	
	//== Scan ================================================================================================
	
	#----------------------------------
	# Return scan info
	function json_scanInfo() 
	{
		# Return info
		$json_content = "" ;

		// channels
		$json_content .= "\"scan\" : " . $this->scan_info_cmd() . "\n" ;

		return $json_content ;
	}

	#----------------------------------
	# Return scan info
	function json_scanStart( $params = array() ) 
	{
		# Return info
		$json_content = "" ;

		// channels
		$json_content .= "\"scan\" : " . $this->scan_start_cmd($params) . "\n" ;

		return $json_content ;
	}

	
	
	//==========================================================================================================================
	// JSON
	//==========================================================================================================================
	
	
	#----------------------------------
	# Init Javascript app
	function _json_data($display_hours, $listings_type, $datetime, $date, $start_hour, $start) 
	{
		$json_content = "" ;

		// Settings
		$json_content .= "\"settings\" : " . $this->_json_settings($display_hours, $listings_type, $datetime, $date, $start_hour, $start) . ",\n" ;

		// Recording schedule
		$json_content .= "\"schedule\" : " . $this->_json_schedule() . ",\n" ;

		// Recording iplay schedule
		$json_content .= "\"iplay\" : " . $this->_json_iplay() . ",\n" ;

		// Recording multiplex containers
		$json_content .= "\"multirec\" : " . $this->_json_multirec($display_hours, $listings_type, $datetime, $date, $start) . ",\n" ;

		// Channels list		
		$json_content .= "\"chans\" : " . $this->_json_chans($listings_type) . ",\n" ;
		
		// Program details
		$json_content .= "\"progs\" : " . $this->_json_progs($display_hours, $listings_type, $datetime, $date, $start) . "\n" ;

		return $json_content ;
	}



	#----------------------------------
	# settings
	function _json_settings($display_hours, $listings_type, $datetime, $date, $start_hour, $start) 
	{
		$json_content = "" ;

		$json_content .= "\"PM_VERSION\": \"" . PM_VERSION . "\",\n" ;
		$json_content .= "\"DISPLAY_DATE\": \"" . $date . "\",\n" ;
		$json_content .= "\"DISPLAY_HOUR\": " . $start_hour . ",\n" ;
		$json_content .= "\"DISPLAY_PERIOD\": " . $display_hours . ",\n" ;
		$json_content .= "\"LISTINGS_TYPE\": \"" . $listings_type . "\",\n" ;

		# Get number of PVRs in use:
		$this->record_mgr($date, "info") ;
		$json_content .= "\"NUM_PVRS\": " . $this->NUM_PVRS . ",\n" ;
		$json_content .= "\"PVRS\": " . $this->_json_pvrs() . "\n" ;
		
		return "{" . $json_content . "}" ;
	}

	#----------------------------------
	# Get pvr list in a Javascript object
	function _json_pvrs() 
	{
		$json_content = "" ;

		foreach ($this->PVRS as $idx => $entry)
		{
			$content = "" ;
			foreach ($entry as $key => $value)
			{
				if ($content) $content .= ",\n" ;
				$content .= "\"" . $key . "\" : " . "\"" . $value . "\"" ;
			}
			if ($json_content) $json_content .= ",\n" ;
			$json_content .= "{" . $content . "}" ;
		}
		return "[" . $json_content . "]" ;
	}
	
	#----------------------------------
	# Get channels in a Javascript object
	function _json_chans() 
	{
		$json_content = "" ;

		// split into sections: one set for TV channels, the other for RADIO channels
		foreach (array('tv', 'radio') as $ch_type)
		{
			$chan_content = "" ;
			foreach ($this->chaninfo as $chid => $entry)
			{
				if (strpos($entry['chan_type'], $ch_type) !== false)
				{
					$obj = $this->_json_object("", $entry, $this->json_chans_fields) ;
		
					if ($chan_content) $chan_content .= ",\n" ;
					$chan_content .= "\"" . $chid . "\" : " . $obj ;
				}
			}
			
			if ($json_content) $json_content .= ",\n" ;
			$json_content .= "\"" . $ch_type . "\" : {\n"  ;
			$json_content .= $chan_content ;
			$json_content .= "}" ;
		}
		

		return "{" . $json_content . "}" ;
	}

	
	#----------------------------------
	# Get list of all channels in a Javascript object
	function _json_chanSel($ch_type) 
	{
		$json_content = "" ;

		foreach ($this->chaninfo as $chid => $entry)
		{
			# ensures hd-tv & tv types match 'tv' type
			if (!$ch_type || (strpos($entry['chan_type'], $ch_type) !== false))
			{
				$json_content = $this->_json_object($json_content, $entry, $this->json_chans_fields) ;
			}
		}
		
		return "[" . $json_content . "]" ;
	}

	#----------------------------------
	# Get programs in a Javascript object
	function _json_progs($display_hours, $listings_type, $datetime, $date, $start) 
	{
		$json_content = "" ;

		$chans = "" ;

//$this->debug_prt("_json_progs()", $this->chaninfo) ;
		
		# Now get the program entries for this channel and date
		foreach ($this->chaninfo as $chanid => $chan_entry)
		{
			// skip non-displayed channels
			if (!$chan_entry['display'])
			{
				continue ;
			}
			
			$chan_name = $chan_entry['channel'] ;
//$this->debug_prt("Chan $chan_name:", $chan_entry) ;
			
			// Need to find all programs which satisfy the criteria such that part or all of the program appears in the display window
			// 
			//           START                                 END
			//             |                                    |
			//             |                                    |
			//  :-A--:  :-B---:    :-C---:                   :-D----:  :-E----:
			//     X      ok          ok                       ok          X
			//             |                                    |
			//             :-F---:                       :-G----:
			//             |  ok                            ok  |
			//             |                                    |
			//
			// This is satisfied if : (a) program start < END, and (b) program end > START
			//		

			// get displayed hours
			$query = "SELECT *
                      FROM `".TBL_LISTINGS."`
                      WHERE `channel`='$chan_name' AND
                      		 UNIX_TIMESTAMP(CONCAT(`date`, ' ', `start`)) < UNIX_TIMESTAMP(ADDTIME('$datetime', '$display_hours:00:00')) AND 
                      		 UNIX_TIMESTAMP(ADDTIME(CONCAT(`date`, ' ', `start`), `duration`)) > UNIX_TIMESTAMP('$datetime')
						ORDER BY `date`, `start`
			" ;


			$result = $this->query($query) ;
$this->debug_prt("Query:", $query) ;
$this->debug_prt("Result:", $result) ;

	
			//*** Gather information ****
			$progs = "" ;
			while ($entry = $this->next()) 
			{
$this->debug_prt("Entry:", $entry) ;

				// Add the information to the program list for this channel
				$prog = $this->create_prog($entry, $chanid, $date, $start) ;

				$progs = $this->_json_object($progs, $prog, $this->json_prog_fields) ;

			}
			
			if ($chans) $chans .= ",\n" ;
			$chans .= "\"". $chanid . "\" : [\n" . $progs . "]" ; 
			
		} // each channel


		$json_content .= $chans ;
		
		return "{" . $json_content . "}" ;
	}

	#----------------------------------
	# Get recording schedule in a Javascript object
	function _json_schedule() 
	{
		$json_content = "" ;

		# Get complete schedule	for progs
		$query = "SELECT rid, pid, channel, record, adapter, multid  FROM `".TBL_SCHEDULE."`" ;
		$result = $this->query($query) ;

		while ($entry = $this->next()) 
		{
			
	$this->debug_prt(TBL_SCHEDULE." sched entry=", $entry) ;

				// only add recordings that are still valid - i.e. the channel name still matches
			if (array_key_exists($entry['channel'], $this->chanids))
			{
	
				# map network channel name to channel id
				$entry['chanid'] = $this->chanids[$entry['channel']] ;
	$this->debug_prt(TBL_SCHEDULE." found chanid=", $entry['chanid']) ;
	
				# Set the program 'type':
				#   'p'  = simple program
				#   'mp' = program in a multiplex container
				#   'm'  = multiplex container
				#
				$type = 'p' ;
				$multid = $entry['multid'] ;
				if ($multid > 0)
				{
					$type = 'mp' ;
				}
				$entry['type'] = $type ;
				
				$json_content = $this->_json_object($json_content, $entry, $this->json_sched_fields) ;
			}
		}

		
		return "[" . $json_content . "]" ;
	}

	#----------------------------------
	# Get recording iplayer schedule in a Javascript object
	function _json_iplay() 
	{
		$json_content = "" ;

		# Get complete schedule	for progs
		$query = "SELECT rid, pid, channel, record  FROM `".TBL_IPLAY."`" ;
		$result = $this->query($query) ;

		while ($entry = $this->next()) 
		{
			
	$this->debug_prt(TBL_IPLAY." sched entry=", $entry) ;

			// only add recordings that are still valid - i.e. the channel name still matches
			if (array_key_exists($entry['channel'], $this->chanids))
			{
				# map network channel name to channel id
				$entry['chanid'] = $this->chanids[$entry['channel']] ;
				$json_content = $this->_json_object($json_content, $entry, $this->json_iplay_fields) ;
			}
		}
		
		return "[" . $json_content . "]" ;
	}

	#----------------------------------
	# Get requested recording list - combine schedule table with listings info
	function _json_reclist($start_date) 
	{
		$json_content = "" ;

		$start_time = "00:00" ;
		
		$reclist = $this->_reclist($start_date, $start_time) ;
		$schedule = $this->_schedlist($start_date, $start_time) ;
		$iplay = $this->_schedIplayList($start_date, $start_time) ;
		
		foreach ($reclist as $rid => $entry)
		{
			// Recording request
			$sched = "" ;
			foreach ($this->json_recording_fields as $key)
			{
				if ($sched) $sched .= ",\n" ;

				$str = $entry[$key] ;
				# remove ""s
				$str = str_replace('"', '', $str) ;
				$sched .= '  "' . $str . "\"" ;
			}
			
			// Scheduled recordings list
			if ($sched) $sched .= ",\n" ;
			$sched .= "[" ;
			$progs = "" ;
			if (array_key_exists($rid, $schedule))
			{
				$prog_list = $schedule[$rid] ;
				foreach ($prog_list as $pid => $prog)
				{
					if ($progs) $progs .= ",\n" ;
	
					$progs .= "  [\n" ;
					foreach ($this->json_prog_fields as $key)
					{
						$str = $prog[$key] ;
						# remove ""s
						$str = str_replace('"', '', $str) ;
						$progs .= '    "' . $str . "\",\n" ;
					}
					$progs .= '""' . "\n" ;
					$progs .= "  ]\n" ;
				}
			}			
			if (array_key_exists($rid, $iplay))
			{
				$prog_list = $iplay[$rid] ;
				foreach ($prog_list as $pid => $prog)
				{
					if ($progs) $progs .= ",\n" ;
	
					$progs .= "  [\n" ;
					foreach ($this->json_prog_fields as $key)
					{
						$str = $prog[$key] ;
						# remove ""s
						$str = str_replace('"', '', $str) ;
						$progs .= '    "' . $str . "\",\n" ;
					}
					$progs .= '""' . "\n" ;
					$progs .= "  ]\n" ;
				}
			}			
			$sched .= $progs ;
			$sched .= "]" ;
			
			if ($json_content) $json_content .= ",\n" ;
			$json_content .= "[" . $sched . "]" ;
		}

		
		return "[" . $json_content . "]" ;
	}

	

	#----------------------------------
	# Get requested recording list - combine schedule table with listings info
	function _search_query($search, $type, $spec) 
	{
		if ($spec)
		{
			# check for anchors
			$len = strlen($spec) ;
			if (strpos($spec, "$") === ($len-1))
			{
				$spec = substr($spec, -1) ;
			}
			else
			{
				$spec = "$spec%" ;
			}
			
			if (strpos($spec, "^") === 0)
			{
				$spec = substr($spec, 1) ;
			}
			else
			{
				$spec = "%$spec" ;
			}
			
			# Create SQL
			if ($search) $search .= " AND " ;
			
			$sqlkey = $this->sql_search_fields[$type] ;
			$search .= "`$sqlkey` like '$spec'" ;
		}
		return $search ;
	}
	
	#----------------------------------
	# Get requested recording list - combine schedule table with listings info
	function _json_srchList($start_date, $searchParams) 
	{
		$json_content = "" ;

//$this->debug_prt("_json_srchList($start_date, $srchTitle, $srchDesc, $srchGenre, $srchChan)") ;
$this->debug_prt("_json_srchList($start_date)", $searchParams) ;
		
		$search = "" ;
		foreach ($this->json_search_fields as $key)
		{
			$search = $this->_search_query($search, $key, $searchParams[$key]) ;
$this->debug_prt(" + key=$key : search now = $search") ;
		}
		
$this->debug_prt("search=$search") ;
		
		if ($search)
		{
			$start_time = "00:00" ;
			
			// List of all programs
			$query = "SELECT *
                 FROM `".TBL_LISTINGS."`,`".TBL_CHANNELS."`
                 WHERE $search AND `date` >= '$start_date'
                 	AND `".TBL_LISTINGS."`.channel = `".TBL_CHANNELS."`.channel
						ORDER BY `date`, `start`
			" ;

			$result = $this->query($query) ;
$this->debug_prt("Query:", $query) ;
$this->debug_prt("Result:", $result) ;

			$srch_prog = 0 ;
			$prog_list = array() ;
			while ($entry = $this->next()) 
			{
				$entry['rid'] = '0' ;
				$entry['record'] = '0' ;
				$entry['priority'] = '50' ;
				
				// only add recordings that are still valid - i.e. the channel name still matches
				if (array_key_exists($entry['channel'], $this->chanids))
				{
					// Add the information to the program list for this channel
					$prog = $this->create_prog($entry, $this->chanids[$entry['channel']], $start_date, $start_time) ;
					$pid = $prog['pid'] ;
					$prog_list[$pid] = $prog ;
					
					// pick the first real program
					if (!$srch_prog) $srch_prog = $prog ;
				}				
			}
$this->debug_prt("prog_list", $prog_list) ;
			
			// List of scheduled recordings - indexed as [rid][pid]
			// 	[id	rid	pid	channel	record	priority Lower numbers are higher priority	adapter	multid]
			$schedule = $this->_schedlist($start_date, $start_time) ;

			// Create a map of pid->rid
			$pid_sched_map = array() ;
			foreach ($schedule as $rid => $prog_array)
			{
				foreach ($prog_array as $pid => $prog)
				{
					$pid_sched_map[$pid] = $prog ;
				}
			}
$this->debug_prt("PID sched", $pid_sched_map) ;
$this->debug_prt("srch_prog", $srch_prog) ;
			
			$seen_pid = array() ;
			$results = array() ;

			// Use any found program as the "dummy" container for the search
			if (!$srch_prog)
			{
				return "[" . $json_content . "]" ;
			}
			
			// For each prog found in the search, look up in the scheduled recordings to see if there is a recording
			foreach ($prog_list as $pid => $prog)
			{
$this->debug_prt("Checking prog $pid") ;
				if (!array_key_exists($pid, $seen_pid))
				{
					if (array_key_exists($pid, $pid_sched_map))
					{
						$prog = $pid_sched_map[$pid] ;
					}
					$date = $prog["date"] ;
					if (!array_key_exists($date, $results))
					{
						$results[$date] = array() ;
					}
					
					array_push($results[$date], $prog) ;
$this->debug_prt(" + no rid") ;
				}
				$seen_pid[$pid]=1 ;
			}
			
$this->debug_prt("RESULTS", $results) ;
			
			
			// Now create JSON from array
			foreach ($results as $date => $prog_list)
			{
				// Date
				$sched = "" ;
				$sched .= '  "' . $date . "\"" ;
				
				// Scheduled recordings list
				if ($sched) $sched .= ",\n" ;
				$sched .= "[" ;

				$progs = "" ;
				foreach ($prog_list as $prog)
				{
					if ($progs) $progs .= ",\n" ;
	
					$progs .= "  [\n" ;
					foreach ($this->json_extended_prog_fields as $key)
					{
						$str = $prog[$key] ;
						# remove ""s
						$str = str_replace('"', '', $str) ;
						$progs .= '    "' . $str . "\",\n" ;
					}
					$progs .= '""' . "\n" ;
					$progs .= "  ]\n" ;
				}
				$sched .= $progs ;
				
				$sched .= "]" ;
				
				if ($json_content) $json_content .= ",\n" ;
				$json_content .= "[" . $sched . "]" ;
			}
			
		
		}
		
		return "[" . $json_content . "]" ;
	}
	
	
	#----------------------------------
	# Get list of recorded programs
	function _json_recorded($start_date) 
	{
		$json_content = "" ;

$this->debug_prt("_json_recorded($start_date)") ;
		
		// List of all recorded programs in most recent order
		$query = "SELECT *
            FROM `".TBL_RECORDED."`
            WHERE `status` like '%recorded%' AND `changed` >= '$start_date'
			ORDER BY `changed` DESC
		" ;

		$result = $this->query($query) ;
$this->debug_prt("Query:", $query) ;
$this->debug_prt("Result:", $result) ;

		while ($entry = $this->next()) 
		{
			// Get file presence
			if (!$entry["file"])
			{
				continue ;
			}
			$entry["filePresent"] = 0 ;
			
			$file = $entry["file"] ;
			if (!file_exists($file))
			{
				// see if it's an audio file that's been converted
				$path_parts = pathinfo($file) ;
$this->debug_prt("File $file !exists : parts=", $path_parts) ;
				$file = $path_parts['dirname'] . '/' . $path_parts['filename'] . '.mp3' ; 
$this->debug_prt("New file: $file") ;
			}
$exists=file_exists($file) ;
$isfile=is_file($file) ;
$size=filesize($file);
$this->debug_prt("exists=$exists, isfile=$isfile, size=$size File: ".$file) ;

			if (file_exists($file) && is_file($file) && (abs(filesize($file)) > 0) )
			{
				// valid non-zero file
				$entry["filePresent"] = 1 ;
				$entry["file"] = $file ;
			}
			
			// Now create JSON
			$json_content = $this->_json_object($json_content, $entry, $this->json_recorded_fields) ; 
		}
		
		return "[" . $json_content . "]" ;
	}
	
	
	#----------------------------------
	# Return the current search params
	function _json_srchSettings($searchParams) 
	{
		$json_content = "" ;
		
		// Use the "display name" passed from the javascript & send it back as the channel
		$searchParams['channel'] = $searchParams['display_channel'] ;
		
		$json_content = $this->_json_object($json_content, $searchParams, $this->json_search_fields) ;

		return $json_content ;
	}
	
	#----------------------------------
	# Get multiplex recording info in a Javascript object
	function _json_multirec($display_hours, $listings_type, $datetime, $date, $start) 
	{
		$json_content = "" ;

		$query = "SELECT multid, date, start, duration, adapter  FROM `".TBL_MULTIREC."`
						ORDER BY `date`, `start`
		" ;
		$result = $this->query($query) ;

		while ($entry = $this->next()) 
		{
			
	$this->debug_prt(TBL_MULTIREC." sched entry=", $entry) ;

			// Add the information to the program list for this channel
			$multirec = $this->create_multirec($entry, $date, $start) ;
			$json_content = $this->_json_object($json_content, $multirec, $this->json_multirec_fields) ;
		}

		
		return "[" . $json_content . "]" ;
	}

	#----------------------------------
	# Create a JSON message object
	function _json_msg($type, $text_array) 
	{
		$json_content = "" ;

		$json_content .= "\"type\" : \"" . $type ."\",\n" ;
		$text_content = "" ;
		
		array_push($text_array, " ") ;
		foreach ($text_array as $text)
		{
			# Must escape text
			$text = str_replace('"', '', $text) ;
			$text = str_replace("\n", '', $text) ;
		
			if ($text_content) $text_content .= ",\n" ;
			$text_content .= '"' . $text . '"' ;
		}
		
		$json_content .= '"content" : [' . $text_content . "]\n" ;
		
		return $json_content ;
	}


	
	//==========================================================================================================================
	// UTILS
	//==========================================================================================================================
	
	
	#----------------------------------
	# Create a JSON (ARRAY) object from an HASH ($entry) and an ARRAY ($fields_array) containing
	# the list of fields to be added (and in which order)
	# Appends to an existing JSON string
	#
	function _json_object($json_content, $entry, $fields_array) 
	{
		$obj = "" ;
		foreach ($fields_array as $key)
		{
			if ($obj) $obj .= ",\n" ;
			
			# remove ""s
			$str = $entry[$key] ;
			$str = str_replace('"', '', $str) ;
			$str = str_replace( array("\r\n", "\n\r", "\n", "\r"), ' ', $str) ;
			$obj .= ' "' . $str . "\"" ;
		}
		$new = "[" . $obj . "]" ;

		if ($json_content) $json_content .= ",\n" ;
		$json_content .= $new ;
		
		return $json_content ;
	}

	//----------------------------------
	function is_assoc ($arr) {
        return (is_array($arr) && count(array_filter(array_keys($arr),'is_string')) == count($arr));
    }

	#----------------------------------
	# Create a JSON (ARRAY) object from a hierarchical ARRAY
	#
	function _json_from_array($json_content, $array) 
	{
		$obj = "" ;
		
		foreach ($array as $value)
		{
			if ($obj) $obj .= ",\n" ;
			
			if ($this->is_assoc($value))
			{
				$obj .= $this->_json_from_hash("", $value) ;
			}
			elseif (is_array($value))
			{
				$obj .= $this->_json_from_array("", $value) ;
			}
			else
			{
				# remove ""s
				$str = $value ;
				$str = str_replace('"', '', $str) ;
				$obj .= ' "' . $str . '"' ;
			}
			
		}
		$new = "[" . $obj . "]" ;

		if ($json_content) $json_content .= ",\n" ;
		$json_content .= $new ;
		
		return $json_content ;
	}

    
	#----------------------------------
	# Create a JSON (HASH) object from a hierarchical HASH
	#
	function _json_from_hash($json_content, $hash) 
	{
		$obj = "" ;
		
		foreach ($hash as $key => $value)
		{
			if ($obj) $obj .= ",\n" ;
			$obj .= ' "' . $key . '" : ' ;
			
			if ($this->is_assoc($value))
			{
				$obj .= $this->_json_from_hash("", $value) ;
			}
			elseif (is_array($value))
			{
				$obj .= $this->_json_from_array("", $value) ;
			}
			else
			{
				# remove ""s
				$str = $value ;
				$str = str_replace('"', '', $str) ;
				$obj .= ' "' . $str . '"' ;
			}
		}
		$new = "{" . $obj . "}" ;

		if ($json_content) $json_content .= ",\n" ;
		$json_content .= $new ;
		
		return $json_content ;
	}

	
	
	#----------------------------------
	# Get programs in a Javascript object
	function _get_num_pvrs() 
	{
		$num_pvrs = 1 ;
		
		// get max adapter number
		$query = "SELECT adapter
                    FROM `".TBL_SCHEDULE."`
                    group by adapter
					order by adapter desc
					limit 1
		" ;


		$result = $this->query($query) ;
		if ($entry = $this->next())
		{
			$num_pvrs = $entry["adapter"] + 1 ;
		}
	
		return $num_pvrs ;			
	}
	
	
	#----------------------------------
	# Return an array of the scheduled recordings - indexed by recording id
	function _schedlist($start_date, $start_time) 
	{
		$schedule = array() ;
		
		# Get complete schedule	for progs
		$query = "SELECT rid, pid, channel, record, adapter, priority, multid  FROM `".TBL_SCHEDULE."`
			WHERE `date` >= '".$start_date."'
		" ;
		$result = $this->query($query) ;
	$this->debug_prt("query=", $query) ;
		
		while ($entry = $this->next()) 
		{
			$pid = $entry['pid'] ;
			$schedule[$pid] = $entry ;
		}
		
		$rid_list = array() ;
		foreach ($schedule as $pid => $entry)
		{
	$this->debug_prt(TBL_SCHEDULE." sched entry=", $entry) ;

			$chan_name = $entry['channel'] ;
			$rid = $entry['rid'] ;
			
			// only add recordings that are still valid - i.e. the channel name still matches
			if (array_key_exists($entry['channel'], $this->chanids))
			{
				if (!array_key_exists($rid, $rid_list))
				{
					$rid_list[$rid] = array() ;
				}
				
				// Get program title & description
				$pquery = "SELECT *
	                      FROM `".TBL_LISTINGS."`
	                      WHERE `channel`='$chan_name' AND
	                      		 `pid`='$pid'
							LIMIT 1
				" ;
				
				$result = $this->query($pquery) ;
				$pentry = $this->next() ;
	
				if (!array_key_exists('pid', $pentry))
				{
					// skip empty
					continue ;
				}
				
	$this->debug_prt("query=$pquery : ", $result) ;
	$this->debug_prt(TBL_LISTINGS." pentry=", $pentry) ;
	
				// Copy over requested recording fields
				foreach ($this->prog_record_fields as $key)
				{
					$pentry[$key] = $entry[$key] ;
				}
				
				// Add the information to the program list for this channel
				$prog = $this->create_prog($pentry, $this->chanids[$chan_name], $start_date, $start_time) ;
							
				# Set the program 'type':
				#   'p'  = simple program
				#   'mp' = program in a multiplex container
				#   'm'  = multiplex container
				#
				$type = 'p' ;
				$multid = $entry['multid'] ;
				if ($multid > 0)
				{
					$type = 'mp' ;
				}
				$prog["type"] = $type ;
				
				$rid_list[$rid][$pid] = $prog ;
	
				$this->debug_prt(TBL_SCHEDULE." sched entry : final prog=", $prog) ;
			}
		}

	$this->debug_prt("_schedlist=", $rid_list) ;
		
		return $rid_list ;
	}

	
	
	#----------------------------------
	# Return an array of the scheduled IPLAYER recordings - indexed by recording id
	function _schedIplayList($start_date, $start_time) 
	{
		$schedule = array() ;
		
		# Get complete schedule	for progs
		$query = "SELECT rid, pid, prog_pid, channel, record, date, start  FROM `".TBL_IPLAY."`
			WHERE `date` >= '".$start_date."'
		" ;
		$result = $this->query($query) ;
	$this->debug_prt("query=", $query) ;
		
		while ($entry = $this->next()) 
		{
			$id = $entry['pid'] ;
			$schedule[$id] = $entry ;
		}
		
		$rid_list = array() ;
		foreach ($schedule as $id => $entry)
		{
	$this->debug_prt(TBL_IPLAY." sched entry=", $entry) ;

			$chan_name = $entry['channel'] ;
			$rid = $entry['rid'] ;
			$pid = $entry['prog_pid'] ;
			
			// only add recordings that are still valid - i.e. the channel name still matches
			if (array_key_exists($chan_name, $this->chanids))
			{
	$this->debug_prt(TBL_IPLAY." Found chanid=".$this->chanids[$chan_name]) ;
				if (!array_key_exists($rid, $rid_list))
				{
					$rid_list[$rid] = array() ;
				}
				
				// Get program title & description
				$pquery = "SELECT *
	                      FROM `".TBL_LISTINGS."`
	                      WHERE `channel`='$chan_name' AND
	                      		 `pid`='$pid'
							LIMIT 1
				" ;
				$result = $this->query($pquery) ;
				$pentry = $this->next() ;
				
				if (!array_key_exists('pid', $pentry))
				{
					// skip empty
					continue ;
				}
				
	$this->debug_prt("listings query=", $pquery) ;
	$this->debug_prt(TBL_IPLAY." orig prog entry=", $pentry) ;
	
				// Copy over requested fields
				foreach ($this->prog_record_fields as $key)
				{
					$pentry[$key] = $entry[$key] ;
				}
				
				// Iplay recordings are special!
				$pentry['date'] = $entry['date'] ;
				$pentry['start'] = $entry['start'] ;
				
	$this->debug_prt(TBL_IPLAY." prog entry=", $pentry) ;
				
				// Add the information to the program list for this channel
				$prog = $this->create_prog($pentry, $this->chanids[$chan_name], $start_date, $start_time) ;
							
				$rid_list[$rid][$id] = $prog ;
	
				$this->debug_prt(TBL_SCHEDULE." sched entry : final prog=", $prog) ;
			}
		}

	$this->debug_prt("_schedIplayList=", $rid_list) ;
		
		return $rid_list ;
	}

	
	
	#----------------------------------
	# Return an array of the requested recording list - indexed by record id
	function _reclist($start_date, $start_time) 
	{
		$schedule = array() ;
		
		# Get complete schedule	for progs
		# Either get any multiple recording (record > 1) OR any single recording (record=1) where date>=TODAY
		$query = "SELECT id, pid, title, channel, date, start, duration, record, priority, pathspec  FROM `".TBL_RECORDING."`
			WHERE (`date` >= '".$start_date."' AND `record` = 1) OR (`record` > 1)
		" ;
		$result = $this->query($query) ;
	$this->debug_prt("query=", $query) ;
		
		while ($entry = $this->next()) 
		{
			$rid = $entry['id'] ;
			$entry['rid'] = $rid ;
			
			// only add recordings that are still valid - i.e. the channel name still matches
			if (array_key_exists($entry['channel'], $this->chanids))
			{
				$entry['chanid'] = $this->chanids[$entry['channel']] ;
				
				# Set up times
				$entry = $this->set_rec_times($entry, $entry, $start_date, $start_time) ;		
				
				$schedule[$rid] = $entry ;
			}
		}
	$this->debug_prt("_reclist=", $schedule) ;
		
		return $schedule ;
	}


	
	
	#========================================================================
	# Record manager methods
	#========================================================================


	#---------------------------------------------------------------------------------------------------
	function record_mgr($date, $cmd, $args=array())
	{
	global $PERL_LIBS, $DVB_RECORD_MGR ;

		$output=array() ;
		$results=array() ;
		$execcmd = "" ;
		
		$json = "" ;
		
		switch($cmd)
		{
			# change recording
			case "rec":
				$execcmd=REC_MGR_REC ;

				$options=$args[0] ;
				$options = str_replace('"', "'", $options) ;
				$options = str_replace('$', '%', $options) ;

				$execcmd .= " \"$options\" -date $date" ;
//				$execcmd .= " " . escapeshellarg($options) . " -date $date" ;
				break ;

			# get info
			case "info":
				$execcmd=REC_MGR_INFO ;
				break ;
		}
		
		if ($execcmd)
		{
$this->debug_prt("RUN: $execcmd\n") ;
//if ($this->logging >= 2) $this->debug_log_msg("RUN: $execcmd $options\n") ;

			// get server to run command
			$retval = 0 ;
			$output = array() ;
			list($retval, $output) = $this->server_cmd($execcmd) ;


	#$this->handle_error($output) ;

$this->debug_prt("REPLY: $retval : ", $output) ;
if ($this->logging >= 2) $this->debug_log_msg("REPLY: $retval : ") ;
if ($this->logging >= 2) $this->debug_log_var($output) ;

			## process output
			#
			# Should be of the form:
			#	<?php
			#	$msg_type = "warning" ;
			#	$messages = array(
			#		"line 1",
			#		"another line"
			#	) ;
			#	
			#
			$messages = array() ;
			$msg_type = "" ;
			
			$text = array() ;
			list($php, $text) = $this->server_output_php($output) ;
			if ($php)
			{
				eval("$php") ;
			}

			## Handle errors
			$json = $this->handle_cmd_errors($json, $retval, $messages, $msg_type, $text) ;
			
			switch($cmd)
			{
				# change recording
				case "rec":
					break ;
	
				# get info
				case "info":
					# Expect the command to have set the number of pvrs
					if ($NUM_PVRS)
					{
						$this->NUM_PVRS = $NUM_PVRS ;
					}
					if ($PVRS)
					{
						$this->PVRS = $PVRS ;
					}
					break ;
			}
			
			
		}	
		
		return $json ;
	}
	
	#---------------------------------------------------------------------------------------------------
	function chan_update_cmd()
	{
		// get server to run command
		list($retval, $output) = $this->server_cmd("dvb_chans") ;
	}
	
	#---------------------------------------------------------------------------------------------------
	function scan_info_cmd()
	{
		$json = "" ;

		// get server to run command
		list($retval, $output) = $this->server_cmd("dvb_scan_info") ;

$this->debug_log_msg("scan_info_cmd() retval=$retval \n") ;
		
		## process output
		#
		# Should be of the form:
		#	<?php
		#	$msg_type = "warning" ;
		#	$messages = array(
		#		"line 1",
		#		"another line"
		#	) ;
		#	
		#
		$messages = array() ;
		$msg_type = "" ;
		
		$text = array() ;
		list($php, $text) = $this->server_output_php($output) ;
		if ($php)
		{
			$STATUS = array() ;
			eval("$php") ;
			
			$json = $this->_json_from_hash($json, $STATUS) ;
			
			if (array_key_exists("BUSY", $STATUS))
			{
				if ($STATUS["BUSY"])
				{
					array_push($messages, "Adapter already busy, please try again later ") ;
				}
			}
		}
		else
		{
			$json = "{}" ;
		}
$this->debug_log_msg(" + json=$json\n") ;
		
		## Handle errors
		$json = $this->handle_cmd_errors($json, $retval, $messages, $msg_type, $text) ;
			
		return $json ;
	}
	
	#---------------------------------------------------------------------------------------------------
	function scan_start_cmd( $params = array() )
	{
		$args = "" ;
		if ($params['adapter'])
		{
			$args .= "-a " . $params['adapter'] . " " ;
		}
		if ($params['clean'])
		{
			$args .= "-clean " ;
		}
		
		if ($params['file'])
		{
			$args .= $params['file'] ;
		}
		else
		{
			$args .= DVBT_FREQFILE ;
		}
		
		// get server to run command
		list($retval, $output) = $this->server_cmd("dvb_scan $args") ;

		return $this->scan_info_cmd() ;
	}
	
	#---------------------------------------------------------------------------------------------------
	function server_cmd($execcmd)
	{
		$retval = 0 ;
		$output = array() ;
		$fp = fsockopen("localhost", SERVER_PORT, $errno, $errstr, 30);
		if (!$fp) 
		{
			$retval = SERVER_DOWN ;
		} 
		else 
		{
			fwrite($fp, "$execcmd\n");
			while (!feof($fp)) 
			{
				array_push($output, fgets($fp, 512)) ;
			}
			fclose($fp);
		}
		
		return array($retval, $output) ;
		
	}

	#---------------------------------------------------------------------------------------------------
	function server_output_php( $output = array() )
	{
		$text = array() ;
		$php = "" ;

		$in_php = false ;
		foreach ($output as $line)
		{
			# look for php
			if (strpos($line, '<?php') !== false)
			{
				//$php .= $line . "\n" ;
				$in_php = true ;
			}
			elseif ($in_php)
			{
				if (strpos($line, '?>') !== false)
				{
					//$php .= $line . "\n" ;
					$in_php = false ;
				}
				else
				{
					$php .= $line ;
				}
			}
			else 
			{
				array_push($text, $line) ;
			}
		}

		return array($php, $text) ;
	}

	//----------------------------------------------------------------------
	function handle_cmd_errors($json, $retval, $messages=array(), $msg_type="", $text=array())
	{
$this->debug_log_msg("handle_cmd_errors(rc=$retval, type=$msg_type)\n") ;
		if ($retval!=0)
		{
			$msg_type = "error" ;
			if (!count($messages))
			{
				$new_message = "" ;
				if ($retval == SERVER_DOWN)
				{
					$new_message = "Unable to contact QuartzPVR server" ;
$this->debug_log_msg(" + server down\n") ;
				}
				else
				{
					$new_message = "Unexpected error when running Perl script program scheduler : " . $retval ;
				}
				array_push($messages,$new_message) ;
				$res = array_merge($messages, $text) ;
$this->debug_log_msg(" + new message=" . $new_message) ;
$this->debug_prt(" + messages=", $messages) ;
$this->debug_prt(" + res=", $res) ;
			}
		}
$this->debug_prt("handle_cmd_errors(type=$msg_type) messages=", $messages) ;


		## Return any messages
		if (count($messages))
		{
			$msg_type = $msg_type ? $msg_type : "info" ;
			if ($json) $json .= ",\n" ;
			$json .= "\"message\" : " . "{" . $this->_json_msg($msg_type, $messages) . "}" ;
		}
			

		return $json ;
	}
	
	#========================================================================
	# Utility methods
	#========================================================================


	#---------------------------------------------------------------------------------------------------
	# Returns true if program starts AFTER specified time
	function prog_start_compare($prog_start_hour, $prog_start_min, $start_hour, $start_min=0)
	{
		return ($prog_start_hour > $start_hour) || 
				(($prog_start_hour == $start_hour) && ($prog_start_min > $start_min)) ;
	}

	#---------------------------------------------------------------------------------------------------
	function set_rec_times($entity, $entry, $display_start_date, $display_start_time)
	{
		# Display start date (0:00)
		list($disp_start_year, $disp_start_month, $disp_start_day) = explode('-',$display_start_date);
		$disp_date_timestamp = mktime(0, 0, 0,  intval($disp_start_month), intval($disp_start_day), intval($disp_start_year)) ;

$d = date("d-m-Y H:i:s", $disp_date_timestamp) ;
$this->debug_prt("recovered START=$d", '') ;
				

		# calc end time
		list($start_year, $start_month, $start_day) = explode('-',$entry['date']);

		$start_time = Sql::sqltime_to_timestr($entry['start']) ;
		list($start_hour, $start_min) = explode(':',$start_time);
		$duration = Sql::sqltime_to_timestr($entry['duration']) ;
		list($duration_hours, $duration_mins) = explode(':',$duration);
		
		$start_dt = mktime($start_hour, $start_min, 0, $start_month, $start_day, $start_year) ;
		$start_date_timestamp = mktime(0, 0, 0, $start_month, $start_day, $start_year) ;
		$end_dt = mktime($start_hour+$duration_hours, $start_min+$duration_mins, 0, $start_month, $start_day, $start_year) ;
		$end_date_timestamp = mktime(0, 0, 0, date("m", $end_dt), date("d", $end_dt), date("Y", $end_dt)) ;

$d = date("d-m-Y H:i:s", $start_date_timestamp) ;
$this->debug_prt("recovered start=$d", '') ;
$d = date("d-m-Y H:i:s", $end_date_timestamp) ;
$this->debug_prt("recovered end=$d", '') ;

// DEBUG
$entity['start_dt'] = $start_dt ;
$entity['start_date_timestamp'] = $start_date_timestamp ;
$entity['end_dt'] = $end_dt ;
$entity['end_date_timestamp'] = $end_date_timestamp ;

		
		$end_time = date("H:i", $end_dt) ;
		list($end_hour, $end_min) = explode(':',$end_time);

		$entity['start'] = $start_time ;
		$entity['duration'] = $duration ;
		$entity['end'] = $end_time ;
		$entity['end_date'] = date("Y-m-d", $end_dt) ;

		$entity['duration_mins'] = $duration_mins + 60*$duration_hours ;
		$entity['start_mins'] = $start_min + 60*$start_hour ;
		$entity['end_mins'] = $end_min + 60*$end_hour ;
		

		// Adjust the 'mins' times. Need to ensure that all of the start/end times are monotonically increasing such that a program's
		// end is always > it's start (i.e. handle any switch from day to another)
		// 
		//                  START                                 END
		//                    |                                    |
		//            0       |                                    |               0
		//        1:  :   :-----------:                        :--------------:    : 
		//            :       |                                    |               :
		//(-24hr)<----:---------------------------> no affect                      :---> (+24hr)
		//             
		//                  0 |                                    |              
		//        2:      :-:---------:                        :--------------:    
		//                  : |                                    |
		//          -24hr<--:---------------------> no affect
		//                    
		//                    |                  0                 |              
		//        3:      :-----------:          :             :--------------:    
		//                    |                  :                 |
		//       			  no affect<---------:--------> +24hr
		//       
		//                    |                                    |   0           
		//        4:      :-----------:                        :-------:------:    
		//                    |                                    |   :
		//                    |                   no affect<-----------:---------------> +24 hr
		//
		// This just boils down to:
		// a) if prog start/end date < START date, then -24hours
		// b) if prog start/end date = START date, then 0 
		// c) if prog start/end date > START date, then +24hours
		//

$this->debug_prt("Creating prog : START $display_start_date, $display_start_time (ts=$disp_date_timestamp) : prog=", $entity) ;

		// Start time
		if ($start_date_timestamp < $disp_date_timestamp)
		{
			$entity['start_mins'] -= 24*60 ;
$this->debug_prt(" + start-24", '') ;
		}
		elseif ($start_date_timestamp > $disp_date_timestamp)
		{
			$entity['start_mins'] += 24*60 ;
$this->debug_prt(" + start+24", '') ;
		}
		
		// End time
		if ($end_date_timestamp < $disp_date_timestamp)
		{
			$entity['end_mins'] -= 24*60 ;
$this->debug_prt(" + end+24", '') ;
		}
		elseif ($end_date_timestamp > $disp_date_timestamp)
		{
			$entity['end_mins'] += 24*60 ;
$this->debug_prt(" + end-24", '') ;
		}
		
		return $entity ;
	}
	
	
	#---------------------------------------------------------------------------------------------------
	function create_prog($entry, $chanid, $display_start_date, $display_start_time)
	{
$this->debug_prt("create_prog(chan=$chanid, date=$display_start_date, time=$display_start_time) entry", $entry) ;
		
		// create Prog from standard LISTINGS table fields
		$prog = array() ;
		$prog['description'] = "" ;
		foreach ($this->prog_fields as $key)
		{
			$prog[$key] = "" ;
			if (array_key_exists($key, $entry))
			{
				$prog[$key] = $entry[$key] ;
			}
		}
		
		// Optional Record fields
		foreach ($this->prog_record_fields as $key)
		{
			$prog[$key] = "" ;
			if (array_key_exists($key, $entry))
			{
				$prog[$key] = $entry[$key] ;
			}
		}
		
		
		
		if (!$prog['description'])
		{
			$prog['description'] = $prog['text'] ;
		}
		
		// Defaults
		$prog["chanid"] = $chanid ;
		if (!$prog["record"]) $prog["record"] = 0 ;
		if (!$prog["genre"]) $prog["genre"] = "misc" ;
		
		# Handle genre. Should be in the form:
		# <genre>|<sub-genre>/<sub-genre>....
		list($genre, $sub_genre) = array("", "") ;
		$sub_array = array() ;

		$pos = strpos($prog['genre'], "|") ;
		if ($pos !== false)
		{
			list($genre, $sub_genre) = explode("|", $prog['genre']) ;
			$prog['genre'] = $genre ;
			$sub_array = explode("/", $sub_genre) ;
		}

		// Convert description to multi-line HTML
		$order   = array("\r\n", "\n", "\r");
		$replace = '<br />';
		// Processes \r\n's first so they aren't converted twice.
		$newstr = str_replace($order, $replace, $prog['description']);

		# Set up times
		$prog = $this->set_rec_times($prog,  $entry, $display_start_date, $display_start_time) ;	

		if (!$prog["record"]) $prog["record"] = 0 ;
		if (!$prog["genre"]) $prog["genre"] = "misc" ;
		

$this->debug_prt("Final prog=", $prog) ;
		
		return $prog ;		
	}

	#---------------------------------------------------------------------------------------------------
	function create_multirec($entry, $display_start_date, $display_start_time)
	{
		$multirec = array() ;
		$multirec['description'] = "" ;
		foreach ($this->multirec_fields as $key)
		{
			$multirec[$key] = "" ;
			if (array_key_exists($key, $entry))
			{
				$multirec[$key] = $entry[$key] ;
			}
		}
		
		# Set up times
		$multirec = $this->set_rec_times($multirec,  $entry, $display_start_date, $display_start_time) ;		

$this->debug_prt("Final multirec=", $multirec) ;
		
		return $multirec ;		
	}

	
	#----------------------------------
	# Create an array containing the search parameters
	function searchParams() 
	{
		// Create a search "object"
		$searchParams = array() ;		
		foreach ($this->json_search_fields as $key)
		{
			$searchParams[$key] = $this->params_array[$key] ;
		}
		
		// If channel is specified, convert from "displayed name" to the "broadcast name"
		if ($searchParams['channel'])
		{
			$display_name = $searchParams['channel'] ;
			$searchParams['display_channel'] = $display_name ;

//$this->debug_prt("Convert display name ($display_name) all=", $this->display_chan_names) ;
			
			if (array_key_exists($display_name, $this->display_chan_names))
			{
				$searchParams['channel'] = $this->display_chan_names[$display_name] ;
			}
			else
			{
				// skip  channel
				$searchParams['channel'] = "" ;
			}
//$this->debug_prt("chan=" . $searchParams['channel']) ;
			
		}
		
		return $searchParams ;
	}
	
	
	#----------------------------------
	# Dump out variable
	function debug_prt($msg, $var="") 
	{
		if ($this->irr_debug)
		{
			$this->_prt($msg, $var) ;
		}
		$this->debug_log_msg($msg) ;
		if ($var)
		{
			$this->debug_log_var($var) ;
		}
		$this->debug_log_msg("\n") ;
	}

	#----------------------------------
	# Dump out variable
	function _prt($msg, $var) 
	{
		print "<pre>\n" ;
		print "$msg\n" ;
		if ($var) print_r($var) ;
		print "</pre>\n" ;
	}

	#----------------------------------
	# Dump out variables
	function debug_prt_vars() 
	{
		if ($this->dbg_flag>=2)
		{
			$this->debug_prt("_POST", $_POST) ;
			$this->debug_prt("_GET", $_GET) ;

			if (get_magic_quotes_gpc()) $magic_quotes=1 ;
			$this->debug_prt("magic_quotes=$magic_quotes", "") ;

		}
	}


	//---------------------------------------------------------------------------
	// log message
	function debug_log_msg($msg)
	{
		if (!$this->LOG_PATH) return ;
		
		if ($fp = fopen($this->LOG_PATH, 'a'))
		{
			fwrite($fp, $msg);
			fclose($fp);
		}
		else
		{
			//print "<pre>BUGGER!\n</pre>";
			
			// Unable to write to log file, so degrade gracefully
			$this->LOG_PATH = "" ;
		}
	}
	
	//---------------------------------------------------------------------------
	// log a variable
	function debug_log_var($var)
	{
		$str = print_r($var, true) ;
		$this->debug_log_msg($str) ;
	}

	

}



#==================================================================
# Application
#==================================================================

$app = new ListingsApp('grid.tpl', DATABASE, TBL_LISTINGS);


// Run the application
$app->run(array(

	// grid
	'dt'=>date("Y-m-d"), 
	'hr'=>date("H"),
	't'=>'tv',		// grid listing type : tv/radio
	'ch'=>1,		// channel display first chanid
	'shw'=>3,		// displayed hours
	'rec'=>'',		// record change specification

	// Search params
	'title'=>'',
	'desc'=>'',
	'genre'=>'',
	'channel'=>'',
	'listingsType'=>'',

	// channel setting
	'chanid'=>'',
	'show'=>'',

	// scan
	'file'=>'',
	'clean'=>0,
	'adapter'=>'',


	// JSON command
	'json'=>'',		

	'dbg'=>0));

 
?>
