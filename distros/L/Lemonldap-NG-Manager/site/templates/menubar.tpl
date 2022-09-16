  <!-- Menu bar -->
  <header id="navbar" role="banner">
    <nav class="navbar navbar-inverse navbar-fixed-top">
      <div class="container-fluid">
        <!-- XS buttons -->
        <div class="navbar-header">
          <span class="navbar-brand">
            <img ng-click="home()" class="link hidden-xs" width="88px" height="32px" title="<TMPL_VAR NAME="INSTANCE_NAME">" src="<TMPL_VAR NAME="STATIC_PREFIX">logos/llng-logo-32.png"/>
            <img ng-click="home()" class="link visible-xs" width="32px" height="32px" title="<TMPL_VAR NAME="INSTANCE_NAME">" src="<TMPL_VAR NAME="STATIC_PREFIX">logos/llng-icon-32.png"/>
          </span>
          <button type="button" class="navbar-toggle" ng-click="showM=!showM">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <button type="button" class="btn btn-default navbar-btn visible-xs" ng-click="showT=!showT">
            <span ng-hide="showT" trspan="browseTree"></span>
            <span ng-show="showT" trspan="hideTree"></span>
          </button>
          <!-- Last buttons, available languages -->
        </div>
        <ul class="hidden-xs nav navbar-nav" role="grid">
          <li ng-repeat="l in links" id="l in links"><a href="{{l.target}}" role="row"><strong><i ng-if="activeModule == l.title" ng-style="myStyle" class="glyphicon glyphicon-{{l.icon}}"></i><i ng-if="activeModule != l.title" class="glyphicon glyphicon-{{l.icon}}" ng-style="clickStyle"></i> <span ng-if="activeModule == l.title" ng-style="myStyle" ng-bind="translate(l.title)"></span><span ng-if="activeModule != l.title" ng-bind="translate(l.title)" ng-style="clickStyle"></span></strong></a></li>

        </ul>
        <ul class="hidden-xs nav navbar-nav navbar-right">
          <li uib-dropdown>
            <a id="mainlangmenu" name="menu" uib-dropdown-toggle data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false"><span ng-bind="translate('menu')"></span> <span class="caret"></span></a>
            <ul uib-dropdown-menu aria-labelled-by="mainlangmenu" role="grid">
              <li ng-repeat="menulink in menulinks"><a href="{{menulink.target}}" role="row"><i ng-if="menulink.icon" class="glyphicon glyphicon-{{menulink.icon}}"></i> <span ng-bind="translate(menulink.title)"></span></a></li>
              <li role="separator" class="divider"></li>
              <li class="dropdown-header"><span ng-bind="translate('languages')"></span></li>
              <li ng-include="'languages.html'"/>
              <li role="separator" class="divider"></li>
              <li class="dropdown-header"><span ng-bind="translate('version')"></span></li>
              <li><a href="https://projects.ow2.org/view/lemonldap-ng" name="version"><TMPL_VAR NAME="VERSION"></a></li>
              <TMPL_IF NAME="INSTANCE_NAME">
                <li role="separator" class="divider"></li>
                <li class="dropdown-header"><span ng-bind="translate('instance')"></span></li>
                <li><a href="https://lemonldap-ng.org/team.html"><TMPL_VAR NAME="INSTANCE_NAME"></a></li>
              </TMPL_IF>
            </ul>
          </li>
        </ul>
      </div>
    </nav>
  </header>
