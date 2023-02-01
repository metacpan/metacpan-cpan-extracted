<TMPL_INCLUDE NAME="header.tpl">
  <TMPL_IF NAME="INSTANCE_NAME">
    <title><TMPL_VAR NAME="INSTANCE_NAME"> Viewer comparator</title>
  <TMPL_ELSE>
    <title>LemonLDAP::NG Viewer comparator</title>
  </TMPL_IF>
  <link rel="prefetch" href="<TMPL_VAR NAME="STATIC_PREFIX">struct.json" />
</head>

<body ng-app="llngConfDiff" ng-strict-di ng-controller="DiffCtrl" ng-csp>

  <TMPL_INCLUDE NAME="menubar.tpl">

  <div id="content" class="row container-fluid">
    <div id="pleaseWait" ng-show="waiting"><span trspan="waitingForDatas"></span></div>

    <!-- Tree -->
    <aside id="left" class="col-lg-4 col-md-4 col-sm-5 col-xs-12 scrollable " ng-class="{'hidden-xs':!showT}" role="complementary">
      <div class="panel panel-default">
        <div class="panel-heading">
          <p class="panel-title text-center"> {{translate('diffViewer')}} </p>
        </div>
        <div class="panel-body">
          <div class="input-group input-group-sm">
            <a ng-show="cfg[0].prev" class="input-group-addon link glyphicon glyphicon-arrow-left" href="#!/{{cfg[0].prev}}/{{cfg[1].prev}}" role="link"></a>
            <span class="input-group-addon">1</span>
            <input class="form-control" size="2" type="integer" ng-model="cfg[0].cfgNum"/>
            <span class="input-group-addon">2</span>
            <input class="form-control" size="2" type="integer" ng-model="cfg[1].cfgNum"/>
            <span class="input-group-addon link glyphicon glyphicon-refresh" ng-click="newDiff()"></span>
            <a ng-show="cfg[1].next" class="input-group-addon link glyphicon glyphicon-arrow-right" href="#!/{{cfg[0].next}}/{{cfg[1].next}}" role="link"></a>
          </div>
        </div>
        <table class="table table-striped">
          <tr>
            <th>{{translate('date')}}</th>
            <td>{{cfg[0].date}}</td>
            <td>{{cfg[1].date}}</td>
          </tr>
          <tr>
            <th>{{translate('author')}}</th>
            <td>{{cfg[0].cfgAuthor}}</td>
            <td>{{cfg[1].cfgAuthor}}</td>
          </tr>
          <tr ng-if="cfg[0].cfgLog || cfg[1].cfgLog">
            <th>{{translate('cfgLog')}}</th>
            <td>{{cfg[0].cfgLog}}</td>
            <td>{{cfg[1].cfgLog}}</td>
          </tr>
        </table>
      </div>
      <div class="region region-sidebar-first">
        <section id="block-superfish-1" class="block block-superfish clearfix">
          <div ui-tree data-drag-enabled="false" id="tree-root">
            <div ng-show="data.length==0" class="center">
              <span class="label label-warning">{{translate('noData')}}</span>
            </div>
            <ol ui-tree-nodes="" ng-model="data">
              <li ng-repeat="node in data" ui-tree-node ng-include="'nodes_renderer.html'" collapsed="true"></li>
            </ol>
          </div>
        </section>
      </div>
      <div class="hresizer hidden-xs" resizer="vertical" resizer-left="#left" resizer-right="#right"></div>
    </aside>

    <!-- Right div -->
    <div id="right" class="col-lg-8 col-md-8 col-sm-7 col-xs-12 scrollable" ng-class="{'hidden-xs':showT&&!showM}">
      <h2 ng-if="message">{{message}}</h2>
      <div class="panel panel-default" ng-if="currentNode">
        <div class="panel-heading">
          <h3 class="panel-title">{{currentNode.title}}</h3>
        </div>
        <table class="table table-striped">
          <tr ng-show="currentNode.oldvalue">
            <th><span class="old" trspan="oldValue"></span></th>
            <td id="tdoldarray" ng-show="currentNode.oldvalue.constructor === 'array'">{{currentNode.oldvalue|json}}</td>
            <td id="tdold" ng-hide="currentNode.oldvalue.constructor === 'array'">{{currentNode.oldvalue}}</td>
          </tr>
          <tr ng-show="currentNode.newvalue">
            <th><span class="new" trspan="newValue"></span></th>
            <td id="tdnewarray" ng-show="currentNode.newvalue.constructor === 'array'">{{currentNode.newvalue|json}}</td>
            <td id="tdnew" ng-hide="currentNode.newvalue.constructor === 'array'">{{currentNode.newvalue}}</td>
          </tr>
        </table>
      </div>
    </div>
  </div>

  <script type="text/ng-template" id="nodes_renderer.html">
    <div ui-tree-handle class="tree-node tree-node-content panel-info tree-node-default">
      <span ng-include="'arrow.html'"></span>
      <span id="t-{{node.id}}" ng-click="stoggle(this,node)">{{node.title}}</span>
    </div>
    <ol ui-tree-nodes="" ng-model="node" ng-class="{hidden: collapsed}" ng-include="'subnodes.html'">
    </ol>
  </script>
  <script type="text/ng-template" id="newnodes_renderer.html">
    <div ui-tree-handle class="tree-node tree-node-content panel-info tree-node-default">
      <span ng-include="'arrow.html'"></span>
      <span id="t-{{node.id}}" ng-click="stoggle(this,node)" class="new">{{node.title}}</span>
    </div>
    <ol ui-tree-nodes="" ng-model="node" ng-class="{hidden: collapsed}" ng-include="'subnodes.html'">
    </ol>
  </script>
  <script type="text/ng-template" id="oldnodes_renderer.html">
    <div ui-tree-handle class="tree-node tree-node-content panel-info tree-node-default">
      <span ng-include="'arrow.html'"></span>
      <span id="t-{{node.id}}" ng-click="stoggle(this,node)" class="old">{{node.title}}</span>
    </div>
    <ol ui-tree-nodes="" ng-model="node" ng-class="{hidden: collapsed}" ng-include="'subnodes.html'">
    </ol>
  </script>

  <script type="text/ng-template" id="arrow.html">
    <a class="btn btn-node btn-sm" ng-click="toggle(this)" ng-if="node.nodes||node.newnodes||node.oldnodes">
      <span class="glyphicon" ng-class="{'glyphicon-chevron-right': collapsed,'glyphicon-chevron-down': !collapsed}"></span>
    </a>
    <a class="btn btn-node btn-sm" ng-click="toggle(this)" ng-if="node.newvalue||node.oldvalue||node.value">
      <span class="glyphicon glyphicon-eye-open"></span>
    </a>
  </script>

  <script type="text/ng-template" id="subnodes.html">
    <li ng-repeat="node in node.nodes" ui-tree-node ng-include="'nodes_renderer.html'" collapsed="true"></li>
    <li ng-repeat="node in node.newnodes" ui-tree-node ng-include="'newnodes_renderer.html'" collapsed="true"></li>
    <li ng-repeat="node in node.oldnodes" ui-tree-node ng-include="'oldnodes_renderer.html'" collapsed="true"></li>
  </script>

  <TMPL_INCLUDE NAME="scripts.tpl">

  <!-- //if:jsminified
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/conftree.min.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/viewDiff.min.js"></script>
  //else -->
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/conftree.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/viewDiff.js"></script>
  <!-- //endif -->

<TMPL_INCLUDE NAME="footer.tpl">
