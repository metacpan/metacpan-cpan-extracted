<?php
#==================================================================
#@ NAME 	Classes/class.JsonApp.php
#@ SUMMARY 	Application class
#@ OWNER 	Steve Price
#@ TYPE		PHP library module
#
#@ HISTORY
#  10-Oct-06	SDP		New
#
#@ DESCRIPTION
# Object that handles parsing params and running a stand alone php
# application. 
#
#==================================================================

#============================================================================================
# BOOTSTRAP
#============================================================================================
require_once('php/Config/Constants.inc') ;

	// Set the timezone
	date_default_timezone_set ( DATE_TZ ) ;

	// Update include path to include local library area first
	$script_filename = $_SERVER{'SCRIPT_FILENAME'} ;
	$install_path = dirname($script_filename);
	if (empty($install_path))
	{
		$install_path = './';
	}
	else
	{
		$install_path .= '/';
	}
	$lib_path = $install_path.LIB_DIR.'/';

	// Update include path to include this dir first
	ini_set('include_path', 
		$lib_path. PATH_SEPARATOR.
		"$lib_path/PEAR/". PATH_SEPARATOR.
		ini_get('include_path'));
	
#============================================================================================
# USES
#============================================================================================
require_once('PEAR.php') ;
require_once('Classes/class.Sql.php') ;

#============================================================================================
# DEBUG
#============================================================================================
PEAR::setErrorHandling(PEAR_ERROR_PRINT) ;


#============================================================================================
# CLASS
#============================================================================================
class JsonApp {
	
	// URI of page (includes query)
	var $uri ;
	
	// Path of page (excludes query)
	var $uri_path ;
	
	// Name of logged in user (if any)
	var $user ;
	
	// Script filename
	var $script_filename ;
	
	// Installation path on server for this script
	var $install_path ;
	
	// Template info
	var $template_file ;
	var $template = "" ;
	
	//------------------------------------------------------------------
	// GLOBAL
	//-------------------------------------------------------------------
	
	// Constructor
	//
    function __construct($template, $database, $table) 
    {
		// Init
		$this->params_array = array() ;

		// Set up variables
		$this->set_vars() ;

		$this->template_file = TEMPLATE_DIR . "/" . $template ;

		$this->database = $database ;
		$this->table = $table ;

		// Connect to database
		$this->sql = new Sql($database) ;	
		
		// Check for error
		$this->check_sql() ;
    }

    function JsonApp($template, $database, $table) 
    {
    	$this->__construct($template, $database, $table) ;
    }
    
    
	// Destroy
    function __destruct() 
    {
		// Disconnect database
		$this->sql->disconnect() ;		
    }

    // Given a parameter name, return it's value if passed in from web
    function parameter($varname, $default=NULL) 
    {
		if (array_key_exists($varname, $_POST)) {
			$retval = $_POST[$varname];
		} elseif (array_key_exists($varname, $_GET)) {
			$retval = $_GET[$varname];
		} elseif (array_key_exists($varname, $_COOKIE)) {
			$retval = $_COOKIE[$varname];
		} elseif (array_key_exists($varname, $_SERVER)) {
			$retval = $_SERVER[$varname];
		} elseif (array_key_exists($varname, $_ENV)) {
			$retval = $_ENV[$varname];
		} else {
			$retval = $default;
		}
		return $retval;
    }

    /**
     * Return the current request URI.
     * Example: for http://domain.com/gallery2/main.php?g2_view=core.ShowItem
     *          it returns /gallery2/main.php?g2_view=core.ShowItem
     *
     * @return string the current URL path component plus query parameters
     * @static
     */
    function get_request_uri() 
    {
    	// Get path
		if (!($path = JsonApp::parameter('REQUEST_URI')) &&
			($path = JsonApp::parameter('SCRIPT_NAME'))) 
		{
		    if (($tmp = JsonApp::parameter('PATH_INFO')) && $tmp != $path) 
		    {
				$path .= $tmp;
		    }
		    
		}

		// Get query
	    $uri = $path ;
		$this->uri_path = html_entity_decode($path);
		$this->uri = html_entity_decode($uri);
		
		// remove any remaing query from path
		$this->uri_path = preg_replace('@\?.*@', '', $this->uri_path) ;

		return $this->uri ;
    }


    // Print out object
    function dump() 
	{
		print_r($this) ;
	}

    // Redirect to new page - no return
	function redirect($url = '/') 
	{
		header("location: $url") ;
	}
    
    //==========================================================================
    // Main
    //
    // Called with the list of valid parameter names. Any passed parameters that 
    // are in this list are added to the $params_array
    //
	// if 'json' parameter is specified, calls 'json_handler()', otherwise calls 'page_handler()'
	//    
    function run($valid_params_array = array()) 
	{
		// Get page params
		$this->get_params($valid_params_array) ;
		
		$json = $this->params_array['json'] ;
		
		// Run the app
		if ($json) 
		{
			# call json handler
			$this->json_handler() ;
			exit ;
		}
		else
		{
			# get template
			$this->read_tpl() ;
			
			# call page handler
			$this->page_handler() ;
			
			# show page
			$this->show() ;
		}
	}
    
