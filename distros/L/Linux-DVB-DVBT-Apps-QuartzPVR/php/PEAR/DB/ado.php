<?php
//
// +----------------------------------------------------------------------+
// | PHP Version 4                                                        |
// +----------------------------------------------------------------------+
// | Copyright (c) 1997-2003 The PHP Group                                |
// +----------------------------------------------------------------------+
// | This source file is subject to version 2.02 of the PHP license,      |
// | that is bundled with this package in the file LICENSE, and is        |
// | available at through the world-wide-web at                           |
// | http://www.php.net/license/2_02.txt.                                 |
// | If you did not receive a copy of the PHP license and are unable to   |
// | obtain it through the world-wide-web, please send a note to          |
// | license@php.net so we can mail you a copy immediately.               |
// +----------------------------------------------------------------------+
// | Author: Alexios Fakos (alexios@php.net)                              |
// +----------------------------------------------------------------------+
//
// $Id: ado.php,v 1.3 2003/01/04 11:54:52 mj Exp $
//

//
// Example:
//
//  $dsn = array(
//      "phptype"  => "ado",
//      "dbsyntax" => "access",  //  "mssql" or "odbc"
//      "username" => "Admin",
//      "password" => "",
//      "database" => "Provider=Microsoft.Jet.OLEDB.4.0;
//                     Data Source=C:\\Programs\\Microsoft Office\\Office\\Samples\\Nordwind.mdb;
//                     Persist Security Info=False"
//  );
//
//	$conn = DB::connect($dsn);
//
//  ....



/**
 * Database independent query interface definition for Microsoft's ADODB
 * library using PHP's COM extension
 *
 * @author   Alexios Fakos <alexios@php.net>
 * @version  $Revision: 1.3 $
 * @package  DB_ado
 */



include_once(dirname(__FILE__) . '/ado_constants.php');

require_once ('DB/common.php');

class DB_ado extends DB_common
{
    /**
     * Points on ADODB.Connection
     * 
     * @var     object ADODB.Connection (COM)
     * @see     connect(), simpleQuery(), disconnect()
     */          
    var $connection;

    /**
     * Database backend used in PHP (mysql, odbc etc.)
     * 
     * @var     string
     * @see     connect(), toString()
     */               
    var $phptype;

    /**
     * Database used with regards to SQL syntax etc.
     * 
     * @var     string
     * @todo    defining special OLEDB-Provider (mssql, access, odbc)
     * @see     connect(), createSequence(), toString()
     */               
    var $dbsyntax;

    /**
     * Flag for method commit(), default no commit on every query
     * 
     * @var     boolean default true
     * @see     autoCommit(), adoTrans(), commit(), rollback()
     */        
    var $autocommit = true;

    /**
     * Flag to see how often a commit was started, Default no commit 
     * on every query
     * 
     * @var     boolean default true
     * @see     autoCommit(), simpleQuery(), rollback()
     */        
    var $transaction_opcount = 0;   // flag

    /**
     * Result of affected rows
     * 
     * @var     variant
     * @see     affectedRows(), simpleQuery()
     */        
    var $affected;

    /**
     * Points on ADODB.Recordset
     * 
     * @var     object ADODB.Recordset (COM)
     * @see     simpleQuery(), disconnect()
     */    
    var $recordset;


    /**
     * Specific max records to be retreived on execution.
     *
     * Default value 0 stays for return all records.
     * 
     * @var     integer default 0
     * @see     setMaxRecords()
     */
    var $_max_records = 0;

    /**
     * Specific option for ADODB.Connection and ADODB.Recordset.
     *
     * Valid values are:    -1 || 1 || 2 || 4 || 8 || 256 || 512
     * 
     * @var     integer default -1
     * @see     setExecuteOption()
     */
    var $_execute_option = -1;

    /**
     * Specific cursor location.
     *
     * Valid values are:    2 || 3
     * 
     * @var     integer  default 2
     * @see     setCursorLocation()
     */
    var $_cursor_location = adUseClient; // 3;

    /**
     * Specific cursor type.
     *
     * Valid values are:    -1 || 0 || 1 || 2 || 3
     * 
     * @var     integer default 3
     * @see     setCursorType()
     */
    var $_cursor_type = adOpenStatic; //3;

