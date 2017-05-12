package Drupal::Module::Starter::4_7_3;

# 4_7_3_ hooks
#
#

use strict;


our $stubs = {
hook_access =>  q!function MODULENAME_access($op, $node) { 
  global $user; 

  if ($op == 'create') { 
    return user_access('create stories'); 
  } 

  if ($op == 'update' || $op == 'delete') { 
    if (user_access('edit own stories') && ($user->uid == $node->uid)) { 
      return TRUE; 
    } 
  } 
} !,
	

hook_auth =>  q!function MODULENAME_auth($username, $password, $server) { 
  $message = new xmlrpcmsg('drupal.login', array(new xmlrpcval($username, 
    'string'), new xmlrpcval($password, 'string'))); 

  $client = new xmlrpc_client('/xmlrpc.php', $server, 80); 
  $result = $client->send($message, 5); 
  if ($result && \!$result->faultCode()) { 
    $value = $result->value(); 
    $login = $value->scalarval(); 
  } 

  return $login; 
} !,
	

hook_block =>  q!function MODULENAME_block($op = 'list', $delta = 0, $edit = array()) { 
  if ($op == 'list') { 
    $blocks[0] = array('info' => t('Mymodule block #1 shows ...'), 
      'weight' => 0, 'enabled' => 1, 'region' => 'left'); 
    $blocks[1] = array('info' => t('Mymodule block #2 describes ...'), 
      'weight' => 0, 'enabled' => 0, 'region' => 'right'); 
    return $blocks; 
  } 
  else if ($op == 'configure' && $delta == 0) { 
    $form['items'] = array( 
      '#type' => 'select', 
      '#title' => t('Number of items'), 
      '#default_value' => variable_get('mymodule_block_items', 0), 
      '#options' => array('1', '2', '3'), 
    ); 
    return $form; 
  } 
  else if ($op == 'save' && $delta == 0) { 
    variable_set('mymodule_block_items', $edit['items']); 
  } 
  else if ($op == 'view') { 
    switch($delta) { 
      case 0: 
        $block = array('subject' => t('Title of block #1'), 
          'content' => mymodule_display_block_1()); 
        break; 
      case 1: 
        $block = array('subject' => t('Title of block #2'), 
          'content' => mymodule_display_block_2()); 
        break; 
    } 
    return $block; 
  } 
} !,
	

hook_comment =>  q!function MODULENAME_comment($comment, $op) { 
  if ($op == 'insert' || $op == 'update') { 
    $nid = $comment['nid']; 
  } 

  cache_clear_all_like(drupal_url(array('id' => $nid))); 
} !,
	

hook_cron =>  q!function MODULENAME_cron() { 
  $result = db_query('SELECT * FROM {site} WHERE checked = 0 OR checked 
    + refresh < %d', time()); 

  while ($site = db_fetch_array($result)) { 
    cloud_update($site); 
  } 
} !,
	

hook_db_rewrite_sql =>  q!function MODULENAME_db_rewrite_sql($query, $primary_table, $primary_field, $args) { 
  switch ($primary_field) { 
    case 'nid': 
      // this query deals with node objects 
      $return = array(); 
      if ($primary_table \!= 'n') { 
        $return['join'] = "LEFT JOIN {node} n ON $primary_table.nid = n.nid"; 
      } 
      $return['where'] = 'created >' . mktime(0, 0, 0, 1, 1, 2005); 
      return $return; 
      break; 
    case 'tid': 
      // this query deals with taxonomy objects 
      break; 
    case 'vid': 
      // this query deals with vocabulary objects 
      break; 
  } 
} !,
	

hook_delete =>  q!function MODULENAME_delete(&$node) { 
  db_query('DELETE FROM {mytable} WHERE nid = %d', $node->nid); 
} !,
	

hook_elements =>  q!function MODULENAME_elements() { 
  $type['filter_format'] = array('#input' => TRUE); 
  return $type; 
} !,
	

hook_exit =>  q!function MODULENAME_exit($destination = NULL) { 
  db_query('UPDATE {counter} SET hits = hits + 1 WHERE type = 1'); 
} !,
	

hook_file_download =>  q!function MODULENAME_file_download($file) { 
  if (user_access('access content')) { 
    if ($filemime = db_result(db_query("SELECT filemime FROM {fileupload} WHERE filepath = '%s'", file_create_path($file)))) { 
      return array('Content-type:' . $filemime); 
    } 
  } 
  else { 
    return -1; 
  } 
} !,
	

hook_filter =>  q!function MODULENAME_filter($op, $delta = 0, $format = -1, $text = '') { 
  switch ($op) { 
    case 'list': 
      return array(0 => t('Code filter')); 

    case 'description': 
      return t('Allows users to post code verbatim using &lt;code&gt; and &lt;?php ?&gt; tags.'); 

    case 'prepare': 
      // Note: we use the bytes 0xFE and 0xFF to replace < > during the filtering process. 
      // These bytes are not valid in UTF-8 data and thus least likely to cause problems. 
      $text = preg_replace('@<code>(.+?)</code>@se', "'\xFEcode\xFF'. codefilter_escape('\\1') .'\xFE/code\xFF'", $text); 
      $text = preg_replace('@<(\?(php)?|%)(.+?)(\?|%)>@se', "'\xFEphp\xFF'. codefilter_escape('\\3') .'\xFE/php\xFF'", $text); 
      return $text; 

    case "process": 
      $text = preg_replace('@\xFEcode\xFF(.+?)\xFE/code\xFF@se', "codefilter_process_code('$1')", $text); 
      $text = preg_replace('@\xFEphp\xFF(.+?)\xFE/php\xFF@se', "codefilter_process_php('$1')", $text); 
      return $text; 

    default: 
      return $text; 
  } 
} !,
	

hook_filter_tips =>  q!function MODULENAME_filter_tips($delta, $format, $long = false) { 
  if ($long) { 
    return t('To post pieces of code, surround them with &lt;code&gt;...&lt;/code&gt; tags. For PHP code, you can use &lt;?php ... ?&gt;, which will also colour it based on syntax.'); 
  } 
  else { 
    return t('You may post code using &lt;code&gt;...&lt;/code&gt; (generic) or &lt;?php ... ?&gt; (highlighted PHP) tags.'); 
  } 
} !,
	

hook_footer =>  q!function MODULENAME_footer($main = 0) { 
  if (variable_get('dev_query', 0)) { 
    print '<div style="clear:both;">'. devel_query_table() .'</div>'; 
  } 
} !,
	

hook_form =>  q!function MODULENAME_form(&$node, &$param) { 
  $form['title'] = array( 
    '#type'=> 'textfield', 
    '#title' => t('Title'), 
    '#required' => TRUE, 
  ); 
  $form['body'] = array( 
    '#type' => 'textatea', 
    '#title' => t('Description'), 
    '#rows' => 20, 
    '#required' => TRUE, 
  ); 
  $form['field1'] = array( 
    '#type' => 'textfield', 
    '#title' => t('Custom field'), 
    '#default_value' => $node->field1, 
    '#maxlength' => 127, 
  ); 
  $form['selectbox'] = array( 
    '#type' => 'select', 
    '#title' => t('Select box'), 
    '#default_value' => $node->selectbox, 
    '#options' => array( 
      1 => 'Option A', 
      2 => 'Option B', 
      3 => 'Option C', 
    ), 
    '#description' => t('Please choose an option.'), 
  ); 

  return $form; 
} !,
	

hook_form_alter =>  q!function MODULENAME_form_alter($form_id, &$form) { 
  if (isset($form['type']) && $form['type']['#value'] .'_node_settings' == $form_id) { 
    $form['workflow']['upload_'. $form['type']['#value']] = array( 
      '#type' => 'radios', 
      '#title' => t('Attachments'), 
      '#default_value' => variable_get('upload_'. $form['type']['#value'], 1), 
      '#options' => array(t('Disabled'), t('Enabled')), 
    ); 
  } 
} !,
	

hook_help =>  q!function MODULENAME_help($section) { 
  switch ($section) { 
    case 'admin/help#block': 
      return t('<p>Blocks are the boxes visible in the sidebar(s) 
        of your web site. These are usually generated automatically by 
        modules (e.g. recent forum topics), but you can also create your 
        own blocks using either static HTML or dynamic PHP content.</p>'); 
      break; 
    case 'admin/modules#description': 
      return t('Controls the boxes that are displayed around the main content.'); 
      break; 
  } 
} !,
	

hook_info =>  q!function MODULENAME_info($field = 0) { 
  $info['name'] = 'Drupal'; 
  $info['protocol'] = 'XML-RPC'; 

  if ($field) { 
    return $info[$field]; 
  } 
  else { 
    return $info; 
  } 
} !,
	

hook_init =>  q!function MODULENAME_init() { 
  global $recent_activity; 

  if ((variable_get('statistics_enable_auto_throttle', 0)) && 
    (\!rand(0, variable_get('statistics_probability_limiter', 9)))) { 

    $throttle = throttle_status(); 
    // if we're at throttle level 5, we don't do anything 
    if ($throttle < 5) { 
      $multiplier = variable_get('statistics_throttle_multiplier', 60); 
      // count all hits in past sixty seconds 
      $result = db_query('SELECT COUNT(timestamp) AS hits FROM 
        {accesslog} WHERE timestamp >= %d', (time() - 60)); 
      $recent_activity = db_fetch_array($result); 
      throttle_update($recent_activity['hits']); 
    } 
  } 
} !,
	

hook_insert =>  q!function MODULENAME_insert($node) { 
  db_query("INSERT INTO {mytable} (nid, extra) 
    VALUES (%d, '%s')", $node->nid, $node->extra); 
} !,
	

hook_install =>  q!function MODULENAME_install() { 
  switch ($GLOBALS['db_type']) { 
    case 'mysql': 
    case 'mysqli': 
      db_query("CREATE TABLE {event} ( 
                  nid int(10) unsigned NOT NULL default '0', 
                  event_start int(10) unsigned NOT NULL default '0', 
                  event_end int(10) unsigned NOT NULL default '0', 
                  timezone int(10) NOT NULL default '0', 
                  PRIMARY KEY (nid), 
                  KEY event_start (event_start) 
                ) TYPE=MyISAM /*\!40100 DEFAULT CHARACTER SET utf8 */;" 
      ); 
      break; 

    case 'pgsql': 
      db_query("CREATE TABLE {event} ( 
                  nid int NOT NULL default '0', 
                  event_start int NOT NULL default '0', 
                  event_end int NOT NULL default '0', 
                  timezone int NOT NULL default '0', 
                  PRIMARY KEY (nid) 
                );" 
      ); 
      break; 
  } 
} !,
	

hook_link =>  q!function MODULENAME_link($type, $node = NULL, $teaser = FALSE) { 
  $links = array(); 

  if ($type == 'node' && $node->type == 'book') { 
    if (book_access('update', $node)) { 
      $links[] = l(t('edit this page'), "node/$node->nid/edit", 
        array('title' => t('Suggest an update for this book page.'))); 
    } 
    if (\!$teaser) { 
      $links[] = l(t('printer-friendly version'), "book/print/$node->nid", 
        array('title' => t('Show a printer-friendly version of this book page 
        and its sub-pages.'))); 
    } 
  } 

  return $links; 
} !,
	

hook_load =>  q!function MODULENAME_load($node) { 
  $additions = db_fetch_object(db_query('SELECT * FROM {mytable} WHERE nid = %s', $node->nid)); 
  return $additions; 
} !,
	

hook_menu =>  q!function MODULENAME_menu($may_cache) { 
  global $user; 
  $items = array(); 

  if ($may_cache) {      	
      	
    $items[] = array(
    	'path' 		=> 'your/path', 
    	'title' 		=> t('my path'), 
      	'access' 	=> user_access('my custom permission'), 
      	'type' 		=> MENU_NORMAL_ITEM); 
    
    
    $items[] = array(
    	'path' 		=> 'your/other/path', 
    	'title' 		=> t('my other path'), 
      	'callback' => '_myFunction', 
      	'access' => user_access('my custom permission'), 
      	'type' => MENU_CALLBACK); 
  } 
  return $items; 
} !,
	

hook_nodeapi =>  q!function MODULENAME_nodeapi(&$node, $op, $a3 = NULL, $a4 = NULL) { 
  switch ($op) { 
    case 'validate': 
      if ($node->nid && $node->moderate) { 
        // Reset votes when node is updated: 
        $node->score = 0; 
        $node->users = ''; 
        $node->votes = 0; 
      } 
      break; 
    case 'insert': 
    case 'update': 
      if ($node->moderate && user_access('access submission queue')) { 
        drupal_set_message(t('The post is queued for approval')); 
      } 
      elseif ($node->moderate) { 
        drupal_set_message(t('The post is queued for approval. The editors will decide whether it should be published.')); 
      } 
      break; 
  } 
} !,
	

hook_node_grants =>  q!function MODULENAME_node_grants($user, $op) { 
  $grants = array(); 
  if ($op == 'view') { 
    if (user_access('access content')) { 
      $grants[] = 0; 
    } 
    if (user_access('access private content')) { 
      $grants[] = 1; 
    } 
  } 
  if ($op == 'update' || $op == 'delete') { 
    if (user_access('edit content')) { 
      $grants[] = 0; 
    } 
    if (user_access('edit private content')) { 
      $grants[] = 1; 
    } 
  } 
  return array('example' => $grants); 
} !,
	

hook_node_info =>  q!function MODULENAME_node_info() { 
  return array( 
    'project_project' => array('name' => t('project'), 'base' => 'project_project'), 
    'project_issue' => array('name' => t('issue'), 'base' => 'project_issue') 
  ); 
} !,
	

hook_perm =>  q!function MODULENAME_perm() { 
  return array('administer my module'); 
} !,
	

hook_ping =>  q!function MODULENAME_ping($name = '', $url = '') { 
  $feed = url('node/feed'); 

  $client = new xmlrpc_client('/RPC2', 'rpc.weblogs.com', 80); 

  $message = new xmlrpcmsg('weblogUpdates.ping', 
    array(new xmlrpcval($name), new xmlrpcval($url))); 

  $result = $client->send($message); 

  if (\!$result || $result->faultCode()) { 
    watchdog('error', 'failed to notify "weblogs.com" (site)'); 
  } 

  unset($client); 
} !,
	

hook_prepare =>  q!function MODULENAME_prepare(&$node) { 
  if ($file = file_check_upload($field_name)) { 
    $file = file_save_upload($field_name, _image_filename($file->filename, NULL, TRUE)); 
    if ($file) { 
      if (\!image_get_info($file->filepath)) { 
        form_set_error($field_name, t('Uploaded file is not a valid image')); 
        return; 
      } 
    } 
    else { 
      return; 
    } 
    $node->images['_original'] = $file->filepath; 
    _image_build_derivatives($node, true); 
    $node->new_file = TRUE; 
	} 
} !,
	

hook_search =>  q!function MODULENAME_search($op = 'search', $keys = null) { 
  switch ($op) { 
    case 'name': 
      return t('content'); 
    case 'reset': 
      variable_del('node_cron_last'); 
      return; 
    case 'search': 
      $find = do_search($keys, 'node', 'INNER JOIN {node} n ON n.nid = i.sid '. node_access_join_sql() .' INNER JOIN {users} u ON n.uid = u.uid', 'n.status = 1 AND '. node_access_where_sql()); 
      $results = array(); 
      foreach ($find as $item) { 
        $node = node_load(array('nid' => $item)); 
        $extra = node_invoke_nodeapi($node, 'search result'); 
        $results[] = array('link' => url('node/'. $item), 
                           'type' => node_invoke($node, 'node_name'), 
                           'title' => $node->title, 
                           'user' => theme('username', $node), 
                           'date' => $node->changed, 
                           'extra' => $extra, 
                           'snippet' => search_excerpt($keys, check_output($node->body, $node->format))); 
      } 
      return $results; 
  } 
} !,
	

hook_search_item =>  q!function MODULENAME_search_item($item) { 
  $output .= ' <b><u><a href="'. $item['link'] 
    .'">'. $item['title'] .'</a></u></b><br />'; 
  $output .= ' <small>' . $item['description'] . '</small>'; 
  $output .= '<br /><br />'; 

  return $output; 
} !,
	

hook_search_preprocess =>  q!function MODULENAME_search_preprocess($text) { 
  // Do processing on $text 
  return $text; 
} !,
	

hook_settings =>  q!function MODULENAME_settings() { 
  $form['example_a'] = array( 
    '#type' => 'textfield', 
    '#title' => t('Setting A'), 
    '#default_value' => variable_get('example_a', 'Default setting'), 
    '#size' => 20, 
    '#maxlength' => 255, 
    '#description' => t('A description of this setting.'), 
  ); 
  $form['example_b'] = array( 
    '#type' => 'checkbox', 
    '#title' => t('Setting B'), 
    '#default_value' => variable_get('example_b', 0), 
    '#description' => t('A description of this setting.'), 
  ); 

  return $form; 
} !,
	

hook_submit =>  q!function MODULENAME_submit(&$node) { 
  // if a file was uploaded, move it to the files directory 
  if ($file = file_check_upload('file')) { 
    $node->file = file_save_upload($file, file_directory_path(), false); 
  } 
} !,
	

hook_taxonomy =>  q!function MODULENAME_taxonomy($op, $type, $object) { 
  if ($type == 'vocabulary' && ($op == 'insert' || $op == 'update')) { 
    if (variable_get('forum_nav_vocabulary', '') == '' 
        && in_array('forum', $object['nodes'])) { 
      // since none is already set, silently set this vocabulary as the navigation vocabulary 
      variable_set('forum_nav_vocabulary', $object['vid']); 
    } 
  } 
} !,
	

hook_update =>  q!function MODULENAME_update($node) { 
  db_query("UPDATE {mytable} SET extra = '%s' WHERE nid = %d", 
    $node->extra, $node->nid); 
} !,
	

hook_update_index =>  q!function MODULENAME_update_index() { 
  $last = variable_get('node_cron_last', 0); 
  $limit = (int)variable_get('search_cron_limit', 100); 

  $result = db_query_range('SELECT n.nid, c.last_comment_timestamp FROM {node} n LEFT JOIN {node_comment_statistics} c ON n.nid = c.nid WHERE n.status = 1 AND n.moderate = 0 AND (n.created > %d OR n.changed > %d OR c.last_comment_timestamp > %d) ORDER BY GREATEST(n.created, n.changed, c.last_comment_timestamp) ASC', $last, $last, $last, 0, $limit); 

  while ($node = db_fetch_object($result)) { 
    $last_comment = $node->last_comment_timestamp; 
    $node = node_load(array('nid' => $node->nid)); 

    // We update this variable per node in case cron times out, or if the node 
    // cannot be indexed (PHP nodes which call drupal_goto, for example). 
    // In rare cases this can mean a node is only partially indexed, but the 
    // chances of this happening are very small. 
    variable_set('node_cron_last', max($last_comment, $node->changed, $node->created)); 

    // Get node output (filtered and with module-specific fields). 
    if (node_hook($node, 'view')) { 
      node_invoke($node, 'view', false, false); 
    } 
    else { 
      $node = node_prepare($node, false); 
    } 
    // Allow modules to change $node->body before viewing. 
    node_invoke_nodeapi($node, 'view', false, false); 

    $text = '<h1>'. drupal_specialchars($node->title) .'</h1>'. $node->body; 

    // Fetch extra data normally not visible 
    $extra = node_invoke_nodeapi($node, 'update index'); 
    foreach ($extra as $t) { 
      $text .= $t; 
    } 

    // Update index 
    search_index($node->nid, 'node', $text); 
  } 
} !,
	

hook_update_N =>  q!function MODULENAME_update_N() { 
  $ret = array(); 

  switch ($GLOBALS['db_type']) { 
    case 'pgsql': 
      db_add_column($ret, 'contact', 'weight', 'smallint', array('not null' => TRUE, 'default' => 0)); 
      db_add_column($ret, 'contact', 'selected', 'smallint', array('not null' => TRUE, 'default' => 0)); 
      break; 

    case 'mysql': 
    case 'mysqli': 
      $ret[] = update_sql("ALTER TABLE {contact} ADD COLUMN weight tinyint(3) NOT NULL DEFAULT 0"); 
      $ret[] = update_sql("ALTER TABLE {contact} ADD COLUMN selected tinyint(1) NOT NULL DEFAULT 0"); 
      break; 
  } 

  return $ret; 
} !,
	

hook_user =>  q!function MODULENAME_user($op, &$edit, &$account, $category = NULL) { 
  if ($op == 'form' && $category == 'account') { 
    $form['comment_settings'] = array( 
      '#type' => 'fieldset', 
      '#title' => t('Comment settings'), 
      '#collapsible' => TRUE, 
      '#weight' => 4); 
    $form['comment_settings']['signature'] = array( 
      '#type' => 'textarea', 
      '#title' => t('Signature'), 
      '#default_value' => $edit['signature'], 
      '#description' => t('Your signature will be publicly displayed at the end of your comments.')); 
    return $form; 
  } 
} !,
	

hook_validate =>  q!function MODULENAME_validate(&$node) { 
  if ($node) { 
    if ($node->end && $node->start) { 
      if ($node->start > $node->end) { 
        form_set_error('time', t('An event may not end before it starts.')); 
      } 
    } 
  } 
} !,
	

hook_view =>  q!function MODULENAME_view(&$node, $teaser = FALSE, $page = FALSE) { 
  if ($page) { 
    $breadcrumb = array(); 
    $breadcrumb[] = array('path' => 'example', 'title' => t('example')); 
    $breadcrumb[] = array('path' => 'example/'. $node->field1, 
      'title' => t('%category', array('%category' => $node->field1))); 
    $breadcrumb[] = array('path' => 'node/'. $node->nid); 
    menu_set_location($breadcrumb); 
  } 

  $node = node_prepare($node, $teaser); 
} !,
	

hook_xmlrpc =>  q!function MODULENAME_xmlrpc() { 
  return array( 
    'drupal.login' => 'drupal_login', 
    array( 
      'drupal.site.ping', 
      'drupal_directory_ping', 
      array('boolean', 'string', 'string', 'string', 'string', 'string'), 
      t('Handling ping request')) 
  ); 
} !,

};



=head1 SYNOPSIS

    4_7_2 stubs

=head1 FUNCTIONS

=head2 new - constructor - no paramaters required

=cut

sub new {
	my ($self,$class) = ({},shift);
	bless $stubs,$class;
	return $stubs;
}

=head2 stub - return a php function stub for the named parameter

=cut

sub stub {
	my $self = shift;
	return $self->{stubs}->{shift};
}

=head1 AUTHOR

Steve McNabb, C<< <smcnabb@cpan.org> >>
IT Director, F5 Site Design - http://www.f5sitedesign.com
Open Source Internet Application Development

=cut
1;

	

