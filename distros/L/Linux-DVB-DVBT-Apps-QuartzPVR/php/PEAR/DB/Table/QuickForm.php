<?php
/**
* 
* DB_Table_QuickForm creates HTML_QuickForm objects from DB_Table properties.
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
* @version $Id: QuickForm.php,v 1.28 2005/09/13 14:46:08 wiesemann Exp $
*
*/

/**
* Needed to build forms.
*/
require_once 'HTML/QuickForm.php';

/**
* US-English messages for some QuickForm rules.  Moritz Heidkamp
* suggested this approach for easier i18n.
*/
if (! isset($GLOBALS['_DB_TABLE']['qf_rules'])) {
    $GLOBALS['_DB_TABLE']['qf_rules'] = array(
      'required'  => 'The item %s is required.',
      'numeric'   => 'The item %s must be numbers only.',
      'maxlength' => 'The item %s can have no more than %d characters.'
    );
}


/**
* 
* DB_Table_QuickForm creates HTML_QuickForm objects from DB_Table properties.
* 
* DB_Table_QuickForm provides HTML form creation facilities based on
* DB_Table column definitions transformed into HTML_QuickForm elements.
* 
* @category DB
* 
* @package DB_Table
*
* @author Paul M. Jones <pmjones@ciaweb.net>
* @author Mark Wiesemann <wiesemann@php.net>
*
*/

class DB_Table_QuickForm {
    
    
    /**
    * 
    * Build a form based on DB_Table column definitions.
    * 
    * @static
    * 
    * @access public
    * 
    * @param array $cols A sequential array of DB_Table column definitions
    * from which to create form elements.
    * 
    * @param string $arrayName By default, the form will use the names
    * of the columns as the names of the form elements.  If you pass
    * $arrayName, the column names will become keys in an array named
    * for this parameter.
    * 
    * @param array $args An associative array of optional arguments to
    * pass to the QuickForm object.  The keys are...
    *
    * 'formName' : String, name of the form; defaults to the name of the
    * table.
    * 
    * 'method' : String, form method; defaults to 'post'.
    * 
    * 'action' : String, form action; defaults to
    * $_SERVER['REQUEST_URI'].
    * 
    * 'target' : String, form target target; defaults to '_self'
    * 
    * 'attributes' : Associative array, extra attributes for <form>
    * tag; the key is the attribute name and the value is attribute
    * value.
    * 
    * 'trackSubmit' : Boolean, whether to track if the form was
    * submitted by adding a special hidden field
    * 
    * @param string $clientValidate By default, validation will match
    * the 'qf_client' value from the column definition.  However,
    * if you set $clientValidate to true or false, this will
    * override the value from the column definition.
    *
    * @param array $formFilters An array with filter function names or
    * callbacks that will be applied to all form elements.
    * 
    * @return object HTML_QuickForm
    * 
    * @see HTML_QuickForm
    *
    * @see DB_Table_QuickForm::createForm()
    * 
    */
    
    function &getForm($cols, $arrayName = null, $args = array(),
        $clientValidate = null, $formFilters = null)
    {
        $form =& DB_Table_QuickForm::createForm($args);
        DB_Table_QuickForm::addElements($form, $cols, $arrayName);
        DB_Table_QuickForm::addRules($form, $cols, $arrayName, $clientValidate);
        DB_Table_QuickForm::addFilters($form, $cols, $arrayName, $formFilters);
        
        return $form;
    }
    
    
    /**
    * 
    * Creates an empty form object.
    *
    * In case you want more control over your form, you can call this function
    * to create it, then add whatever elements you want.
    *
    * @static
    * 
    * @access public
    * 
    * @author Ian Eure <ieure@php.net>
    * 
    * @param array $args An associative array of optional arguments to
    * pass to the QuickForm object.  The keys are...
    *
    * 'formName' : String, name of the form; defaults to the name of the
    * table.
    * 
    * 'method' : String, form method; defaults to 'post'.
    * 
    * 'action' : String, form action; defaults to
    * $_SERVER['REQUEST_URI'].
    * 
    * 'target' : String, form target target; defaults to '_self'
    * 
    * 'attributes' : Associative array, extra attributes for <form>
    * tag; the key is the attribute name and the value is attribute
    * value.
    * 
    * 'trackSubmit' : Boolean, whether to track if the form was
    * submitted by adding a special hidden field
    * 
    * @return object HTML_QuickForm
    * 
    */
    