    /**
     * Specific lock type.
     *
     * Valid values are:    -1 || 0 || 1 || 2 || 3 || 4
     * 
     * @var     integer default -1
     * @see     setLockType()
     */
    var $_lock_type = -1;

////////////////////////////////////////////// ///////////////////////////
 
  
  
  
////////////////////////////////////////////// ///////////////////////////

    /**
     * DB_ado constructor.
     * Visit 
     * http://support.microsoft.com/default.aspx?scid=kb;EN-US;q168354
     * for $errorcode_map
     * 
     * @access     public
     * @return     void
     * @see        DB::common(), $dbsyntax, $phptype
     */
    function DB_ado()
    {
        $this->DB_common();
        $this->phptype  = 'ado';
        $this->dbsyntax = 'ado';
        $this->features = array(
                                'prepare'       => false,
                                'pconnect'      => false,
                                'transactions'  => true,
                                'limit'         => 'alter'
        );
        $this->errorcode_map = array(
            -2147483647  => DB_ERROR_UNSUPPORTED,
            -2147467263  => DB_ERROR_UNSUPPORTED,
            -2147467259  => DB_ERROR_UNSUPPORTED,
            -2147217865  => DB_ERROR_NOSUCHTABLE,
            -2147217900  => DB_ERROR_NOSUCHFIELD,
             2147749392  => DB_ERROR_NOSUCHFIELD,
            -2147217857  => DB_ERROR_ALREADY_EXISTS,
            -2147217843  => DB_ERROR_CONNECT_FAILED
        );
        $this->affected = new VARIANT();
    }

    
    /**
     * DB_ado destructor.
     *
     * @since      1.0
     * @access     private
     * @return     void
     * @see        disconnect()
     */
    function _DB_ado()
    {
        $this->disconnect();
    }


    /**
     * Connect to a database and log in as the specified user.
     *
     * @param      $dsn the data source name (see DB::parseDSN for syntax)
     * @param      $persistent (optional) whether the connection should be 
     *                         persistent (actually not supported persistent 
     *                         COM objects in php)
     * @access     public
     * @throws     DB_Error 
     * @return     mixed DB_OK on success or DB_Error on failure
     * @see        adoIsError(), adoRaiseError(), raiseError()
     */
    function connect($dsninfo, $persistent = false)
    {
        if (!OS_WINDOWS) {
            return $this->raiseError(DB_ERROR_EXTENSION_NOT_FOUND, null, 
                        null, null, 'This class runs only on Windows OS');
        }

        $this->dsn = $dsninfo;
        $this->dbsyntax = (string) strtolower(trim($dsninfo['dbsyntax']));
        $connstr  = (string) $dsninfo['database'];
        $user     = (string) $dsninfo['username'];
        $pw       = (string) $dsninfo['password'];

        $this->connection = new COM("ADODB.Connection");

        if (!$this->connection) {
           $errMsg  = 'Could not create an instance of ADODB.Connection.\n';
           $errMsg .= 'Check if you have installed MDAC on your machine.\n';
           $errMsg .= 'Take a look at '; 
           $errMsg .= 'http://www.microsoft.com/data/download.htm';

           return $this->raiseError(DB_ERROR_CONNECT_FAILED, null, 
                                    null, null, $errMsg);
        }

        //check some valid link properties    
        $link  = 'PROVIDER=|DRIVER=|DATA+SOURCE=|PERSIST+SECURITY+INFO=|UID=|';
        $link .= 'USER+ID=|PASSWORD=|PWD=|INITIAL+CATALOG=';
  
        if (!empty($connstr) && preg_match('/\b\s*('.$link.')\b/i', $connstr)) {
            @$this->connection->Open($connstr, $user, $pw);
            
            if (!$this->connection || $this->adoIsError()) {
                return $this->adoRaiseErrorEx(DB_ERROR_CONNECT_FAILED);
            }

        } else {
                return $this->adoRaiseErrorEx(DB_ERROR_INVALID_DSN);
        }

        return DB_OK;
    }


    /**
     * Close ADODB.Recordset, ADODB.Connection and delete vars to free memory.
     *
     * @access     public
     * @return     boolean always TRUE
     * @see        $connection, $recordset
     */
    function disconnect()
    {   
        if (is_object($this->recordset)) {
            if (@$this->recordset->State != adStateClosed) {
                @$this->recordset->Close();
            }
        }
        if (is_object($this->connection) && 
                    @$this->connection->State != adStateClosed) {
            @$this->connection->Close();
        }

        $this->recordset  = null;
        $this->connection = null;

        return true;
    }


