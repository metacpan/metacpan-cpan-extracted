<?php

/* vim: set expandtab tabstop=4 shiftwidth=4 foldmethod=marker: */

/**
 * The PEAR DB driver for the odbtp extension
 * for remotely interacting with Win32-based databases from
 * any platform.  The odbtp extension is available at
 * http://odbtp.sourceforge.net.
 *
 * PHP versions 4 and 5
 *
 * LICENSE: This source file is subject to version 3.0 of the PHP license
 * that is available through the world-wide-web at the following URI:
 * http://www.php.net/license/3_0.txt.  If you did not receive a copy of
 * the PHP License and are unable to obtain it through the web, please
 * send a note to license@php.net so we can mail you a copy immediately.
 *
 * @category   Database
 * @package    DB_odbtp
 * @author     Robert Twitty <rtwitty@users.sourceforge.net>
 * @copyright  1997-2005 The PHP Group
 * @license    http://www.php.net/license/3_0.txt  PHP License 3.0
 * @version    CVS: $Id: odbtp.php,v 1.6 2005/03/13 00:54:42 rtwitty Exp $
 * @link       http://pear.php.net/package/DB_odbtp
 */

/**
 * Obtain the DB_common class so it can be extended from
 */
require_once 'DB/common.php';

/**
 * Database independent query interface definition for ODBTP extension.
 *
 * @package  DB_odbtp
 * @version  $Id: odbtp.php,v 1.6 2005/03/13 00:54:42 rtwitty Exp $
 * @category Database
 * @author   Robert Twitty <rtwitty@users.sourceforge.net>
 */

/**
 * The methods PEAR DB uses to interact with the odbtp extension
 * for remotely interacting with Win32-based databases.
 *
 * These methods overload the ones declared in DB_common.
 *
 * @category   Database
 * @package    DB_odbtp
 * @author     Robert Twitty <rtwitty@users.sourceforge.net>
 * @copyright  1997-2005 The PHP Group
 * @license    http://www.php.net/license/3_0.txt  PHP License 3.0
 * @version    Release: 1.0.3
 * @link       http://pear.php.net/package/DB_odbtp
 */
class DB_odbtp extends DB_common
{
    // {{{ properties

    /**
     * The DB driver type (mysql, oci8, odbc, etc.)
     * @var string
     * @access public
     */
    var $phptype = 'odbtp';

    /**
     * DSN used to establish connection.
     * @var array
     * @access public
     * @see DB::parseDSN()
     */
    var $dsn = array();

    /**
     * Database used with regards to SQL syntax, ODBC driver, etc.
     * @var string
     * @access public
     * @see connect(), toString()
     */
    var $dbsyntax = 'unknown';

    /**
     * The capabilities of this DB implementation
     *
     * The 'new_link' element contains the PHP version that first provided
     * new_link support for this DBMS.  Contains false if it's unsupported.
     *
     * Meaning of the 'limit' element:
     *   + 'emulate' = emulate with fetch row by number
     *   + 'alter'   = alter the query
     *   + false     = skip rows
     *
     * @var array
     * @access private
     */
    var $features = array(
        'limit'         => 'emulate',
        'new_link'      => false,
        'numrows'       => true,
        'pconnect'      => true,
        'prepare'       => false,
        'ssl'           => false,
        'transactions'  => false
    );

    /**
     * A mapping of native error codes to DB error codes
     * @var array
     * @access private
     */
    var $errorcode_map = array(
        '01004' => DB_ERROR_TRUNCATED,
        '07001' => DB_ERROR_MISMATCH,
        '21S01' => DB_ERROR_MISMATCH,
        '21S02' => DB_ERROR_MISMATCH,
        '22003' => DB_ERROR_INVALID_NUMBER,
        '22007' => DB_ERROR_INVALID_DATE,
        '22018' => DB_ERROR_INVALID_NUMBER,
        '22012' => DB_ERROR_DIVZERO,
        '23000' => DB_ERROR_CONSTRAINT,
        '23503' => DB_ERROR_CONSTRAINT,
        '24000' => DB_ERROR_INVALID,
        '34000' => DB_ERROR_INVALID,
        '42000' => DB_ERROR_SYNTAX,
        '42S01' => DB_ERROR_ALREADY_EXISTS,
        '42S02' => DB_ERROR_NOSUCHTABLE,
        '42S11' => DB_ERROR_ALREADY_EXISTS,
        '42S12' => DB_ERROR_NOT_FOUND,
        '42S21' => DB_ERROR_ALREADY_EXISTS,
        '42S22' => DB_ERROR_NOSUCHFIELD,
        '08004' => DB_ERROR_CONNECT_FAILED,
        '08007' => DB_ERROR_CONNECT_FAILED,
        '08S01' => DB_ERROR_CONNECT_FAILED,
        'HY009' => DB_ERROR_INVALID,
        'HY024' => DB_ERROR_INVALID,
        'HY090' => DB_ERROR_INVALID,
        'IM001' => DB_ERROR_UNSUPPORTED,
        'ODBTPINV' => DB_ERROR_INVALID
    );

