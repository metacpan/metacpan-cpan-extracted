use vars qw($schedule $links $page_index $link_index $fixlink_cgi
	    $user_address);
$::user_address = 'mikedlr@scotclimb.org.uk';
$::links="/home/sca/link-data/links.db" ;
$::page_index="/home/sca/link-data/page_has_link.cdb" ;
$::link_index="/home/sca/link-data/link_on_page.cdb" ;
$::schedule="/home/sca/link-data/schedule.db" ;
$::link_stat_log="/home/sca/link-data/new-broken";
#added

$::fixlink_cgi = "http://scotclimb.org.uk/cgi-bin/link/fix-link.cgi";
$::base_dir="/home/sca/link-data";

$::infostrucs{"http://scotclimb.org.uk/"}= {
    mode => "directory",
    file_base => "/home/sca/www/",
    resource_exclude_re => "priv_stats|oldstuff",
    link_exclude_re => '(^[a-z]+://([a-z]+\.)*example\.com)|(^http://scotclimb.org.uk/cgi-bin/links)',
    prune_re => "leitheatre|dbadmin|link",
};