    /**
     * Sending a query through ADODB.Connection and recieve ADO.Recordset 
     * as result.
     * For manip queries we use ADODB.Connection execute method instead of 
     * ADO.Recordset open method.
     * 
     * @param      string $query sql statement 
     * @access     public
     * @throws     DB_Error 
     * @return     mixed object ADODB.Recordset or DB_Error on failure
     * @see        $connection, $recordset, $_max_records, $_cursor_type, 
     *             $_lock_type, $_execute_option, $transaction_opcount, 
     *             adoTrans(), commit()
     */
    function simpleQuery($query)
    {
        $ismanip = DB::isManip($query);
        $this->last_query = $query;
        $query = $this->modifyQuery($query);
        
        if (!$this->autocommit && $ismanip) {
            // transaction supported?
            if ($this->adoTrans()) {
                $this->transaction_opcount++;
            }
        }

        if ($ismanip) {

            $this->recordset = @$this->connection->Execute($query,
                                                           &$this->affected,
                                                           $this->_execute_option);

        } else {

            if (!is_object($this->recordset)) {
                $this->recordset = new COM('ADODB.Recordset');
                if (!$this->recordset) {
                    $errMsg  = 'Creating an instance of ADODB.Recordset ';
                    $errMsg .= 'failed!';
                    return $this->raiseError(DB_ERROR_EXTENSION_NOT_FOUND,
                                               null, null, null, $errMsg);
                }
            } else {
                //  close other open recordset to open a new one
                if ($this->recordset->State != adStateClosed) {  
                    @$this->recordset->Close();  
                }
            }

            $this->recordset->MaxRecords = $this->_max_records;
            @$this->recordset->Open ($query, $this->connection, $this->_cursor_type, 
                             $this->_lock_type, $this->_execute_option);
        }

        if ($this->adoIsError()) {
            return $this->adoRaiseErrorEx($this->errorNative());
        }
        
        return $this->recordset;
    }


    /**
     * Move the internal ADODB.Recordset result pointer to the next 
     * available result.
     *
     * @param      object (reference) ADODB.Recordset 
     * @access     public
     * @return     void
     */
    function nextResult($result)
    {
        if (!@$result->EOF()) {
            @$result->MoveNext();
        }
    }


    /**
     * Fetch and return a row of current ADODB.Recordset.
     * Internally we do some important transformations for right php 
     * result.
     * Take a look at ADODB.DataTypeEnum for details.
     *
     * @param     object $result ADODB.Recordset
     * @param     array $arr (reference) where data from the row is stored
     * @param     integer $fetchmode how the array data should be indexed
     * @param     integer $rownum the row number to fetch
     * @access    public
     * @return    mixed DB_OK on success, NULL on no more rows
     * @todo      BINARY DATA handling
     */
    function fetchInto($result, &$arr, $fetchmode, $rownum=null)
    {

        if ($rownum !== null && !@$result->EOF()) {
            $this->pushErrorHandling(PEAR_ERROR_RETURN);
            // adBookmarkFirst, start at the first record
            @$result->Move($rownum, 1);
            $this->popErrorHandling();
            if ($this->adoIsError()) {
                return $this->adoRaiseErrorEx();
            } 
        }

        if (@$result->EOF()) {
            return null;
        }

        $arr = array();

        $count = $this->numCols($result);

        for($i = 0; $i < $count; $i++) {
            $field = $result->Fields($i);
            $type  = $field->Type;

            $fvalue = $field->Value;

            // avoiding 1970-01-01 01:00:00 on date values if 
            // $fvalue is null or < 0
            $value = null;

            if ($fvalue !== null) {
                //  adCurrency == 6
                if ($this->isTypeOfCurrency($type)) {
                    $value = (float) $fvalue;
                //  adDate == 7 + adDBDate DBTYPE_DBDATE == 133
                } elseif ($this->isTypeOfDate($type)) {
                    if ($fvalue > 0) {
                        $value = date('Y-m-d', (integer) $fvalue);
                    }
                //  adDBTime DBTYPE_DBTIME == 134
                } elseif ($this->isTypeOfTime($type)) {
                    if ($fvalue > 0) {
                        $value = date('H:i:s', (integer) $fvalue);
                    }
                //  adDBTimeStamp DBTYPE_DBTIMESTAMP == 135
                } elseif ($this->isTypeOfTimestamp($type)) {
                    if ($fvalue > 0) {
                        $value = date('Y-m-d H:i:s', (integer) $fvalue);
                    }
                } elseif ($this->isTypeOfBinary($type)) {
                    if (is_array($fvalue)) {
                        $value = ''; 
                        foreach ($fvalue as $value) {
                            $value .= pack('C', $value);
                        } 
                        $fvalue = null;
                    } else {
                        $value = $fvalue;
                    }
                } else {
                    $value = $fvalue;
                }
            }

            if ($fetchmode !== DB_FETCHMODE_ASSOC) {
                $arr[] = $value;
            } else {
                $arr[$field->Name] = $value;
            }
        }
        @$result->MoveNext();

        $field = null;
        unset($field);

        return DB_OK;
    }


