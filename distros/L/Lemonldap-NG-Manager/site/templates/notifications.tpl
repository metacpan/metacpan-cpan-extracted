<TMPL_INCLUDE NAME="header.tpl">

  <title>LemonLDAP::NG notifications explorer</title>
</head>

<body ng-app="llngNotificationsExplorer" ng-controller="NotificationsExplorerCtrl" ng-csp>

  <TMPL_INCLUDE NAME="menubar.tpl">

  <div id="content" class="row container-fluid">
    <div id="pleaseWait" ng-show="waiting"><span trspan="waitingForDatas"></span></div>

    <!-- Tree -->
    <aside id="left" class="col-lg-4 col-md-4 col-sm-5 col-xs-12 scrollable " ng-class="{'hidden-xs':!showT}" role="complementary">
      <div class="navbar navbar-default">
        <div class="navbar-collapse">
          <ul class="nav navbar-nav" role="grid">
            <li><a id="a-actives" href="#" role="row"><i class="glyphicon glyphicon-eye-open"></i> {{translate('actives')}}</a></li>
            <li><a id="a-done" href="#!/done" role="row"><i class="glyphicon glyphicon-check"></i> {{translate('dones')}}</a></li>
            <li><a id="a-new" href="#!/new" role="row"><i class="glyphicon glyphicon-plus-sign"></i> {{translate('create')}}</a></li>
          </ul>
        </div>
      </div>
      <div ng-show="data.length!=0" class="text-center"><p class="badge">{{total}} <span trspan="notification_s"></span></p></div>
      <div class="region region-sidebar-first">
        <section id="block-superfish-1" class="block block-superfish clearfix">
          <div ui-tree data-drag-enabled="false" id="tree-root">
            <div ng-show="data.length==0" class="center">
              <span class="label label-warning" trspan="noDatas"></span>
            </div>
            <ol ui-tree-nodes="" ng-model="data">
              <li ng-repeat="node in data track by node.id" ui-tree-node ng-include="'nodes_renderer.html'" collapsed="true"></li>
            </ol>
          </div>
        </section>
      </div>
      <div class="hresizer hidden-xs" resizer="vertical" resizer-left="#left" resizer-right="#right"></div>
    </aside>

    <!-- Right(main) div -->
    <div id="right" class="col-lg-8 col-md-8 col-sm-7 col-xs-12 scrollable" ng-class="{'hidden-xs':showT&&!showM}">
      <!-- Menu buttons -->
      <div ng-if="type=='new'||currentNotification" class="lmmenu navbar navbar-default" ng-class="{'hidden-xs':!showM}">
        <div class="navbar-collapse" ng-class="{'collapse':!showM}" id="formmenu">
          <ul class="nav navbar-nav">
            <li ng-repeat="button in menu[type]" ng-include="'menubutton.html'"></li>
            <li uib-dropdown class="visible-xs">
              <a id="langmenu" name="menu" uib-dropdown-toggle data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Menu <span class="caret"></span></a>
              <ul uib-dropdown-menu aria-labelled-by="langmenu" role="grid">
                <li ng-repeat="link in links"><a href="{{link.target}}" role="row"><i ng-if="link.icon" class="glyphicon glyphicon-{{link.icon}}"></i> {{translate(link.title)}}</a></li>
                <li ng-repeat="menulink in menulinks"><a href="{{menulink.target}}" role="row"><i ng-if="menulink.icon" class="glyphicon glyphicon-{{menulink.icon}}"></i> {{translate(menulink.title)}}</a></li>
                <li ng-include="'languages.html'"></li>
              </ul>
            </li>
          </ul>
        </div>
      </div>
      <!-- Notification content -->
      <div class="panel panel-default" ng-hide="currentNotification===null">
        <div class="panel-heading">
          <h1 class="panel-title text-center">{{translate('view')}}</h1>
        </div>
        <table class="table">
          <tr>
            <th><span trspan="uid" /></th>
            <td>{{currentNotification.uid}}</td>
          </tr>
          <tr>
            <th><span trspan="reference" /></th>
            <td>{{currentNotification.reference}}</td>
          </tr>
          <tr ng-if="currentNotification.done">
            <th><span trspan="internalReference" /></th>
            <td>{{currentNotification.done}}</td>
          </tr>
          <tr ng-if="currentNotification.notifications">
            <th>Notifications</th>
            <td><pre ng-repeat="n in currentNotification.notifications">{{n}}</pre></td>
          </tr>
        </table> 
      </div>
      <!-- Create form -->
      <div class="panel panel-default" ng-if="showForm">
        <div class="panel-heading">
          <h1 class="panel-title text-center">{{translate('create')}}</h1>
        </div>
        <form>
        <table class="table">
          <tr>
            <th><span trspan="uid" /></th>
            <td><input type="text" class="form-control" ng-model="form.uid" /></td>
          </tr>
          <tr>
            <th><span trspan="date" /></th>
            <td>
            <p class="input-group">
              <input type="text" class="form-control" uib-datepicker-popup="yyyy-MM-dd" ng-model="form.date"  min-date="minDate" is-open="popup.opened" datepicker-options="dateOptions" popup-placement="auto top-right"/>
              <span class="input-group-btn">
                <button type="button" class="btn btn-default" ng-click="popupopen()"><i class="glyphicon glyphicon-calendar"></i></button>
              </span>
            </p>
            </td>
          </tr>
          <tr>
            <th><span trspan="reference" /></th>
            <td><input type="text" class="form-control" ng-model="form.reference" /></td>
          </tr>
          <tr>
            <th><span trspan="condition" /></th>
            <td><input type="text" class="form-control" ng-model="form.condition"/></td>
          </tr>
          <tr>
            <th><span trspan="content" /></th>
            <td>
              <textarea rows=5 class="form-control" ng-model="form.xml"></textarea>
              <div class="alert alert-info">
                <p><span trspan="allowedMarkups" /></p>
                <table border="0">
                 <thead>
                  <tr><th>JSON</th><th>XML</th></tr>
                 </thead>
                 <tbody><tr>
                  <td>
                    <pre>
{
  "title":    "...",
  "subtitle": "...",
  "text":     "...",
  "check": [ "...", "..." ]
}
                    </pre>
                  </td>
                  <td>
                    <ul>
                      <li>&lt;title&gt;...&lt;/title&gt;</li>
                      <li>&lt;subtitle&gt;...&lt;/subtitle&gt;</li>
                      <li>&lt;text&gt;...&lt;/text&gt;</li>
                      <li>&lt;check&gt;...&lt;/check&gt;</li>
                    </ul>
                  </td>
                </tr></tbody></table>
              </div>
            </td>
          </tr>
        </table>
        </form>
      </div>
    </div>
  </div>

  <script type="text/ng-template" id="nodes_renderer.html">
    <div ui-tree-handle class="tree-node tree-node-content panel-info" ng-class="{'bg-info':this.$modelValue===currentNotification.$modelValue,'tree-node-default':this.$modelValue!==currentNotification.$modelValue}">
      <span ng-if="node.value">
        <a id="a-{{node.value}}" class="btn btn-node btn-sm" ng-click="stoggle(this)">
          <span class="glyphicon" ng-class="{'glyphicon-chevron-right': collapsed,'glyphicon-chevron-down': !collapsed}"></span>
        </a>
        <span id="s-{{node.value}}" ng-click="stoggle(this)">{{node.value}} <span class="badge">{{node.count}}</span></span>
      </span>
      <span ng-if="node.notification">
        <a class="btn btn-node btn-sm" ng-click="displayNotification(this)">
          <span class="glyphicon glyphicon-pencil"></span>
        </a>
        <span id="s-{{node.notification}}" ng-click="displayNotification(this)">{{node.reference}} <i ng-if="node.date">({{notifDate(node.date)}})</i></span>
      </span>
    </div>
    <ol ui-tree-nodes="" ng-model="node.nodes" ng-class="{hidden: collapsed}">
      <li ng-repeat="node in node.nodes track by node.id" ui-tree-node ng-include="'nodes_renderer.html'" collapsed="true"></li>
    </ol>
  </script>

  <script type="text/ng-template" id="alert.html">
    <div class="modal-header">
      <h3 class="modal-title" trspan="{{elem('message').title}}" />
    </div>
    <div class="modal-body" ng-if="elem('message').message">
      <div class="modal-p">{{translateP(elem('message').message)}}</div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-primary" id="promptok" ng-click="ok()" trspan="ok"></button>
      <button class="btn btn-warning" ng-click="cancel()" trspan="cancel"></button>
    </div>
  </script>

  <TMPL_INCLUDE NAME="scripts.tpl">

  <!-- //if:jsminified
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/notifications.min.js"></script>
  //else -->
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/notifications.js"></script>
  <!-- //endif -->

<TMPL_INCLUDE NAME="footer.tpl">
