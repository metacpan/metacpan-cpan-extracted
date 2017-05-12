<?php

/**
* 
* Creates tables from DB_Table definitions.
* 
* DB_Table_Manager provides database automated table creation
* facilities.
* 
* @category DB
* 
* @package DB_Table
*
* @author Paul M. Jones <pmjones@php.net>
* @author Mark Wiesemann <wiesemann@php.net>
* 
* @license http://www.gnu.org/copyleft/lesser.html LGPL
* 
* @version $Id: Manager.php,v 1.9 2005/08/18 08:09:42 wiesemann Exp $
*
*/

require_once 'DB/Table.php';


/**
* 
* Creates tables from DB_Table definitions.
* 
* DB_Table_Manager provides database automated table creation
* facilities.
* 
* @category DB
* 
* @package DB_Table
*
* @author Paul M. Jones <pmjones@php.net>
* @author Mark Wiesemann <wiesemann@php.net>
*
*/

class DB_Table_Manager {
    
    
    /**
    * 
    * Create the table based on DB_Table column and index arrays.
    * 
    * @static
    * 
    * @access public
    * 
    * @param object &$db A PEAR DB object.
    * 
    * @param string $table The table name to connect to in the database.
    * 
    * @param mixed $column_set A DB_Table $this->col array.
    * 
    * @param mixed $index_set A DB_Table $this->idx array.
    * 
    * @return mixed Boolean false if there was no attempt to create the
    * table, boolean true if the attempt succeeded, and a PEAR_Error if
    * the attempt failed.
    * 
    */
    