    /**
     * Get the number of columns in a recordset.
     *
     * @since      1.0
     * @param      object $result ADODB.Recordset
     * @access     public
     * @return     integer the number of columns per row in $result
     */
    function numCols($result)
    {
        $cols = -1;
        if (is_object($result)) {
            $cols = @$result->Fields->Count();
        }
        return  ($cols !== -1) ? $cols : 0;
    }


    /**
     * Get the number of rows in a ADODB.Recordset.
     * Note: If cursor type supports does not support RecordCount, 
     *       the result is always adUnknown = -1.
     *
     * @since      1.0
     * @param      object $result ADODB.Recordset
     * @access     public
     * @return     integer number of rows in ADODB.Recordset
     * @see        setCursorType()
     */
    function numRows($result)
    {   
        $count = -1;
        if (is_object($result)) {
            $count = @$result->RecordCount();
        }
        return  ($count !== -1) ? $count : 0;
    }


    /**
     * Gets the number of rows affected by the last manip query.
     *
     * @since      1.0
     * @access     public
     * @return     integer  number of rows affected by the last query
     * @see        $affected
     */
    function affectedRows()
    {
        return $this->affected->value;
    }


    /**
     * Get the next value in a sequence.  Depends on $dbsyntax which type 
     * we use
     *
     * @access     public
     * @param      $seq_name the name of the sequence
     * @param      $ondemand whether to create the sequence table on 
     *                       demand (default is true)
     * @return     mixed a sequence integer or DB_Error
     */
    function nextId($seq_name, $ondemand = true)
    {
        $sqn = preg_replace('/[^a-z0-9_]/i', '_', $seq_name);

        $repeat = 0;
        do {
            $this->pushErrorHandling(PEAR_ERROR_RETURN);
            $rs = $this->query("UPDATE ${sqn}_seq SET id = id + 1");
            $this->popErrorHandling();    

            if ($ondemand && DB::isError($rs) && 
              $this->errorCode($rs->getCode()) == DB_ERROR_NOSUCHTABLE) {
                $repeat = 1;
                $rs = $this->createSequence($seq_name);
            } else {
                $rs = $this->getOne("SELECT MAX(id) FROM ${sqn}_seq");
                $repeat = 0;
            }
        } while ($repeat);

        if (DB::isError($rs)) {
            return $this->raiseError($result);
        }

        return $rs;
    }

    // }}}
    // {{{ createSequence()

    function createSequence($seq_name)
    {   
        $sqn = preg_replace('/[^a-z0-9_]/i', '_', $seq_name);
        
        if ($this->_tableExists("${sqn}_seq")) {
            return DB_OK;
        }

        $ftype = $this->_helpCreateSequence();
        $rs = $this->query("CREATE TABLE ${sqn}_seq " . $ftype);

        if (DB::isError($rs)) {
            return $rs;
        }
        $rs = $this->query("INSERT INTO ${sqn}_seq (id) VALUES(0)");

        return $rs;
    }

    // }}}
    // {{{ dropSequence()

    function dropSequence($seq_name)
    {
        $sqn = preg_replace('/[^a-z0-9_]/i', '_', $seq_name);
        // close recordset first to avoid table is locked
        if (@$this->recordset->State != 0) {
            @$this->recordset->Close();
        }

        return $this->query("DROP TABLE ${sqn}_seq");
    }