    /**
     * ODBTP connection resource
     * @var resource
     * @access private
     */
    var $connection;

    /**
     * ODBTP query result resource
     * @var resource
     * @access private
     */
    var $query_result;

    /**
     * Transaction isolation level
     * @var int
     * @access private
     */
    var $txn_isolation;

    // }}}
    // {{{ constructor

    /**
     * This constructor calls <kbd>$this->DB_common()</kbd>
     *
     * @return void
     *
     * @access public
     * @see DB::common()
     */
    function DB_odbtp()
    {
        $this->DB_common();
        $this->errorcode_map = array(
        );
    }

    // }}}
    // {{{ connect()

    /**
     * Connect to a database via an ODBTP server
     *
     * The format of the supplied DSN:
     *
     *   odbtp(dbsyntax)://username:password@odbtphost/database
     *
     * or
     *
     *   odbtp://username:password@odbtpinterface/database
     *
     * Examples:
     *
     *  odbtp(access)://myuid:mypwd@odbtp.somewhere.com/c:\mydb.mdb
     *  odbtp(mssql)://myuid:mypwd@odbtp.somewhere.com/mydb?server=mysqlsrv
     *  odbtp://myuid:mypwd@myinterface/mydb
     *
     * @param array $dsninfo data source name info returned by DB::parseDSN
     * @param boolean $persistent kept for interface compatibility
     *
     * @return int DB_OK if successful, or DB error code if failure
     *
     * @see DB::parseDSN()
     * @access public
     */
    function connect($dsninfo, $persistent = false)
    {
        if (!PEAR::loadExtension('odbtp')) {
            return $this->raiseError(DB_ERROR_EXTENSION_NOT_FOUND);
        }
        $this->dsn = $dsninfo;
        $this->dbsyntax = 'unknown';
        $this->txn_isolation = ODB_TXN_DEFAULT;
        $odbcinfo = array();
        $hostspec = '';
        $port = '';
        $conntype = 'normal';
        $rowcache = false;
        $unicode = false;
        $vardatasize = 0;
        $connid = '';
        $dbparam = 'DATABASE';

        foreach ($dsninfo as $option => $value) {
            $option = strtoupper($option);

            switch ($option) {
                // PEAR DB DSN specific options
                case 'PHPTYPE':
                    $this->phptype = $value; break;
                case 'DBSYNTAX':
                    $this->dbsyntax = strtolower($value);
                    switch( $this->dbsyntax ) {
                        case 'mssql':
                            $dbparam = 'DATABASE';
                            if (!isset($odbcinfo['DRIVER']))
                                $odbcinfo['DRIVER'] = '{SQL Server}';
                            if (!isset($odbcinfo['SERVER']))
                                $odbcinfo['SERVER'] = '(local)';
                            break;
                        case 'access':
                            $dbparam = 'DBQ';
                            if (!isset($odbcinfo['DRIVER']))
                                $odbcinfo['DRIVER'] = '{Microsoft Access Driver (*.mdb)}';
                            if (!isset($odbcinfo['UID']))
                                $odbcinfo['UID'] = 'admin';
                            if (!isset($odbcinfo['PWD']))
                                $odbcinfo['PWD'] = '';
                            break;
                        case 'vfp':
                            $dbparam = 'SOURCEDB';
                            if (!isset($odbcinfo['DRIVER']))
                                $odbcinfo['DRIVER'] = '{Microsoft Visual FoxPro Driver}';
                            if (!isset($odbcinfo['SOURCETYPE']))
                                $odbcinfo['SOURCETYPE'] = 'DBF';
                            if (!isset($odbcinfo['EXCLUSIVE']))
                                $odbcinfo['EXCLUSIVE'] = 'NO';
                            break;
                        case 'oracle':
                            $dbparam = 'DBQ';
                            if (!isset($odbcinfo['DRIVER']))
                                $odbcinfo['DRIVER'] = '{Oracle ODBC Driver}';
                            break;
                        case 'sybase':
                            $dbparam = 'DATABASE';
                            if (!isset($odbcinfo['DRIVER']))
                                $odbcinfo['DRIVER'] = '{Sybase ASE ODBC Driver}';
                            if (!isset($odbcinfo['SRVR']))
                                $odbcinfo['SRVR'] = 'localhost';
                            break;
                        case 'db2':
                            $dbparam = 'DATABASE';
                            if (!isset($odbcinfo['DRIVER']))
                                $odbcinfo['DRIVER'] = '{IBM DB2 ODBC Driver}';
                            if (!isset($odbcinfo['HOSTNAME']))
                                $odbcinfo['HOSTNAME'] = 'localhost';
                            if (!isset($odbcinfo['PORT']))
                                $odbcinfo['PORT'] = '50000';
                            if (!isset($odbcinfo['PROTOCOL']))
                                $odbcinfo['PROTOCOL'] = 'TCPIP';
                            break;
                        case 'mysql':
                            $dbparam = 'DATABASE';
                            if (!isset($odbcinfo['DRIVER']))
                                $odbcinfo['DRIVER'] = '{mySQL}';
                            if (!isset($odbcinfo['SERVER']))
                                $odbcinfo['SERVER'] = 'localhost';
                            if (!isset($odbcinfo['PORT']))
                                $odbcinfo['PORT'] = '3306';
                            if (!isset($odbcinfo['OPTION']))
                                $odbcinfo['OPTION'] = '131072';
                            if (!isset($odbcinfo['STMT']))
                                $odbcinfo['STMT'] = '';
                            break;
                        case 'text':
                            $dbparam = 'DBQ';
                            if (!isset($odbcinfo['DRIVER']))
                                $odbcinfo['DRIVER'] = '{Microsoft Text Driver (*.txt; *.csv)}';
                            if (!isset($odbcinfo['EXTENSIONS']))
                                $odbcinfo['EXTENSIONS'] = 'asc,csv,tab,txt';
                            break;
                        case 'excel':
                            $dbparam = 'DBQ';
                            if (!isset($odbcinfo['DRIVER']))
                                $odbcinfo['DRIVER'] = '{Microsoft Excel Driver (*.xls)}';
                            if (!isset($odbcinfo['DRIVERID']))
                                $odbcinfo['DRIVERID'] = '790';
                            break;
                        case 'dsn':
                            $dbparam = 'DSN';
                            if (!isset($odbcinfo['DSN']))
                                $odbcinfo['DSN'] = '';
                            $this->dbsyntax = 'unknown';
                            break;
                        default:
                            $this->dbsyntax = 'unknown';
                    }
                    break;
                case 'USERNAME':
                    $username = $value; break;
                case 'PASSWORD':
                    $password = $value; break;
                case 'PROTOCOL':
                    $protocol = $value; break;
                case 'SOCKET':
                    $socket = $value; break;
                case 'HOSTSPEC':
                    $hostspec = $value; break;
                case 'PORT':
                    $port = $value; break;
                case 'DATABASE':
                    $database = $value; break;

                // ODBTP specific options
                case 'CONNTIMEOUT':
                    $conntimeout = $value; break;
                case 'READTIMEOUT':
                    $readtimeout = $value; break;
                case 'CONNTYPE':
                    $conntype = strtolower($value); break;
                case 'ROWCACHE':
                    $rowcache = strtolower($value); break;
                case 'UNICODE':
                    $unicode = strtolower($value); break;
                case 'TXNISOL':
                    switch (strtolower($value)) {
                        case 'readuncommitted':
                            $this->txn_isolation = ODB_TXN_READUNCOMMITTED;
                            break;
                        case 'readcommitted':
                            $this->txn_isolation = ODB_TXN_READCOMMITTED;
                            break;
                        case 'repeatableread':
                            $this->txn_isolation = ODB_TXN_REPEATABLEREAD;
                            break;
                        case 'serializable':
                            $this->txn_isolation = ODB_TXN_SERIALIZABLE;
                            break;
                        default:
                            $this->txn_isolation = ODB_TXN_DEFAULT;
                    }
                case 'VARDATASIZE':
                    $vardatasize = intval($value); break;
                case 'CONNID':
                    $connid = strtolower($value); break;
                case 'DBPARAM':
                    $dbparam = strtoupper($value); break;
                case 'ODBCPROTOCOL':
                    $odbcinfo['PROTOCOL'] = $value; break;
                case 'ODBCPORT':
                    $odbcinfo['PORT'] = $value; break;

                // Unrecognized options are considered to be ODBC specific
                default:
                    $odbcinfo[$option] = $value;
            }
        }
        if ($conntype == 'reserved') {
            $connect_function = 'odbtp_rconnect';
        } else if ($conntype == 'single') {
            $connect_function = 'odbtp_sconnect';
        } else {
            $connect_function = 'odbtp_connect';
        }
        if( !$hostspec ) $hostspec = '127.0.0.1';

        if ($port) {
            $hostspec .= ':' . $port;
        }
        if (isset($conntimeout)) {
            if ($port)
                $hostspec .= ':' . $conntimeout;
            else
                $hostspec .= '::' . $conntimeout;
        }
        if (isset($readtimeout)) {
            if ($port && isset($conntimeout))
                $hostspec .= ':' . $readtimeout;
            else if ($port)
                $hostspec .= '::' . $readtimeout;
            else
                $hostspec .= ':::' . $readtimeout;
        }
        if (count($odbcinfo) != 0) {
            if (is_string($username)) $odbcinfo['UID'] = $username;
            if (is_string($password)) $odbcinfo['PWD'] = $password;
            if (is_string($database)) $odbcinfo[$dbparam] = $database;

            $odbc_connect = '';
            foreach ($odbcinfo as $option => $value) {
                $odbc_connect .= "$option=$value;";
            }
            $conn = @$connect_function($hostspec, $odbc_connect);
        } else if ($connid) {
            $conn = @$connect_function($hostspec, $connid);
        } else {
            $conn = @$connect_function($hostspec, $username, $password, $database);
        }
        if (!$conn) {
            return $this->raiseError(DB_ERROR_CONNECT_FAILED,
                                     null, null, null, @odbtp_last_error());
        }
        if ($connect_function == 'odbtp_connect' && !$persistent) {
            @odbtp_dont_pool_dbc($conn);
        }
        switch ($rowcache) {
            case 1:
            case 'true':
            case 'yes':
                if (!@odbtp_use_row_cache($conn)) {
                    return $this->raiseError(DB_ERROR, null, null, null,
                                             @odbtp_last_error());
                }
        }
        switch ($unicode) {
            case 1:
            case 'true':
            case 'yes':
                if (!@odbtp_set_attr(ODB_ATTR_UNICODESQL, 1, $conn)) {
                    return $this->raiseError(DB_ERROR, null, null, null,
                                             @odbtp_last_error());
                }
        }
        if ($vardatasize) {
            if (!@odbtp_set_attr(ODB_ATTR_VARDATASIZE, $vardatasize, $conn)) {
                return $this->raiseError(DB_ERROR, null, null, null,
                                         @odbtp_last_error());
            }
        }
        if (!@odbtp_set_attr(ODB_ATTR_FULLCOLINFO, 1, $conn)) {
            return $this->raiseError(DB_ERROR, null, null, null,
                                     @odbtp_last_error());
        }
        if( $this->dbsyntax == 'unknown' ) {
            switch (@odbtp_get_attr(ODB_ATTR_DRIVER, $conn)) {
                case ODB_DRIVER_MSSQL:
                    $this->dbsyntax = 'mssql'; break;
                case ODB_DRIVER_FOXPRO:
                    $this->dbsyntax = 'vfp'; break;
                case ODB_DRIVER_ORACLE:
                    $this->dbsyntax = 'oracle'; break;
                case ODB_DRIVER_SYBASE:
                    $this->dbsyntax = 'sybase'; break;
                case ODB_DRIVER_MYSQL:
                    $this->dbsyntax = 'mysql'; break;
                default:
                    $dbms = strtolower(@odbtp_get_attr(ODB_ATTR_DBMSNAME, $conn));
                    if ($dbms == 'access')
                        $this->dbsyntax = 'access';
                    else if ($dbms == 'text')
                        $this->dbsyntax = 'text';
                    else if ($dbms == 'excel')
                        $this->dbsyntax = 'excel';
                    else if (strncmp($dbms, 'db2', 3) == 0)
                        $this->dbsyntax = 'db2';
                    else
                        $this->dbsyntax = $dbms;
            }
        }
        switch ($this->dbsyntax) {
            case 'access':
            case 'vfp':
            case 'text':
            case 'excel':
                $tc = false;
                break;
            case 'mssql':
            case 'oracle':
            case 'sybase':
            case 'db2':
                $tc = true;
                break;
            default:
                $tc = @odbtp_get_attr(ODB_ATTR_TXNCAPABLE, $conn);
        }
        $this->features['transactions'] = $tc ? true : false;

        $this->connection = $conn;

        return DB_OK;
    }