	//-------------------------------------------------------------------
	// PAGE HANDLING
	//-------------------------------------------------------------------

    // Default page handler
	function page_handler() 
	{
	}
    
    // Default JSON handler
	function json_handler() 
	{
	}
    

	//-------------------------------------------------------------------
	// ERROR HANDLING
	//-------------------------------------------------------------------

    // Handle error code
	function handle_errorcode($error_code) 
	{
		print "Error: $error_code" ;
		exit ;
	}
    
    // Handle error message
	function handle_error($error_msg) 
	{
		$msg = implode("\n", $error_msg) ;
		print "<pre>\nError: $msg\n</pre>" ;
		exit ;
	}
 
 
     //----------------------------------------------------------------------------------------------------
    // Template utility functions
    //----------------------------------------------------------------------------------------------------

	#-----------------------------------------------------------------------------------------------------
	# Display page
	#
	function show()
	{
		print $this->template ;
	}

	#-----------------------------------------------------------------------------------------------------
	# Read the template file
	#
	function read_tpl()
	{
		$filename = $this->template_file ;
        if (!($fh = @fopen($filename, 'r'))) 
        {
        	$this->handle_error("Unable to read template file $filename") ;
        }

        $fsize = filesize($filename);
        if ($fsize < 1) 
        {
            fclose($fh);
            return;
        }

		$this->template = fread($fh, $fsize);
        fclose($fh);
	}
 
 
 	//-------------------------------------------------------------------
	// SQL
	//-------------------------------------------------------------------
 
     // Provide Sql wrapper functions with error handling
    function connect($database, 
    	$dbtype=SQL_DBTYPE, 
    	$user, 
    	$password, 
    	$host) 
    {
    	$host = $host ? $host : SQL_HOST ;
    	return $this->sql->connect($database, $user, $password, $host) ;
    }

    /**
     * check for any sql errors - call handler if error
     */
	function check_sql() 
	{
		if ($this->sql->error) 
		{
			$this->sql_error_handler() ;
		}
	}

	// Handle sql errors
	function sql_error_handler() 
	{
		// Error
		$error_msg = array('A database error has occured. Retry the operation or contact the site admin.') ;
		$error_msg[] = $this->error_message() ;
		
		$this->handle_error($error_msg) ;
	}
    
    /**
     * disconnect from the database
     */
    function disconnect() 
    {
        $this->sql->disconnect();   
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
		$result = $this->sql->query($query, $type, $format) ;
		$this->check_sql() ;
		if ($type == SQL_ALL)
		{
			$result = $this->sql->record ;
		}
		return $result ;
    }
    
    /**
     * Get next row
     *
     * @param string $format the query format
     */
    function next($format = SQL_ASSOC) 
    {
    	$result = $this->sql->next($format) ;
		$this->check_sql() ;
		return $result ;
    }

	/**
	 * insert data as a new row
	 * 
	 * @param string $table database table
	 * @param array $data hash of key/value pairs to be inserted
	 */   
	function insert ($table, $data) 
	{
    	$this->sql->insert($table, $data) ;
		$this->check_sql() ;
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
    	$this->sql->update($table, $data, $where, $limit) ;
		$this->check_sql() ;
	}
 
	function num_rows() 
	{
		return $this->sql->num_rows ;
	}
 
    
    /**
     * Return full Sql error/warning message
     *
     */
    function error_message() 
    {
		return $this->sql->error_message() ;            
    }
    
 
    
	//-------------------------------------------------------------------
	// PROTECTED
	//-------------------------------------------------------------------
    
    // Get params passed in from web - only recognise those in the valid list
    function get_params($valid_params_array=array()) 
    {
		foreach($valid_params_array as $param => $default)
		{
			$param_val = $this->parameter($param, $default) ; 

			if (isset($param_val)) 
			{
				$this->params_array[$param] = $param_val ;
			}
		}
    }
    
    // Set up various useful variables & the include path
    function set_vars() 
	{
		// Set uri vars
		$this->get_request_uri() ;
		
		// Set user
		$this->user = JsonApp::parameter('PHP_AUTH_USER') ;

		// define global vars
		$this->script_filename = JsonApp::parameter('SCRIPT_FILENAME') ;
		$this->install_path = dirname($this->script_filename);
		if (empty($this->install_path))
		{
			$this->install_path = './';
		}
		else
		{
			$this->install_path .= '/';
		}
	
		// Update include path to include this dir first
		ini_set('include_path', $this->install_path.PATH_SEPARATOR.ini_get('include_path'));
	}
}
?>