    function create(&$db, $table, $column_set, $index_set)
    {
        // columns to be created
        $column = array();
        
        // indexes to be created
        $index = array();
        
        // is the table name too long?
        if (strlen($table) > 30) {
			return DB_Table::throwError(
				DB_TABLE_ERR_TABLE_STRLEN,
				" ('$table')"
			);
        }
        
        
        // -------------------------------------------------------------
        // 
        // validate each column mapping and build the individual
        // definitions, and note column indexes as we go.
        //
        
        foreach ($column_set as $colname => $val) {
            
            $colname = trim($colname);
            
            // column name cannot be a reserved keyword
            $reserved = in_array(
                strtoupper($colname),
                $GLOBALS['_DB_TABLE']['reserved']
            );
            
            if ($reserved) {
                return DB_Table::throwError(
                    DB_TABLE_ERR_DECLARE_COLNAME,
                    " ('$colname')"
                );
            }
            
            // column must be no longer than 30 chars
            if (strlen($colname) > 30) {
				return DB_Table::throwError(
					DB_TABLE_ERR_DECLARE_STRLEN,
					"('$colname')"
				);
            }
            
            
            // prepare variables
            $type    = (isset($val['type']))    ? $val['type']    : null;
            $size    = (isset($val['size']))    ? $val['size']    : null;
            $scope   = (isset($val['scope']))   ? $val['scope']   : null;
            $require = (isset($val['require'])) ? $val['require'] : null;
            $default = (isset($val['default'])) ? $val['default'] : null;
            
            // get the declaration string
            $result = DB_Table_Manager::getDeclare($db->phptype, $type, $size, 
                $scope, $require, $default);
            
            // did it work?
            if (PEAR::isError($result)) {
                $result->userinfo .= " ('$colname')";
                return $result;
            }
            
            // add the declaration to the array of all columns
            $column[] = "$colname $result";
        }
        
        
        // -------------------------------------------------------------
        // 
        // validate the indexes.
        //
        
        foreach ($index_set as $idxname => $val) {
            
            if (is_string($val)) {
                // shorthand for index names: colname => index_type
                $type = trim($val);
                $cols = trim($idxname);
            } elseif (is_array($val)) {
                // normal: index_name => array('type' => ..., 'cols' => ...)
                $type = (isset($val['type'])) ? $val['type'] : 'normal';
                $cols = (isset($val['cols'])) ? $val['cols'] : null;
            }
            
            // index name cannot be a reserved keyword
            $reserved = in_array(
                strtoupper($idxname),
                $GLOBALS['_DB_TABLE']['reserved']
            );
            
            if ($reserved) {
                return DB_Table::throwError(
                    DB_TABLE_ERR_DECLARE_IDXNAME,
                    "('$idxname')"
                );
            }
            
            // are there any columns for the index?
            if (! $cols) {
                return DB_Table::throwError(
                    DB_TABLE_ERR_IDX_NO_COLS,
                    "('$idxname')"
                );
            }
            
            // are there any CLOB columns, or any columns that are not
            // in the schema?
            settype($cols, 'array');
            $valid_cols = array_keys($column_set);
            foreach ($cols as $colname) {
            
                if (! in_array($colname, $valid_cols)) {
                    return DB_Table::throwError(
                        DB_TABLE_ERR_IDX_COL_UNDEF,
                        "'$idxname' ('$colname')"
                    );
                }
                
                if ($column_set[$colname]['type'] == 'clob') {
                    return DB_Table::throwError(
                        DB_TABLE_ERR_IDX_COL_CLOB,
                        "'$idxname' ('$colname')"
                    );
                }
                
            }
            
            // string of column names
            $colstring = implode(', ', $cols);
            
            // we prefix all index names with the table name,
            // and suffix all index names with '_idx'.  this
            // is to soothe PostgreSQL, which demands that index
            // names not collide, even when they indexes are on
            // different tables.
            $newIdxName = $table . '_' . $idxname . '_idx';
            
            // now check the length; must be under 30 chars to
            // soothe Oracle.
            if (strlen($newIdxName) > 30) {
				return DB_Table::throwError(
					DB_TABLE_ERR_IDX_STRLEN,
					"'$idxname' ('$newIdxName')"
				);
            }
            
            // create index entry
            if ($type == 'unique') {
                $index[] = "CREATE UNIQUE INDEX $newIdxName ON $table ($colstring)";
            } elseif ($type == 'normal') {
                $index[] = "CREATE INDEX $newIdxName ON $table ($colstring)";
            } else {
                return DB_Table::throwError(
                    DB_TABLE_ERR_IDX_TYPE,
                    "'$idxname' ('$type')"
                );
            }
            
        }
        
        
        // -------------------------------------------------------------
        // 
        // now for the real action: create the table and indexes!
        //
        
        // build the CREATE TABLE command
        $cmd = "CREATE TABLE $table (\n\t";
        $cmd .= implode(",\n\t", $column);
        $cmd .= "\n)";
        
        // attempt to create the table
        $result = $db->query($cmd);
        if (PEAR::isError($result)) {
            return $result;
        }
        
        // attempt to create the indexes
        foreach ($index as $cmd) {
            $result = $db->query($cmd);
            if (PEAR::isError($result)) {
                return $result;
            }
        }
        
        // we're done!
        return true;
    }
    
    
    /**
    * 
    * Get the column declaration string for a DB_Table column.
    * 
    * @static
    * 
    * @access public
    * 
    * @param string $phptype The DB phptype key.
    * 
    * @param string $coltype The DB_Table column type.
    * 
    * @param int $size The size for the column (needed for string and
    * decimal).
    * 
    * @param int $scope The scope for the column (needed for decimal).
    * 
    * @param bool $require True if the column should be NOT NULL, false
    * allowed to be NULL.
    * 
    * @param string $default The SQL calculation for a default value.
    * 
    * @return string|object A declaration string on success, or a
    * PEAR_Error on failure.
    * 
    */
    
    function getDeclare($phptype, $coltype, $size = null, $scope = null,
        $require = null, $default = null)
    {
        // validate char and varchar: does it have a size?
        if (($coltype == 'char' || $coltype == 'varchar') &&
            ($size < 1 || $size > 255) ) {
            return DB_Table::throwError(
                DB_TABLE_ERR_DECLARE_STRING,
                "(size='$size')"
            );
        }
        
        // validate decimal: does it have a size and scope?
        if ($coltype == 'decimal' &&
            ($size < 1 || $size > 255 || $scope < 0 || $scope > $size)) {
            return DB_Table::throwError(
                DB_TABLE_ERR_DECLARE_DECIMAL,
                "(size='$size' scope='$scope')"
            );
        }
        
        // map of column types and declarations for this RDBMS
        $map = $GLOBALS['_DB_TABLE']['type'][$phptype];
        
        // is it a recognized column type?
        $types = array_keys($map);
        if (! in_array($coltype, $types)) {
            return DB_Table::throwError(
                DB_TABLE_ERR_DECLARE_TYPE,
                "('$coltype')"
            );
        }
        
        // basic declaration
        switch ($coltype) {
    
        case 'char':
        case 'varchar':
            $declare = $map[$coltype] . "($size)";
            break;
        
        case 'decimal':
            $declare = $map[$coltype] . "($size,$scope)";
            break;
        
        default:
            $declare = $map[$coltype];
            break;
        
        }
        
        // set the "NULL"/"NOT NULL" portion
        $declare .= ($require) ? ' NOT NULL' : ' NULL';
        
        // set the "DEFAULT" portion
        $declare .= ($default) ? " DEFAULT $default" : '';
        
        // done
        return $declare;
    }
}