    // }}}
    // {{{ disconnect()

    /**
     * Disconnect from ODBTP server
     *
     * @return boolean TRUE if successful, otherwise FALSE
     *
     * @access public
     */
    function disconnect()
    {
        $ret = @odbtp_close($this->connection);
        $this->connection = null;
        return $ret;
    }

    // }}}
    // {{{ simpleQuery()

    /**
     * Perform a SQL query.
     *
     * @param string $query SQL statement
     *
     * @return mixed ODBTP query result resource, DB_OK or DB_Error
     *
     * @access public
     */
    function simpleQuery($query)
    {
        $ismanip = DB::isManip($query);
        $this->last_query = $query;
        $query = $this->modifyQuery($query);
        $this->query_result = @odbtp_query($query, $this->connection);
        if (!$this->query_result) {
            return $this->odbtpRaiseError();
        }
        // Determine which queries that should return data, and which
        // should return an error code only.
        return $ismanip ? DB_OK : $this->query_result;
    }

    // }}}
    // {{{ nextResult()

    /**
     * Move the internal odbtp result pointer to the next available result
     *
     * @param resource $result ODBTP query result identifier
     *
     * @return boolean TRUE if a result is available, otherwise FALSE
     *
     * @access public
     */
    function nextResult($result)
    {
        return @odbtp_next_result($result);
    }