    function &createForm($args = array(), $clientValidate = null)
    {
        $formName = isset($args['formName'])
            ? $args['formName'] : $this->table;
            
        $method = isset($args['method'])
            ? $args['method'] : 'post';
        
        $action = isset($args['action'])
            ? $args['action'] : $_SERVER['REQUEST_URI'];
        
        $target = isset($args['target'])
            ? $args['target'] : '_self';
        
        $attributes = isset($args['attributes'])
            ? $args['attributes'] : null;
        
        $trackSubmit = isset($args['trackSubmit'])
            ? $args['trackSubmit'] : false;
        
        $form =& new HTML_QuickForm($formName, $method, $action, $target, 
            $attributes, $trackSubmit);
        
        return $form;
    }
    
    
    /**
    * 
    * Adds DB_Table columns to a pre-existing HTML_QuickForm object.
    * 
    * @author Ian Eure <ieure@php.net>
    * 
    * @static
    * 
    * @access public
    * 
    * @param object &$form An HTML_QuickForm object.
    * 
    * @param array $cols A sequential array of DB_Table column definitions
    * from which to create form elements.
    * 
    * @param string $arrayName By default, the form will use the names
    * of the columns as the names of the form elements.  If you pass
    * $arrayName, the column names will become keys in an array named
    * for this parameter.
    * 
    * @return void
    * 
    */
    
    function addElements(&$form, $cols, $arrayName = null)
    {
        $elements =& DB_Table_QuickForm::getElements($cols, $arrayName);
        $cols_keys = array_keys($cols);
        foreach (array_keys($elements) as $k) {
        
            $element =& $elements[$k];
            
            // are we adding a group?
            if (is_array($element)) {
                
                // get the label for the group.  have to do it this way
                // because the group of elements does not itself have a
                // label, there are only the labels for the individual
                // elements.
                $tmp = $cols[$cols_keys[$k]];
                if (! isset($tmp['qf_label'])) {
                    $label = $cols_keys[$k];
                    if ($arrayName) {
                        $label = $arrayName . "[$label]";
                    }
                } else {
                    $label = $tmp['qf_label'];
                }
                   
                // set the element name
                if ($arrayName) {
                    $name  = $arrayName . '[' . $cols_keys[$k] . ']';
                } else {
                	$name = $cols_keys[$k];
                }
                
                // done
                $group =& $form->addGroup($element, $name, $label);

                // set default value (if given) for radio elements
                // (reason: QF "resets" the checked state, when adding a group)
                if ($tmp['qf_type'] == 'radio' && isset($tmp['qf_setvalue'])) {
                    $form->setDefaults(array($name => $tmp['qf_setvalue']));
                }

            } elseif (is_object($element)) {
                $form->addElement($element);
            }
        }
    }

    /**
    * 
    * Gets controls for a list of columns
    * 
    * @author Ian Eure <ieure@php.net>
    * 
    * @static
    * 
    * @access public
    * 
    * @param object &$form An HTML_QuickForm object.
    * 
    * @param array $cols A sequential array of DB_Table column definitions
    * from which to create form elements.
    * 
    * @param string $arrayName By default, the form will use the names
    * of the columns as the names of the form elements.  If you pass
    * $arrayName, the column names will become keys in an array named
    * for this parameter.
    * 
    * @return void
    * 
    */
    
