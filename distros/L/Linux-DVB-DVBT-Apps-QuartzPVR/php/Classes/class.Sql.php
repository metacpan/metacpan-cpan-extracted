<?php
#==================================================================
#@ NAME 	Classes/Class.Sql.php
#@ SUMMARY 	Database access object
#@ OWNER 	Steve Price
#@ TYPE		PHP library module
#
#@ HISTORY
#  10-Oct-06	SDP		New
#
#@ DESCRIPTION
# Contains useful database access methods. 
# Uses PEAR DB calls and the config constants. 
#
#==================================================================

#============================================================================================
# USES
#============================================================================================

// Use PEAR
include_once("DB.php") ;

#============================================================================================
# CONSTANTS
#============================================================================================

// define the query types
define('SQL_NONE', 1);
define('SQL_ALL', 2);
define('SQL_INIT', 3);

// define the query formats
define('SQL_ASSOC', 1);
define('SQL_INDEX', 2);

#============================================================================================
# CLASS
#============================================================================================
class Sql 
{
	var $VERSION = '1.000' ;

	// Database 
    var $db = null;
    
    // Results of last query
    var $result = null;
    
    // Error message from last query
    var $error = null;
    
    // Data from last query (row or all results depending on query type)
    var $record = null;
    
    // Number of rows
    var $num_rows ;
    
    
    /**
     * class constructor
     */
    function __construct($database = NULL) 
    { 
    	if (isset($database))
    	{
    		$this->connect($database) ;
    	}	
    }
    
    function Sql($database = NULL) 
    { 
    	$this->__construct($database) ;
    }
    
    
    /**
     * connect to the database
     *
     * @param string $dsn the data source name
     */
    function connect($database, 
    	$dbtype=SQL_DBTYPE, 
    	$user=SQL_USER, 
    	$password=SQL_PASSWORD, 
    	$host=SQL_HOST) 
    {
		$dsn = "$dbtype://$user:$password@$host/$database" ; 
        $this->db = DB::connect($dsn);

        if(DB::isError($this->db)) {
            $this->error = $this->db->getMessage() . " Connecting to $dsn";
            return false;
        }        
        return true;
    }
    
    /**
     * disconnect from the database
     */
    function disconnect() 
    {
        $this->db->disconnect();   
    }
    
    /**
     * query the database
     *
     * @param string $query the SQL query
     * @param string $type the type of query
     * @param string $format the query format
     */
    function query($query, $type = SQL_NONE, $format = SQL_ASSOC) 
    {

		$this->record = array();
		$_data = array();
		$this->num_rows = 0 ;
        
		// determine fetch mode (index or associative)
        $_fetchmode = ($format == SQL_ASSOC) ? DB_FETCHMODE_ASSOC : null;
        
        $this->result = $this->db->query($query);
        if (DB::isError($this->result)) {
            $this->error = $this->result->getMessage();
            $this->error .= "\nQuery: $query\n" ;
            return false;
        }

		$obj_methods = array_map('strtolower', (array)get_class_methods($this->result));
		if (in_array('numrows', (array)$obj_methods)) 
		{
        	$this->num_rows = $this->result->numRows() ;
		}
        
        switch ($type) {
            case SQL_ALL:
				// get all the records
                while($_row = $this->result->fetchRow($_fetchmode)) {
                    $_data[] = $_row;   
                }
                $this->result->free();            
                $this->record = $_data;
                break;
            case SQL_INIT:
				// get the first record
                $this->record = $this->result->fetchRow($_fetchmode);
                break;
            case SQL_NONE:
            default:
				// records will be looped over with next()
                break;   
        }
        return true;
    }
    
