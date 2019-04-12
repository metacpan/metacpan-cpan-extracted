<TMPL_INCLUDE NAME="header.tpl">

  <title>LemonLDAP::NG 2nd Factor sessions explorer</title>
</head>

<body ng-app="llngSessionsExplorer" ng-controller="SessionsExplorerCtrl" ng-csp>

  <TMPL_INCLUDE NAME="menubar.tpl">
  <div id="content" class="row container-fluid">
    <div id="pleaseWait" ng-show="waiting"><span trspan="waitingForDatas"></span></div>
    <aside id="left" class="col-lg-4 col-md-4 col-sm-5 col-xs-12 scrollable " ng-class="{'hidden-xs':!showT}" role="complementary">
      <div class="navbar navbar-default">
        <div class="navbar-collapse">
          <ul class="nav navbar-nav" role="grid">
            <li><a id="a-persistent" role="row"><i class="glyphicon glyphicon-filter"></i> {{translate('2faSessions')}} &nbsp;&nbsp;</a></li>
            <form name="filterForm">
              <div class="form-check ">&nbsp;&nbsp;&nbsp;
                <input type="checkbox" ng-model="U2FCheck" class="form-check-input"  ng-true-value="2" ng-false-value="1" ng-change="search2FA()"/>
                <label class="form-check-label" for="U2FCheck">U2F</label>
                &nbsp;&nbsp;&&nbsp;&nbsp;
                <input type="checkbox" ng-model="TOTPCheck" class="form-check-input" ng-true-value="2" ng-false-value="1" ng-change="search2FA()"/>
                <label class="form-check-label" for="TOTPCheck">TOTP</label>
                &nbsp;&nbsp;&&nbsp;&nbsp;
                <input type="checkbox" ng-model="UBKCheck" class="form-check-input" ng-true-value="2" ng-false-value="1" ng-change="search2FA()"/>
                <label class="form-check-label" for="UBKCheck">UBK</label>
              </div>
            </form>
          </ul>
		  <div class="col-lg-6 col-md-6 col-sm-8 col-xs-14" >
		    <form class="navbar-form" role="search">
              <div class="input-group add-on">
                <input class="form-control" placeholder="{{translate('search')}}" type="text" ng-model="searchString" ng-init="" ng-keyup="search2FA()"/>
                <div class="input-group-btn">
                <button class="btn btn-default" ng-click="search2FA(1)"><i class="glyphicon glyphicon-search"></i></button>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>

          <!-- Tree -->

      <div class="text-center"><p class="badge">{{total}} <span trspan="session_s"></span></p></div>
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
      <div class="panel panel-default" ng-hide="currentSession===null">
        <div class="panel-heading">
          <h1 class="panel-title text-center">{{translate("sessionTitle")}} {{currentSession.id}}</h1>
        </div>
        <div class="panel-body">
          <div class="alert alert-info">
            <strong>{{translate("sessionStartedAt")}}</strong>
            {{localeDate(currentSession._utime)}}
          </div>
          <div ng-model="currentSession.nodes">
            <div ng-repeat="node in currentSession.nodes" ng-include="'session_attr.html'"></div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <script type="text/ng-template" id="session_attr.html">
    <div class="panel panel-default" ng-if="node.nodes">
      <div class="panel-heading">
        <h2 class="panel-title text-center">{{translateP(node.title)}}</h2>
      </div>
      <table class="table table-striped" ng-model="node.nodes">
        <tr ng-repeat="node in node.nodes" ng-include="'session_attr.html'"></tr>
      </table>
    </div>
    <div ng-if="!node.nodes" >
	  <th class="col-md-3" ng-if="node.title!='UBK' && node.title!='TOTP' && node.title!='U2F'">{{translate(node.title)}}</th>
      <td class="data-{{node.epoch}}" ng-if="node.title=='TOTP' || node.title=='UBK' || node.title=='U2F'" >{{node.title}}</td>
	  <th class="col-md-3" ng-if="node.title=='type'">{{translate(node.value)}}</th>
	  <td class="col-md-3 data-{{node.epoch}}" ng-if="node.title!='type'" >{{node.value}}</td>
	  <th class="col-md-3" ng-if="node.title=='type'">{{translate(node.epoch)}}</th>
	  <td class="col-md-3 data-{{node.epoch}}" ng-if="node.title=='TOTP' || node.title=='UBK' || node.title=='U2F'">{{localeDate(node.epoch)}}</td>
      <td class="data-{{node.epoch}}">
	  <span ng-if="node.title=='TOTP' || node.title=='UBK' || node.title=='U2F'" class="link text-danger glyphicon glyphicon-minus-sign" ng-click="delete2FA(node.title, node.epoch)"></span>
		  <!--
		  <span ng-if="$last && ( node.title=='TOTP' || node.title=='UBK' || node.title=='U2F' )" class="link text-success glyphicon glyphicon-plus-sign" ng-click="menuClick({title:'newRule'})"></span>
		  -->
      </td>
    </div>
  </script>

  <script type="text/ng-template" id="nodes_renderer.html">
    <div ui-tree-handle class="tree-node tree-node-content panel-info" ng-class="{'bg-info':this.$modelValue===currentScope.$modelValue,'tree-node-default':this.$modelValue!==currentScope.$modelValue}">
      <span ng-if="node.value">
        <a id="a-{{node.value}}" class="btn btn-node btn-sm" ng-click="stoggle(this)">
          <span class="glyphicon" ng-class="{'glyphicon-chevron-right': collapsed,'glyphicon-chevron-down': !collapsed}"></span>
        </a>
        <span id="s-{{node.value}}" ng-click="stoggle(this)">{{node.title || node.value}} <span class="badge">{{node.count}}</span></span>
      </span>
      <span ng-if="node.session">
        <a class="btn btn-node btn-sm" ng-click="displaySession(this)">
          <span class="glyphicon glyphicon-eye-open"></span>
        </a>
        <span id="s-{{node.session}}" ng-click="displaySession(this)">{{node.userId}}</span>
      </span>
    </div>
    <ol ui-tree-nodes="" ng-model="node.nodes" ng-class="{hidden: collapsed}">
      <li ng-repeat="node in node.nodes track by node.id" ui-tree-node ng-include="'nodes_renderer.html'" collapsed="true"></li>
    </ol>
  </script>

  <TMPL_INCLUDE NAME="scripts.tpl">

  <!-- //if:jsminified
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/2ndfa.min.js"></script>
  //else -->
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/2ndfa.js"></script>
  <!-- //endif -->

<TMPL_INCLUDE NAME="footer.tpl">