    function &getElements($cols, $arrayName = null)
    {
        $elements = array();
        
        foreach ($cols as $name => $col) {
            
            if ($arrayName) {
                $elemname = $arrayName . "[$name]";
            } else {
                $elemname = $name;
            }
            
            DB_Table_QuickForm::fixColDef($col, $elemname);

            $elements[] =& DB_Table_QuickForm::getElement($col, $elemname);
        }
        
        return $elements;
    }
    
    
    /**
    * 
    * Build a single QuickForm element based on a DB_Table column.
    * 
    * @static
    * 
    * @access public
    * 
    * @param array $col A DB_Table column definition.
    * 
    * @param string $elemname The name to use for the generated QuickForm
    * element.
    * 
    * @return object HTML_QuickForm_Element
    * 
    */
    
    function &getElement($col, $elemname)
    {
        if (isset($col['qf_setvalue'])) {
            $setval = $col['qf_setvalue'];
        }
        
        switch ($col['qf_type']) {
        
        case 'advcheckbox':
        case 'checkbox':
            
            $element =& HTML_QuickForm::createElement(
                'advcheckbox',
                $elemname,
                $col['qf_label'],
                isset($col['qf_label_append']) ?
                    $col['qf_label_append'] : null,
                $col['qf_attrs'],
                $col['qf_vals']
            );
            
            // WARNING: advcheckbox elements in HTML_QuickForm v3.2.2
            // and earlier do not honor setChecked(); they will always
            // be un-checked, unless a POST value sets them.  Upgrade
            // to QF 3.2.3 or later.
            if (isset($setval) && $setval == true) {
                $element->setChecked(true);
            } else {
                $element->setChecked(false);
            }
            
            break;
            
        case 'autocomplete':
        
            $element =& HTML_QuickForm::createElement(
                $col['qf_type'],
                $elemname,
                $col['qf_label'],
                $col['qf_vals'],
                $col['qf_attrs']
            );
            
            if (isset($setval)) {
                $element->setValue($setval);
            }
            
            break;
            
        case 'date':
        
            if (! isset($col['qf_opts']['format'])) {
                $col['qf_opts']['format'] = 'Y-m-d';
            }
            
            $element =& HTML_QuickForm::createElement(
                'date',
                $elemname,
                $col['qf_label'],
                $col['qf_opts'],
                $col['qf_attrs']
            );
            
            if (isset($setval)) {
                $element->setValue($setval);
            }
            
            break;
            
        case 'time':
        
            if (! isset($col['qf_opts']['format'])) {
                $col['qf_opts']['format'] = 'H:i:s';
            }
            
            $element =& HTML_QuickForm::createElement(
                'date',
                $elemname,
                $col['qf_label'],
                $col['qf_opts'],
                $col['qf_attrs']
            );
            
            if (isset($setval)) {
                $element->setValue($setval);
            }
            
            break;

        case 'timestamp':
        
            if (! isset($col['qf_opts']['format'])) {
                $col['qf_opts']['format'] = 'Y-m-d H:i:s';
            }
            
            $element =& HTML_QuickForm::createElement(
                'date',
                $elemname,
                $col['qf_label'],
                $col['qf_opts'],
                $col['qf_attrs']
            );
            
            if (isset($setval)) {
                $element->setValue($setval);
            }
            
            break;
        
        case 'hidden':
        
            $element =& HTML_QuickForm::createElement(
                $col['qf_type'],
                $elemname,
                $col['qf_attrs']
            );
            
            if (isset($setval)) {
                $element->setValue($setval);
            }
            
            break;
            
            
        case 'radio':
        
            $element = array();
            
            foreach ((array) $col['qf_vals'] as $btnvalue => $btnlabel) {
                
                $element[] =& HTML_QuickForm::createElement(
                    $col['qf_type'],
                    null, // elemname not added because this is a group
                    null,
                    $btnlabel . $col['qf_radiosep'],
                    $btnvalue,
                    $col['qf_attrs']
                );
                
            }
            
            break;
            
        case 'select':
            
            $element =& HTML_QuickForm::createElement(
                $col['qf_type'],
                $elemname,
                $col['qf_label'],
                $col['qf_vals'],
                $col['qf_attrs']
            );
            
            if (isset($setval)) {
                $element->setSelected($setval);
            }
            
            break;
            
        case 'password':
        case 'text':
        case 'textarea':
        
            if (! isset($col['qf_attrs']['maxlength']) &&
                isset($col['size'])) {
                $col['qf_attrs']['maxlength'] = $col['size'];
            }
            
            $element =& HTML_QuickForm::createElement(
                $col['qf_type'],
                $elemname,
                $col['qf_label'],
                $col['qf_attrs']
            );
            
            if (isset($setval)) {
                $element->setValue($setval);
            }
            
            break;
        
        case 'static':
            $element =& HTML_QuickForm::createElement(
                $col['qf_type'],
                $elemname,
                $col['qf_label'],
                (isset($setval) ? $setval : '')
            );
            break;
            
        default:
            
            /**
            * @author Moritz Heidkamp <moritz.heidkamp@invision-team.de>
            */
            
            // not a recognized type.  is it registered with QuickForm?
            if (HTML_QuickForm::isTypeRegistered($col['qf_type'])) {
                
                // yes, create it with some minimalist parameters
                $element =& HTML_QuickForm::createElement(
                    $col['qf_type'],
                    $elemname,
                    $col['qf_label'],
                    $col['qf_attrs']
                );
                
                // set its default value, if there is one
                if (isset($setval)) {
                    $element->setValue($setval);
                }
                
            } else {
                // element type is not registered with QuickForm.
                $element = null;
            }
            
            break;

        }
        
        // done
        return $element;
    }
    
    
    /**
    * 
    * Build an array of form elements based from DB_Table columns.
    * 
    * @static
    * 
    * @access public
    * 
    * @param array $cols A sequential array of DB_Table column
    * definitions from which to create form elements.
    * 
    * @param string $arrayName By default, the form will use the names
    * of the columns as the names of the form elements.  If you pass
    * $arrayName, the column names will become keys in an array named
    * for this parameter.
    * 
    * @return array An array of HTML_QuickForm_Element objects.
    * 
    */
    
