  <!-- Menu bar -->
  <header id="navbar" role="banner">
    <nav class="navbar navbar-inverse navbar-fixed-top">
      <div class="container-fluid">
        <!-- XS buttons -->
        <div class="navbar-header">
          <span class="navbar-brand">
            <img ng-click="home()" class="link hidden-xs" width="88px" height="32px" src="<TMPL_VAR NAME="STATIC_PREFIX">logos/llng-logo-32.png"/>
            <img ng-click="home()" class="link visible-xs" width="32px" height="32px" src="<TMPL_VAR NAME="STATIC_PREFIX">logos/llng-icon-32.png"/>
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
        <ul class="hidden-xs nav navbar-nav">
          <li ng-repeat="l in links"><a href="{{l.target}}"><strong><i ng-if="l.icon" class="glyphicon glyphicon-{{l.icon}}"></i> {{translate(l.title)}}</strong></a></li>
        </ul>
        <ul class="hidden-xs nav navbar-nav navbar-right">
          <li uib-dropdown>
            <a id="mainlangmenu" name="menu" uib-dropdown-toggle data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">{{translate('menu')}} <span class="caret"></span></a>
            <ul uib-dropdown-menu aria-labelled-by="mainlangmenu">
              <li ng-repeat="menulink in menulinks"><a href="{{menulink.target}}"><i ng-if="menulink.icon" class="glyphicon glyphicon-{{menulink.icon}}"></i> {{translate(menulink.title)}}</a></li>
              <li role="separator" class="divider"></li>
              <li class="dropdown-header">{{translate('languages')}}</li>
              <li ng-include="'languages.html'"/>
              <li role="separator" class="divider"></li>
              <li class="dropdown-header">{{translate('version')}}</li>
              <li><a name="version"><TMPL_VAR NAME="VERSION"></a></li>
            </ul>
          </li>
        </ul>
      </div>
    </nav>
  </header>
