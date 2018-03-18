/* LemonLDAP::NG Manager client
 *
 * This is the main app file. Other are:
 *  - struct.json and js/confTree.js that contains the full tree
 *  - translate.json that contains the keywords translation
 *
 *  This file contains:
 *   - the AngularJS controller
 */
(function() {
  'use strict';

  var llapp = angular.module('llngManager', ['ui.tree', 'ui.bootstrap', 'llApp', 'ngCookies']);

  /* Main AngularJS controller
   *
   */
  llapp.controller('TreeCtrl', ['$scope', '$http', '$location', '$q', '$uibModal', '$translator', '$cookies', '$htmlParams', function($scope, $http, $location, $q, $uibModal, $translator, $cookies, $htmlParams) {

    $scope.links = links;
    $scope.menu = $htmlParams.menu;
    $scope.menulinks = menulinks;
    $scope.staticPrefix = staticPrefix;
    $scope.formPrefix = formPrefix;
    $scope.availableLanguages = availableLanguages;
    $scope.waiting = true;
    $scope.showM = false;
    $scope.showT = false;
    $scope.form = 'home';
    $scope.currentCfg = {};
    $scope.confPrefix = confPrefix;
    $scope.message = {};
    $scope.result = '';
    $scope.helpUrl = 'start.html#configuration';
    /* Help display */
    $scope.setShowHelp = function(val) {
      if (typeof val === 'undefined') val = !$scope.showH;
      $scope.showH = val;
      var d = new Date(Date.now());
      d.setFullYear(d.getFullYear() + 1);
      $cookies.put('showhelp', (val ? 'true' : 'false'), {
        expires: d
      });
    }
    $scope.showH = ($cookies.get('showhelp') === 'false' ? false : true);
    if (typeof $scope.showH === 'undefined') $scope.setShowHelp(true);
    /* Intercept AJAX errors */
    var readError = function(response) {
      var e = response.status;
      var j = response.statusText;
      $scope.waiting = false;
      if (e == 403) {
        $scope.message = {
          title: 'forbidden',
          message: '',
          items: []
        };
      }
      else if (e == 401) {
        console.log('Authentication needed');
        $scope.message = {
          title: 'authenticationNeeded',
          message: '__waitOrF5__',
          items: []
        };
      }
      else if (e == 400) {
        $scope.message = {
          title: 'badRequest',
          message: j
        };
      }
      else if (e > 0) {
        $scope.message = {
          title: 'badRequest',
          message: j
        };
      }
      else {
        $scope.message = {
          title: 'networkProblem',
          message: ''
        };
      }
      return $scope.showModal('message.html');
    };

    /* Modal launcher */
    $scope.showModal = function(tpl, init) {
      var modalInstance = $uibModal.open({
        templateUrl: tpl,
        controller: 'ModalInstanceCtrl',
        size: 'lg',
        resolve: {
          elem: function() {
            return function(s) {
              return $scope[s];
            }
          },
          set: function() {
            return function(f, s) {
              $scope[f] = s;
            }
          },
          init: function() {
            return init
          }
        }
      });
      var d = $q.defer();
      modalInstance.result.then(function(msgok) {
        $scope.message = {
          title: '',
          message: '',
          items: []
        };
        d.resolve(msgok);
      },
      function(msgnok) {
        $scope.message = {
          title: '',
          message: '',
          items: []
        };
        d.reject(msgnok);
      });
      return modalInstance.result;
    }

    /* Manage form menu clicks */
    $scope.menuClick = function(button) {
      if (button.popup) {
        window.open(button.popup);
      } else {
        if (!button.action) button.action = button.title;
        switch (typeof button.action) {
        case 'function':
          button.action($scope.currentNode, $scope);
          break;
        case 'string':
          $scope[button.action]();
          break;
        default:
          console.log(typeof button.action);
        };
      }
      $scope.showM = false;
    };

    $scope.home = function() {
      $scope.form = 'home';
      $scope.showM = false;
    }

    var _checkSaveResponse = function(data) {
      $scope.message = {
        title: '',
        message: '',
        items: []
      };
      if (data.message && data.message == '__needConfirmation__') {
        $scope.confirmNeeded = true;
      }
      if (data.message) $scope.message.message = data.message;
      if (data.details) {
        for (var m in data.details) {
          if (m != '__changes__') $scope.message.items.push({
            message: m,
            items: data.details[m]
          });
        };
      }
      $scope.waiting = false;
      if (data.result == 1) {
        /* Force reload */
        $location.path('/confs/');
        $scope.message.title = 'successfullySaved';
      } else {
        $scope.message.title = 'saveReport';
      }
      $scope.showModal('message.html');
    };

    $scope.downloadConf = function() {
      window.open($scope.confPrefix + $scope.currentCfg.cfgNum + '?full');
    };

    $scope.save = function() {
      $scope.showModal('save.html').then(function() {
        $scope.waiting = true;
        $scope.data.push({
          id: "cfgLog",
          title: "cfgLog",
          data: $scope.result ? $scope.result : ''
        });
        $http.post(confPrefix + '?cfgNum=' + $scope.currentCfg.cfgNum + ($scope.forceSave ? "&force=1" : ''), $scope.data).then(function(response) {
          $scope.data.pop();
          _checkSaveResponse(response.data);
        },
        function(response) {
          readError(response);
          $scope.data.pop();
        });
      },
      function() {
        console.log('Saving canceled');
      });
      $scope.showM = false;
    }

    /* Raw save function */
    $scope.saveRawConf = function($fileContent) {
      $scope.waiting = true;
      $http.post(confPrefix + '/raw', $fileContent).then(function(response) {
        _checkSaveResponse(response.data);
      },
      readError);
    };

    /* Restore raw conf function */
    $scope.restore = function() {
      $scope.currentNode = null;
      $scope.form = 'restore';
    };

    /* Cancel save function */
    $scope.cancel = function() {
      $scope.currentNode.data = null;
      $scope.getKey($scope.currentNode);
    };

    /* Nodes management */
    var id = 1;

    $scope._findContainer = function() {
      return $scope._findScopeContainer().$modelValue;
    };
    $scope._findScopeContainer = function() {
      var cs = $scope.currentScope;
      while (!cs.$modelValue.type.match(/Container$/)) {
        cs = cs.$parentNodeScope;
      }
      return cs;
    };

    $scope._findScopeByKey = function(k) {
      var cs = $scope.currentScope;
      while (! (cs.$modelValue.title === k)) {
        cs = cs.$parentNodeScope;
      }
      return cs;
    }

    /* Add grant rule entry */
    $scope.newGrantRule = function() {
      var node = $scope._findContainer();
      var l = node.nodes.length;
      var n = l > 0 ? l - 1 : 0;
      node.nodes.splice(n, 0, {
        id: node.id + '/n' + (id++),
        title: 'New rule',
        re: '1',
        comment: 'New rule',
        data: 'Message',
        type: "grant"
      });
    };

    /* Add rules entry */
    $scope.newRule = function() {
      var node = $scope._findContainer();
      var l = node.nodes.length;
      var n = l > 0 ? l - 1 : 0;
      node.nodes.splice(n, 0, {
        id: node.id + '/n' + (id++),
        title: 'New rule',
        re: '^/new',
        comment: 'New rule',
        data: 'accept',
        type: "rule"
      });
    };

    /* Add form replay */
    $scope.newPost = function() {
      var node = $scope._findContainer();
      node.nodes.push({
        id: node.id + '/n' + (id++),
        title: "/absolute/path/to/form",
        data: {},
        type: "post"
      });
    };

    $scope.newPostVar = function() {
      if (typeof $scope.currentNode.data.vars === 'undefined') $scope.currentNode.data.vars = [];
      $scope.currentNode.data.vars.push(['var1', '$uid']);
    };

    /* Add auth chain entry to authChoice */
    $scope.newAuthChoice = function() {
      var node = $scope._findContainer();
      node.nodes.push({
        id: node.id + '/n' + (id++),
        title: "1_Key",
        data: ['Null', 'Null', 'Null'],
        type: "authChoice"
      });
      $scope.execFilters($scope._findScopeByKey('authParams'));
    };

    /* Add hash entry */
    $scope.newHashEntry = function() {
      var node = $scope._findContainer();
      node.nodes.push({
        id: node.id + '/n' + (id++),
        title: 'new',
        data: '',
        type: "keyText"
      });
    }

    /* Menu cat entry */
    $scope.newCat = function() {
      var cs = $scope.currentScope;
      if (cs.$modelValue.type == 'menuApp') cs = cs.$parentNodeScope;
      cs.$modelValue.nodes.push({
        id: cs.$modelValue.id + '/n' + (id++),
        title: "New category",
        type: "menuCat",
        nodes: []
      });
    };

    /* Menu app entry */
    $scope.newApp = function() {
      var cs = $scope.currentScope;
      if (cs.$modelValue.type == 'menuApp') cs = cs.$parentNodeScope;
      cs.$modelValue.nodes.push({
        id: cs.$modelValue.id + '/n' + (id++),
        title: "New application",
        type: "menuApp",
        data: {
          description: "New app description",
          uri: "https://test.example.com/",
          logo: "network.png",
          display: "auto"
        }
      });
    };

    /* Add host*/
    $scope.addHost = function() {
      var cn = $scope.currentNode;
      if (!cn.data) cn.data = [];
      cn.data.push({
        "k": "newHost",
        h: [{
          "k": "key",
          "v": "uid"
        }]
      });
    };

    /* SAML attribute entry */
    $scope.addSamlAttribute = function() {
      var node = $scope._findContainer();
      node.nodes.push({
        id: node.id + '/n' + (id++),
        title: 'new',
        type: 'samlAttribute',
        data: [0, 'New', '', '']
      });
    };

    /* Nodes with template */
    $scope.addVhost = function() {
      var name = $scope.domain ? ('.' + $scope.domain.data) : '.example.com';
      $scope.message = {
        title: 'virtualHostName',
        field: 'hostname'
      };
      $scope.showModal('prompt.html', name).then(function() {
        var name = $scope.result;
        if (name) {
          return $scope.addTemplateNode(name, 'virtualHost');
        }
      });
    };

    $scope.duplicateVhost = function() {
      var name = $scope.domain ? ('.' + $scope.domain.data) : '.example.com';
      $scope.message = {
        title: 'virtualHostName',
        field: 'hostname'
      };
      $scope.showModal('prompt.html', name).then(function() {
        var name = $scope.result;
        return $scope.duplicateNode(name, 'virtualHost', $scope.currentNode.title);
      });
    };

    $scope.addSamlIDP = function() {
      $scope.newTemplateNode('samlIDPMetaDataNode', 'samlPartnerName', 'idp-example');
    };

    $scope.addSamlSP = function() {
      $scope.newTemplateNode('samlSPMetaDataNode', 'samlPartnerName', 'sp-example');
    };

    $scope.addOidcOp = function() {
      $scope.newTemplateNode('oidcOPMetaDataNode', 'oidcOPName', 'op-example');
    };

    $scope.addOidcRp = function() {
      $scope.newTemplateNode('oidcRPMetaDataNode', 'oidcRPName', 'rp-example');
    };

    $scope.newTemplateNode = function(type, title, init) {
      $scope.message = {
        title: title,
        field: 'name'
      };
      $scope.showModal('prompt.html', init).then(function() {
        var name = $scope.result;
        if (name) {
          $scope.addTemplateNode(name, type)
        }
      });
    };

    $scope.addTemplateNode = function(name, type) {
      var cs = $scope.currentScope;
      while (cs.$modelValue.title != type + 's') {
        cs = cs.$parentNodeScope;
      }
      var t = {
        id: type + "s/" + 'new__' + name,
        title: name,
        type: type,
        nodes: templates(type, 'new__' + name)
      };
      setDefault(t.nodes);
      cs.$modelValue.nodes.push(t);
      cs.expand();
      return t;
    };
    var setDefault = function(node) {
      var len, n, o;
      for (o = 0, len = node.length; o < len; o++) {
        n = node[o];
        if (n.cnodes && n["default"]) {
          delete n.cnodes;
          n._nodes = n["default"];
        }
        if (n._nodes) {
          setDefault(n._nodes);
        } else if (n["default"] || n["default"] === 0) {
          n.data = n["default"];
        }
      }
      return node;
    };

    var _getAll = function(node) {
      var d = $q.defer();
      var d2 = $q.defer();
      if (node._nodes) {
        _stoggle(node);
        d.resolve();
      }
      else if (node.cnodes) {
        _download(node).then(function() {
          d.resolve()
        });
      }
      else if (node.nodes || node.data) {
        d.resolve()
      }
      else {
        $scope.getKey(node).then(function() {
          d.resolve()
        });
      }
      d.promise.then(function() {
        var t = [];
        if (node.nodes) {
          node.nodes.forEach(function(n) {
            t.push(_getAll(n));
          });
        }
        $q.all(t).then(function() {
          d2.resolve()
        });
      });
      return d2.promise;
    };

    $scope.duplicateNode = function(name, type, idkey) {
      var cs = $scope.currentScope;
      _getAll($scope.currentNode).then(function() {
        while (cs.$modelValue.title != type + 's') {
          cs = cs.$parentNodeScope;
        }
        var t = JSON.parse(JSON.stringify($scope.currentNode).replace(new RegExp(idkey, 'g'), 'new__' + name));
        t.id = type + "s/" + 'new__' + name;
        t.title = name;
        cs.$modelValue.nodes.push(t);
        return t;
      })
    };

    $scope.del = function(a, i) {
      a.splice(i, 1);
    };

    $scope.deleteEntry = function() {
      var p = $scope.currentScope.$parentNodeScope;
      $scope.currentScope.remove();
      $scope.displayForm(p)
    };

    $scope.down = function() {
      var id = $scope.currentNode.id;
      var p = $scope.currentScope.$parentNodeScope.$modelValue;
      var ind = p.nodes.length;
      for (var i = 0; i < p.nodes.length; i++) {
        if (p.nodes[i].id == id) ind = i;
      }
      if (ind < p.nodes.length - 1) {
        var tmp = p.nodes[ind];
        p.nodes[ind] = p.nodes[ind + 1];
        p.nodes[ind + 1] = tmp;
      }
    };

    $scope.up = function() {
      var id = $scope.currentNode.id;
      var p = $scope.currentScope.$parentNodeScope.$modelValue;
      var ind = -1;
      for (var i = 0; i < p.nodes.length; i++) {
        if (p.nodes[i].id == id) ind = i;
      }
      if (ind > 0) {
        var tmp = p.nodes[ind];
        p.nodes[ind] = p.nodes[ind - 1];
        p.nodes[ind - 1] = tmp;
      }
    };

    /* Leaf title management */
    $scope.translateTitle = function(node) {
      return $translator.translateField(node, 'title');
    };

    $scope.translateP = $translator.translateP;
    $scope.translate = $translator.translate;

    /* test if value is in select */
    $scope.inSelect = function(value) {
      for (var i = 0; i < $scope.currentNode.select.length; i++) {
        if ($scope.currentNode.select[i].k == value) return true;
      }
      return false;
    }

    /* This is for rule form: title = comment if defined, else title = re */
    $scope.changeRuleTitle = function(node) {
      if (node.comment.length > 0) {
        node.title = node.comment;
      } else {
        node.title = node.re;
      }
    }

    /* Node opening
     */

    /* authParams mechanism: show used auth modules only (launched by stoggle) */
    $scope.filters = {};
    $scope.execFilters = function(scope) {
      scope = scope ? scope : $scope;
      for (var filter in $scope.filters) {
        if ($scope.filters.hasOwnProperty(filter)) {
          filterFunctions[filter](scope, $q, $scope.filters[filter]);
        }
      }
    };

    /* To avoid binding all the tree, nodes are pushed in DOM only when opened */
    $scope.stoggle = function(scope) {
      var node = scope.$modelValue;
      _stoggle(node);
      scope.toggle();
    };
    var _stoggle = function(node) {
      ['nodes', 'nodes_cond'].forEach(function(n) {
        if (node['_' + n]) {
          node[n] = [];
          node['_' + n].forEach(function(a) {
            node[n].push(a);
          });
          delete node['_' + n];
        }
      });
      /* Call execFilter for authParams */
      if (node._nodes_filter) {
        if (node.nodes) {
          node.nodes.forEach(function(n) {
            n.onChange = $scope.execFilters
          });
        }
        $scope.filters[node._nodes_filter] = node;
        $scope.execFilters();
      }
    };

    /* Simple toggle management */
    $scope.toggle = function(scope) {
      scope.toggle();
    };

    /*
    $scope.collapseAll = function() {
      var scope = getRootNodesScope();
      scope.collapseAll();
    };

    $scope.expandAll = function() {
      var scope = getRootNodesScope();
      scope.expandAll();
    };*/

    /* cnodes management: hash keys/values are loaded when parent node is opened */
    $scope.download = function(scope) {
      var node = scope.$modelValue;
      return _download(node);
    };
    var _download = function(node) {
      var d = $q.defer();
      d.notify('Trying to get datas');
      $scope.waiting = true;
      $http.get(confPrefix + $scope.currentCfg.cfgNum + '/' + node.cnodes).then(function(response) {
        var data = response.data;
        /* Manage datas errors */
        if (!data) {
          d.reject('Empty response from server');
        } else if (data.error) {
          if (data.error.match(/setDefault$/)) {
            if (node['default']) {
              node.nodes = node['default'].slice(0);
            } else node.nodes = [];
            delete node.cnodes;
            d.resolve('Set data to default value');
          } else d.reject('Server return an error: ' + data.error);

          /* Store datas */
        } else {
          delete node.cnodes;
          if (!node.type) {
            node.type = 'keyTextContainer';
          }
          node.nodes = [];
          /* TODO: try/catch */
          data.forEach(function(a) {
            if (a.template) {
              a._nodes = templates(a.template, a.title);
            }
            node.nodes.push(a);
          });
          d.resolve('OK');
        }
        $scope.waiting = false;
      },
      function(response) {
        readError(response);
        d.reject('');
      });
      return d.promise;
    };

    $scope.openCnode = function(scope) {
      $scope.download(scope).then(function() {
        scope.toggle();
      });
    }

    var setHelp = function(scope) {
      while (!scope.$modelValue.help && scope.$parentNodeScope) {
        scope = scope.$parentNodeScope;
      }
      $scope.helpUrl = scope.$modelValue.help || 'start.html#configuration';
    }

    /* Form management
     *
     * `currentNode` contains the last select node
     *
     * method `diplayForm()`:
     *  - set the `form` property to the name of the form to download
     *    (`text` by default or `home` for node without `type` property)
     *  - launch getKeys to set `node.data`
     *  - hide tree when in XS size
     */
    $scope.displayForm = function(scope) {
      var node = scope.$modelValue;
      if (node.cnodes) $scope.download(scope);
      if (node._nodes) $scope.stoggle(scope);
      $scope.currentNode = node;
      $scope.currentScope = scope;
      var f;
      if (node.type) {
        f = node.type;
      } else {
        f = 'text';
      }
      if (node.nodes || node._nodes || node.cnodes) {
        $scope.form = f != 'text' ? f : 'mini';
      } else {
        $scope.form = f;
        /* Get datas */
        $scope.getKey(node);
        /* Hide tree in XS size */
      }
      if (node.type && node.type == 'simpleInputContainer') {
        node.nodes.forEach(function(n) {
          $scope.getKey(n);
        });
      }
      $scope.showT = false;
      setHelp(scope);
    };

    $scope.keyWritable = function(scope) {
      var node = scope.$modelValue;
      return node.type && node.type.match(/^(authChoice|keyText|virtualHost|rule|menuCat|menuApp|samlAttribute)$/) ? true : false;
    }

    /* RSA keys generation */
    $scope.newRSAKey = function() {
      $scope.showModal('password.html').then(function() {
        $scope.waiting = true;
        var currentNode = $scope.currentNode;
        var password = $scope.result;
        $http.post(confPrefix + '/newRSAKey', {
          password: password
        }).then(function(response) {
          var data = response.data;
          currentNode.data[0].data = data['private'];
          currentNode.data[1].data = password;
          currentNode.data[2].data = data['public'];
          $scope.waiting = false;
        },
        readError);
      },
      function() {
        console.log('New key cancelled');
      });
    }

    $scope.newRSAKeyNoPassword = function() {
      $scope.waiting = true;
      var currentNode = $scope.currentNode;
      $http.post(confPrefix + '/newRSAKey', {
        password: ''
      }).then(function(response) {
        var data = response.data;
        currentNode.data[0].data = data['private'];
        currentNode.data[1].data = data['public'];
        $scope.waiting = false;
      },
      readError);
    }

    /* method `getKey()`:
     *  - return a promise with the data:
     *    - from node when set
     *    - after downloading else
     */
    $scope.getKey = function(node) {
      var d = $q.defer();
      if (!node.data) {
        $scope.waiting = true;
        if (node.get && typeof(node.get) == 'object') {
          node.data = [];
          var tmp = [];
          for (var i = 0; i < node.get.length; i++) {
            node.data[i] = ({
              title: node.get[i],
              id: node.get[i]
            });
            tmp.push($scope.getKey(node.data[i]));
          };
          $q.all(tmp).then(function() {
            d.resolve(node.data);
          },
          function(response) {
            d.reject(e);
            $scope.waiting = false;
          });
        } else {
          $http.get(confPrefix + $scope.currentCfg.cfgNum + '/' + (node.get ? node.get : node.title)).then(function(response) {
            /* Set default value if response is null or if asked by server */
            var data = response.data;
            if ((data.value === null || (data.error && data.error.match(/setDefault$/))) && node['default'] !== null) {
              node.data = node['default'];
            } else {
              node.data = data.value;
            }
            /* Cast int as int (remember that booleans are int for Perl) */
            if (node.type && node.type.match(/^(int|bool|trool)$/)) {
              node.data = parseInt(node.data);
              /* Split SAML types */
            } else if (node.type && node.type.match(/^(saml(Service|Assertion)|blackWhiteList)$/) && !(typeof node.data === 'object')) {
              node.data = node.data.split(';');
            }
            $scope.waiting = false;
            d.resolve(node.data);
          },
          function(response) {
            d.reject(e);
            readError(response);
          });
        }
      } else {
        d.resolve(node.data);
      }
      return d.promise;
    };

    /* function `pathEvent(event, next; current)`:
     * Called when $location.path() change, launch getCfg() with the new
     * configuration number
     */
    var pathEvent = function(event, next, current) {
      var n = next.match(new RegExp('#/confs/(latest|[0-9]+)'));
      if (n === null) {
        $location.path('/confs/latest');
      } else {
        console.log('Trying to get cfg number ' + n[1]);
        $scope.getCfg(n[1]);
      }
    };
    $scope.$on('$locationChangeSuccess', pathEvent);

    /* function `getCfg(n)
     * Download configuration metadatas
     */
    $scope.getCfg = function(n) {
      if ($scope.currentCfg.cfgNum != n) {
        $http.get(confPrefix + n).then(function(response) {
          var data = response.data;
          $scope.currentCfg = data;
          var d = new Date($scope.currentCfg.cfgDate * 1000);
          $scope.currentCfg['date'] = d.toLocaleString();
          console.log('Metadatas of cfg ' + n + ' loaded');
          $location.path('/confs/' + n);
          $scope.init();
        },
        function(response) {
          readError(response).then(function() {
            $scope.currentCfg.cfgNum = 0;
            $scope.init();
          });
        });
      } else {
        $scope.waiting = false;
      }
    };

    /* method `getLanguage(lang)`
     * Launch init() after setting current language
     */
    $scope.getLanguage = function(lang) {
      $scope.lang = lang;
      // Force reload home
      $scope.form = 'white';
      $scope.init();
      $scope.showM = false;
    }

    /* Initialization */

    /* Load JSON files:
     *  - struct.json: the main tree
     *  - languages/<lang>.json: the chosen language datas
     */
    $scope.init = function() {
      var tmp;
      $scope.waiting = true;
      $scope.data = [];
      $scope.confirmNeeded = false;
      $scope.forceSave = false;
      $q.all([
      $translator.init($scope.lang), $http.get(staticPrefix + "struct.json").then(function(response) {
        tmp = response.data;
        console.log("Structure loaded");
      })]).then(function() {
        console.log("Starting structure binding");
        $scope.data = tmp;
        tmp = null;
        if ($scope.currentCfg.cfgNum != 0) {
          setScopeVars($scope);
        }
        else {
          $scope.message = {
            title: 'emptyConf',
            message: '__zeroConfExplanations__'
          };
          $scope.showModal('message.html');
        }
        $scope.form = 'home';
        $scope.waiting = false;
      },
      readError);
    };
    var c = $location.path().match(new RegExp('^/confs/(latest|[0-9]+)'));
    if (!c) {
      console.log("Redirecting to /confs/latest");
      $location.path('/confs/latest');
    }

    /* File form function */
    $scope.replaceContentByUrl = function(node, url) {
      $scope.waiting = true;
      $http.post(scriptname + "prx", {
        url: url
      }).then(function(response) {
        node.data = response.data.content;
        $scope.waiting = false;
      },
      readError);
    }
    $scope.replaceContent = function(node, $fileContent) {
      node.data = $fileContent;
    };

    /* Import Filesaver.js saveAs() */
    $scope.saveAs = function(content, type, filename) {
      saveAs(new Blob([content], {
        type: type
      }), filename);
    };

    /* Save as pem, text */
    $scope.saveAsPem = function(cs, scope) {
      scope.saveAs(cs.data[0].data + "\n" + cs.data[2].data, 'application/x-pem-file', cs.title + ".pem");
    };
    $scope.saveAsText = function(cs, scope) {
      scope.saveAs(cs.data, 'text/plain', cs.title + ".txt");
    };
  }]);

})();