    // }}}
    // {{{ fetchInto()

    /**
     * Fetch a row and insert the data into an existing array.
     *
     * Formating of the array and the data therein are configurable.
     * See DB_result::fetchInto() for more information.
     *
     * @param resource $result    ODBTP query result identifier
     * @param array    $arr       (reference) array where data from the row
     *                            should be placed
     * @param int      $fetchmode how the resulting array should be indexed
     * @param int      $rownum    the row number to fetch
     *
     * @return mixed DB_OK on success, NULL when end of result set is
     *               reached or on failure
     *
     * @access private
     * @see DB_result::fetchInto()
     */
    function fetchInto($result, &$arr, $fetchmode, $rownum=null)
    {
        if ($rownum !== null) {
            if (!@odbtp_data_seek($result, $rownum)) {
                return null;
            }
        }
        if ($fetchmode & DB_FETCHMODE_ASSOC) {
            $arr = @odbtp_fetch_assoc($result);
            if ($this->options['portability'] & DB_PORTABILITY_LOWERCASE && $arr) {
                $arr = array_change_key_case($arr, CASE_LOWER);
            }
        } else {
            $arr = @odbtp_fetch_row($result);
        }
        if (!$arr) {
            return null;
        }
        if ($this->options['portability'] & DB_PORTABILITY_RTRIM) {
            $this->_rtrimArrayValues($arr);
        }
        if ($this->options['portability'] & DB_PORTABILITY_NULL_TO_EMPTY) {
            $this->_convertNullArrayValuesToEmpty($arr);
        }
        return DB_OK;
    }

