use Test2::V0;

#use Test2::Require::EnvVar 'LIVE_TEST_JENKINS_URL';

# Set LIVE_TEST_JENKINS_URL if you want to run these tests against a live jenkins server.
# Set LIVE_TEST_JENKINS_API_KEY and LIVE_TEST_JENKINS_API_PASS if your server requires authentication.
use Test2::Plugin::BailOnFail;
use Test2::Tools::Explain;

use Jenkins::API;
use HTTP::Response;
use REST::Client;
my $url     = $ENV{LIVE_TEST_JENKINS_URL};
my $apiKey  = $ENV{LIVE_TEST_JENKINS_API_KEY};
my $apiPass = $ENV{LIVE_TEST_JENKINS_API_PASS};
my $mock_client;

unless ( $ENV{LIVE_TEST_JENKINS_URL} ) {
    setup_fake_responses();
}
my $api = Jenkins::API->new(
    base_url => $url,
    api_key  => $apiKey,
    api_pass => $apiPass
);

my $v = $api->check_jenkins_url;
ok $v, 'Jenkins running on ' . $url;
note explain $v;

my $status = $api->current_status;
ok( ( grep { $_ eq 'Test-Project' } map { $_->{name} } @{ $status->{jobs} } ),
    'Ensure we found the Test-Project' );
note 'This is the current status returned by the API';
note explain($status);

note 'This is a more refined query of the API';
$status =
  $api->current_status( { extra_params => { tree => 'jobs[name,color]' } } );
note explain $status;
ok grep { $_ eq 'Test-Project' } map { $_->{name} } @{ $status->{jobs} };

$status = $api->current_status(
    { path_parts => [qw/job Test-Project/], extra_params => { depth => 1 } } );
note 'Querying job Test-Project with depth => 1';
note explain $status;

my $build_status = $api->build_queue;
note 'Build queue';
note explain $build_status;
$build_status = $api->build_queue( { extra_params => { depth => 1 } } );
note 'With depth => 1';
note explain $build_status;

my $statistics = $api->load_statistics;
is $api->response_code, '200';
ok $api->response_content;
note explain $api->project_config('Test-Project');

my $job_info = $api->get_job_details('Test-Project');
note 'get_job_details';
note explain $job_info;

my $job_info2 = $api->get_job_details( 'Test-Project',
    { extra_params => { tree => 'healthReport' } } );
note explain $job_info2;

note 'Load statistics';
note explain $statistics;

my $view = $api->view_status('Test');
note explain $view;
my $view_list =
  $api->current_status( { extra_params => { tree => 'views[name]' } } );
note explain $view_list;
my @views = grep { $_ ne 'All' } map { $_->{name} } @{ $view_list->{views} };
for my $view (@views) {
    my $view_jobs = $api->view_status( $view,
        { extra_params => { tree => 'jobs[name,color]' } } );
    note explain $view_jobs;
}

my $response = $api->general_call(
    [ 'job', 'Test', 'api', 'json' ],
    {
        method                 => 'GET',
        extra_params           => { tree => 'color,description' },
        decode_json            => 1,
        expected_response_code => 200,
    }
);
note 'General call';
note explain $response;

done_testing;