/**
* List of all reserved words for all supported databases. Yes, this is a
* monster of a list.
*/
if (! isset($GLOBALS['_DB_TABLE']['reserved'])) {
    $GLOBALS['_DB_TABLE']['reserved'] = array(
        '_ROWID_',
        'ABSOLUTE',
        'ACCESS',
        'ACTION',
        'ADD',
        'ADMIN',
        'AFTER',
        'AGGREGATE',
        'ALIAS',
        'ALL',
        'ALLOCATE',
        'ALTER',
        'ANALYSE',
        'ANALYZE',
        'AND',
        'ANY',
        'ARE',
        'ARRAY',
        'AS',
        'ASC',
        'ASENSITIVE',
        'ASSERTION',
        'AT',
        'AUDIT',
        'AUTHORIZATION',
        'AUTO_INCREMENT',
        'AVG',
        'BACKUP',
        'BDB',
        'BEFORE',
        'BEGIN',
        'BERKELEYDB',
        'BETWEEN',
        'BIGINT',
        'BINARY',
        'BIT',
        'BIT_LENGTH',
        'BLOB',
        'BOOLEAN',
        'BOTH',
        'BREADTH',
        'BREAK',
        'BROWSE',
        'BULK',
        'BY',
        'CALL',
        'CASCADE',
        'CASCADED',
        'CASE',
        'CAST',
        'CATALOG',
        'CHANGE',
        'CHAR',
        'CHAR_LENGTH',
        'CHARACTER',
        'CHARACTER_LENGTH',
        'CHECK',
        'CHECKPOINT',
        'CLASS',
        'CLOB',
        'CLOSE',
        'CLUSTER',
        'CLUSTERED',
        'COALESCE',
        'COLLATE',
        'COLLATION',
        'COLUMN',
        'COLUMNS',
        'COMMENT',
        'COMMIT',
        'COMPLETION',
        'COMPRESS',
        'COMPUTE',
        'CONDITION',
        'CONNECT',
        'CONNECTION',
        'CONSTRAINT',
        'CONSTRAINTS',
        'CONSTRUCTOR',
        'CONTAINS',
        'CONTAINSTABLE',
        'CONTINUE',
        'CONVERT',
        'CORRESPONDING',
        'COUNT',
        'CREATE',
        'CROSS',
        'CUBE',
        'CURRENT',
        'CURRENT_DATE',
        'CURRENT_PATH',
        'CURRENT_ROLE',
        'CURRENT_TIME',
        'CURRENT_TIMESTAMP',
        'CURRENT_USER',
        'CURSOR',
        'CYCLE',
        'DATA',
        'DATABASE',
        'DATABASES',
        'DATE',
        'DAY',
        'DAY_HOUR',
        'DAY_MICROSECOND',
        'DAY_MINUTE',
        'DAY_SECOND',
        'DBCC',
        'DEALLOCATE',
        'DEC',
        'DECIMAL',
        'DECLARE',
        'DEFAULT',
        'DEFERRABLE',
        'DEFERRED',
        'DELAYED',
        'DELETE',
        'DENY',
        'DEPTH',
        'DEREF',
        'DESC',
        'DESCRIBE',
        'DESCRIPTOR',
        'DESTROY',
        'DESTRUCTOR',
        'DETERMINISTIC',
        'DIAGNOSTICS',
        'DICTIONARY',
        'DISCONNECT',
        'DISK',
        'DISTINCT',
        'DISTINCTROW',
        'DISTRIBUTED',
        'DIV',
        'DO',
        'DOMAIN',
        'DOUBLE',
        'DROP',
        'DUMMY',
        'DUMP',
        'DYNAMIC',
        'EACH',
        'ELSE',
        'ELSEIF',
        'ENCLOSED',
        'END',
        'END-EXEC',
        'EQUALS',
        'ERRLVL',
        'ESCAPE',
        'ESCAPED',
        'EVERY',
        'EXCEPT',
        'EXCEPTION',
        'EXCLUSIVE',
        'EXEC',
        'EXECUTE',
        'EXISTS',
        'EXIT',
        'EXPLAIN',
        'EXTERNAL',
        'EXTRACT',
        'FALSE',
        'FETCH',
        'FIELDS',
        'FILE',
        'FILLFACTOR',
        'FIRST',
        'FLOAT',
        'FOR',
        'FORCE',
        'FOREIGN',
        'FOUND',
        'FRAC_SECOND',
        'FREE',
        'FREETEXT',
        'FREETEXTTABLE',
        'FREEZE',
        'FROM',
        'FULL',
        'FULLTEXT',
        'FUNCTION',
        'GENERAL',
        'GET',
        'GLOB',
        'GLOBAL',
        'GO',
        'GOTO',
        'GRANT',
        'GROUP',
        'GROUPING',
        'HAVING',
        'HIGH_PRIORITY',
        'HOLDLOCK',
        'HOST',
        'HOUR',
        'HOUR_MICROSECOND',
        'HOUR_MINUTE',
        'HOUR_SECOND',
        'IDENTIFIED',
        'IDENTITY',
        'IDENTITY_INSERT',
        'IDENTITYCOL',
        'IF',
        'IGNORE',
        'ILIKE',
        'IMMEDIATE',
        'IN',
        'INCREMENT',
        'INDEX',
        'INDICATOR',
        'INFILE',
        'INITIAL',
        'INITIALIZE',
        'INITIALLY',
        'INNER',
        'INNODB',
        'INOUT',
        'INPUT',
        'INSENSITIVE',
        'INSERT',
        'INT',
        'INTEGER',
        'INTERSECT',
        'INTERVAL',
        'INTO',
        'IO_THREAD',
        'IS',
        'ISNULL',
        'ISOLATION',
        'ITERATE',
        'JOIN',
        'KEY',
        'KEYS',
        'KILL',
        'LANGUAGE',
        'LARGE',
        'LAST',
        'LATERAL',
        'LEADING',
        'LEAVE',
        'LEFT',
        'LESS',
        'LEVEL',
        'LIKE',
        'LIMIT',
        'LINENO',
        'LINES',
        'LOAD',
        'LOCAL',
        'LOCALTIME',
        'LOCALTIMESTAMP',
        'LOCATOR',
        'LOCK',
        'LONG',
        'LONGBLOB',
        'LONGTEXT',
        'LOOP',
        'LOW_PRIORITY',
        'LOWER',
        'MAIN',
        'MAP',
        'MASTER_SERVER_ID',
        'MATCH',
        'MAX',
        'MAXEXTENTS',
        'MEDIUMBLOB',
        'MEDIUMINT',
        'MEDIUMTEXT',
        'MIDDLEINT',
        'MIN',
        'MINUS',
        'MINUTE',
        'MINUTE_MICROSECOND',
        'MINUTE_SECOND',
        'MLSLABEL',
        'MOD',
        'MODE',
        'MODIFIES',
        'MODIFY',
        'MODULE',
        'MONTH',
        'NAMES',
        'NATIONAL',
        'NATURAL',
        'NCHAR',
        'NCLOB',
        'NEW',
        'NEXT',
        'NO',
        'NO_WRITE_TO_BINLOG',
        'NOAUDIT',
        'NOCHECK',
        'NOCOMPRESS',
        'NONCLUSTERED',
        'NONE',
        'NOT',
        'NOTNULL',
        'NOWAIT',
        'NULL',
        'NULLIF',
        'NUMBER',
        'NUMERIC',
        'OBJECT',
        'OCTET_LENGTH',
        'OF',
        'OFF',
        'OFFLINE',
        'OFFSET',
        'OFFSETS',
        'OID',
        'OLD',
        'ON',
        'ONLINE',
        'ONLY',
        'OPEN',
        'OPENDATASOURCE',
        'OPENQUERY',
        'OPENROWSET',
        'OPENXML',
        'OPERATION',
        'OPTIMIZE',
        'OPTION',
        'OPTIONALLY',
        'OR',
        'ORDER',
        'ORDINALITY',
        'OUT',
        'OUTER',
        'OUTFILE',
        'OUTPUT',
        'OVER',
        'OVERLAPS',
        'PAD',
        'PARAMETER',
        'PARAMETERS',
        'PARTIAL',
        'PATH',
        'PCTFREE',
        'PERCENT',
        'PLACING',
        'PLAN',
        'POSITION',
        'POSTFIX',
        'PRECISION',
        'PREFIX',
        'PREORDER',
        'PREPARE',
        'PRESERVE',
        'PRIMARY',
        'PRINT',
        'PRIOR',
        'PRIVILEGES',
        'PROC',
        'PROCEDURE',
        'PUBLIC',
        'PURGE',
        'RAISERROR',
        'RAW',
        'READ',
        'READS',
        'READTEXT',
        'REAL',
        'RECONFIGURE',
        'RECURSIVE',
        'REF',
        'REFERENCES',
        'REFERENCING',
        'REGEXP',
        'RELATIVE',
        'RENAME',
        'REPEAT',
        'REPLACE',
        'REPLICATION',
        'REQUIRE',
        'RESOURCE',
        'RESTORE',
        'RESTRICT',
        'RESULT',
        'RETURN',
        'RETURNS',
        'REVOKE',
        'RIGHT',
        'RLIKE',
        'ROLE',
        'ROLLBACK',
        'ROLLUP',
        'ROUTINE',
        'ROW',
        'ROWCOUNT',
        'ROWGUIDCOL',
        'ROWID',
        'ROWNUM',
        'ROWS',
        'RULE',
        'SAVE',
        'SAVEPOINT',
        'SCHEMA',
        'SCOPE',
        'SCROLL',
        'SEARCH',
        'SECOND',
        'SECOND_MICROSECOND',
        'SECTION',
        'SELECT',
        'SENSITIVE',
        'SEPARATOR',
        'SEQUENCE',
        'SESSION',
        'SESSION_USER',
        'SET',
        'SETS',
        'SETUSER',
        'SHARE',
        'SHOW',
        'SHUTDOWN',
        'SIMILAR',
        'SIZE',
        'SMALLINT',
        'SOME',
        'SONAME',
        'SPACE',
        'SPATIAL',
        'SPECIFIC',
        'SPECIFICTYPE',
        'SQL',
        'SQL_BIG_RESULT',
        'SQL_CALC_FOUND_ROWS',
        'SQL_SMALL_RESULT',
        'SQL_TSI_DAY',
        'SQL_TSI_FRAC_SECOND',
        'SQL_TSI_HOUR',
        'SQL_TSI_MINUTE',
        'SQL_TSI_MONTH',
        'SQL_TSI_QUARTER',
        'SQL_TSI_SECOND',
        'SQL_TSI_WEEK',
        'SQL_TSI_YEAR',
        'SQLCODE',
        'SQLERROR',
        'SQLEXCEPTION',
        'SQLITE_MASTER',
        'SQLITE_TEMP_MASTER',
        'SQLSTATE',
        'SQLWARNING',
        'SSL',
        'START',
        'STARTING',
        'STATE',
        'STATEMENT',
        'STATIC',
        'STATISTICS',
        'STRAIGHT_JOIN',
        'STRIPED',
        'STRUCTURE',
        'SUBSTRING',
        'SUCCESSFUL',
        'SUM',
        'SYNONYM',
        'SYSDATE',
        'SYSTEM_USER',
        'TABLE',
        'TABLES',
        'TEMPORARY',
        'TERMINATE',
        'TERMINATED',
        'TEXTSIZE',
        'THAN',
        'THEN',
        'TIME',
        'TIMESTAMP',
        'TIMESTAMPADD',
        'TIMESTAMPDIFF',
        'TIMEZONE_HOUR',
        'TIMEZONE_MINUTE',
        'TINYBLOB',
        'TINYINT',
        'TINYTEXT',
        'TO',
        'TOP',
        'TRAILING',
        'TRAN',
        'TRANSACTION',
        'TRANSLATE',
        'TRANSLATION',
        'TREAT',
        'TRIGGER',
        'TRIM',
        'TRUE',
        'TRUNCATE',
        'TSEQUAL',
        'UID',
        'UNDER',
        'UNDO',
        'UNION',
        'UNIQUE',
        'UNKNOWN',
        'UNLOCK',
        'UNNEST',
        'UNSIGNED',
        'UPDATE',
        'UPDATETEXT',
        'UPPER',
        'USAGE',
        'USE',
        'USER',
        'USER_RESOURCES',
        'USING',
        'UTC_DATE',
        'UTC_TIME',
        'UTC_TIMESTAMP',
        'VALIDATE',
        'VALUE',
        'VALUES',
        'VARBINARY',
        'VARCHAR',
        'VARCHAR2',
        'VARCHARACTER',
        'VARIABLE',
        'VARYING',
        'VERBOSE',
        'VIEW',
        'WAITFOR',
        'WHEN',
        'WHENEVER',
        'WHERE',
        'WHILE',
        'WITH',
        'WITHOUT',
        'WORK',
        'WRITE',
        'WRITETEXT',
        'XOR',
        'YEAR',
        'YEAR_MONTH',
        'ZEROFILL',
        'ZONE',
    );
}
        
?>