    /**
     * Free the internal resources associated with $result 
     * (basicly it means close recordset)
     *
     * @since     1.0
     * @param     object $result ADODB.Recordset
     * @return    boolean always TRUE
     */
    function freeResult($result)
    {
        if (@$result->State != 0) {
            @$result->Close();
        }

        $this->affected->value     = 0;
        $this->transaction_opcount = 0;

        return true;
    }

    /**
    * Enable automatic commit.
    *
    * @param      boolean $onoff (optional) default false
    * @return     boolean always TRUE
    * @access     public
    * @see        $autocommit
    */
    function autoCommit($onoff = false)
    {
        $this->autocommit = $onoff ? true : false;
        return DB_OK;
    }


    /**
    * Checking of transaction support by OLEDB-Provider.
    * Normally the startpoint of an transaction will be set here
    *
    * @param      boolean $onoff
    * @return     mixed TRUE on success, FALSE if transaction is not 
    *                   supported
    * @throws     DB_Error
    * @access     public
    * @see        $autocommit, $transaction_opcount 
    */
    function adoTrans()
    {
        $ret = $this->connection->Properties('Transaction DDL');

        if (!$ret) {
            return false;
        } else {
            $ret = null;
            unset($ret);
            if ($this->transaction_opcount == 0) {
                @$this->connection->BeginTrans();

                if ($this->adoIsError()) {
                    return $this->adoRaiseErrorEx();
                }
            }
        }

        return DB_OK;
    }


    /**
    * Starts a commit
    *
    * @param      none
    * @return     boolean TRUE on success
    * @throws     DB_Error
    * @access     public
    * @see        $autoCommit()
    */
    function commit()
    {
        if ($this->transaction_opcount > 0) {
            @$this->connection->CommitTrans(); 
            
            if ($this->adoIsError()) {
                return $this->adoRaiseErrorEx();
            }        
            $this->transaction_opcount = 0;
        }

        return DB_OK;
    }


    /**
    * Starts a rollback
    *
    * @param      none
    * @return     boolean TRUE on success
    * @throws     DB_Error
    * @access     public
    * @see        $autoCommit()
    */
    function rollback()
    {
        if ($this->transaction_opcount > 0) {
            @$this->connection->RollbackTrans(); 
            
            if ($this->adoIsError()) {
                return $this->adoRaiseErrorEx();
            }
            $this->transaction_opcount = 0;
        }

        return DB_OK;
    }


    /**
     * Get the extended error collection of the current ADODB.Connection
     *
     * @since      1.0
     * @access     public
     * @return     string ADODB.Error
     */
    function errorNativeEx()
    {
        $errors = $this->connection->Errors();
        if ($errors->Count() == 0) {
            return DB_ERROR_NOT_CAPABLE;
        }
        
        $count = $errors->Count();
        $ret = '';
        for($i = 0; $i < $count; $i++) {
            $item = $errors->Item($i);

            $msg    = $item->Description;
            $native = $item->NativeError;
            $nr     = $item->Number;
            $source = $item->Source; 
            $sql    = $item->SQLState; 
            
            $ret .= "Source: $source - Description: $msg - SQLState: ";
            $ret .= "$sql - Number: $nr - Native: $native \n";
        }

        $item = null;
        unset($item);
        $errors = null;
        unset($errors);

        return  $ret;
    }

	
    /**
     * Get the native error code of the last error (if any) that
     * occured on the current ADODB.Connection
     *
     * @since      1.0
     * @access     public
     * @return     string ADODB.Error
     */
    function errorNative()
    {
        $errors = $this->connection->Errors();
        if ($errors->Count() == 0) {
            return DB_ERROR_NOT_CAPABLE;
        }

        $item = $errors->Item(0);
        $ret  = (int) $item->Number;

        $item = null;
        unset($item);
        $errors = null;
        unset($errors);

        return $ret;
    }


    /**
     * Raise an error and set as param nativecode on raiseError() 
     * result-string of errorNative()
     *
     * @param      integer $errno (optional) default null
     * @since      1.0
     * @access     public
     * @return     void
     * @see        errorNative(), raiseError()
     */
    function adoRaiseError($errno = null)
    {
        return $this->raiseError($errno, null, null, null,
                                    $this->errorNative());
    }