sub setup_fake_responses {
    $url = 'http://jenkins:8080';
    my $fake_responses = [
        {
            'req' => {
                'url'     => 'http://172.17.0.2:8080/',
                'content' => '',
                'method'  => 'GET'
            },
            'res' => {
                'msg'     => 'OK',
                'code'    => '200',
                'content' => "




  
  <!DOCTYPE html><html><head resURL=\"/static/c70f6e5a\" data-rooturl=\"\" data-resurl=\"/static/c70f6e5a\">
    

    <title>Dashboard [Jenkins]</title><link rel=\"stylesheet\" href=\"/static/c70f6e5a/css/layout-common.css\" type=\"text/css\" /><link rel=\"stylesheet\" href=\"/static/c70f6e5a/css/style.css\" type=\"text/css\" /><link rel=\"stylesheet\" href=\"/static/c70f6e5a/css/color.css\" type=\"text/css\" /><link rel=\"stylesheet\" href=\"/static/c70f6e5a/css/responsive-grid.css\" type=\"text/css\" /><link rel=\"shortcut icon\" href=\"/static/c70f6e5a/favicon.ico\" type=\"image/vnd.microsoft.icon\" /><link color=\"black\" rel=\"mask-icon\" href=\"/images/mask-icon.svg\" /><script>var isRunAsTest=false; var rootURL=\"\"; var resURL=\"/static/c70f6e5a\";</script><script src=\"/static/c70f6e5a/scripts/prototype.js\" type=\"text/javascript\"></script><script src=\"/static/c70f6e5a/scripts/behavior.js\" type=\"text/javascript\"></script><script src='/adjuncts/c70f6e5a/org/kohsuke/stapler/bind.js' type='text/javascript'></script><script src=\"/static/c70f6e5a/scripts/yui/yahoo/yahoo-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/dom/dom-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/event/event-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/animation/animation-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/dragdrop/dragdrop-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/container/container-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/connection/connection-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/datasource/datasource-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/autocomplete/autocomplete-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/menu/menu-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/element/element-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/button/button-min.js\"></script><script src=\"/static/c70f6e5a/scripts/yui/storage/storage-min.js\"></script><script src=\"/static/c70f6e5a/scripts/hudson-behavior.js\" type=\"text/javascript\"></script><script src=\"/static/c70f6e5a/scripts/sortable.js\" type=\"text/javascript\"></script><script>crumb.init(\"Jenkins-Crumb\", \"7e646497288df2890bd0ccacac6392ad\");</script><link rel=\"stylesheet\" href=\"/static/c70f6e5a/scripts/yui/container/assets/container.css\" type=\"text/css\" /><link rel=\"stylesheet\" href=\"/static/c70f6e5a/scripts/yui/assets/skins/sam/skin.css\" type=\"text/css\" /><link rel=\"stylesheet\" href=\"/static/c70f6e5a/scripts/yui/container/assets/skins/sam/container.css\" type=\"text/css\" /><link rel=\"stylesheet\" href=\"/static/c70f6e5a/scripts/yui/button/assets/skins/sam/button.css\" type=\"text/css\" /><link rel=\"stylesheet\" href=\"/static/c70f6e5a/scripts/yui/menu/assets/skins/sam/menu.css\" type=\"text/css\" /><link rel=\"search\" href=\"/opensearch.xml\" type=\"application/opensearchdescription+xml\" title=\"Jenkins\" /><meta name=\"ROBOTS\" content=\"INDEX,NOFOLLOW\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" /><link rel=\"alternate\" href=\"/rssAll\" title=\"Jenkins:all (all builds)\" type=\"application/rss+xml\" /><link rel=\"alternate\" href=\"/rssAll?flavor=rss20\" title=\"Jenkins:all (all builds) (RSS 2.0)\" type=\"application/rss+xml\" /><link rel=\"alternate\" href=\"/rssFailed\" title=\"Jenkins:all (failed builds)\" type=\"application/rss+xml\" /><link rel=\"alternate\" href=\"/rssFailed?flavor=rss20\" title=\"Jenkins:all (failed builds) (RSS 2.0)\" type=\"application/rss+xml\" /><script src=\"/static/c70f6e5a/scripts/yui/cookie/cookie-min.js\"></script><script>
              YAHOO.util.Cookie.set(\"screenResolution\", screen.width+\"x\"+screen.height);
            </script><script src=\"/static/c70f6e5a/jsbundles/page-init.js\" type=\"text/javascript\"></script></head><body data-model-type=\"hudson.model.AllView\" id=\"jenkins\" class=\"yui-skin-sam two-column jenkins-2.60.3\" data-version=\"2.60.3\"><a href=\"#skip2content\" class=\"skiplink\">Skip to content</a><div id=\"page-head\"><div id=\"header\"><div class=\"logo\"><a id=\"jenkins-home-link\" href=\"/\"><img src=\"/static/c70f6e5a/images/headshot.png\" alt=\"title\" id=\"jenkins-head-icon\" /><img src=\"/static/c70f6e5a/images/title.png\" alt=\"title\" width=\"139\" id=\"jenkins-name-icon\" height=\"34\" /></a></div><div class=\"login\">\x{a0}<span style=\"white-space:nowrap\"><a href=\"/user/admin\" class=\"model-link inside inverse\"><b>Colin</b></a>
                    |
                    <a href=\"/logout\"><b>log out</b></a></span></div><div class=\"searchbox hidden-xs\"><form method=\"get\" name=\"search\" action=\"/search/\" style=\"position:relative;\" class=\"no-json\"><div id=\"search-box-minWidth\"></div><div id=\"search-box-sizer\"></div><div id=\"searchform\"><input name=\"q\" placeholder=\"search\" id=\"search-box\" class=\"has-default-text\" />\x{a0}<a href=\"https://jenkins.io/redirect/search-box\"><img src=\"/static/c70f6e5a/images/16x16/help.png\" style=\"width: 16px; height: 16px; \" class=\"icon-help icon-sm\" /></a><div id=\"search-box-completion\"></div><script>createSearchBox(\"/search/\");</script></div></form></div></div><div id=\"breadcrumbBar\"><tr id=\"top-nav\"><td id=\"left-top-nav\" colspan=\"2\"><link rel='stylesheet' href='/adjuncts/c70f6e5a/lib/layout/breadcrumbs.css' type='text/css' /><script src='/adjuncts/c70f6e5a/lib/layout/breadcrumbs.js' type='text/javascript'></script><div class=\"top-sticker noedge\"><div class=\"top-sticker-inner\"><div id=\"right-top-nav\"><div id=\"right-top-nav\"><div class=\"smallfont\"><a href=\"?auto_refresh=true\">ENABLE AUTO REFRESH</a></div></div></div><ul id=\"breadcrumbs\"><li class=\"item\"><a href=\"/\" class=\"model-link inside\">Jenkins</a></li><li href=\"/\" class=\"children\"></li></ul><div id=\"breadcrumb-menu-target\"></div></div></div></td></tr></div></div><div id=\"page-body\" class=\"clear\"><div id=\"side-panel\"><div id=\"tasks\"><div class=\"task\"><a href=\"/view/all/newJob\" class=\"task-icon-link\"><img src=\"/static/c70f6e5a/images/24x24/new-package.png\" style=\"width: 24px; height: 24px; width: 24px; height: 24px; margin: 2px;\" class=\"icon-new-package icon-md\" /></a>\x{a0}<a href=\"/view/all/newJob\" class=\"task-link\">New Item</a></div><div class=\"task\"><a href=\"/asynchPeople/\" class=\"task-icon-link\"><img src=\"/static/c70f6e5a/images/24x24/user.png\" style=\"width: 24px; height: 24px; width: 24px; height: 24px; margin: 2px;\" class=\"icon-user icon-md\" /></a>\x{a0}<a href=\"/asynchPeople/\" class=\"task-link\">People</a></div><div class=\"task\"><a href=\"/view/all/builds\" class=\"task-icon-link\"><img src=\"/static/c70f6e5a/images/24x24/notepad.png\" style=\"width: 24px; height: 24px; width: 24px; height: 24px; margin: 2px;\" class=\"icon-notepad icon-md\" /></a>\x{a0}<a href=\"/view/all/builds\" class=\"task-link\">Build History</a></div><div class=\"task\"><a href=\"/manage\" class=\"task-icon-link\"><img src=\"/static/c70f6e5a/images/24x24/gear2.png\" style=\"width: 24px; height: 24px; width: 24px; height: 24px; margin: 2px;\" class=\"icon-gear2 icon-md\" /></a>\x{a0}<a href=\"/manage\" class=\"task-link\">Manage Jenkins</a></div><div class=\"task\"><a href=\"/me/my-views\" class=\"task-icon-link\"><img src=\"/static/c70f6e5a/images/24x24/user.png\" style=\"width: 24px; height: 24px; width: 24px; height: 24px; margin: 2px;\" class=\"icon-user icon-md\" /></a>\x{a0}<a href=\"/me/my-views\" class=\"task-link\">My Views</a></div><div class=\"task\"><a href=\"/credentials\" class=\"task-icon-link\"><img src=\"/static/c70f6e5a/plugin/credentials/images/24x24/credentials.png\" style=\"width: 24px; height: 24px; width: 24px; height: 24px; margin: 2px;\" class=\"icon-credentials-credentials icon-md\" /></a>\x{a0}<a href=\"/credentials\" class=\"task-link\">Credentials</a></div></div><div id=\"buildQueue\" class=\"container-fluid pane-frame track-mouse expanded\"><div class=\"row\"><div class=\"col-xs-24 pane-header\"><a href=\"/toggleCollapse?paneId=buildQueue\" title=\"collapse\" class=\"collapse\"><img src=\"/static/c70f6e5a/images/16x16/collapse.png\" alt=\"collapse\" style=\"width: 16px; height: 16px; \" class=\"icon-collapse icon-sm\" /></a>Build Queue</div></div><div class=\"row pane-content\"><table class=\"pane \"><tr><td class=\"pane\" colspan=\"2\">No builds in the queue.</td></tr></table></div></div><script defer=\"defer\">refreshPart('buildQueue',\"/ajaxBuildQueue\");</script><div id=\"executors\" class=\"container-fluid pane-frame track-mouse expanded\"><div class=\"row\"><div class=\"col-xs-24 pane-header\"><a href=\"/toggleCollapse?paneId=executors\" title=\"collapse\" class=\"collapse\"><img src=\"/static/c70f6e5a/images/16x16/collapse.png\" alt=\"collapse\" style=\"width: 16px; height: 16px; \" class=\"icon-collapse icon-sm\" /></a><a href='/computer/'>Build Executor Status</a></div></div><div class=\"row pane-content\"><table class=\"pane \"><colgroup><col width=\"30\" /><col width=\"200*\" /><col width=\"24\" /></colgroup><tr></tr><tr><td class=\"pane\" align=\"right\" style=\"vertical-align: top\">1</td><td class=\"pane\">Idle</td><td class=\"pane\"></td><td class=\"pane\"></td></tr><tr><td class=\"pane\" align=\"right\" style=\"vertical-align: top\">2</td><td class=\"pane\">Idle</td><td class=\"pane\"></td><td class=\"pane\"></td></tr></table></div></div><script defer=\"defer\">refreshPart('executors',\"/ajaxExecutors\");</script></div><div id=\"main-panel\"><a name=\"skip2content\"></a><div id=\"view-message\"><div id=\"systemmessage\"></div><div id=\"description\"><div></div><div align=\"right\"><a onclick=\"return replaceDescription();\" id=\"description-link\" href=\"editDescription\"><img src=\"/static/c70f6e5a/images/16x16/notepad.png\" style=\"width: 16px; height: 16px; \" class=\"icon-notepad icon-sm\" />add description</a></div></div></div><div class=\"dashboard\"><div id=\"projectstatus-tabBar\"><div class=\"tabBarFrame \"><div class=\"tabBar\"><div class=\"tab active\"><input name=\"tab-group-1506448960416\" checked=\"checked\" id=\"tab-1506448960416-\" type=\"radio\" /><a href=\"/\" class=\"\">All</a></div><div class=\"tab\"><input name=\"tab-group-1506448960416\" id=\"tab-1506448960416-1\" type=\"radio\" /><a href=\"/view/Test/\" class=\"\">Test</a></div><div class=\"tab\"><input name=\"tab-group-1506448960416\" id=\"tab-1506448960416-2\" type=\"radio\" /><a href=\"/newView\" title=\"New View\" class=\"addTab\">+</a></div></div><div class=\"tabBarBaseline\"></div></div></div><div class=\"pane-frame\"><table id=\"projectstatus\" class=\"sortable pane bigtable stripped-odd\"><tr class=\"header\"><th tooltip=\"Status of the last build\">&nbsp;&nbsp;&nbsp;S</th><th tooltip=\"Weather report showing aggregated status of recent builds\">&nbsp;&nbsp;&nbsp;W</th><th initialSortDir=\"down\">Name</th><th>Last Success</th><th>Last Failure</th><th>Last Duration</th><th width=\"1\">\x{a0}</th><th>\x{a0}</th></tr><tr id=\"job_Test\" class=\" job-status-nobuilt\"><td data=\"12\"><img src=\"/static/c70f6e5a/images/32x32/nobuilt.png\" alt=\"Not built\" tooltip=\"Not built\" style=\"width: 32px; height: 32px; \" class=\"icon-nobuilt icon-lg\" /></td><td data=\"100\" class=\"healthReport\" onmouseover=\"this.className='healthReport hover';return true;
        \" onmouseout=\"this.className='healthReport';return true;\"><img src=\"/static/c70f6e5a/images/32x32/health-80plus.png\" alt=\"100%\" style=\"width: 32px; height: 32px; \" class=\"icon-health-80plus icon-lg\" /></td><td><a href=\"job/Test/\" class=\"model-link inside\">Test</a></td><td data=\"-\">N/A</td><td data=\"-\">N/A</td><td data=\"0\">N/A</td><td><a href=\"job/Test/build?delay=0sec\"><img src=\"/static/c70f6e5a/images/24x24/clock.png\" onclick=\"return build_id148(this)\" alt=\"Schedule a Build for Test\" style=\"width: 24px; height: 24px; \" title=\"Schedule a Build for Test\" class=\"icon-clock icon-md\" /></a><script>function build_id148(img) {
                  new Ajax.Request(img.parentNode.href);
                  hoverNotification('Build scheduled', img, -100);
                  return false;
                }</script></td><td>\x{a0}</td></tr><tr id=\"job_Test-Project\" class=\" job-status-nobuilt\"><td data=\"12\"><img src=\"/static/c70f6e5a/images/32x32/nobuilt.png\" alt=\"Not built\" tooltip=\"Not built\" style=\"width: 32px; height: 32px; \" class=\"icon-nobuilt icon-lg\" /></td><td data=\"100\" class=\"healthReport\" onmouseover=\"this.className='healthReport hover';return true;
        \" onmouseout=\"this.className='healthReport';return true;\"><img src=\"/static/c70f6e5a/images/32x32/health-80plus.png\" alt=\"100%\" style=\"width: 32px; height: 32px; \" class=\"icon-health-80plus icon-lg\" /></td><td><a href=\"job/Test-Project/\" class=\"model-link inside\">Test<wbr>-Project</a></td><td data=\"-\">N/A</td><td data=\"-\">N/A</td><td data=\"0\">N/A</td><td><a href=\"job/Test-Project/build?delay=0sec\"><img src=\"/static/c70f6e5a/images/24x24/clock.png\" onclick=\"return build_id149(this)\" alt=\"Schedule a Build for Test-Project\" style=\"width: 24px; height: 24px; \" title=\"Schedule a Build for Test-Project\" class=\"icon-clock icon-md\" /></a><script>function build_id149(img) {
                  new Ajax.Request(img.parentNode.href);
                  hoverNotification('Build scheduled', img, -100);
                  return false;
                }</script></td><td>\x{a0}</td></tr></table></div><div><table style=\"width:100%\"><tr><td>Icon:
        \x{a0}<a href=\"/iconSize?16x16\">S</a>\x{a0}<a href=\"/iconSize?24x24\">M</a>\x{a0}L</td><td><div align=\"right\" style=\"margin:1em\"><a href=\"/legend\">Legend</a><span style=\"padding-left:1em\"><a href=\"rssAll\"><img border=\"0\" src=\"/static/c70f6e5a/images/atom.gif\" alt=\"Feed\" width=\"16\" height=\"16\" /></a>\x{a0}<a href=\"rssAll\">RSS for all</a></span><span style=\"padding-left:1em\"><a href=\"rssFailed\"><img border=\"0\" src=\"/static/c70f6e5a/images/atom.gif\" alt=\"Feed\" width=\"16\" height=\"16\" /></a>\x{a0}<a href=\"rssFailed\">RSS for failures</a></span><span style=\"padding-left:1em\"><a href=\"rssLatest\"><img border=\"0\" src=\"/static/c70f6e5a/images/atom.gif\" alt=\"Feed\" width=\"16\" height=\"16\" /></a>\x{a0}<a href=\"rssLatest\">RSS for just latest builds</a></span></div></td></tr></table></div></div></div></div><footer><div class=\"container-fluid\"><div class=\"row\"><div class=\"col-md-6\" id=\"footer\"></div><div class=\"col-md-18\"><span class=\"page_generated\">Page generated: Sep 26, 2017 6:02:40 PM UTC</span><span class=\"rest_api\"><a href=\"api/\">REST API</a></span><span class=\"jenkins_ver\"><a href=\"https://jenkins.io/\">Jenkins ver. 2.60.3</a></span><link rel='stylesheet' href='/adjuncts/c70f6e5a/jenkins/management/AdministrativeMonitorsDecorator/resources.css' type='text/css' /><script src='/adjuncts/c70f6e5a/jenkins/management/AdministrativeMonitorsDecorator/resources.js' type='text/javascript'></script><div id=\"visible-am-container\"><a onclick=\"toggleVisibleAmList(event)\" id=\"visible-am-button\" href=\"#\" title=\"There are 1 active administrative monitors.\">1</a><div id=\"visible-am-list\"><div class=\"am-message\"><div class=\"warning\"><form method=\"post\" action=\"/updateCenter/upgrade\">
        New version of Jenkins (2.73.1) is available for <a href=\"http://updates.jenkins-ci.org/download/war/2.73.1/jenkins.war\">download</a> (<a href=\"https://jenkins.io/changelog-stable\">changelog</a>).
          </form></div></div><p style=\"text-align: center; margin: 10px 0 0 0;\"><a onclick=\"document.location.href='/manage';\" href=\"/manage\">Manage Jenkins</a></p></div></div><script type=\"text/javascript\">
            document.getElementById(\"header\").appendChild(document.getElementById(\"visible-am-container\"));
        </script></div></div></div></footer></body></html>",
                'headers' => [
                    'Cache-Control',
                    'no-cache,no-store,must-revalidate',
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'text/html;charset=UTF-8',
                    'Expires',
                    'Thu, 01 Jan 1970 00:00:00 GMT',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'Link',
'</static/c70f6e5a/css/layout-common.css>; rel="stylesheet"; type="text/css"',
                    'Link',
'</static/c70f6e5a/css/style.css>; rel="stylesheet"; type="text/css"',
                    'Link',
'</static/c70f6e5a/css/color.css>; rel="stylesheet"; type="text/css"',
                    'Link',
'</static/c70f6e5a/css/responsive-grid.css>; rel="stylesheet"; type="text/css"',
                    'Link',
'</static/c70f6e5a/favicon.ico>; rel="shortcut icon"; type="image/vnd.microsoft.icon"',
                    'Link',
                    '</images/mask-icon.svg>; color="black"; rel="mask-icon"',
                    'Link',
'</static/c70f6e5a/scripts/yui/container/assets/container.css>; rel="stylesheet"; type="text/css"',
                    'Link',
'</static/c70f6e5a/scripts/yui/assets/skins/sam/skin.css>; rel="stylesheet"; type="text/css"',
                    'Link',
'</static/c70f6e5a/scripts/yui/container/assets/skins/sam/container.css>; rel="stylesheet"; type="text/css"',
                    'Link',
'</static/c70f6e5a/scripts/yui/button/assets/skins/sam/button.css>; rel="stylesheet"; type="text/css"',
                    'Link',
'</static/c70f6e5a/scripts/yui/menu/assets/skins/sam/menu.css>; rel="stylesheet"; type="text/css"',
                    'Link',
'</opensearch.xml>; rel="search"; title="Jenkins"; type="application/opensearchdescription+xml"',
                    'Link',
'</rssAll>; rel="alternate"; title="Jenkins:all (all builds)"; type="application/rss+xml"',
                    'Link',
'</rssAll?flavor=rss20>; rel="alternate"; title="Jenkins:all (all builds) (RSS 2.0)"; type="application/rss+xml"',
                    'Link',
'</rssFailed>; rel="alternate"; title="Jenkins:all (failed builds)"; type="application/rss+xml"',
                    'Link',
'</rssFailed?flavor=rss20>; rel="alternate"; title="Jenkins:all (failed builds) (RSS 2.0)"; type="application/rss+xml"',
                    'Set-Cookie',
'JSESSIONID.c629e2b1=rwi44fgcsgop1phy3o0yl76pz;Path=/;HttpOnly',
                    'Title',
                    'Dashboard [Jenkins]',
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Frame-Options',
                    'sameorigin',
                    'X-Hudson',
                    '1.395',
                    'X-Hudson-CLI-Port',
                    '50000',
                    'X-Hudson-Theme',
                    'default',
                    'X-Instance-Identity',
'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhY8RerN8MW+X8D9b4FMQfw3t9M0WAcE2cLagkhJ+EmX3F972ReiMWWdY8l/1BEq2fHvRYuB/WzwdXvGpeWEbj/fXpUU5ny8ezchkdlx0WaP330c7d04FJbTHlVNXhRuPjk+ywvcfcZlXfEiybjglvVH/s0ks1C2YWfG7heYq40ip/qvdev7cT4mVW3IFaz8E2Kx1jhnE6nWa3XtZhO6he1U5iT1jkFqplk/DZ8bYNqOSSvD+AAU2SJKlwKanx2VFY/6QfiyYriqgEzype5tSZn6XXVonhMP/LsT5DbF98Vy0vmKxeDzSvuAp9jOTZyEYQtltjV0tauURNTDtfP/61wIDAQAB',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-CLI-Port',
                    '50000',
                    'X-Jenkins-CLI2-Port',
                    '50000',
                    'X-Jenkins-Session',
                    'c70f6e5a',
                    'X-Meta-ROBOTS',
                    'INDEX,NOFOLLOW',
                    'X-Meta-Viewport',
                    'width=device-width, initial-scale=1'
                ]
            }
        },
        {
            'res' => {
                'code' => '200',
                'msg'  => 'OK',
                'content' =>
'{"_class":"hudson.model.Hudson","assignedLabels":[{}],"mode":"NORMAL","nodeDescription":"the master Jenkins node","nodeName":"","numExecutors":2,"description":null,"jobs":[{"_class":"hudson.model.FreeStyleProject","name":"Test","url":"http://172.17.0.2:8080/job/Test/","color":"notbuilt"},{"_class":"hudson.model.FreeStyleProject","name":"Test-Project","url":"http://172.17.0.2:8080/job/Test-Project/","color":"notbuilt"}],"overallLoad":{},"primaryView":{"_class":"hudson.model.AllView","name":"all","url":"http://172.17.0.2:8080/"},"quietingDown":false,"slaveAgentPort":50000,"unlabeledLoad":{"_class":"jenkins.model.UnlabeledLoadStatistics"},"useCrumbs":true,"useSecurity":true,"views":[{"_class":"hudson.model.ListView","name":"Test","url":"http://172.17.0.2:8080/view/Test/"},{"_class":"hudson.model.AllView","name":"all","url":"http://172.17.0.2:8080/"}]}',
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ]
            },
            'req' => {
                'url'     => 'http://172.17.0.2:8080/api/json',
                'method'  => 'GET',
                'content' => ''
            }
        },
        {
            'res' => {
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ],
                'content' =>
'{"_class":"hudson.model.Hudson","jobs":[{"_class":"hudson.model.FreeStyleProject","name":"Test","color":"notbuilt"},{"_class":"hudson.model.FreeStyleProject","name":"Test-Project","color":"notbuilt"}]}',
                'msg'  => 'OK',
                'code' => '200'
            },
            'req' => {
                'content' => '',
                'method'  => 'GET',
                'url' =>
                  'http://172.17.0.2:8080/api/json?tree=jobs%5Bname%2Ccolor%5D'
            }
        },
        {
            'req' => {
                'url' =>
                  'http://172.17.0.2:8080/job/Test-Project/api/json?depth=1',
                'method'  => 'GET',
                'content' => ''
            },
            'res' => {
                'content' =>
'{"_class":"hudson.model.FreeStyleProject","actions":[{},{},{"_class":"com.cloudbees.plugins.credentials.ViewCredentialsAction","stores":{}}],"description":"","displayName":"Test-Project","displayNameOrNull":null,"fullDisplayName":"Test-Project","fullName":"Test-Project","name":"Test-Project","url":"http://172.17.0.2:8080/job/Test-Project/","buildable":true,"builds":[],"color":"notbuilt","firstBuild":null,"healthReport":[],"inQueue":false,"keepDependencies":false,"lastBuild":null,"lastCompletedBuild":null,"lastFailedBuild":null,"lastStableBuild":null,"lastSuccessfulBuild":null,"lastUnstableBuild":null,"lastUnsuccessfulBuild":null,"nextBuildNumber":1,"property":[],"queueItem":null,"concurrentBuild":false,"downstreamProjects":[],"scm":{"_class":"hudson.scm.NullSCM","browser":null,"type":"hudson.scm.NullSCM"},"upstreamProjects":[]}',
                'code'    => '200',
                'msg'     => 'OK',
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ]
            }
        },
        {
            'req' => {
                'method'  => 'GET',
                'content' => '',
                'url'     => 'http://172.17.0.2:8080/queue/api/json'
            },
            'res' => {
                'content' =>
'{"_class":"hudson.model.Queue","discoverableItems":[],"items":[]}',
                'msg'     => 'OK',
                'code'    => '200',
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ]
            }
        },
        {
            'res' => {
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ],
                'code' => '200',
                'msg'  => 'OK',
                'content' =>
'{"_class":"hudson.model.Queue","discoverableItems":[],"items":[]}'
            },
            'req' => {
                'url'     => 'http://172.17.0.2:8080/queue/api/json?depth=1',
                'content' => '',
                'method'  => 'GET'
            }
        },
        {
            'req' => {
                'url'     => 'http://172.17.0.2:8080/overallLoad/api/json',
                'content' => '',
                'method'  => 'GET'
            },
            'res' => {
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ],
                'content' =>
'{"_class":"hudson.model.OverallLoadStatistics","availableExecutors":{},"busyExecutors":{},"connectingExecutors":{},"definedExecutors":{},"idleExecutors":{},"onlineExecutors":{},"queueLength":{},"totalExecutors":{},"totalQueueLength":{}}',
                'msg'  => 'OK',
                'code' => '200'
            }
        },
        {
            'res' => {
                'msg'     => 'OK',
                'code'    => '200',
                'content' => '<?xml version=\'1.0\'?>
<project>
  <actions/>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <scm class="hudson.scm.NullSCM"/>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <builders/>
  <publishers/>
  <buildWrappers/>
</project>',
                'headers' => [
                    'Connection',             'close',
                    'Date',                   'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',                 'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',           'application/xml',
                    'Client-Date',            'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',            '172.17.0.2:8080',
                    'Client-Response-Num',    1,
                    'X-Content-Type-Options', 'nosniff'
                ]
            },
            'req' => {
                'content' => '',
                'method'  => 'GET',
                'url' => 'http://172.17.0.2:8080/job/Test-Project/config.xml'
            }
        },
        {
            'req' => {
                'method'  => 'GET',
                'content' => '',
                'url'     => 'http://172.17.0.2:8080/job/Test-Project/api/json'
            },
            'res' => {
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ],
                'content' =>
'{"_class":"hudson.model.FreeStyleProject","actions":[{},{},{"_class":"com.cloudbees.plugins.credentials.ViewCredentialsAction"}],"description":"","displayName":"Test-Project","displayNameOrNull":null,"fullDisplayName":"Test-Project","fullName":"Test-Project","name":"Test-Project","url":"http://172.17.0.2:8080/job/Test-Project/","buildable":true,"builds":[],"color":"notbuilt","firstBuild":null,"healthReport":[],"inQueue":false,"keepDependencies":false,"lastBuild":null,"lastCompletedBuild":null,"lastFailedBuild":null,"lastStableBuild":null,"lastSuccessfulBuild":null,"lastUnstableBuild":null,"lastUnsuccessfulBuild":null,"nextBuildNumber":1,"property":[],"queueItem":null,"concurrentBuild":false,"downstreamProjects":[],"scm":{"_class":"hudson.scm.NullSCM"},"upstreamProjects":[]}',
                'msg'  => 'OK',
                'code' => '200'
            }
        },
        {
            'res' => {
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ],
                'msg'  => 'OK',
                'code' => '200',
                'content' =>
                  '{"_class":"hudson.model.FreeStyleProject","healthReport":[]}'
            },
            'req' => {
                'url' =>
'http://172.17.0.2:8080/job/Test-Project/api/json?tree=healthReport',
                'content' => '',
                'method'  => 'GET'
            }
        },
        {
            'res' => {
                'content' =>
'{"_class":"hudson.model.ListView","description":null,"jobs":[],"name":"Test","property":[],"url":"http://172.17.0.2:8080/view/Test/"}',
                'code'    => '200',
                'msg'     => 'OK',
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ]
            },
            'req' => {
                'url'     => 'http://172.17.0.2:8080/view/Test/api/json',
                'method'  => 'GET',
                'content' => ''
            }
        },
        {
            'req' => {
                'url' => 'http://172.17.0.2:8080/api/json?tree=views%5Bname%5D',
                'method'  => 'GET',
                'content' => ''
            },
            'res' => {
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ],
                'content' =>
'{"_class":"hudson.model.Hudson","views":[{"_class":"hudson.model.ListView","name":"Test"},{"_class":"hudson.model.AllView","name":"all"}]}',
                'code' => '200',
                'msg'  => 'OK'
            }
        },
        {
            'res' => {
                'content' => '{"_class":"hudson.model.ListView","jobs":[]}',
                'msg'     => 'OK',
                'code'    => '200',
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ]
            },
            'req' => {
                'content' => '',
                'method'  => 'GET',
                'url' =>
'http://172.17.0.2:8080/view/Test/api/json?tree=jobs%5Bname%2Ccolor%5D'
            }
        },
        {
            'res' => {
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ],
                'content' =>
'{"_class":"hudson.model.AllView","jobs":[{"_class":"hudson.model.FreeStyleProject","name":"Test","color":"notbuilt"},{"_class":"hudson.model.FreeStyleProject","name":"Test-Project","color":"notbuilt"}]}',
                'code' => '200',
                'msg'  => 'OK'
            },
            'req' => {
                'url' =>
'http://172.17.0.2:8080/view/all/api/json?tree=jobs%5Bname%2Ccolor%5D',
                'content' => '',
                'method'  => 'GET'
            }
        },
        {
            'req' => {
                'url' =>
'http://172.17.0.2:8080/job/Test/api/json?tree=color%2Cdescription',
                'method'  => 'GET',
                'content' => ''
            },
            'res' => {
                'headers' => [
                    'Connection',
                    'close',
                    'Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Server',
                    'Jetty(9.2.z-SNAPSHOT)',
                    'Content-Type',
                    'application/json;charset=UTF-8',
                    'Client-Date',
                    'Tue, 26 Sep 2017 18:02:40 GMT',
                    'Client-Peer',
                    '172.17.0.2:8080',
                    'Client-Response-Num',
                    1,
                    'X-Content-Type-Options',
                    'nosniff',
                    'X-Jenkins',
                    '2.60.3',
                    'X-Jenkins-Session',
                    'c70f6e5a'
                ],
                'msg'  => 'OK',
                'code' => '200',
                'content' =>
'{"_class":"hudson.model.FreeStyleProject","description":null,"color":"notbuilt"}'
            }
        }
    ];
    $mock_client = mock 'REST::Client' => (
        override => [
            request => sub {
                my $self = shift;
                my $req  = shift @$fake_responses;
                my $res  = $req->{res};

                # FIXME: check request looks sane
                $self->{_res} = HTTP::Response->new(
                    $res->{code},    $res->{msg},
                    $res->{headers}, $res->{content}
                );
                return $self;
            }
        ]
    );
}