    // }}}
    // {{{ freeResult()

    /**
     * Free the internal resources associated with $result.
     *
     * @param resource $result ODBTP query result identifier
     *
     * @return boolean TRUE on success, FALSE if $result is invalid
     *
     * @access public
     */
    function freeResult($result)
    {
        return @odbtp_free_query($result);
    }

    // }}}
    // {{{ numCols()

    /**
     * Returns the number of columns in a result
     *
     * @param resource $result ODBTP query result identifier
     *
     * @return mixed DB_Error or the number of columns
     *
     * @access public
     */
    function numCols($result)
    {
        $cols = @odbtp_num_fields($result);
        if ($cols === false) {
            return $this->odbtpRaiseError();
        }
        return $cols;
    }

    // }}}
    // {{{ numRows()

    /**
     * Returns the number of rows in a result if row caching has been
     * enabled.
     *
     * @param resource $result ODBTP query result identifier
     *
     * @return mixed DB_Error or the number of rows
     *
     * @access public
     */
    function numRows($result)
    {
        $rows = @odbtp_num_rows($result);
        if ($rows === false) {
            return $this->odbtpRaiseError();
        }
        return $rows;
    }

    // }}}
    // {{{ autoCommit()

    /**
     * enable automatic Commit
     *
     * @param boolean $onoff
     * @return mixed DB_Error
     *
     * @access public
     */
    function autoCommit($onoff = false)
    {
        $txn = $onoff ? ODB_TXN_NONE : $this->txn_isolation;
        if (!@odbtp_set_attr(ODB_ATTR_TRANSACTIONS, $txn, $this->connection)) {
            return $this->odbtpRaiseError();
        }
        return DB_OK;
    }

    // }}}
    // {{{ commit()

    /**
     * Commit the current transaction.
     *
     * @return mixed DB_Error
     *
     * @access public
     */
    function commit()
    {
        if (!@odbtp_commit($this->connection)) {
            return $this->odbtpRaiseError();
        }
        return DB_OK;
    }

    // }}}
    // {{{ rollback()

    /**
     * Rollback the current transaction.
     *
     * @return mixed DB_Error
     *
     * @access public
     */
    function rollback()
    {
        if (!@odbtp_rollback($this->connection)) {
            return $this->odbtpRaiseError();
        }
        return DB_OK;
    }

    // }}}
    // {{{ affectedRows()

    /**
     * Returns the affected rows of a query
     *
     * @return mixed DB_Error or the number of rows
     *
     * @access public
     */
    function affectedRows()
    {
        if (is_resource($this->query_result)) {
            $rows = @odbtp_affected_rows($this->query_result);
            if ($rows === false) {
                return $this->odbtpRaiseError();
            }
        } else {
            $rows = -1;
        }
        return $rows;
    }

    // }}}
    // {{{ nextId()