    /**
     * Raise an error and set as param nativecode on raiseError() 
     * result-string of errorNative()
     *
     * @param      integer $errno (optional) default null
     * @since      1.0
     * @access     public
     * @return     void
     * @see        errorNativeEx(), raiseError()
     */
    function adoRaiseErrorEx($errno = null)
    {
        if ($errno === null) {
            $errno = $this->errorCode($errno);
        }
        return $this->raiseError($errno, null, null, null,
                                    $this->errorNativeEx());
    }

    
    /**
     * Checking if an ADODB.Connection error occured
     *
     * @param      none
     * @since      1.0
     * @access     public
     * @return     boolean TRUE error(s) occured, 
     *                     FALSE no error occured
     */
    function adoIsError()
    {   
        if ($this->connection->Errors->Count() > 0 &&
                            is_object($this->connection)) {
            return true;
        }
        return false;
    }
  

    /**
     * Set execute option for ADODB.Connection. Only for manip queries.
     *
     * CommandTypeEnum
     *      adCmdText        = 1
     *      adCmdTable       = 2
     *      adCmdStoredProc  = 4
     *      adCmdUnknown     = 8
     *      adCmdFile        = 256
     *      adCmdTableDirect = 512
     *
     * @param      integer $value (optional) default -1
     * @since      1.0
     * @access     public
     * @return     boolean TRUE we set the $value, FALSE wrong Enum was 
     *                     given
     * @see        $_execute_option
     */
    function setExecuteOption($value = -1)
    {    
        if ($value > 0 && $value < 3) {
        } elseif ($value == -1) {
        } elseif ($value == 4) {
        } elseif ($value == 8) {
        } elseif ($value == 256) {
        } elseif ($value == 512) {
        } else {
            return false;
        }
        $this->_execute_option = $value;

        return true;
    }


    /**
     * Set the cursor type for ADODB.Recordset. 
     * Only for catching records.
     *
     * Notes: 
     * Use adOpenKeyset = 1 or adOpenstatic = 3 to get a 
     * value > 0 of numRows().
     *
     * CursorTypeEnum
     *      adOpenUnspecified   = -1
     *      adOpenForwardOnly   = 0
     *      adOpenKeyset        = 1
     *      adOpenDynamic       = 2   
     *      adOpenStatic        = 3  
     *
     * @param      integer $value (optional) default -1
     * @since      1.0
     * @access     public
     * @return     boolean TRUE we set the $value, 
     *                     FALSE wrong Enum was given
     * @see        numRows(), $_cursor_type
     */
    function setCursorType($value = -1)
    {   
        if ($value >= 0 || $value < 4) {
            $this->_cursor_type = $value;
            return true;
        }
        return false;
    }

    
    /**
     * Set the cursor location for ADODB.Connection
     *
     * CursorLocationEnum
     *      adUseServer     = 2
     *      adUseClient     = 3
     *
     * @param      integer $value (optional) default 3
     * @since      1.0
     * @access     public
     * @return     boolean TRUE we set the $value, 
     *                     FALSE wrong Enum was given
     * @see        $_cursor_location
     */
    function setCursorLocation($value = 3)
    {
        if ($value > 1 && $value < 4) {
            $this->_cursor_location = $value;
            return true;
        }
        return false;
    }


    /**
     * Set the lock type for ADODB.Recordset. Only for catching records.
     *
     * LockTypeEnum
     *      adLockUnspecified       = -1
     *      adLockReadOnly          = 1
     *      adLockPessimistic       = 2   
     *      adLockOptimistic        = 3  
     *      adLockBatchOptimistic   = 4
     *
     * @param      integer $value (optional) default -1
     * @since      1.0
     * @access     public
     * @return     boolean TRUE we set the $value, 
     *                     FALSE wrong Enum was given
     * @see        $_lock_type
     */
    function setLockType($value = -1)
    {
        if ($value > 0 || $value < 5) {
            $this->_lock_type = $value;
            return true;
        }
        return false;
    }


   /**
    * Setting of MaxRecords to get only xx records on every query
    *
    * Note: msdn-article (Q186267)
    * "PRB: MaxRecords Property Is Not Used in Access Queries with ADO"
    *
    * @param      integer $value (optional) default 0
    * @since      1.0
    * @access     public
    * @return     boolean TRUE we set the $value, 
    *                     FALSE no integer value was given
    * @see        $_max_records
    */
    function setMaxRecords($value = 0)
    {
        if (is_int($value)) {
            $this->_max_records = $value;
            return true;
        }
        return false;
    }


    
    /**
     * Help function to get string of field declaration
     *
     * @return     string fieldtype and conditions
     * @see        createSequence()
     */
    function _helpCreateSequence()
    {
        $dbsyntax = strtolower($this->dbsyntax);

        if ($dbsyntax == 'access') {
            $ftype = '(id LONG NOT NULL, PRIMARY KEY(id))';
        } else {
            // odbc compliant
            $ftype = '(id BIGINT NOT NULL, PRIMARY KEY(id))';
        }

        return $ftype;
    }



