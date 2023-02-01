<TMPL_INCLUDE NAME="header.tpl">
  <TMPL_IF NAME="INSTANCE_NAME">
    <title><TMPL_VAR NAME="INSTANCE_NAME"> Manager</title>
  <TMPL_ELSE>
    <title>LemonLDAP::NG Manager</title>
  </TMPL_IF>
  <link rel="prefetch" href="<TMPL_VAR NAME="STATIC_PREFIX">forms/home.html" />
  <link rel="prefetch" href="<TMPL_VAR NAME="STATIC_PREFIX">struct.json" />
</head>

<body ng-app="llngManager" ng-controller="TreeCtrl" ng-csp>

  <TMPL_INCLUDE NAME="menubar.tpl">

  <div id="content" class="row container-fluid">

    <TMPL_INCLUDE NAME="tree.tpl">

    <!-- Right(main) div -->
    <div id="right" class="col-lg-8 col-md-8 col-sm-7 col-xs-12 scrollable" ng-class="{'hidden-xs':showT&&!showM}">
      <!-- Form container -->
      <div id="top">
        <!-- Menu buttons -->
        <div class="lmmenu navbar navbar-default" ng-class="{'hidden-xs':!showM}">
          <div class="navbar-collapse" ng-class="{'collapse':!showM}" id="formmenu">
            <ul class="nav navbar-nav">
              <li><a class="link" ng-click="home()"><i class="glyphicon glyphicon-home"></i></a></li>
              <li>
                <a id="save" class="link" ng-click="save()" tabIndex="-1">
                  <i class="glyphicon glyphicon-cloud-upload"></i>
                  {{translate('save')}}
                </a>
              </li>
              <li >
                <input id="forcesave" type="checkbox" ng-model="forceSave" uib-tooltip="{{translate('forceSave')}}" tooltip-placement="right" ng-show="confirmNeeded||currentCfg.next" role="checkbox" aria-label="Force save">
              </li>
              <li uib-dropdown>
                <a id="navmenu" name="menu" uib-dropdown-toggle data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false"><i class="glyphicon glyphicon-cog"></i> {{translate('browse')}} <span class="caret"></span></a>
                <ul uib-dropdown-menu aria-labelled-by="navmenu">
                  <li ng-class="{'disabled':!currentCfg.prev}"><a class="link" ng-click="currentCfg.prev && getCfg(currentCfg.prev)" title="Configuration {{currentCfg.prev}}"><i class="glyphicon glyphicon-arrow-left"></i> {{translate('previous')}}</a></li>
                  <li ng-class="{'disabled':!currentCfg.next}"><a class="link" ng-click="currentCfg.next && getCfg(currentCfg.next)" title="Configuration {{currentCfg.next}}"><i class="glyphicon glyphicon-arrow-right"></i> {{translate('next')}}</a></a></li>
                  <li><a class="link" ng-click="getCfg('latest')" title="Latest configuration"><i class="glyphicon glyphicon-refresh"></i> {{translate('latest')}}</a></li>
                </ul>
              </li>
              <li><a class="link hidden-xs" ng-click="setShowHelp()"><i class="glyphicon" ng-class="{'glyphicon-eye-close': showH,'glyphicon-eye-open': !showH}" ></i> {{ translate((showH ? 'hideHelp' : 'showHelp')) }}</a></li>
              <li ng-repeat="button in menu()" ng-include="'menubutton.html'"></li>
              <li uib-dropdown class="visible-xs">
                <a id="langmenu" name="menu" uib-dropdown-toggle data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">{{translate('menu')}} <span class="caret"></span></a>
                <ul uib-dropdown-menu aria-labelled-by="langmenu" role="grid">
                  <li ng-repeat="link in links"><a href="{{link.target}}" role="row"><i ng-if="link.icon" class="glyphicon glyphicon-{{link.icon}}"></i> {{translate(link.title)}}</a></li>
                  <li ng-repeat="menulink in menulinks"><a href="{{menulink.target}}" role="row"><i ng-if="menulink.icon" class="glyphicon glyphicon-{{menulink.icon}}"></i> {{translate(menulink.title)}}</a></li>
                  <li ng-include="'languages.html'"></li>
                  <TMPL_IF NAME="INSTANCE_NAME">
                    <li><a href="https://lemonldap-ng.org"><TMPL_VAR NAME="INSTANCE_NAME"></a></li>
                  </TMPL_IF>
                </ul>
              </li>
            </ul>
          </div>
        </div>
        <form class="form-group slide-animate-container" ng-include="formPrefix+form+'.html'" scope="$scope" />
      </div>
      <!-- Help container -->
      <div id="bottom" ng-if="showH" class="hidden-xs">
        <div class="panel panel-default">
          <div class="panel-body">
            <iframe id="helpframe" width="100%" height="100%" ng-src="{{'<TMPL_VAR NAME="DOC_PREFIX">/pages/documentation/current/'+helpUrl}}" frameborder="0"></iframe>
          </div>
        </div> 
      </div>
    </div>
  </div>

  <!-- HTML recursive templates (used in `ng-repeat... ng-include="'template.html'") -->
  <!-- Tree nested node template -->
  <script type="text/ng-template" id="nodes_renderer.html">
    <div ui-tree-handle class="tree-node panel-info" ng-class="{'bg-info':this.$modelValue===currentNode,'tree-node-default':this.$modelValue!==currentNode}">
      <!-- Glyph icons -->
      <span ng-switch="node.nodes||node.nodes_cond?1:((node._nodes&&node._nodes.length>0)||(node._nodes_cond&&node._nodes_cond.length>0)?3:(node.cnodes&&node.cnodes.length>0?2:0))">
        <!-- Undownloaded nodes (hash data)-->
        <a class="btn btn-sm" id="a-{{node.id}}" ng-switch-when="2" ng-click="openCnode(this)">
          <span class="glyphicon glyphicon-chevron-right"></span>
        </a>
        <!-- Javascript nodes not yet bind to DOM -->
        <a class="btn btn-sm" id="a-{{node.id}}" ng-switch-when="3" ng-click="stoggle(this)">
          <span class="glyphicon" ng-class="{'glyphicon-chevron-right': collapsed, 'glyphicon-chevron-down': !collapsed}"></span>
        </a>
        <!-- Nodes already loaded and binded -->
        <a class="btn btn-sm" id="a-{{node.id}}" ng-switch-when="1" ng-click="toggle(this)">
          <span class="glyphicon" ng-class="{'glyphicon-chevron-right': collapsed, 'glyphicon-chevron-down': !collapsed}"></span>
        </a>
        <!-- Leaf -->
        <a class="btn btn-sm" ng-switch-default ng-click="displayForm(this)">
          <span class="glyphicon glyphicon-pencil"></span>
        </a>
      </span>
      <!-- Node text with/without translation -->
      <span id="t-{{node.id}}" ng-if="keyWritable(this)" ng-click="displayForm(this)">{{node.title}}</span>
      <span id="t-{{node.id}}" ng-if="!keyWritable(this)" ng-click="displayForm(this)" trspan="{{node.title}}"></span>
    </div>
    <!-- Subnodes -->
    <ol ui-tree-nodes="btn btn-sm" ng-model="node.nodes" ng-class="{hidden: collapsed}">
      <li ng-repeat="node in node.nodes track by node.id" ui-tree-node ng-include="'nodes_renderer.html'" collapsed="true"></li>
    </ol>
    <!-- Filtered subnodes (authParams mechanism) -->
    <ol ui-tree-nodes="btn btn-sm" ng-model="node.nodes_cond" ng-class="{hidden: collapsed}">
      <li ng-repeat="(name,node) in node.nodes_cond track by node.id" ng-if="node.show" ui-tree-node ng-include="'nodes_renderer.html'" collapsed="true"></li>
    </ol>
  </script>

  <!-- Prompt -->
  <script type="text/ng-template" id="prompt.html">
  <div role="alertdialog" aria-labelledby="ptitle" aria-describedby="ptitle">
    <div class="modal-header">
      <h3 id="ptitle" class="modal-title" trspan="{{elem('message').title}}" />
      <TMPL_IF NAME="INSTANCE_NAME"><h4><TMPL_VAR NAME="INSTANCE_NAME"></h4></TMPL_IF>
    </div>
    <div class="modal-body">
      <div class="input-group maxw">
        <label class="input-group-addon" id="promptlabel" for="promptinput" trspan="{{elem('message').field}}"></label>
        <input id="promptinput" class="form-control" ng-model="result" aria-describedby="promptlabel"/>
      </div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-primary" id="promptok" ng-click="ok()" trspan="ok" role="button"></button>
      <button class="btn btn-warning" ng-click="cancel()" trspan="cancel" role="button"></button>
    </div>
  </div>
  </script>

  <!-- Message display -->
  <script type="text/ng-template" id="message.html">
  <div role="alertdialog" aria-labelledby="mtitle" aria-describedby="mbody">
    <div class="modal-header">
      <h3 id="mtitle" class="modal-title" trspan="{{elem('message').title}}" />
      <TMPL_IF NAME="INSTANCE_NAME"><h4><TMPL_VAR NAME="INSTANCE_NAME"></h4></TMPL_IF>
    </div>
    <div ng-if="elem('message').items[0] || elem('message').message" id="mbody" class="modal-body">
      <div class="modal-p">{{translateP(elem('message').message)}}</div>
      <ul class="main-modal-ul" ng-model="elem('message').items">
        <li ng-repeat="item in elem('message').items" ng-include="'messageitem.html'"/>
      </ul>
    </div>
    <div class="modal-footer">
      <button class="btn btn-primary" id="messageok" ng-click="ok()" trspan="ok" role="button"></button>
      <button class="btn btn-warning" ng-click="cancel()" ng-if="elem('message').displayCancel" trspan="cancel" role="button"></button>
    </div>
  </div>
  </script>

  <script type="text/ng-template" id="messageitem.html">
    <div class="modal-p">{{translateP(item.message)}}</div>
    <ul class="modal-ul" ng-model="item.items">
      <li ng-repeat="item in item.items" ng-include="'messageitem.html'"/>
    </ul>
  </script>

  <!-- Password question -->
  <script type="text/ng-template" id="password.html">
  <div role="alertdialog" aria-labelledby="pwtitle" aria-describedby="pwtitle">
    <div class="modal-header">
      <h3 id="pwtitle" class="modal-title" trspan="enterPassword" />
      <TMPL_IF NAME="INSTANCE_NAME"><h4><TMPL_VAR NAME="INSTANCE_NAME"></h4></TMPL_IF>
    </div>
    <div class="modal-body">
      <div class="input-group maxw">
        <label class="input-group-addon" id="mlabel" for="mdPwd" trspan="password"></label>
        <input id="mdPwd" class="form-control" ng-model="result" aria-describedby="mlabel"/>
      </div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-primary" id="passwordok" ng-click="ok()" trspan="ok" role="button"></button>
      <button class="btn btn-warning" ng-click="cancel()" trspan="cancel" role="button"></button>
    </div>
  </div>
  </script>

  <!-- Save confirm -->
  <script type="text/ng-template" id="save.html">
  <div role="alertdialog" aria-labelledby="stitle" aria-describedby="sbody">
    <div class="modal-header">
      <h3 id="stitle" class="modal-title" trspan="savingConfirmation" />
      <TMPL_IF NAME="INSTANCE_NAME"><h4><TMPL_VAR NAME="INSTANCE_NAME"></h4></TMPL_IF>
    </div>
    <div id="sbody" class="modal-body">
      <div class="input-group maxw">
        <label id="slabel" class="input-group-addon" for="longtextinput" trspan="cfgLog"></label>
        <textarea id="longtextinput" rows="5" class="form-control" ng-model="result" aria-describedby="slabel"></textarea>
      </div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-primary" id="saveok" ng-click="ok()" trspan="ok" role="button"></button>
      <button class="btn btn-warning" ng-click="cancel()" trspan="cancel" role="button"></button>
    </div>
  </div>
  </script>

  <TMPL_INCLUDE NAME="scripts.tpl">

  <!-- //if:jsminified
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/conftree.min.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/filterFunctions.min.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/manager.min.js"></script>
  //else -->
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/conftree.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/filterFunctions.js"></script>
    <script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/manager.js"></script>
  <!-- //endif -->

<TMPL_INCLUDE NAME="footer.tpl">