    /**
     * Returns the next free id in a sequence
     *
     * @param string  $seq_name  name of the sequence
     * @param boolean $ondemand  when true, the seqence is automatically
     *                           created if it does not exist
     *
     * @return int  the next id number in the sequence.  DB_Error if problem.
     *
     * @access public
     * @internal
     * @see DB_common::nextID()
     */
    function nextId($seq_name, $ondemand = true)
    {
        $seqname = $this->getSequenceName($seq_name);
        $repeat = 0;
        do {
            $this->pushErrorHandling(PEAR_ERROR_RETURN);
            $result = $this->query("UPDATE ${seqname} SET id = id + 1");
            $this->popErrorHandling();
            if ($ondemand && DB::isError($result) &&
                $result->getCode() == DB_ERROR_NOSUCHTABLE) {
                $repeat = 1;
                $this->pushErrorHandling(PEAR_ERROR_RETURN);
                $result = $this->createSequence($seq_name);
                $this->popErrorHandling();
                if (DB::isError($result)) {
                    return $this->raiseError($result);
                }
                $result = $this->query("INSERT INTO ${seqname} (id) VALUES (0)");
            } else {
                $repeat = 0;
            }
        } while ($repeat);

        if (DB::isError($result)) {
            return $this->raiseError($result);
        }
        $result = $this->query("SELECT id FROM ${seqname}");
        if (DB::isError($result)) {
            return $result;
        }
        $row = $result->fetchRow(DB_FETCHMODE_ORDERED);
        if (DB::isError($row || !$row)) {
            return $row;
        }
        return $row[0];
    }

    // }}}
    // {{{ createSequence()

    /**
     * Creates a new sequence
     *
     * @param string $seq_name  name of the new sequence
     *
     * @return int  DB_OK on success.  A DB_Error object is returned if
     *              problems arise.
     *
     * @access public
     * @internal
     * @see DB_common::createSequence()
     */
    function createSequence($seq_name)
    {
        $seqname = $this->getSequenceName($seq_name);

        // Make sure Visual FoxPro creates table in database folder.
        if( $this->dbsyntax == 'vfp' ) {
            $path = @odbtp_get_attr(ODB_ATTR_DATABASENAME, $this->connection);
            //if using vfp dbc file
            if( !strcasecmp(strrchr($path, '.'), '.dbc') )
                $path = substr($path,0,strrpos($path,"\\"));
            $seqname = $path . "\\" . $seqname;
        }
        return $this->query("CREATE TABLE ${seqname} ".
                            '(id INT NOT NULL UNIQUE)');
    }

    // }}}
    // {{{ dropSequence()

    /**
     * Deletes a sequence
     *
     * @param string $seq_name  name of the sequence to be deleted
     *
     * @return int  DB_OK on success.  DB_Error if problems.
     *
     * @access public
     * @internal
     * @see DB_common::dropSequence()
     */
    function dropSequence($seq_name)
    {
        $seqname = $this->getSequenceName($seq_name);

        // Make sure Visual FoxPro drops table in database folder.
        if( $this->dbsyntax == 'vfp' ) {
            $path = @odbtp_get_attr(ODB_ATTR_DATABASENAME, $this->connection);
            //if using vfp dbc file
            if( !strcasecmp(strrchr($path, '.'), '.dbc') )
                $path = substr($path,0,strrpos($path,"\\"));
            $seqname = $path . "\\" . $seqname;
        }
        return $this->query("DROP TABLE ${seqname}");
    }

    // }}}
    // {{{ quote()

    /**
     * DEPRECATED: Quotes a string so it can be safely used in a query
     *
     * @param string $string the input string to quote
     *
     * @return string The NULL string or the string quotes
     *                in magic_quote_sybase style
     *
     * @access public
     * @see DB_common::quoteSmart(), DB_common::escapeSimple()
     * @deprecated  Deprecated in release 1.6.0
     * @internal
     */
    function quote($str = null)
    {
        switch (strtolower(gettype($str))) {
            case 'null':
                return 'NULL';
            case 'integer':
            case 'double':
                return $str;
            case 'string':
            default:
                $str = str_replace("'", "''", $str);
                return "'$str'";
        }
    }

    // }}}
    // {{{ errorNative()

    /**
     * Get the native error code of the last error (if any) that
     * occured on the current connection.
     *
     * @return string native ODBTP error message
     *
     * @access public
     */
    function errorNative()
    {
        if (!isset($this->connection) || !is_resource($this->connection)) {
            return @odbtp_last_error();
        }
        return @odbtp_last_error($this->connection);
    }

    // }}}
    // {{{ odbtpRaiseError()

    /**
     * Gather information about an error, then use that info to create a
     * DB error object and finally return that object.
     *
     * @param  integer  $code  PEAR error number (usually a DB constant) if
     *                         manually raising an error
     *
     * @return object  DB error object
     *
     * @access public
     * @see errorCode()
     * @see errorNative()
     * @see DB_common::raiseError()
     */
    function odbtpRaiseError($code = null)
    {
        if ($code === null) {
            $code = $this->errorCode(@odbtp_last_error_state());
        }
        return $this->raiseError($code, null, null, null, @odbtp_last_error());
    }

    // }}}
    // {{{ tableInfo()

