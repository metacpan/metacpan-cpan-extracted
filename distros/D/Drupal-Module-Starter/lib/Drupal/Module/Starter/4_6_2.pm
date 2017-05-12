package Drupal::Module::Starter::4_6_2;



=head1 NAME

Drupal::Module::Starter::4_6_2  -  stub php code for 4.6.2 hooks

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# stub code for each hook
our $stubs = {
	hook_access => q!function MODULENAME_access($op, $node) {
	global $user;
	if ($op == 'create') {
    	return user_access('create MODULENAMEs');
    }

	if ($op == 'update' || $op == 'delete') {
    	if (user_access('edit own MODULENAMEs') && ($user->uid == $node->uid)) {
      		return TRUE;
    	}
  	}
}!,
		
	hook_auth  => q|
function MODULENAME_auth($username, $password, $server) {
  /* return TRUE for a valid authentication, FALSE otherwise */
  
  $message = new xmlrpcmsg('drupal.login', array(new xmlrpcval($username,
    'string'), new xmlrpcval($password, 'string')));

  $client = new xmlrpc_client('/xmlrpc.php', $server, 80);
  $result = $client->send($message, 5);
  if ($result && !$result->faultCode()) {
    $value = $result->value();
    $login = $value->scalarval();
  }

  return $login;
}|,

	hook_block  => q|
function MODULENAME_block($op = 'list', $delta = 0, $edit = array()) {
  if ($op == 'list') {
    $blocks[0]['info'] = t('Mymodule block #1 shows ...');
    $blocks[1]['info'] = t('Mymodule block #2 describes ...');
    return $blocks;
  }
  else if ($op == 'configure' && $delta == 0) {
    return form_select(t('Number of items'), 'items', variable_get('mymodule_block_items', 0), array('1', '2', '3'));
  }
  else if ($op == 'save' && $delta == 0) {
    variable_set('mymodule_block_items', $edit['items']);
  }
  else if ($op == 'view') {
    switch($delta) {
      case 0:
        $block['subject'] = t('Title of block #1');
        $block['content'] = mymodule_display_block_1();
        break;
      case 1:
        $block['subject'] = t('Title of block #2');
        $block['content'] = mymodule_display_block_2();
        break;
    }
    return $block;
  }
}|,	
	
	hook_comment  => q!
function MODULENAME_comment($op, $comment) {
  if ($op == 'insert' || $op == 'update') {
    $nid = $comment['nid'];
  }
  cache_clear_all_like(drupal_url(array('id' => $nid)));
}!,
	
	hook_cron  => q!
function MODULENAME_cron() {
  $result = db_query('SELECT * FROM {site} WHERE checked = 0 OR checked
    + refresh < %d', time());

  while ($site = db_fetch_array($result)) {
    cloud_update($site);
  }
}!,
		
	hook_db_rewrite_sql  => q|
function MODULENAME_db_rewrite_sql($query, $primary_table, $primary_field, $args) {
  switch ($primary_field) {
    case 'nid':
      // this query deals with node objects
      $return = array();
      if ($primary_table != 'n') {
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
} |,
	
	hook_delete  => q!
function MODULENAME_delete(&$node) {
  db_query('DELETE FROM {mytable} WHERE nid = %d', $node->nid);
}!,
	
	hook_exit  => q!
function MODULENAME_exit($destination = NULL) {
  db_query('UPDATE {counter} SET hits = hits + 1 WHERE type = 1');
}!,
		
	hook_filter  => q!
	function MODULENAME_filter($op, $delta = 0, $format = -1, $text = '') {
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
	
	hook_filter_tips  => q!
function MODULENAME_filter_tips($delta, $format, $long = false) {
  if ($long) {
    return t('To post pieces of code, surround them with &lt;code&gt;...&lt;/code&gt; tags. For PHP code, you can use &lt;?php ... ?&gt;, which will also colour it based on syntax.');
  }
  else {
    return t('You may post code using &lt;code&gt;...&lt;/code&gt; (generic) or &lt;?php ... ?&gt; (highlighted PHP) tags.');
  }
} !,
	
	hook_footer  => q!
function MODULENAME_footer($main = 0) {
  if (variable_get('dev_query', 0)) {
    print '<div style="clear:both;">'. devel_query_table() .'</div>';
  }
}!,
		
	hook_form  => q!
function MODULENAME_form(&$node, &$param) {
  if (function_exists('taxonomy_node_form')) {
    $output = implode('', taxonomy_node_form('example', $node));
  }

  $output .= form_textfield(t('Custom field'), 'field1', $node->field1, 60,
    127);
  $output .= form_select(t('Select box'), 'selectbox', $node->selectbox,
    array (1 => 'Option A', 2 => 'Option B', 3 => 'Option C'),
    t('Please choose an option.'));

  return $output;
}!,
		
	hook_help  => q!
function MODULENAME_help($section) {
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
}!,
	
	hook_info  => q!
function MODULENAME_info($field = 0) {
  $info['name'] = 'Drupal';
  $info['protocol'] = 'XML-RPC';

  if ($field) {
    return $info[$field];
  }
  else {
    return $info;
  }
}!,
		
	hook_init  => q|
function MODULENAME_init() {
  global $recent_activity;

  if ((variable_get('statistics_enable_auto_throttle', 0)) &&
    (!rand(0, variable_get('statistics_probability_limiter', 9)))) {

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
}|,
	
	hook_insert  => q!
function MODULENAME_insert($node) {
  db_query("INSERT INTO {mytable} (nid, extra)
    VALUES (%d, '%s')", $node->nid, $node->extra);
}!,
		
	hook_link  => q|
function MODULENAME_link($type, $node = NULL, $teaser = FALSE) {
  $links = array();

  if ($type == 'node' && $node->type == 'book') {
    if (MODULENAME_access('update', $node)) {
      $links[] = l(t('edit this page'), "node/$node->nid/edit",
        array('title' => t('Suggest an update for this book page.')));
    }
    if (!$teaser) {
      $links[] = l(t('printer-friendly version'), "book/print/$node->nid",
        array('title' => t('Show a printer-friendly version of this book page
        and its sub-pages.')));
    }
  }

  return $links;
}|,
		
	hook_load  => q!
function MODULENAME_load($node) {
  $additions = db_fetch_object(db_query('SELECT * FROM {mytable} WHERE nid = %s', $node->nid));
  return $additions;
}!,
	
	hook_menu  => q!
function MODULENAME_menu($may_cache) {
  global $user;
  $items = array();

  if ($may_cache) {
    $items[] = array('path' => 'node/add/blog', 'title' => t('blog entry'),
      'access' => user_access('maintain personal blog'));
    $items[] = array('path' => 'blog', 'title' => t('blogs'),
      'callback' => 'blog_page',
      'access' => user_access('access content'),
      'type' => MENU_SUGGESTED_ITEM);
    $items[] = array('path' => 'blog/'. $user->uid, 'title' => t('my blog'),
      'access' => user_access('maintain personal blog'),
      'type' => MENU_DYNAMIC_ITEM);
    $items[] = array('path' => 'blog/feed', 'title' => t('RSS feed'),
      'callback' => 'blog_feed',
      'access' => user_access('access content'),
      'type' => MENU_CALLBACK);
  }
  return $items;
}!,
		
	hook_nodeapi  => q!
function MODULENAME_nodeapi(&$node, $op, $teaser = NULL, $page = NULL) {
  switch ($op) {
    case 'fields':
      return array('score', 'users', 'votes');
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
        print theme('box', t('Post queued'), t('The post is queued for approval.
        You can check the votes in the <a href="%queue">submission
        queue</a>.', array('%queue' => url('queue'))));
      }
      elseif ($node->moderate) {
        print theme('box', t('Post queued'), t('The post is queued for approval.
        The editors will decide whether it should be published.'));
      }
      else {
        print theme('box', t('Post published'), t('The post is published.'));
      }
      break;
  }
}!,
		
	hook_node_grants  => q!
function MODULENAME_node_grants($user, $op) {
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
}!,
		
	hook_node_name  => q|function MODULENAME_node_name($node) {
  			return MODULENAME;
  }|,
	
	hook_node_types  => q!function MODULENAME_node_types() {
  return array('project-issue', 'project-project');
}!,
	
	hook_onload  => q!function MODULENAME_onload() {
  return array('my_javascript_function()');
}!,





	hook_perm  => q!function MODULENAME_perm() {
  return array('create MODULENAME', 'edit own MODULENAMEs');
}!,

	hook_ping  => q"function MODULENAME_ping($name = '', $url = '') {
  $feed = url('node/feed');

  $client = new xmlrpc_client('/RPC2', 'rpc.weblogs.com', 80);

  $message = new xmlrpcmsg('weblogUpdates.ping',
    array(new xmlrpcval($name), new xmlrpcval($url)));

  $result = $client->send($message);

  if (!$result || $result->faultCode()) {
    watchdog('error', 'failed to notify \'weblogs.com\' (site)');
  }

  unset($client);
}" ,

	hook_search  => q!function MODULENAME_search($op = 'search', $keys = null) {
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
                           'user' => format_name($node),
                           'date' => $node->changed,
                           'extra' => $extra,
                           'snippet' => search_excerpt($keys, check_output($node->body, $node->format)));
      }
      return $results;
  }
} !,

	hook_search_item  => q!function MODULENAME_search_item($item) {
  $output .= ' <b><u><a href="'. $item['link']
    .'">'. $item['title'] .'</a></u></b><br />';
  $output .= ' <small>' . $item['description'] . '</small>';
  $output .= '<br /><br />';

  return $output;
}!,
		
	hook_search_preprocess  => q!function MODULENAME_search_preprocess($text) {
  // Do processing on $text
  return $text;
}!,
	
	hook_settings  => q!function MODULENAME_settings() {
  $output = form_textfield(t('Setting A'), 'example_a',
    variable_get('example_a', 'Default setting'), 20, 255,
    t('A description of this setting.'));
  $output .= form_checkbox(t('Setting B'), 'example_b', 1,
    variable_get('example_b', 0), t('A description of this setting.'));
  return $output;
}!,
	
	
	hook_taxonomy  => q!function MODULENAME_taxonomy($op, $type, $object) {
  if ($type == 'vocabulary' && ($op == 'insert' || $op == 'update')) {
    if (variable_get('forum_nav_vocabulary', '') == ''
        && in_array('forum', $object['nodes'])) {
      // since none is already set, silently set this vocabulary as the navigation vocabulary
      variable_set('forum_nav_vocabulary', $object['vid']);
    }
  }
}!,

	hook_textarea  => q!function MODULENAME_textarea($op, $name) {
  global $htmlarea_init, $htmlarea_fields, $htmlarea_codeview;

  if ($op == 'pre') {
    $real_name = $name;
    $name = _htmlarea_parse_name($name);

    if (_htmlarea_is_changed($name)) {
      $htmlarea_init[] = "var $name = null;";
      $htmlarea_fields[] = "attacheditor($name, '$name');";
    }
  }
}!,

	hook_update  => q!function MODULENAME_update($node) {
  db_query("UPDATE {mytable} SET extra = '%s' WHERE nid = %d",
    $node->extra, $node->nid);
} !,

	hook_update_index  => q!function MODULENAME_update_index() {
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
}!,

	hook_user  => q!function MODULENAME_user($op, &$edit, &$user, $category) {
  switch ($op) {
    case 'view':
      if ($user->signature) {
        return array('account' => form_item(t('Signature'), check_output($user->signature)));
      }
      break;
    case 'form':
      // When user tries to edit his own data:
      if ($category == 'account') {
        return array(array('title' => t('Personal information'), 'data' => form_textarea(t('Signature'), 'signature', $user->signature, 70, 3, t('Your signature will be publicly displayed at the end of your comments.') .'<br />'. filter_tips_short()), 'weight' => 0));
      }
  }
}!,

	hook_validate  => q!function MODULENAME_validate(&$node) {
  if ($node) {
    if ($node->end && $node->start) {
      if ($node->start > $node->end) {
        form_set_error('time', t('An event may not end before it starts.'));
      }
    }
  }
} !,
	
	hook_view  => q!function MODULENAME_view(&$node, $teaser = FALSE, $page = FALSE) {
  if ($page) {
    $breadcrumb = array();
    $breadcrumb[] = array('path' => 'example', 'title' => t('example'));
    $breadcrumb[] = array('path' => 'example/'. $node->field1,
      'title' => t('%category', array('%category' => $node->field1)));
    $breadcrumb[] = array('path' => 'node/'. $node->nid);
    menu_set_location($breadcrumb);
  }

  $node = node_prepare($node, $teaser);
}!,
	
	hook_xmlrpc  => q!function MODULENAME_xmlrpc() {
  return array('drupal.site.ping' => array('function' => 'drupal_directory_ping'),
    'drupal.login' => array('function' => 'drupal_login'));
} !,
	
	clean_menu => q!function MODULENAME_menu($may_cache) {
  global $user;
  $items = array();

  if ($may_cache) {
  
  MENU_ITEMLIST
 
  }
  return $items!,

};



=head1 SYNOPSIS

    For this version, 4_6_2.pm is the only set of hooks provided.  Other versions
    could easily be created

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
