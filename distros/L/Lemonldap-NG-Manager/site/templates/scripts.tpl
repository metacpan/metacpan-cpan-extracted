  <!-- Menu dropdown template -->
  <script type="text/ng-template" id="menubutton.html">
    <a class="link" ng-if="!button.buttons" ng-click="menuClick(button)"><i class="glyphicon glyphicon-{{button.icon}}" ng-if="button.icon"></i> {{translateTitle(button)}}</a>
    <a id="dropmenu{{$index}}" name="menu" ng-if="button.buttons" uib-dropdown-toggle data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false"><span class="caret"></span> {{translateTitle(button)}} <span class="caret"></span></a>
    <ul uib-dropdown-menu" role="menu" aria-labelled-by="dropmenu{{$index}}">
      <li ng-repeat="button in button.buttons" ng-include="'menubutton.html'" />
    </ul>
  </script>

  <!-- Language choice -->
  <script type="text/ng-template" id="languages.html">
    <a name="languages" class="link">
      <span ng-repeat="lang in availableLanguages" role="row">
        <img ng-src="<TMPL_VAR NAME="STATIC_PREFIX">logos/{{lang}}.png" width="16px" height="11px" ng-click="getLanguage(lang)"/>
      </span>
    </a>
  </script>



<!-- Constants -->
<script type="text/JavaScript" src="<TMPL_VAR NAME="SCRIPTNAME">psgi.js"></script>

<!-- //if:usedebianlibs
<script type="text/javascript" src="/javascript/es5-shim/es5-shim.min.js"></script>
<script type="text/javascript" src="/javascript/angular.js/angular.min.js"></script>
<script type="text/javascript" src="/javascript/angular.js/angular-aria.min.js"></script>
<script type="text/javascript" src="/javascript/angular.js/angular-cookies.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-ui-tree/dist/angular-ui-tree.min.js"></script>
<script type="text/javascript" src="/javascript/angular.js/angular-animate.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-bootstrap/ui-bootstrap-tpls.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/file-saver.js/FileSaver.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/llApp.min.js"></script>
//elsif:useexternallibs
<script type="text/javascript" src="http://cdnjs.cloudflare.com/ajax/libs/es5-shim/4.4.1/es5-shim.min.js"></script>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/angularjs/1.5.11/angular.min.js"></script>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/angularjs/1.5.11/angular-aria.min.js"></script>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/angularjs/1.5.11/angular-cookies.min.js"></script>
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/angular-ui-tree/2.13.0/angular-ui-tree.min.js"></script>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/angularjs/1.4.9/angular-animate.min.js"></script>
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/angular-ui-bootstrap/1.1.0/ui-bootstrap-tpls.min.js"></script>
<script type="text/javascript" src="https://cdn.rawgit.com/eligrey/FileSaver.js/master/FileSaver.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/llApp.min.js"></script>
//elsif:jsminified
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/es5-shim/es5-shim.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular/angular.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-aria/angular-aria.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-cookies/angular-cookies.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-ui-tree/dist/angular-ui-tree.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-animate/angular-animate.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-bootstrap/ui-bootstrap-tpls.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/file-saver.js/FileSaver.min.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/llApp.min.js"></script>
//else -->
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/es5-shim/es5-shim.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular/angular.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-aria/angular-aria.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-cookies/angular-cookies.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-ui-tree/dist/angular-ui-tree.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-animate/angular-animate.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/angular-bootstrap/ui-bootstrap-tpls.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">bwr/file-saver.js/FileSaver.js"></script>
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">js/llApp.js"></script>
<!-- //endif -->