    /**
     * Returns information about a table or a result set
     *
     * The format of the resulting array depends on which <var>$mode</var>
     * you select.  The sample output below is based on this query:
     * <pre>
     *    SELECT tblFoo.fldID, tblFoo.fldPhone, tblBar.fldId
     *    FROM tblFoo
     *    JOIN tblBar ON tblFoo.fldId = tblBar.fldId
     * </pre>
     *
     * <ul>
     * <li>
     *
     * <kbd>null</kbd> (default)
     *   <pre>
     *   [0] => Array (
     *       [table] => tblFoo
     *       [name] => fldId
     *       [type] => int
     *       [len] => 11
     *       [flags] => primary_key not_null
     *   )
     *   [1] => Array (
     *       [table] => tblFoo
     *       [name] => fldPhone
     *       [type] => string
     *       [len] => 20
     *       [flags] =>
     *   )
     *   [2] => Array (
     *       [table] => tblBar
     *       [name] => fldId
     *       [type] => int
     *       [len] => 11
     *       [flags] => primary_key not_null
     *   )
     *   </pre>
     *
     * </li><li>
     *
     * <kbd>DB_TABLEINFO_ORDER</kbd>
     *
     *   <p>In addition to the information found in the default output,
     *   a notation of the number of columns is provided by the
     *   <samp>num_fields</samp> element while the <samp>order</samp>
     *   element provides an array with the column names as the keys and
     *   their location index number (corresponding to the keys in the
     *   the default output) as the values.</p>
     *
     *   <p>If a result set has identical field names, the last one is
     *   used.</p>
     *
     *   <pre>
     *   [num_fields] => 3
     *   [order] => Array (
     *       [fldId] => 2
     *       [fldTrans] => 1
     *   )
     *   </pre>
     *
     * </li><li>
     *
     * <kbd>DB_TABLEINFO_ORDERTABLE</kbd>
     *
     *   <p>Similar to <kbd>DB_TABLEINFO_ORDER</kbd> but adds more
     *   dimensions to the array in which the table names are keys and
     *   the field names are sub-keys.  This is helpful for queries that
     *   join tables which have identical field names.</p>
     *
     *   <pre>
     *   [num_fields] => 3
     *   [ordertable] => Array (
     *       [tblFoo] => Array (
     *           [fldId] => 0
     *           [fldPhone] => 1
     *       )
     *       [tblBar] => Array (
     *           [fldId] => 2
     *       )
     *   )
     *   </pre>
     *
     * </li>
     * </ul>
     *
     * The <samp>flags</samp> element contains a space separated list
     * of extra information about the field.  This data is inconsistent
     * between DBMS's due to the way each DBMS works.
     *   + <samp>primary_key</samp>
     *   + <samp>unique_key</samp>
     *   + <samp>multiple_key</samp>
     *   + <samp>not_null</samp>
     *
     * Most DBMS's only provide the <samp>table</samp> and <samp>flags</samp>
     * elements if <var>$result</var> is a table name.  The following DBMS's
     * provide full information from queries:
     *   + fbsql
     *   + mysql
     *
     * If the 'portability' option has <samp>DB_PORTABILITY_LOWERCASE</samp>
     * turned on, the names of tables and fields will be lowercased.
     *
     * @param object|string  $result  DB_result object from a query or a
     *                                string containing the name of a table.
     *                                While this also accepts a query result
     *                                resource identifier, this behavior is
     *                                deprecated.
     * @param int  $mode   either unused or one of the tableInfo modes:
     *                     <kbd>DB_TABLEINFO_ORDERTABLE</kbd>,
     *                     <kbd>DB_TABLEINFO_ORDER</kbd> or
     *                     <kbd>DB_TABLEINFO_FULL</kbd> (which does both).
     *                     These are bitwise, so the first two can be
     *                     combined using <kbd>|</kbd>.
     * @return array  an associative array with the information requested.
     *                If something goes wrong an error object is returned.
     *
     * @access public
     * @see DB_common::setOption()
     */
    function tableInfo($result, $mode = null)
    {
        if (is_string($result)) {
            /*
             * Probably received a table name.
             */
            $is_table = true;
        } else if (isset($result->result)) {
            /*
             * Probably received a result object.
             * Extract the result resource identifier.
             */
            $id = $result->result;
            $is_table = false;
        } else {
            /*
             * Probably received a result resource identifier.
             * Copy it.
             * Deprecated.  Here for compatibility only.
             */
            $id = $result;
            $is_table = false;
        }

        $res = array();

        if ($mode) {
            $res['num_fields'] = 0;
        }

        if ($this->options['portability'] & DB_PORTABILITY_LOWERCASE) {
            $case_func = 'strtolower';
        } else {
            $case_func = 'strval';
        }

        // if $result is a string, then we want information about a
        // table without a resultset

        if ($is_table) {
            // Extract schema name if present
            if (($at = strpos($result,'.')) !== false) {
                $schema = substr( $result, 0, $at );
                $table  = substr( $result, $at+1 );
            }
            else {
                $schema = '';
                $table  = $result;
            }
            $id = @odbtp_query("||SQLColumns||$schema|$table", $this->connection);
            if (!$id) {
                return $this->odbtpRaiseError();
            }
            for ($i=0; ($row = @odbtp_fetch_row($id)); $i++) {
                $res[$i]['table'] = $case_func($row[2]);
                $res[$i]['name']  = $case_func($row[3]);
                $res[$i]['type']  = $case_func($row[5]);
                $res[$i]['len']   = $row[6];
                $res[$i]['flags'] = @odbtp_flags($row[4], $row[5], $row[10]);
            }
            $count = $i;
            $id = @odbtp_query("||SQLPrimaryKeys|$db||$result", $this->connection);
            if ($id) {
                while ($row = @odbtp_fetch_row($id)) {
                    for ($i=0; $i<$count; $i++) {
                        if (!strcasecmp($row[3], $res[$i]['name'])) {
                            if ($res[$i]['flags'])
                                $res[$i]['flags'] .= ' primary_key';
                            else
                                $res[$i]['flags'] .= 'primary_key';
                            break;
                        }
                    }
                }
                @odbtp_free_query($id);
            }
        } else { // else we want information about a resultset
            $count = @odbtp_num_fields($id);
            for ($i=0; $i<$count; $i++) {
                $res[$i]['table'] = $case_func(@odbtp_field_table($id, $i));
                $res[$i]['name']  = $case_func(@odbtp_field_name($id, $i));
                $res[$i]['type']  = $case_func(@odbtp_field_type($id, $i));
                $res[$i]['len']   = @odbtp_field_length($id, $i);
                $res[$i]['flags'] = @odbtp_field_flags($id, $i);
            }
        }
        if ($mode) { // full
            $res['num_fields'] = $count;

            for ($i=0; $i<$count; $i++) {
                if ($mode & DB_TABLEINFO_ORDER) {
                    $res['order'][$res[$i]['name']] = $i;
                }
                if ($mode & DB_TABLEINFO_ORDERTABLE) {
                    $res['ordertable'][$res[$i]['table']][$res[$i]['name']] = $i;
                }
            }
        }
        return $res;
    }