    function &getGroup($cols, $arrayName = null)
    {
        $group = array();
        
        foreach ($cols as $name => $col) {
            
            if ($arrayName) {
                $elemname = $arrayName . "[$name]";
            } else {
                $elemname = $name;
            }
            
            DB_Table_QuickForm::fixColDef($col, $elemname);
            
            $group[] =& DB_Table_QuickForm::getElement($col, $elemname);
        }
        
        return $group;
    }
    
    
    /**
    *
    * Adds DB_Table filters to a pre-existing HTML_QuickForm object.
    *
    * @static
    *
    * @access public
    *
    * @param object &$form An HTML_QuickForm object.
    *
    * @param array $cols A sequential array of DB_Table column definitions
    * from which to create form elements.
    *
    * @param string $arrayName By default, the form will use the names
    * of the columns as the names of the form elements.  If you pass
    * $arrayName, the column names will become keys in an array named
    * for this parameter.
    *
    * @param array $formFilters An array with filter function names or
    * callbacks that will be applied to all form elements.
    *
    * @return void
    *
    */
    function addFilters(&$form, $cols, $arrayName = null,
        $formFilters = null)
    {
        foreach ($cols as $name => $col) {
            if ($arrayName) {
                $elemname = $arrayName . "[$name]";
            } else {
                $elemname = $name;
            }

            DB_Table_QuickForm::fixColDef($col, $elemname);

            foreach (array_keys($col['qf_filters']) as $fk) {
                $form->applyFilter($elemname, $col['qf_filters'][$fk]);
            }
        }

        if (is_array($formFilters)) {
            foreach (array_keys($formFilters) as $fk) {
                $form->applyFilter('__ALL__', $formFilters[$fk]);
            }
        }
    }


