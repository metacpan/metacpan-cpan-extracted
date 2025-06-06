/*
LemonLDAP::NG Manager client

This is the main app file. Other are:
 - struct.json and js/confTree.js that contains the full tree
 - translate.json that contains the keywords translation

This file contains:
 - the AngularJS controller
*/
var llapp;

llapp = angular.module('llngManager', ['ui.tree', 'ui.bootstrap', 'llApp', 'ngCookies']);

/*
Main AngularJS controller
*/
llapp.controller('TreeCtrl', [
  '$scope',
  '$http',
  '$location',
  '$q',
  '$uibModal',
  '$translator',
  '$cookies',
  '$htmlParams',
  function($scope,
  $http,
  $location,
  $q,
  $uibModal,
  $translator,
  $cookies,
  $htmlParams) {
    var _checkSaveResponse,
  _download,
  _getAll,
  _stoggle,
  c,
  idinc,
  pathEvent,
  readError,
  setDefault,
  setHelp;
    $scope.links = window.links;
    $scope.menu = $htmlParams.menu;
    $scope.menulinks = window.menulinks;
    $scope.staticPrefix = window.staticPrefix;
    $scope.formPrefix = window.formPrefix;
    $scope.availableLanguages = window.availableLanguages;
    $scope.waiting = true;
    $scope.showM = false;
    $scope.showT = false;
    $scope.form = 'home';
    $scope.currentCfg = {};
    $scope.confPrefix = window.confPrefix;
    $scope.message = {};
    $scope.result = '';
    // Import translations functions
    $scope.translateTitle = function(node) {
      return $translator.translateField(node,
  'title');
    };
    $scope.translateP = $translator.translateP;
    $scope.translate = $translator.translate;
    // HELP DISPLAY
    $scope.helpUrl = 'start.html#configuration';
    $scope.setShowHelp = function(val) {
      var d;
      if (val == null) {
        val = !$scope.showH;
      }
      $scope.showH = val;
      d = new Date(Date.now());
      d.setFullYear(d.getFullYear() + 1);
      return $cookies.put('showhelp',
  (val ? 'true' : 'false'),
  {
        "expires": d
      });
    };
    $scope.showH = $cookies.get('showhelp') === 'false' ? false : true;
    if ($scope.showH == null) {
      $scope.setShowHelp(true);
    }
    // INTERCEPT AJAX ERRORS
    readError = function(response) {
      var e,
  j;
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
        console.log('Authentication needed');
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
    $scope.showModal = function(tpl,
  init) {
      var d,
  modalInstance;
      modalInstance = $uibModal.open({
        templateUrl: tpl,
        controller: 'ModalInstanceCtrl',
        size: 'lg',
        resolve: {
          elem: function() {
            return function(s) {
              return $scope[s];
            };
          },
          set: function() {
            return function(f,
  s) {
              return $scope[f] = s;
            };
          },
          init: function() {
            return init;
          }
        }
      });
      d = $q.defer();
      modalInstance.result.then(function(msgok) {
        $scope.message = {
          title: '',
          message: '',
          items: []
        };
        return d.resolve(msgok);
      },
  function(msgnok) {
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
    $scope.menuClick = function(button) {
      if (button.popup) {
        window.open(button.popup);
      } else {
        if (!button.action) {
          button.action = button.title;
        }
        switch (typeof button.action) {
          case 'function':
            button.action($scope.currentNode,
  $scope);
            break;
          case 'string':
            $scope[button.action]();
            break;
          default:
            console.log(typeof button.action);
        }
      }
      return $scope.showM = false;
    };
    // Display main form
    $scope.home = function() {
      $scope.form = 'home';
      return $scope.showM = false;
    };
    // SAVE FUNCTIONS

    // Private method called by $scope.save()
    _checkSaveResponse = function(data) {
      var m;
      $scope.message = {
        title: '',
        message: '',
        items: [],
        itemsE: [],
        itemsNC: [],
        itemsW: []
      };
      if (data.needConfirm) {
        $scope.confirmNeeded = true;
      }
      if (data.message) {
        $scope.message.message = data.message;
      }
      // Sort messages
      if (data.details) {
        for (m in data.details) {
          if (m !== '__changes__') {
            if (m === '__needConfirmation__') {
              $scope.message.itemsNC.push({
                message: m,
                items: data.details[m]
              });
              console.log('NeedConfirmation:',
  $scope.message.itemsNC);
            } else if (m === '__warnings__') {
              $scope.message.itemsW.push({
                message: m,
                items: data.details[m]
              });
              console.log('Warnings:',
  $scope.message.itemsW);
            } else {
              $scope.message.itemsE.push({
                message: m,
                items: data.details[m]
              });
              console.log('Errors:',
  $scope.message.itemsE);
            }
          }
        }
        $scope.message.items = $scope.message.itemsE.concat($scope.message.itemsNC.concat($scope.message.itemsW));
      }
      $scope.waiting = false;
      if (data.result === 1) {
        // Force reloading page
        $location.path('/confs/');
        $scope.message.title = 'successfullySaved';
      } else {
        $scope.message.title = 'saveReport';
      }
      return $scope.showModal('message.html');
    };
    // Download raw conf
    $scope.downloadConf = function() {
      return window.open($scope.confPrefix + $scope.currentCfg.cfgNum + '?full=1');
    };
    // Download OIDC metadata
    $scope.downloadOidcMetadata = function() {
      return window.open($scope.confPrefix + $scope.currentCfg.cfgNum + '?oidcMetadata=1');
    };
    // Download SAML metadata
    $scope.downloadSamlMetadata = function() {
      return window.open($scope.confPrefix + $scope.currentCfg.cfgNum + '?samlMetadata=1');
    };
    // Main save function
    $scope.save = function() {
      $scope.showModal('save.html').then(function() {
        $scope.waiting = true;
        $scope.data.push({
          id: "cfgLog",
          title: "cfgLog",
          data: $scope.result ? $scope.result : ''
        });
        return $http.post(`${window.confPrefix}?cfgNum=${$scope.currentCfg.cfgNum}&cfgDate=${$scope.currentCfg.cfgDate}${$scope.forceSave ? "&force=1" : ''}`,
  $scope.data).then(function(response) {
          $scope.data.pop();
          return _checkSaveResponse(response.data);
        },
  function(response) {
          readError(response);
          return $scope.data.pop();
        });
      },
  function() {
        return console.log('Saving canceled');
      });
      return $scope.showM = false;
    };
    // Raw save function
    $scope.saveRawConf = function($fileContent) {
      $scope.waiting = true;
      return $http.post(`${window.confPrefix}/raw`,
  $fileContent).then(function(response) {
        return _checkSaveResponse(response.data);
      },
  readError);
    };
    // Restore raw conffunction
    $scope.restore = function() {
      $scope.currentNode = null;
      return $scope.form = 'restore';
    };
    // Cancel save function
    $scope.cancel = function() {
      $scope.currentNode.data = null;
      return $scope.getKey($scope.currentNode);
    };
    // NODES MANAGEMENT
    idinc = 1;
    $scope._findContainer = function() {
      return $scope._findScopeContainer().$modelValue;
    };
    $scope._findScopeContainer = function() {
      var cs;
      cs = $scope.currentScope;
      while (!cs.$modelValue.type.match(/Container$/)) {
        cs = cs.$parentNodeScope;
      }
      return cs;
    };
    $scope._findScopeByKey = function(k) {
      var cs;
      cs = $scope.currentScope;
      while (!(cs.$modelValue.title === k)) {
        cs = cs.$parentNodeScope;
      }
      return cs;
    };
    // Add grant rule entry
    $scope.newGrantRule = function() {
      var node;
      node = $scope._findContainer();
      node.nodes.length;
      return node.nodes.push({
        id: `${node.id}/n${idinc++}`,
        title: 'New rule',
        re: 'Message',
        comment: 'New rule',
        data: '1',
        type: "grant"
      });
    };
    // Add rules entry
    $scope.newRule = function() {
      var l,
  n,
  node;
      node = $scope._findContainer();
      l = node.nodes.length;
      n = l > 0 ? l - 1 : 0;
      return node.nodes.splice(n,
  0,
  {
        id: `${node.id}/n${idinc++}`,
        title: 'New rule',
        re: '^/new',
        comment: 'New rule',
        data: 'accept',
        type: "rule"
      });
    };
    // Add form replay
    $scope.newPost = function() {
      var node;
      node = $scope._findContainer();
      return node.nodes.push({
        id: `${node.id}/n${idinc++}`,
        title: "/absolute/path/to/form",
        data: {},
        type: "post"
      });
    };
    $scope.newPostVar = function() {
      if ($scope.currentNode.data.vars == null) {
        $scope.currentNode.data.vars = [];
      }
      return $scope.currentNode.data.vars.push(['var1',
  '$uid']);
    };
    // Add auth chain entry to authChoice
    $scope.newAuthChoice = function() {
      var node;
      node = $scope._findContainer();
      node.nodes.push({
        id: `${node.id}/n${idinc++}`,
        title: "1_Key",
        data: ['Null',
  'Null',
  'Null'],
        type: "authChoice"
      });
      return $scope.execFilters($scope._findScopeByKey('authParams'));
    };
    // Add hash entry
    $scope.newHashEntry = function() {
      var node;
      node = $scope._findContainer();
      return node.nodes.push({
        id: `${node.id}/n${idinc++}`,
        title: 'new',
        data: '',
        type: "keyText"
      });
    };
    // Menu cat entry
    $scope.newCat = function() {
      var cs;
      cs = $scope.currentScope;
      if (cs.$modelValue.type === 'menuApp') {
        cs = cs.$parentNodeScope;
      }
      return cs.$modelValue.nodes.push({
        id: `${cs.$modelValue.id}/n${idinc++}`,
        title: "New category",
        type: "menuCat",
        nodes: []
      });
    };
    // Menu app entry
    $scope.newApp = function() {
      var cs;
      cs = $scope.currentScope;
      if (cs.$modelValue.type === 'menuApp') {
        cs = cs.$parentNodeScope;
      }
      return cs.$modelValue.nodes.push({
        id: `${cs.$modelValue.id}/n${idinc++}`,
        title: "New application",
        type: "menuApp",
        data: {
          description: "New app description",
          uri: "https://test.example.com/",
          tooltip: "New app tooltip",
          logo: "network.png",
          display: "auto"
        }
      });
    };
    // Combination module
    $scope.newCmbMod = function() {
      var node;
      node = $scope._findContainer();
      node.nodes.push({
        id: `${node.id}/n${idinc++}`,
        title: 'new',
        type: 'cmbModule',
        data: {
          type: 'LDAP',
          for: '0',
          over: []
        }
      });
      return $scope.execFilters($scope._findScopeByKey('authParams'));
    };
    $scope.newSfExtra = function() {
      var node;
      node = $scope._findContainer();
      return node.nodes.push({
        id: `${node.id}/n${idinc++}`,
        title: 'new',
        type: 'sfExtra',
        data: {
          type: '',
          rule: '',
          logo: '',
          level: '',
          label: '',
          over: []
        }
      });
    };
    $scope.newSfOver = function() {
      var d;
      d = $scope.currentNode.data;
      if (!d.over) {
        d.over = [];
      }
      return d.over.push([`new${idinc++}`,
  '']);
    };
    $scope.newCmbOver = function() {
      var d;
      d = $scope.currentNode.data;
      if (!d.over) {
        d.over = [];
      }
      return d.over.push([`new${idinc++}`,
  '']);
    };
    $scope.newChoiceOver = function() {
      var d;
      d = $scope.currentNode.data;
      console.log("data",
  d);
      if (!d[5]) {
        d[5] = [];
      }
      return d[5].push([`new${idinc++}`,
  '']);
    };
    // Add host
    $scope.addHost = function() {
      var cn;
      cn = $scope.currentNode;
      if (!cn.data) {
        cn.data = [];
      }
      return cn.data.push({
        k: "newHost",
        h: [
          {
            "k": "key",
            "v": "uid"
          }
        ]
      });
    };
    // SAML attribute entry
    $scope.addSamlAttribute = function() {
      var node;
      node = $scope._findContainer();
      return node.nodes.push({
        id: `${node.id}/n${idinc++}`,
        title: 'new',
        type: 'samlAttribute',
        data: ['0',
  'New',
  '',
  '']
      });
    };
    // OIDC attribute entry
    $scope.addOidcAttribute = function() {
      var node;
      node = $scope._findContainer();
      return node.nodes.push({
        id: `${node.id}/n${idinc++}`,
        title: 'new',
        type: 'oidcAttribute',
        data: ['',
  'string',
  'auto']
      });
    };
    // Nodes with template
    $scope.addVhost = function() {
      var name;
      name = $scope.domain ? `.${$scope.domain.data}` : '.example.com';
      $scope.message = {
        title: 'virtualHostName',
        field: 'hostname'
      };
      return $scope.showModal('prompt.html',
  name).then(function() {
        var n;
        n = $scope.result;
        if (n) {
          return $scope.addTemplateNode(n,
  'virtualHost');
        }
      });
    };
    $scope.duplicateVhost = function() {
      var name;
      name = $scope.domain ? `.${$scope.domain.data}` : '.example.com';
      $scope.message = {
        title: 'virtualHostName',
        field: 'hostname'
      };
      return $scope.showModal('prompt.html',
  name).then(function() {
        var n;
        n = $scope.result;
        return $scope.duplicateNode(n,
  'virtualHost',
  $scope.currentNode.title);
      });
    };
    $scope.addSamlIDP = function() {
      return $scope.newTemplateNode('samlIDPMetaDataNode',
  'samlPartnerName',
  'idp-example');
    };
    $scope.addSamlSP = function() {
      return $scope.newTemplateNode('samlSPMetaDataNode',
  'samlPartnerName',
  'sp-example');
    };
    $scope.addOidcOp = function() {
      return $scope.newTemplateNode('oidcOPMetaDataNode',
  'oidcOPName',
  'op-example');
    };
    $scope.addOidcRp = function() {
      return $scope.newTemplateNode('oidcRPMetaDataNode',
  'oidcRPName',
  'rp-example');
    };
    $scope.addCasSrv = function() {
      return $scope.newTemplateNode('casSrvMetaDataNode',
  'casPartnerName',
  'srv-example');
    };
    $scope.addCasApp = function() {
      return $scope.newTemplateNode('casAppMetaDataNode',
  'casPartnerName',
  'app-example');
    };
    $scope.newTemplateNode = function(type,
  title,
  init) {
      $scope.message = {
        title: title,
        field: 'name'
      };
      return $scope.showModal('prompt.html',
  init).then(function() {
        var name;
        name = $scope.result;
        if (name) {
          return $scope.addTemplateNode(name,
  type);
        }
      });
    };
    $scope.addTemplateNode = function(name,
  type) {
      var cs,
  t;
      cs = $scope.currentScope;
      while (cs.$modelValue.title !== `${type}s`) {
        cs = cs.$parentNodeScope;
      }
      t = {
        id: `${type}s/new__${name}`,
        title: name,
        type: type,
        nodes: templates(type,
  `new__${name}`)
      };
      setDefault(t.nodes);
      cs.$modelValue.nodes.push(t);
      cs.expand();
      return t;
    };
    setDefault = function(node) {
      var len,
  n,
  o;
      for (o = 0, len = node.length; o < len; o++) {
        n = node[o];
        if (n.cnodes && n.default) {
          delete n.cnodes;
          n._nodes = n.default;
        }
        if (n._nodes) {
          setDefault(n._nodes);
        } else if (n.default || n.default === 0) {
          n.data = n.default;
        }
      }
      return node;
    };
    _getAll = function(node) {
      var d,
  d2;
      d = $q.defer();
      d2 = $q.defer();
      if (node._nodes) {
        _stoggle(node);
        d.resolve();
      } else if (node.cnodes) {
        _download(node).then(function() {
          return d.resolve();
        });
      } else if (node.nodes || node.data) {
        d.resolve();
      } else {
        $scope.getKey(node).then(function() {
          return d.resolve();
        });
      }
      d.promise.then(function() {
        var len,
  n,
  o,
  ref,
  t;
        t = [];
        if (node.nodes) {
          ref = node.nodes;
          for (o = 0, len = ref.length; o < len; o++) {
            n = ref[o];
            t.push(_getAll(n));
          }
        }
        return $q.all(t).then(function() {
          return d2.resolve();
        });
      });
      return d2.promise;
    };
    $scope.duplicateNode = function(name,
  type,
  idkey) {
      var cs;
      cs = $scope.currentScope;
      return _getAll($scope.currentNode).then(function() {
        var t;
        while (cs.$modelValue.title !== `${type}s`) {
          cs = cs.$parentNodeScope;
        }
        t = JSON.parse(JSON.stringify($scope.currentNode).replace(/[*]/g,
  '').replace(new RegExp(idkey,
  'g'),
  'new__' + name));
        t.id = `${type}s/new__${name}`;
        t.title = name;
        cs.$modelValue.nodes.push(t);
        return t;
      });
    };
    $scope.del = function(a,
  i) {
      return a.splice(i,
  1);
    };
    $scope.deleteEntry = function() {
      var p;
      p = $scope.currentScope.$parentNodeScope;
      $scope.currentScope.remove();
      return $scope.displayForm(p);
    };
    $scope.down = function() {
      var i,
  id,
  ind,
  len,
  n,
  o,
  p,
  ref,
  tmp;
      id = $scope.currentNode.id;
      p = $scope.currentScope.$parentNodeScope.$modelValue;
      ind = p.nodes.length;
      ref = p.nodes;
      for (i = o = 0, len = ref.length; o < len; i = ++o) {
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
    $scope.up = function() {
      var i,
  id,
  ind,
  len,
  n,
  o,
  p,
  ref,
  tmp;
      id = $scope.currentNode.id;
      p = $scope.currentScope.$parentNodeScope.$modelValue;
      ind = -1;
      ref = p.nodes;
      for (i = o = 0, len = ref.length; o < len; i = ++o) {
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
    $scope.inSelect = function(value) {
      var len,
  n,
  o,
  ref;
      ref = $scope.currentNode.select;
      for (o = 0, len = ref.length; o < len; o++) {
        n = ref[o];
        if (n.k === value) {
          return true;
        }
      }
      return false;
    };
    // This is for rule form: title = comment if defined, else title = re
    $scope.changeRuleTitle = function(node) {
      return node.title = node.comment.length > 0 ? node.comment : node.re;
    };
    // Node opening

    // authParams mechanism: show used auth modules only (launched by stoggle)
    $scope.filters = {};
    $scope.execFilters = function(scope) {
      var filter,
  func,
  ref;
      scope = scope ? scope : $scope;
      ref = $scope.filters;
      for (filter in ref) {
        func = ref[filter];
        if ($scope.filters.hasOwnProperty(filter)) {
          return window.filterFunctions[filter](scope,
  $q,
  func);
        }
      }
      return false;
    };
    // To avoid binding all the tree, nodes are pushed in DOM only when opened
    $scope.stoggle = function(scope) {
      var node;
      node = scope.$modelValue;
      _stoggle(node);
      return scope.toggle();
    };
    _stoggle = function(node) {
      var a,
  len,
  len1,
  len2,
  n,
  o,
  q,
  r,
  ref,
  ref1,
  ref2;
      ref = ['nodes', 'nodes_cond'];
      for (o = 0, len = ref.length; o < len; o++) {
        n = ref[o];
        if (node[`_${n}`]) {
          node[n] = [];
          ref1 = node[`_${n}`];
          for (q = 0, len1 = ref1.length; q < len1; q++) {
            a = ref1[q];
            node[n].push(a);
          }
          delete node[`_${n}`];
        }
      }
      // Call execFilter for authParams
      if (node._nodes_filter) {
        if (node.nodes) {
          ref2 = node.nodes;
          for (r = 0, len2 = ref2.length; r < len2; r++) {
            n = ref2[r];
            n.onChange = $scope.execFilters;
          }
        }
        $scope.filters[node._nodes_filter] = node;
        return $scope.execFilters();
      }
    };
    // Simple toggle management
    $scope.toggle = function(scope) {
      return scope.toggle();
    };
    // cnodes management: hash keys/values are loaded when parent node is opened
    $scope.download = function(scope) {
      var node;
      node = scope.$modelValue;
      return _download(node);
    };
    _download = function(node) {
      var d,
  uri;
      d = $q.defer();
      d.notify('Trying to get datas');
      $scope.waiting = true;
      console.log(`Trying to get key ${node.cnodes}`);
      uri = encodeURI(node.cnodes);
      $http.get(`${window.confPrefix}${$scope.currentCfg.cfgNum}/${uri}`).then(function(response) {
        var a,
  data,
  len,
  o;
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
          for (o = 0, len = data.length; o < len; o++) {
            a = data[o];
            if (a.template) {
              a._nodes = templates(a.template,
  a.title);
            }
            node.nodes.push(a);
            if (a.type.match(/^rule$/)) {
              console.log("Parse rule AuthnLevel as integer");
              if (a.level && typeof a.level === 'string') {
                a.level = parseInt(a.level,
  10);
              }
            }
          }
          d.resolve('OK');
        }
        return $scope.waiting = false;
      },
  function(response) {
        readError(response);
        return d.reject('');
      });
      return d.promise;
    };
    $scope.openCnode = function(scope) {
      return $scope.download(scope).then(function() {
        return scope.toggle();
      });
    };
    setHelp = function(scope) {
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

    $scope.displayForm = function(scope) {
      var f,
  len,
  n,
  node,
  o,
  ref;
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
        for (o = 0, len = ref.length; o < len; o++) {
          n = ref[o];
          $scope.getKey(n);
        }
      }
      $scope.showT = false;
      return setHelp(scope);
    };
    $scope.keyWritable = function(scope) {
      var node;
      node = scope.$modelValue;
      // regexp-assemble of:
      //  authChoice
      //  cmbModule
      //  keyText
      //  menuApp
      //  menuCat
      //  rule
      //  oidcAttribute
      //  samlAttribute
      //  samlIDPMetaDataNode
      //  samlSPMetaDataNode
      //  sfExtra
      //  virtualHost
      if (node.type && node.type.match(/^(?:s(?:aml(?:(?:ID|S)PMetaDataNod|Attribut)e|fExtra)|oidcAttribute|(?:(?:cmbMod|r)ul|authChoic)e|(?:virtualHos|keyTex)t|menu(?:App|Cat))$/)) {
        return true;
      } else {
        return false;
      }
    };
    // Send test Email
    $scope.sendTestMail = function() {
      $scope.message = {
        title: 'sendTestMail',
        field: 'dest'
      };
      return $scope.showModal('prompt.html').then(function() {
        var dest;
        $scope.result;
        $scope.waiting = true;
        dest = $scope.result;
        return $http.post(`${window.confPrefix}/sendTestMail`,
  {
          "dest": dest
        }).then(function(response) {
          var error,
  success;
          success = response.data.success;
          error = response.data.error;
          $scope.waiting = false;
          if (success) {
            $scope.message = {
              title: 'ok',
              message: '__sendTestMailSuccess__',
              items: []
            };
          } else {
            $scope.message = {
              title: 'error',
              message: error,
              items: []
            };
          }
          return $scope.showModal('message.html');
        },
  readError);
      },
  function() {
        return console.log('Error sending test email');
      });
    };
    // RSA keys generation
    $scope.newCertificate = function() {
      return $scope.showModal('password.html').then(function() {
        var currentNode,
  password;
        $scope.waiting = true;
        currentNode = $scope.currentNode;
        password = $scope.result;
        return $http.post(`${window.confPrefix}/newCertificate`,
  {
          "password": password
        }).then(function(response) {
          currentNode.data[0].data = response.data.private;
          currentNode.data[1].data = password;
          currentNode.data[2].data = response.data.public;
          return $scope.waiting = false;
        },
  readError);
      },
  function() {
        return console.log('New key cancelled');
      });
    };
    $scope.newEcKeys = function() {
      var currentNode;
      $scope.waiting = true;
      currentNode = $scope.currentNode;
      return $http.post(`${window.confPrefix}/newEcKeys`,
  {
        "password": ''
      }).then(function(response) {
        var i,
  o;
        for (i = o = 0; o <= 3; i = ++o) {
          currentNode.data[i + 4].data = currentNode.data[i].data;
        }
        currentNode.data[0].data = response.data.private;
        currentNode.data[1].data = response.data.public;
        currentNode.data[2].data = response.data.hash;
        currentNode.data[3].data = 'EC';
        return $scope.waiting = false;
      },
  readError);
    };
    $scope.newCertificateNoPassword = function() {
      var currentNode;
      $scope.waiting = true;
      currentNode = $scope.currentNode;
      return $http.post(`${window.confPrefix}/newCertificate`,
  {
        "password": ''
      }).then(function(response) {
        var i,
  o;
        for (i = o = 0; o <= 3; i = ++o) {
          currentNode.data[i + 4].data = currentNode.data[i].data;
        }
        currentNode.data[0].data = response.data.private;
        currentNode.data[1].data = response.data.public;
        currentNode.data[2].data = response.data.hash;
        currentNode.data[3].data = 'RSA';
        return $scope.waiting = false;
      },
  readError);
    };
    $scope.newRSAKey = function() {
      return $scope.showModal('password.html').then(function() {
        var currentNode,
  password;
        $scope.waiting = true;
        currentNode = $scope.currentNode;
        password = $scope.result;
        return $http.post(`${window.confPrefix}/newRSAKey`,
  {
          "password": password
        }).then(function(response) {
          currentNode.data[0].data = response.data.private;
          currentNode.data[1].data = password;
          currentNode.data[2].data = response.data.public;
          return $scope.waiting = false;
        },
  readError);
      },
  function() {
        return console.log('New key cancelled');
      });
    };
    // - return a promise with the data:
    // 	- from node when set
    // 	- after downloading else

    $scope.getKey = function(node) {
      var d,
  i,
  len,
  n,
  o,
  ref,
  tmp,
  uri;
      d = $q.defer();
      if (!node.data) {
        $scope.waiting = true;
        if (node.get && typeof node.get === 'object') {
          node.data = [];
          tmp = [];
          ref = node.get;
          for (i = o = 0, len = ref.length; o < len; i = ++o) {
            n = ref[i];
            node.data[i] = {
              title: n,
              id: n
            };
            tmp.push($scope.getKey(node.data[i]));
          }
          $q.all(tmp).then(function() {
            return d.resolve(node.data);
          },
  function(response) {
            d.reject(response.statusLine);
            return $scope.waiting = false;
          });
        } else {
          uri = '';
          if (node.get) {
            console.log(`Trying to get key ${node.get}`);
            uri = encodeURI(node.get);
          } else {
            console.log(`Trying to get title ${node.title}`);
          }
          $http.get(`${window.confPrefix}${$scope.currentCfg.cfgNum}/${node.get ? uri : node.title}`).then(function(response) {
            var data;
            // Set default value if response is null or if asked by server
            data = response.data;
            if ((data.value === null || (data.error && data.error.match(/setDefault$/))) && node['default'] !== null) {
              node.data = node['default'];
            } else {
              node.data = data.value;
            }
            // Cast int as int (remember that booleans are int for Perl)
            if (node.type && node.type.match(/^(bool|trool|boolOrExpr)$/)) {
              if (typeof node.data === 'string' && node.data.match(/^(?:-1|0|1)$/)) {
                node.data = parseInt(node.data,
  10);
              }
            }
            if (node.type && node.type.match(/^int$/)) {
              node.data = parseInt(node.data,
  10);
            }
            if (node.type && node.type.match(/^select$/)) {
              node.data = node.data ? node.data.toString() : '';
            // Split SAML types
            } else if (node.type && node.type.match(/^(saml(Service|Assertion)|blackWhiteList)$/) && !(node.data && typeof node.data === 'object')) {
              node.data = node.data ? node.data.split(';') : [];
            }
            $scope.waiting = false;
            return d.resolve(node.data);
          },
  function(response) {
            readError(response);
            return d.reject(response.status);
          });
        }
      } else {
        d.resolve(node.data);
      }
      return d.promise;
    };
    // function `pathEvent(event, next; current)`:
    // Called when $location.path() change, launch getCfg() with the new
    // configuration number
    pathEvent = function(event,
  next,
  current) {
      var n;
      n = next.match(new RegExp('#!?/confs/(latest|[0-9]+)'));
      if (n === null) {
        return $location.path('/confs/latest');
      } else {
        console.log(`Trying to get cfg number ${n[1]}`);
        return $scope.getCfg(n[1]);
      }
    };
    $scope.$on('$locationChangeSuccess',
  pathEvent);
    // function `getCfg(n)`:
    // Download configuration metadatas
    $scope.getCfg = function(n) {
      if ($scope.currentCfg.cfgNum !== n) {
        return $http.get(`${window.confPrefix}${n}`).then(function(response) {
          var d;
          $scope.currentCfg = response.data;
          d = new Date($scope.currentCfg.cfgDate * 1000);
          $scope.currentCfg.date = d.toLocaleString();
          console.log(`Metadatas of cfg ${n} loaded`);
          $location.path(`/confs/${n}`);
          return $scope.init();
        },
  function(response) {
          return readError(response).then(function() {
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
    $scope.getLanguage = function(lang) {
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
    $scope.init = function() {
      var tmp;
      tmp = null;
      $scope.waiting = true;
      $scope.data = [];
      $scope.confirmNeeded = false;
      $scope.forceSave = false;
      $q.all([
        $translator.init($scope.lang),
        $http.get(`${window.staticPrefix}struct.json`).then(function(response) {
          tmp = response.data;
          return console.log("Structure loaded");
        })
      ]).then(function() {
        console.log("Starting structure binding");
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
        $scope.form = 'home';
        return $scope.waiting = false;
      },
  readError);
      // Colorized link
      $scope.activeModule = "conf";
      return $scope.myStyle = {
        color: '#ffb84d'
      };
    };
    c = $location.path().match(new RegExp('^/confs/(latest|[0-9]+)'));
    if (!c) {
      console.log("Redirecting to /confs/latest");
      $location.path('/confs/latest');
    }
    // File form function
    $scope.replaceContentByUrl = function(node,
  url) {
      $scope.waiting = true;
      return $http.post(window.scriptname + "prx",
  {
        url: url
      }).then(function(response) {
        node.data = response.data.content;
        return $scope.waiting = false;
      },
  readError);
    };
    $scope.replaceContent = function(node,
  $fileContent) {
      return node.data = $fileContent;
    };
    // Import Filesaver.js saveAs()
    $scope.saveAs = function(content,
  type,
  filename) {
      return saveAs(new Blob([content],
  {
        "type": type
      }),
  filename);
    };
    // Save as pem, text,...
    $scope.saveAsPem = function(cs,
  scope) {
      return scope.saveAs(`${cs.data[0].data}\n${cs.data[2].data}`,
  'application/x-pem-file',
  `${cs.title}.pem`);
    };
    return $scope.saveAsText = function(cs,
  scope) {
      return scope.saveAs(cs.data,
  'text/plain',
  `${cs.title}.txt`);
    };
  }
]);