    // }}}
    // {{{ getSpecialQuery()

    /**
     * Returns the query needed to get some backend info
     *
     * @param string $type What kind of info you want to retrieve
     *
     * @return string The SQL query string
     *
     * @access public
     */
    function getSpecialQuery($type)
    {
        switch ($this->dbsyntax) {
            case 'mssql':
            case 'sybase':
                switch ($type) {
                    case 'tables':
                        $sql = "select name from sysobjects where type = 'U' order by name";
                        break;
                    case 'views':
                        $sql = "select name from sysobjects where type = 'V' order by name";
                        break;
                    case 'tables':
                        $sql = "SELECT name FROM sysobjects WHERE type = 'U'"
                             . ' ORDER BY name';
                        break;
                    case 'views':
                        $sql = "SELECT name FROM sysobjects WHERE type = 'V'"
                             . ' ORDER BY name';
                        break;
                    default:
                        return null;
                }
                break;
            case 'oracle':
                switch ($type) {
                    case 'tables':
                        $sql = "SELECT table_name FROM user_tables";
                        break;
                    case 'synonyms':
                        $sql = 'SELECT synonym_name FROM user_synonyms';
                        break;
                    default:
                        return null;
                }
                break;
            case 'mysql':
                switch ($type) {
                    case 'tables':
                        $sql = "SHOW TABLES";
                        break;
                    case 'users':
                        $sql =  'SELECT DISTINCT User FROM mysql.user';
                        break;
                    case 'databases':
                        $sql = "SHOW DATABASES";
                        break;
                    default:
                        return null;
                }
                break;
            default:
                return null;
        }
        return $sql;
    }

    // }}}
    // {{{ quoteIdentifier()

    /**
     * Quote a string so it can be safely used as a table / column name
     *
     * Quoting style depends on the database syntax in use.
     *
     * @param string $str identifier name to be quoted
     *
     * @return string quoted identifier string
     *
     * @access public
     */
    function quoteIdentifier($str)
    {
        switch ($this->dbsyntax) {
            case 'access':
                return '[' . $str . ']';
            case 'mssql':
            case 'sybase':
                return '[' . str_replace(']', ']]', $str) . ']';
            case 'mysql':
            case 'mysqli':
                return '`' . $str . '`';
        }
        return '"' . str_replace('"', '""', $str) . '"';
    }

    // }}}
    // {{{ getConnectionId()

    /**
     * Get ODBTP Connection Id string
     *
     * @return mixed Connection Id string, or DB_Error if failure
     *
     * @access public
     */
    function getConnectionId()
    {
        $id = @odbtp_connect_id($this->connection);
        if (!is_string($id)) {
            return $this->odbtpRaiseError();
        }
        return $id;
    }

    // }}}

}

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 */

?>