    /**
    * 
    * Adds element rules to a pre-existing HTML_QuickForm object.
    * 
    * @static
    * 
    * @access public
    * 
    * @param object &$form An HTML_QuickForm object.
    * 
    * @param array $cols A sequential array of DB_Table column definitions
    * from which to create form elements.
    * 
    * @param string $arrayName By default, the form will use the names
    * of the columns as the names of the form elements.  If you pass
    * $arrayName, the column names will become keys in an array named
    * for this parameter.
    * 
    * @param string $clientValidate By default, validation will match
    * the 'qf_client' value from the column definition.  However,
    * if you set $clientValidate to true or false, this will
    * override the value from the column definition.
    * 
    * @return void
    * 
    */
    
    function addRules(&$form, $cols, $arrayName = null,
        $clientValidate = null)
    {
        foreach ($cols as $name => $col) {
            
            if ($arrayName) {
                $elemname = $arrayName . "[$name]";
            } else {
                $elemname = $name;
            }
            
            // make sure all necessary elements are in place
            DB_Table_QuickForm::fixColDef($col, $elemname);
            
            // if clientValidate is specified, override the column
            // definition.  otherwise use the col def as it is.
            if (! is_null($clientValidate)) {
                // override
                if ($clientValidate) {
                    $validate = 'client';
                } else {
                    $validate = 'server';
                }
            } else {
                // use as-is
                if ($col['qf_client']) {
                    $validate = 'client';
                } else {
                    $validate = 'server';
                }
            }
            
            // **always** override these rules to make them 
            // server-side only.  suggested by Mark Wiesemann,
            // debugged by Hero Wanders.
            $onlyServer = array('filename', 'maxfilesize', 'mimetype',
                'uploadedfile');
            
            // loop through the rules and add them
            foreach ($col['qf_rules'] as $type => $opts) {
                
                // override the onlyServer types so that we don't attempt
                // client-side validation at all.
                if (in_array($type, $onlyServer)) {
                    $validate = 'server';
                }
                
                switch ($type) {
                    
                case 'alphanumeric':
                case 'email':
                case 'lettersonly':
                case 'nonzero':
                case 'nopunctuation':
                case 'numeric':
                case 'required':
                case 'uploadedfile':
                    // $opts is the error message
                    $message = $opts;
                    $format = null;
                    break;
                
                case 'filename':
                case 'maxfilesize':
                case 'maxlength':
                case 'mimetype':
                case 'minlength':
                case 'regex':
                    // $opts[0] is the message
                    // $opts[1] is the size, mimetype, or regex
                    $message = $opts[0];
                    $format = $opts[1];
                    break;
                
                default:
                    // by Alex Hoebart: this should allow any registered rule.
                    if (!in_array($type, $form->getRegisteredRules())) {
                        // rule is not registered ==> do not add a rule
                        continue;
                    }
                    if (is_array($opts)) {
                        // $opts[0] is the message
                        // $opts[1] is the size or regex
                        $message = $opts[0];
                        $format = $opts[1];
                    } else {
                        // $opts is the error message
                        $message = $opts;
                        $format = null;
                    }
                    break;
                }
                
                switch ($col['qf_type']) {

                case 'date':
                case 'time':
                case 'timestamp':
                    // date "elements" are groups ==> use addGroupRule()
                    $form->addGroupRule($elemname, $message, $type, $format,
                        null, $validate);
                    break;

                default:  // use addRule() for all other elements
                    $form->addRule($elemname, $message, $type, $format,
                        $validate);
                    break;

                }

            }
        }
    }
    
    
    /**
    * 
    * "Fixes" a DB_Table column definition for QuickForm.
    * 
    * Makes it so that all the 'qf_*' key constants are populated
    * with appropriate default values; also checks the 'require'
    * value (if not set, defaults to false).
    * 
    * @static
    * 
    * @access public
    * 
    * @param array &$col A DB_Table column definition.
    * 
    * @param string $elemname The name for the target form element.
    * 
    * @return void
    * 
    */
    
