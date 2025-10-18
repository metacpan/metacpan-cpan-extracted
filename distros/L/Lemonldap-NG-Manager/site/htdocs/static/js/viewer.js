(function () {
  'use strict';

  /*
  LemonLDAP::NG Viewer client

  This is the main app file. Other are:
   - struct.json and js/confTree.js that contains the full tree
   - translate.json that contains the keywords translation

  This file contains:
   - the AngularJS controller
  */
  var llapp;
  llapp = angular.module('llngViewer', ['ui.tree', 'ui.bootstrap', 'llApp', 'ngCookies']);

  /*
  Main AngularJS controller
  */
  llapp.controller('TreeCtrl', ['$scope', '$http', '$location', '$q', '$uibModal', '$translator', '$cookies', '$htmlParams', '$timeout', function ($scope, $http, $location, $q, $uibModal, $translator, $cookies, $htmlParams, $timeout) {
    var _download, _stoggle, c, id, pathEvent, readError, setHelp;
    $scope.links = window.links;
    $scope.menu = $htmlParams.menu;
    $scope.menulinks = window.menulinks;
    $scope.staticPrefix = window.staticPrefix;
    $scope.formPrefix = window.formPrefix;
    $scope.availableLanguages = window.availableLanguages;
    $scope.waiting = true;
    $scope.showM = false;
    $scope.showT = false;
    $scope.form = 'homeViewer';
    $scope.currentCfg = {};
    $scope.clipboardAvailable = Boolean(navigator.clipboard);
    $scope.viewPrefix = window.viewPrefix;
    $scope.allowDiff = window.allowDiff;
    $scope.message = {};
    $scope.result = '';
    // Import translations functions
    $scope.translateTitle = function (node) {
      return $translator.translateField(node, 'title');
    };
    $scope.translateP = $translator.translateP;
    $scope.translate = $translator.translate;
    // HELP DISPLAY
    $scope.helpUrl = 'start.html#configuration';
    $scope.setShowHelp = function (val) {
      var d;
      if (val == null) {
        val = !$scope.showH;
      }
      $scope.showH = val;
      d = new Date(Date.now());
      d.setFullYear(d.getFullYear() + 1);
      return $cookies.put('showhelp', val ? 'true' : 'false', {
        "expires": d
      });
    };
    $scope.showH = $cookies.get('showhelp') === 'false' ? false : true;
    if ($scope.showH == null) {
      $scope.setShowHelp(true);
    }
    // INTERCEPT AJAX ERRORS
    readError = function (response) {
      var e, j;
      e = response.status;
      j = response.statusLine;
      $scope.waiting = false;
      if (e === 403) {
        $scope.message = {
          title: 'forbidden',
          message: '',
          items: []
        };
      } else if (e === 401) {
        console.debug('Authentication needed');
        $scope.message = {
          title: 'authenticationNeeded',
          message: '__waitOrF5__',
          items: []
        };
      } else if (e === 400) {
        $scope.message = {
          title: 'badRequest',
          message: j,
          items: []
        };
      } else if (e > 0) {
        $scope.message = {
          title: 'badRequest',
          message: j,
          items: []
        };
      } else {
        $scope.message = {
          title: 'networkProblem',
          message: '',
          items: []
        };
      }
      return $scope.showModal('message.html');
    };
    // Modal launcher
    $scope.showModal = function (tpl, init) {
      var d, modalInstance;
      modalInstance = $uibModal.open({
        templateUrl: tpl,
        controller: 'ModalInstanceCtrl',
        size: 'lg',
        resolve: {
          elem: function () {
            return function (s) {
              return $scope[s];
            };
          },
          set: function () {
            return function (f, s) {
              return $scope[f] = s;
            };
          },
          init: function () {
            return init;
          }
        }
      });
      d = $q.defer();
      modalInstance.result.then(function (msgok) {
        $scope.message = {
          title: '',
          message: '',
          items: []
        };
        return d.resolve(msgok);
      }, function (msgnok) {
        $scope.message = {
          title: '',
          message: '',
          items: []
        };
        return d.reject(msgnok);
      });
      return d.promise;
    };
    // FORM DISPLAY FUNCTIONS

    // Function called when a menu item is selected. It launch function stored in
    // "action" or "title"
    $scope.menuClick = function (button) {
      if (button.popup) {
        window.open(button.popup);
      } else {
        if (!button.action) {
          button.action = button.title;
        }
        switch (typeof button.action) {
          case 'function':
            button.action($scope.currentNode, $scope);
            break;
          case 'string':
            $scope[button.action]();
            break;
          default:
            console.warn('Unknown action type', typeof button.action);
        }
      }
      return $scope.showM = false;
    };
    // Display main form
    $scope.home = function () {
      $scope.form = 'homeViewer';
      return $scope.showM = false;
    };
    // Download raw conf
    $scope.downloadConf = function () {
      return window.open($scope.viewPrefix + $scope.currentCfg.cfgNum + '?full=1');
    };
    // NODES MANAGEMENT
    id = 1;
    $scope._findContainer = function () {
      return $scope._findScopeContainer().$modelValue;
    };
    $scope._findScopeContainer = function () {
      var cs;
      cs = $scope.currentScope;
      while (!cs.$modelValue.type.match(/Container$/)) {
        cs = cs.$parentNodeScope;
      }
      return cs;
    };
    $scope._findScopeByKey = function (k) {
      var cs;
      cs = $scope.currentScope;
      while (!(cs.$modelValue.title === k)) {
        cs = cs.$parentNodeScope;
      }
      return cs;
    };
    $scope.down = function () {
      var i, ind, l, len, n, p, ref, tmp;
      id = $scope.currentNode.id;
      p = $scope.currentScope.$parentNodeScope.$modelValue;
      ind = p.nodes.length;
      ref = p.nodes;
      for (i = l = 0, len = ref.length; l < len; i = ++l) {
        n = ref[i];
        if (n.id === id) {
          ind = i;
        }
      }
      if (ind < p.nodes.length - 1) {
        tmp = p.nodes[ind];
        p.nodes[ind] = p.nodes[ind + 1];
        p.nodes[ind + 1] = tmp;
      }
      return ind;
    };
    $scope.up = function () {
      var i, ind, l, len, n, p, ref, tmp;
      id = $scope.currentNode.id;
      p = $scope.currentScope.$parentNodeScope.$modelValue;
      ind = -1;
      ref = p.nodes;
      for (i = l = 0, len = ref.length; l < len; i = ++l) {
        n = ref[i];
        if (n.id === id) {
          ind = i;
        }
      }
      if (ind > 0) {
        tmp = p.nodes[ind];
        p.nodes[ind] = p.nodes[ind - 1];
        p.nodes[ind - 1] = tmp;
      }
      return ind;
    };
    // test if value is in select
    $scope.inSelect = function (value) {
      var l, len, n, ref;
      ref = $scope.currentNode.select;
      for (l = 0, len = ref.length; l < len; l++) {
        n = ref[l];
        if (n.k === value) {
          return true;
        }
      }
      return false;
    };
    // This is for rule form: title = comment if defined, else title = re
    $scope.changeRuleTitle = function (node) {
      return node.title = node.comment.length > 0 ? node.comment : node.re;
    };
    // Node opening

    // authParams mechanism: show used auth modules only (launched by stoggle)
    $scope.filters = {};
    $scope.execFilters = function (scope) {
      var filter, func, ref;
      scope = scope ? scope : $scope;
      ref = $scope.filters;
      for (filter in ref) {
        func = ref[filter];
        if ($scope.filters.hasOwnProperty(filter)) {
          return window.filterFunctions[filter](scope, $q, func);
        }
      }
      return false;
    };
    // To avoid binding all the tree, nodes are pushed in DOM only when opened
    $scope.stoggle = function (scope) {
      var node;
      node = scope.$modelValue;
      _stoggle(node);
      return scope.toggle();
    };
    _stoggle = function (node) {
      var a, l, len, len1, len2, m, n, o, ref, ref1, ref2;
      ref = ['nodes', 'nodes_cond'];
      for (l = 0, len = ref.length; l < len; l++) {
        n = ref[l];
        if (node[`_${n}`]) {
          node[n] = [];
          ref1 = node[`_${n}`];
          for (m = 0, len1 = ref1.length; m < len1; m++) {
            a = ref1[m];
            node[n].push(a);
          }
          delete node[`_${n}`];
        }
      }
      // Call execFilter for authParams
      if (node._nodes_filter) {
        if (node.nodes) {
          ref2 = node.nodes;
          for (o = 0, len2 = ref2.length; o < len2; o++) {
            n = ref2[o];
            n.onChange = $scope.execFilters;
          }
        }
        $scope.filters[node._nodes_filter] = node;
        return $scope.execFilters();
      }
    };
    // Simple toggle management
    $scope.toggle = function (scope) {
      return scope.toggle();
    };
    // cnodes management: hash keys/values are loaded when parent node is opened
    $scope.download = function (scope) {
      var node;
      node = scope.$modelValue;
      return _download(node);
    };
    _download = function (node) {
      var d, uri;
      d = $q.defer();
      d.notify('Trying to get datas');
      $scope.waiting = true;
      console.debug(`Trying to get key ${node.cnodes}`);
      uri = encodeURI(node.cnodes);
      $http.get(`${window.viewPrefix}${$scope.currentCfg.cfgNum}/${uri}`).then(function (response) {
        var a, data, l, len;
        data = response.data;
        // Manage datas errors
        if (!data) {
          d.reject('Empty response from server');
        } else if (data.error) {
          if (data.error.match(/setDefault$/)) {
            if (node['default']) {
              node.nodes = node['default'].slice(0);
            } else {
              node.nodes = [];
            }
            delete node.cnodes;
            d.resolve('Set data to default value');
          } else {
            d.reject(`Server return an error: ${data.error}`);
          }
        } else {
          // Store datas
          delete node.cnodes;
          if (!node.type) {
            node.type = 'keyTextContainer';
          }
          node.nodes = [];
          // TODO: try/catch
          for (l = 0, len = data.length; l < len; l++) {
            a = data[l];
            if (a.template) {
              a._nodes = templates(a.template, a.title);
            }
            node.nodes.push(a);
          }
          d.resolve('OK');
        }
        return $scope.waiting = false;
      }, function (response) {
        readError(response);
        return d.reject('');
      });
      return d.promise;
    };
    $scope.openCnode = function (scope) {
      return $scope.download(scope).then(function () {
        return scope.toggle();
      });
    };
    $scope.copyPath = function () {
      var text = $scope.breadCrumb.join(" » ");
      navigator.clipboard.writeText(text).then(function () {
        $scope.$apply(function () {
          $scope.copySuccess = true;
          $timeout(function () {
            $scope.copySuccess = false;
          }, 400);
        });
      });
    };
    setHelp = function (scope) {
      while (!scope.$modelValue.help && scope.$parentNodeScope) {
        scope = scope.$parentNodeScope;
      }
      return $scope.helpUrl = scope.$modelValue.help || 'start.html#configuration';
    };
    // Form management

    // `currentNode` contains the last select node

    // method `diplayForm()`:
    //	- set the `form` property to the name of the form to download
    //		(`text` by default or `home` for node without `type` property)
    //	- launch getKeys to set `node.data`
    //	- hide tree when in XS size

    $scope.getTrPath = function (scope) {
      var path = [];
      var trpath = [];
      var current = scope;
      var safetycount = 0;
      while (current && current.$modelValue && safetycount < 100) {
        safetycount = safetycount + 1;
        if (current.$modelValue.title && current.$modelValue.title != path[0]) {
          trpath.unshift(scope.translate(current.$modelValue.title));
          path.unshift(current.$modelValue.title);
        }
        current = current.$parent;
      }
      return trpath;
    };
    $scope.displayForm = function (scope) {
      var f, l, len, n, node, ref;
      node = scope.$modelValue;
      if (node.cnodes) {
        $scope.download(scope);
      }
      if (node._nodes) {
        $scope.stoggle(scope);
      }
      $scope.currentNode = node;
      $scope.currentScope = scope;
      f = node.type ? node.type : 'text';
      if (node.nodes || node._nodes || node.cnodes) {
        $scope.form = f !== 'text' ? f : 'mini';
      } else {
        $scope.form = f;
        // Get datas
        $scope.getKey(node);
      }
      if (node.type && node.type === 'simpleInputContainer') {
        ref = node.nodes;
        for (l = 0, len = ref.length; l < len; l++) {
          n = ref[l];
          $scope.getKey(n);
        }
      }
      $scope.showT = false;
      $scope.breadCrumb = $scope.getTrPath(scope);
      return setHelp(scope);
    };
    $scope.keyWritable = function (scope) {
      var node;
      node = scope.$modelValue;
      // regexp-assemble of:
      //  authChoice
      //  cmbModule
      //  keyText
      //  menuApp
      //  menuCat
      //  rule
      //  samlAttribute
      //  samlIDPMetaDataNode
      //  samlSPMetaDataNode
      //  sfExtra
      //  virtualHost
      if (node.type && node.type.match(/^(?:s(?:aml(?:(?:ID|S)PMetaDataNod|Attribut)e|fExtra)|(?:(?:cmbMod|r)ul|authChoic)e|(?:virtualHos|keyTex)t|menu(?:App|Cat))$/)) {
        return true;
      } else {
        return false;
      }
    };
    // method `getKey()`:
    // - return a promise with the data:
    // 	- from node when set
    // 	- after downloading else

    $scope.getKey = function (node) {
      var d, i, l, len, n, ref, tmp, uri;
      d = $q.defer();
      if (!node.data) {
        $scope.waiting = true;
        if (node.get && typeof node.get === 'object') {
          node.data = [];
          tmp = [];
          ref = node.get;
          for (i = l = 0, len = ref.length; l < len; i = ++l) {
            n = ref[i];
            node.data[i] = {
              title: n.split("/").pop(),
              get: n,
              id: n
            };
            tmp.push($scope.getKey(node.data[i]));
          }
          $q.all(tmp).then(function () {
            return d.resolve(node.data);
          }, function (response) {
            d.reject(response.statusLine);
            return $scope.waiting = false;
          });
        } else {
          uri = '';
          if (node.get) {
            console.debug(`Trying to get key ${node.get}`);
            uri = encodeURI(node.get);
          } else {
            console.debug(`Trying to get title ${node.title}`);
          }
          $http.get(`${window.viewPrefix}${$scope.currentCfg.cfgNum}/${node.get ? uri : node.title}`).then(function (response) {
            var data;
            // Set default value if response is null or if asked by server
            data = response.data;
            if ((data.value === null || data.error && data.error.match(/setDefault$/)) && node['default'] !== null) {
              node.data = node['default'];
            } else {
              node.data = data.value;
            }
            if (node.data && node.data.toString().match(/_Hidden_$/)) {
              node.type = 'text';
              node.data = '######';
            }
            // Cast int as int (remember that booleans are int for Perl)
            if (node.type && node.type.match(/^(bool|trool|boolOrExpr)$/)) {
              if (typeof node.data === 'string' && node.data.match(/^(?:-1|0|1)$/)) {
                node.data = parseInt(node.data, 10);
              }
            }
            if (node.type && node.type.match(/^int$/)) {
              node.data = parseInt(node.data, 10);
              // Split SAML types
            } else if (node.type && node.type.match(/^(saml(Service|Assertion)|blackWhiteList)$/) && !(typeof node.data === 'object')) {
              node.data = node.data.split(';');
            }
            $scope.waiting = false;
            return d.resolve(node.data);
          }, function (response) {
            readError(response);
            return d.reject(response.status);
          });
        }
      } else {
        if (node.data.toString().match(/_Hidden_$/)) {
          node.type = 'text';
          node.data = '######';
        }
        d.resolve(node.data);
      }
      return d.promise;
    };
    // function `pathEvent(event, next; current)`:
    // Called when $location.path() change, launch getCfg() with the new
    // configuration number
    pathEvent = function (event, next, current) {
      var n;
      n = next.match(new RegExp('#!?/view/(latest|[0-9]+)'));
      if (n === null) {
        return $location.path('/view/latest');
      } else {
        console.debug(`Trying to get cfg number ${n[1]}`);
        return $scope.getCfg(n[1]);
      }
    };
    $scope.$on('$locationChangeSuccess', pathEvent);
    // function `getCfg(n)`:
    // Download configuration metadatas
    $scope.getCfg = function (n) {
      if ($scope.currentCfg.cfgNum !== n) {
        return $http.get(`${window.viewPrefix}${n}`).then(function (response) {
          var d;
          $scope.currentCfg = response.data;
          d = new Date($scope.currentCfg.cfgDate * 1000);
          $scope.currentCfg.date = d.toLocaleString();
          console.debug(`Metadatas of cfg ${n} loaded`);
          $location.path(`/view/${n}`);
          return $scope.init();
        }, function (response) {
          return readError(response).then(function () {
            $scope.currentCfg.cfgNum = 0;
            return $scope.init();
          });
        });
      } else {
        return $scope.waiting = false;
      }
    };
    // method `getLanguage(lang)`
    // Launch init() after setting current language
    $scope.getLanguage = function (lang) {
      $scope.lang = lang;
      // Force reload home
      $scope.form = 'white';
      $scope.init();
      return $scope.showM = false;
    };
    // Initialization

    // Load JSON files:
    //	- struct.json: the main tree
    //	- languages/<lang>.json: the chosen language datas
    $scope.init = function () {
      var tmp;
      tmp = null;
      $scope.waiting = true;
      $scope.breadCrumb = null;
      $scope.data = [];
      $scope.confirmNeeded = false;
      $scope.forceSave = false;
      $q.all([$translator.init($scope.lang), $http.get(`${window.staticPrefix}struct.json`).then(function (response) {
        tmp = response.data;
        console.debug("Structure loaded");
      })]).then(function () {
        console.debug("Starting structure binding");
        $scope.data = tmp;
        tmp = null;
        if ($scope.currentCfg.cfgNum !== 0) {
          setScopeVars($scope);
        } else {
          $scope.message = {
            title: 'emptyConf',
            message: '__zeroConfExplanations__'
          };
          $scope.showModal('message.html');
        }
        $scope.form = 'homeViewer';
        return $scope.waiting = false;
      }, readError);
      // Colorized link
      $scope.activeModule = "viewer";
      return $scope.myStyle = {
        color: '#ffb84d'
      };
    };
    c = $location.path().match(new RegExp('^/view/(latest|[0-9]+)'));
    if (!c) {
      console.debug("Redirecting to /view/latest");
      return $location.path('/view/latest');
    }
  }]);

})();