    /**
     * Help function to know if table exists
     *
     * param       string $value tablename
     * @return     boolean TRUE table exists, FALSE table does not exist
     * @see        createSequence()
     */
    function _tableExists($value)
    {
        $ok = false;
        $cat = new COM('ADOX.Catalog');

        if ($cat) {

        // @$cat->ActiveConnection = $this->connection;
        // can use it in this way, i get always a seq fault of php.exe, 
        // maybe a bug reported bug-id #16720
        // so we use an alternative way ...

            @$cat->ActiveConnection = $this->connection->ConnectionString;

            $tables = @$cat->Tables;
            $count = $tables->Count();
            
            for($i = 0; $i < $count; $i++) {
                $table = $tables->Item($i);
                if (strtolower($table->Type) != 'view' &&
                        strtolower($table->Name) == $value) {
                    $ok = true;
                    break;
                }
            }
            $table = null; 
            unset($table);
            $tables = null; 
            unset($tables);
            $cat = null;
            unset($cat);
        }

        return $ok;
    }


   // }}}
   // {{{ tableInfo()

    function tableInfo($result, $mode = null) {
        $count = 0;
        $id    = 0;
        $res   = array();

        // if $result is a string, then we want information about a
        // table without a resultset
        if (is_string($result)) {
            $table_name = $result;
        } else { // is_object
            $sql = $this->last_query;
            $table_name = strtolower($this->_getTableNameFromSQL($sql));
            // or @$result->Source
            if (empty($table_name)) {
                return $this->raiseError(DB_ERROR_INVALID, null, null,
                        null, 'Empty table name in tableInfo() ' . __LINE__);
            }
        }

        $cat = new COM('ADOX.Catalog');

        if ($cat) {

            @$cat->ActiveConnection = $this->connection->ConnectionString;

            $tables = @$cat->Tables;
            $count = $tables->Count();

            if (!empty($mode)) {
                $res['num_fields']= $count;
            }
            for($i = 0; $i < $count; $i++) {
                $table = $tables->Item($i);
                if (strtolower($table->Type) != 'view' &&
                        strtolower($table->Name) == $table_name) {
                    
                    for($x = 0; $x < $table->Columns->Count(); $x++) {
                        $column = $table->Columns->Item($x);
                        $res[$x]['table']= (string) @$table->Name;
                        $res[$x]['name'] = (string) @$column->Name;
                        $type = $this->_getStringOfADOType($column->Type);
                        $res[$x]['type'] = (string) $type;
                        $res[$x]['len']  = (string) @$column->DefinedSize;
                        $flags = $this->_getFlags4TableInfo($column);
                        $res[$x]['flags']= (string) $flags;

                        if (!empty($mode)) {
                            if ($mode & DB_TABLEINFO_ORDER) {
                                $res['order'][$res[$x]['name']] = $x;
                            }
                            if ($mode & DB_TABLEINFO_ORDERTABLE) {
                                $res['ordertable'][$res[$x]['table']][$res[$x]['name']] = $x;
                            }                        
                        }
                    }
                    break;
                } // $table_name
            }
        } // !$cat

        $column = null;
        unset($column);
        $table = null;
        unset($table);
        $tables = null;
        unset($tables);
        $cat = null;
        unset($cat);

        return $res;
    }

// todo: transforming ret int-value to string
    /**
     * Get MS ADODB integer value of field type
     * as human string 
     *
     * @param      string $value integer value of ADODB field type
     * @access     privat
     * @return     string human string
     */
    function _getStringOfADOType($value)
    {   
        $ret = 'char';

        if ($this->isTypeOfBinary($value)) {
            $ret = 'binary';
        } elseif ($this->isTypeOfBit($value)) {
            $ret = 'bit';
        } elseif ($this->isTypeOfDecimal($value)) {
            $ret = 'decimal';
        } elseif ($this->isTypeOfNumeric($value)) {
            $ret = 'numeric';
        } elseif ($this->isTypeOfDouble($value)) {
            $ret = 'double';
        } elseif ($this->isTypeOfFloat($value)) {
            $ret = 'float';
        } elseif ($this->isTypeOfReal($value)) {
            $ret = 'real';
        } elseif ($this->isTypeOfCurrency($value)) {
            $ret = 'currency';
        } elseif ($this->isTypeOfInteger($value)) {
            $ret = 'int';
        } elseif ($this->isTypeOfTime($value)) {
            $ret = 'datetime';
        } elseif ($this->isTypeOfTimestamp($value)) {
            $ret = 'timestamp';
        } elseif ($this->isTypeOfDate($value)) {
            $ret = 'date';
        }

        return $ret;
    }