    function fixColDef(&$col, $elemname)
    {    
        // always have a "require" value, false if not set
        if (! isset($col['require'])) {
            $col['require'] = false;
        }
        
        // array of acceptable values, typically for
        // 'select' or 'radio'
        if (! isset($col['qf_vals'])) {
            $col['qf_vals'] = null;
        }
        
        // are we doing client validation in addition to 
        // server validation?  by default, no.
        if (! isset($col['qf_client'])) {
            $col['qf_client'] = false;
        }

        if (! isset($col['qf_filters'])) {
            $col['qf_filters'] = array();
        }
        
        // the element type; if not set,
        // assigns an element type based on the column type.
        // by default, the type is 'text' (unless there are
        // values, in which case the type is 'select')
        if (! isset($col['qf_type'])) {
        
            switch ($col['type']) {
            
            case 'boolean':
                $col['qf_type'] = 'checkbox';
                $col['qf_vals'] = array(0,1);
                break;
            
            case 'date':
                $col['qf_type'] = 'date';
                break;
                
            case 'time':
                $col['qf_type'] = 'time';
                break;
                
            case 'timestamp':
                $col['qf_type'] = 'timestamp';
                break;
                
            case 'clob':
                $col['qf_type'] = 'textarea';
                break;
                
            default:
                if (isset($col['qf_vals'])) {
                    $col['qf_type'] = 'select';
                } else {
                    $col['qf_type'] = 'text';
                }
                break;

            }
        }
        
        // label for the element; defaults to the element
        // name.  adds both quickform label and table-header
        // label if qf_label is not set.
        if (! isset($col['qf_label'])) {
            if (isset($col['label'])) {
                $col['qf_label'] = $col['label'];
            }
            else {
                $col['qf_label'] = $elemname . ':';
            }
        }
        
        // special options for the element, typically used
        // for 'date' element types
        if (! isset($col['qf_opts'])) {
            $col['qf_opts'] = array();
        }
        
        // array of additional HTML attributes for the element
        if (! isset($col['qf_attrs'])) {
            // setting to array() generates an error in HTML_Common
            $col['qf_attrs'] = null;
        }
        
        // array of QuickForm validation rules to apply
        if (! isset($col['qf_rules'])) {
            $col['qf_rules'] = array();
        }
        
        // if the element is hidden, then we're done
        // (adding rules to hidden elements is mostly useless)
        if ($col['qf_type'] == 'hidden') {
            return;
        }
        
        // add a separator for radio elements
        if (! isset($col['qf_radiosep'])) {
            $col['qf_radiosep'] = '<br />';
        }
        
        
        // the element is required
        if (! isset($col['qf_rules']['required']) && $col['require']) {
            
            $col['qf_rules']['required'] = sprintf(
                $GLOBALS['_DB_TABLE']['qf_rules']['required'],
                $col['qf_label']
            );
            
        }
        
        $numeric = array('smallint', 'integer', 'bigint', 'decimal', 
            'single', 'double');
        
        // the element is numeric
        if (! isset($col['qf_rules']['numeric']) &&
            in_array($col['type'], $numeric)) {
            
            $col['qf_rules']['numeric'] = sprintf(
                $GLOBALS['_DB_TABLE']['qf_rules']['numeric'],
                $col['qf_label']
            );
            
        }
        
        // the element has a maximum length
        if (! isset($col['qf_rules']['maxlength']) &&
            isset($col['size'])) {
        
            $max = $col['size'];
            
            $msg = sprintf(
                $GLOBALS['_DB_TABLE']['qf_rules']['maxlength'],
                $col['qf_label'],
                $max
            );
            
            $col['qf_rules']['maxlength'] = array($msg, $max);
        }
    }
}

?>