	/**
	 * insert data as a new row
	 * 
	 * @param string $table database table
	 * @param array $data hash of key/value pairs to be inserted
	 */   
	function insert ($table, $data) 
	{
		$escaped = array() ;
		foreach ($data as $field => $value)
		{
//			$escaped[$field] = $this->db->quoteSmart($value) ;
			$escaped[$field] = "'$value'" ;
		}
	
		$field_list = join(array_keys($escaped), ', ') ;
		$values_list = join(array_values($escaped), ', ') ;
	
		$query = "INSERT INTO $table 
				 ( $field_list )  
				 VALUES ( $values_list )" ;
		$this->query($query) ;
	}

	/**
	 * udpate data for an existing row
	 * 
	 * @param string $table database table
	 * @param array $data hash of key/value pairs to be inserted
	 * @param string $where Sql query to define specific row (must include WHERE keyword)
	 * @param integer $limit when set, limits number of matches to limit count
	 */   
	function update($table, $data, $where='', $limit=1) 
	{
		$escaped = array() ;
		foreach ($data as $field => $value)
		{
//			$escaped[$field] = $this->db->quoteSmart($value) ;
			$escaped[$field] = "'$value'" ;
		}
	
		$set_list = "" ;
		foreach ($escaped as $field => $value)
		{
			if ($set_list)
			{
				$set_list .= ", " ;
			}
			$set_list .= "`$field` = $value" ;
		}

		if ($limit)
		{
			$where .= " LIMIT $limit" ;
		}
		
		$query = "UPDATE $table SET 
				 $set_list
				 $where" ;

//print_r($data) ;
//print_r($escaped) ;
//print "$query" ;
//exit ;		
//
		$this->query($query) ;
	}
 
 
    
    /**
     * Get next row
     *
     * @param string $format the query format
     */
    function next($format = SQL_ASSOC) 
    {
		// fetch mode (index or associative)
        $_fetchmode = ($format == SQL_ASSOC) ? DB_FETCHMODE_ASSOC : null;
        if ($this->record = $this->result->fetchRow($_fetchmode)) {
            return $this->record;
        } else {
            $this->result->free();
            return false;
        }
            
    }

    /**
     * Return full Sql error/warning message
     *
     */
    function error_message() 
    {
    	$message = $this->error ;
        if (DB::isError($this->db)) 
        {
        	$obj =& $this->db ;
        }
        elseif (DB::isError($this->result))
        {
        	$obj =& $this->result ;
        }
        
        if ($obj)
        {
			$message .= "Sql Error:" . $obj->getMessage() . "\n";
			$message .= "'Standard Code: " . $obj->getCode() . "\n";
			$message .= "DBMS/User Message: " . $obj->getUserInfo() . "\n";
			$message .= "DBMS/Debug Message: " . $obj->getDebugInfo() . "\n";
        }
		return $message ;
    }

	# Convert SQL based date (YYYY-MM-DD) to standard date string (d-MMM-YYYY)
	function sqldate_to_datestr($sqldate)
	{
		list($year, $month, $day) = explode('-',$sqldate);

// int mktime ( [int hour [, int minute [, int second [, int month [, int day [, int year [, int is_dst]]]]]]] )

		$time = mktime(0,0,0,1*$month,1*$day,1*$year) ;
		$datestr = date("d-M-Y", $time) ;
	
		return $datestr ;
	}
	
	# Convert standard date string (d-MMM-YYYY) to SQL based date (YYYY-MM-DD)
	function datestr_to_sqldate($datestr)
	{
		list($day, $month, $year) = explode('-',$datestr);
		$time = mktime(0,0,0,$month,$day,$year) ;
		$datestr = date("d-M-Y", $time) ;
	
		return $datestr ;
	}
	
	
	# Convert SQL based date (YYYY-MM-DD) to timestamp
	function sqldate_to_date($sqldate)
	{
		return strtotime(sqldate_to_datestr($sqldate)) ;
	}
	
	
	# Convert SQL based time (HH:MM:SS) to standard time string (HH:MM)
	function sqltime_to_timestr($sqltime)
	{
		list($hours, $mins, $secs) = explode(':',$sqltime);
		return sprintf("%02d:%02d", $hours, $mins) ;
	}



    
}

?>
