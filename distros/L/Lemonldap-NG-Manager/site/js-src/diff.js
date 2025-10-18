/*
diff.html script
*/
var llapp;

llapp = angular.module('llngConfDiff', ['ui.tree', 'ui.bootstrap', 'llApp', 'ngCookies'], [
  '$rootScopeProvider',
  function($rootScopeProvider) {
    return $rootScopeProvider.digestTtl(15);
  }
]);

llapp.controller('DiffCtrl', [
  '$scope',
  '$http',
  '$q',
  '$translator',
  '$location',
  function($scope,
    $http,
    $q,
    $translator,
    $location) {
    var buildTree,
      getCfg,
      init,
      pathEvent,
      readDiff,
      reverseTree,
      toNodes;
    $scope.links = links;
    $scope.menulinks = menulinks;
    $scope.staticPrefix = staticPrefix;
    $scope.scriptname = scriptname;
    //$scope.formPrefix = formPrefix
    $scope.availableLanguages = availableLanguages;
    $scope.waiting = true;
    $scope.showM = false;
    $scope.cfg = [];
    $scope.data = {};
    $scope.currentNode = null;
    // Import translations functions
    $scope.translateTitle = function(node) {
      return $translator.translateField(node,
        'title');
    };
    $scope.translateP = $translator.translateP;
    $scope.translate = $translator.translate;
    $scope.toggle = function(scope) {
      return scope.toggle();
    };
    $scope.stoggle = function(scope,
      node) {
      $scope.currentNode = node;
      return scope.toggle();
    };
    // Handle menu items
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
            console.warn('Unknown action type', typeof button.action);
        }
      }
      return $scope.showM = false;
    };
    // Function to change interface language
    $scope.getLanguage = function(lang) {
      $scope.lang = lang;
      init();
      return $scope.showM = false;
    };
    // function `getCfg(b,n)`:
    // Download configuration metadatas

    //@param b local conf (0 or 1)
    //@param n cfgNumber
    getCfg = function(b, n) {
      var d;
      d = $q.defer();
      if (($scope.cfg[b] == null) || $scope.cfg[b] !== n) {
        $http.get(`${confPrefix}${n}`).then(function(response) {
            var date;
            if (response && response.data) {
              $scope.cfg[b] = response.data;
              date = new Date(response.data.cfgDate * 1000);
              $scope.cfg[b].date = date.toLocaleString();
              console.debug(`Metadatas of cfg ${n} loaded`);
              return d.resolve('OK');
            } else {
              return d.reject(response);
            }
          },
          function(response) {
            return d.reject('NOK');
          });
      } else {
        d.resolve();
      }
      return d.promise;
    };
    // Intialization function
    // Simply set $scope.waiting to false during $translator and tree root
    // initialization
    init = function() {
      $scope.message = null;
      $scope.currentNode = null;
      $q.all([
        $translator.init($scope.lang),
        $http.get(`${staticPrefix}reverseTree.json`).then(function(response) {
          response.data;
          console.debug("Structure loaded");
        })
      ]).then(function() {
        $q.defer();
        return $http.get(`${scriptname}diff/${$scope.cfg[0].cfgNum}/${$scope.cfg[1].cfgNum}`).then(function(response) {
            var data;
            data = [];
            data = readDiff(response.data[0], response.data[1]);
            $scope.data = buildTree(data);
            $scope.message = '';
            return $scope.waiting = false;
          },
          function(response) {
            return $scope.message = `${$scope.translate('error')} : ${response.statusLine}`;
          });
      });
      // Colorized link
      $scope.activeModule = "conf";
      return $scope.myStyle = {
        color: '#ffb84d'
      };
    };
    readDiff = function(c1,
      c2,
      tr = true) {
      var k,
        res,
        tmp,
        v;
      res = [];
      for (k in c1) {
        v = c1[k];
        if (tr) {
          tmp = {
            title: $scope.translate(k),
            id: k
          };
        } else {
          tmp = {
            title: k
          };
        }
        if (!k.match(/^cfg(?:Num|Log|Author(?:IP)?|Date)$/)) {
          if ((v != null) && typeof v === 'object') {
            if (v.constructor === 'array') {
              tmp.oldvalue = v;
              tmp.newvalue = c2[k];
            } else if (typeof c2[k] === 'object') {
              tmp.nodes = readDiff(c1[k],
                c2[k],
                false);
            } else {
              tmp.oldnodes = toNodes(v,
                'old');
            }
          } else {
            tmp.oldvalue = v;
            tmp.newvalue = c2[k];
          }
          res.push(tmp);
        }
      }
      for (k in c2) {
        v = c2[k];
        if (!((k.match(/^cfg(?:Num|Log|Author(?:IP)?|Date)$/)) || (c1[k] != null))) {
          if (tr) {
            tmp = {
              title: $scope.translate(k),
              id: k
            };
          } else {
            tmp = {
              title: k
            };
          }
          if ((v != null) && typeof v === 'object') {
            if (v.constructor === 'array') {
              tmp.newvalue = v;
            } else {
              tmp.newnodes = toNodes(v, 'new');
            }
          } else {
            tmp.newvalue = v;
          }
          res.push(tmp);
        }
      }
      return res;
    };
    toNodes = function(c,
      s) {
      var k,
        res,
        tmp,
        v;
      res = [];
      for (k in c) {
        v = c[k];
        tmp = {
          title: k
        };
        if (typeof v === 'object') {
          if (v.constructor === 'array') {
            tmp[`${s}value`] = v;
          } else {
            tmp[`${s}nodes`] = toNodes(c[k],
              s);
          }
        } else {
          tmp[`${s}value`] = v;
        }
        res.push(tmp);
      }
      return res;
    };
    reverseTree = [];
    buildTree = function(data) {
      var elem,
        found,
        i,
        j,
        l,
        len,
        len1,
        len2,
        m,
        n,
        node,
        offset,
        path,
        res;
      if (reverseTree == null) {
        return data;
      }
      res = [];
      for (j = 0, len = data.length; j < len; j++) {
        elem = data[j];
        offset = res;
        path = reverseTree[elem.id] != null ? reverseTree[elem.id].split('/') : '';
        for (l = 0, len1 = path.length; l < len1; l++) {
          node = path[l];
          if (node.length > 0) {
            if (offset.length) {
              found = -1;
              for (i = m = 0, len2 = offset.length; m < len2; i = ++m) {
                n = offset[i];
                if (n.id === node) {
                  //offset = n.nodes
                  found = i;
                }
              }
              if (found !== -1) {
                offset = offset[found].nodes;
              } else {
                offset.push({
                  id: node,
                  title: $scope.translate(node),
                  nodes: []
                });
                offset = offset[offset.length - 1].nodes;
              }
            } else {
              offset.push({
                id: node,
                title: $scope.translate(node),
                nodes: []
              });
              offset = offset[0].nodes;
            }
          }
        }
        offset.push(elem);
      }
      return res;
    };
    $scope.newDiff = function() {
      return $location.path(`/${$scope.cfg[0].cfgNum}/${$scope.cfg[1].cfgNum}`);
    };
    pathEvent = function(event, next, current) {
      var n;
      n = next.match(new RegExp('#!?/(latest|[0-9]+)(?:/(latest|[0-9]+))?$'));
      if (n === null) {
        $location.path('/latest');
      } else {
        $scope.waiting = true;
        $q.all([
          $translator.init($scope.lang),
          $http.get(`${staticPrefix}reverseTree.json`).then(function(response) {
            reverseTree = response.data;
            console.debug("Structure loaded");
          }),
          getCfg(0,
            n[1]),
          n[2] != null ? getCfg(1,
            n[2]) : void 0
        ]).then(function() {
            if (n[2] != null) {
              return init();
            } else {
              if ($scope.cfg[0].prev) {
                $scope.cfg[1] = $scope.cfg[0];
                return getCfg(0, $scope.cfg[1].prev).then(function() {
                  return init();
                });
              } else {
                $scope.data = [];
                return $scope.waiting = false;
              }
            }
          },
          function() {
            $scope.message = $scope.translate('error');
            return $scope.waiting = false;
          });
      }
      return true;
    };
    return $scope.$on('$locationChangeSuccess', pathEvent);
  }
]);