    /**
     * Receiving of the table name in a SQL query string
     *
     * @param      string $value SQL query string
     * @access     privat
     * @return     string table name in the SQL query
     */
    function _getTableNameFromSQL($value)
    {   
        $sql = ltrim($value);
        $from_part = stristr($sql, 'from');
        $from_array = split(' ', $from_part);

        return (string) $from_array[1];
    }

    /**
     * Transform MS ADODB Enum into php readable string
     * 
     * @param      object $column column item
     * @access     privat
     * @return     string empty string or the name type of column
     */
    function _getFlags4TableInfo($column)
    {   
        $this->pushErrorHandling(PEAR_ERROR_RETURN);
        $ret = '';
        if ($column->Properties->Count() > 0) {
            $property = @$column->Properties('Nullable');
            $ret .= (string) (@$property->Value == false) ? 'not_null' : '';
            $property = @$column->Properties('Autoincrement');
            $ret .= (string) (@$property->Value == true) ? 'auto_increment' : '';
            $property = @$column->Properties('Primary Key');
            $ret .= (string) (@$property->Value == true) ? 'primary_key' : '';
            $property = @$column->Properties('Unique');
            $ret .= (string) (@$property->Value == true) ? 'unique' : '';
        }
        $this->popErrorHandling();

        $property = null;
        unset($property);

        return $ret;
    }




    /**
     * Returns ADODB version
     *
     * @access    (public)
     * @return    string  ADODB version
     */
    function getVersion()
    {
        if (is_object($this->connection)) {
            return (string) $this->connection->Version;
        }
        return '';
    }


    /**
     * Returns ADODB Provider
     *
     * @access    (public)
     * @return    string  ADODB version
     */
    function getProvider()
    {
        if (is_object($this->connection)) {
            return (string) $this->connection->Provider;
        }
        return '';
    }


    /**
     * Checks if field is a binary type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfBinary($value)
    {
        if ($value == adBinary || $value == adVarBinary ||
                $value == adLongVarBinary) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a bit type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfBit($value)
    {
        if ($value == adBoolean) {
            return true;
        }
        return false;
    }


    /**
     * Checks if field is a char type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfChar($value)
    {
        if ($value == adChar || $value == adVarChar || 
                $value == adWChar || $value == adVarWChar ||
                $value == adLongVarChar || $value == adLongVarWChar) {
            return true;
        }
        return false;
    }


    /**
     * Checks if field is a date type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfDate($value)
    {
        if ($value == adDate || $value == adDBDate) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a decimal type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfDecimal($value)
    {
        if ($value == adNumeric) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a numeric type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfNumeric($value)
    {
        if ($value == adNumeric) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a double type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfDouble($value)
    {
        if ($value == adDouble) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a float type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfFloat($value)
    {
        if ($value == adSingle) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a real type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfReal($value)
    {
        if ($value == adSingle) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a integer type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfInteger($value)
    {
        if ($value == adInteger || $value == adSmallInt ||
                $value == adUnsignedTinyInt) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a currency type
     * (which is not supported by php)
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfCurrency($value)
    {
        if ($value == adCurrency) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a time type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfTime($value)
    {
        if ($value == adDBTime) {
            return true;
        }
        return false;
    }

    /**
     * Checks if field is a timestamp type
     *
     * @param      integer $value fieldtype
     * @access     public
     * @return     boolean TRUE on match, FALSE if other type
     */
    function isTypeOfTimestamp($value)
    {
        if ($value == adDBTimeStamp) {
            return true;
        }
        return false;
    }

}  // class DB_ado