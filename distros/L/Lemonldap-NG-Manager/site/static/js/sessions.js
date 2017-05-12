/* LemonLDAP::NG Sessions Explorer client
 *
 */

(function() {
  'use strict';
  var schemes = {
    "_whatToTrace": [
    function(t, v) {
      return "groupBy=substr(" + t + ",1)";
    },
    function(t, v) {
      return t + "=" + v + "*&groupBy=" + t;
    },
    function(t, v) {
      return t + "=" + v;
    }],
    "ipAddr": [
    function(t, v) {
      return "groupBy=net4(" + t + ",1)";
    },
    function(t, v) {
      return t + "=" + v + ".*&groupBy=net4(" + t + ",2)";
    },
    function(t, v) {
      return t + "=" + v + ".*&groupBy=net4(" + t + ",3)";
    },
    function(t, v) {
      return t + "=" + v + ".*&groupBy=net4(" + t + ",4)";
    },
    function(t, v) {
      return t + "=" + v + '&groupBy=_whatToTrace';
    },
    function(t, v, q) {
      return q.replace(/\&groupBy.*$/, '') + "&_whatToTrace=" + v;
    }],
    "doubleIp": [
    function(t, v) {
      return t;
    },
    function(t, v) {
      return '_whatToTrace=' + v + '&groupBy=ipAddr';
    },
    function(t, v, q) {
      return q.replace(/\&groupBy.*$/, '') + "&ipAddr=" + v;
    }]
  };
  var hiddenAttributes = '_password';
  var categories = [
    ['dateTitle', ['_utime', 'startTime', 'updateTime', '_lastAuthnUTime', '_lastSeen']],
    ['connectionTitle', ['ipAddr', '_timezone', '_url']],
    ['authenticationTitle', ['_session_id', '_user', '_password', 'authenticationLevel']],
    ['modulesTitle', ['_auth', '_userDB', '_passwordDB', '_issuerDB', '_authChoice', '_authMulti', '_userDBMulti']],
    ['saml', ['_idp', '_idpConfKey', '_samlToken', '_lassoSessionDump', '_lassoIdentityDump']],
    ['groups', ['groups', 'hGroups']],
    ['ldap', ['dn']],
    ['BrowserID', ['_browserIdAnswer', '_browserIdAnswerRaw']],
    ['OpenIDConnect', ['OpenIDConnect_IDToken', 'OpenIDConnect_OP', 'OpenIDConnect_access_token']]];
  var menu = {
    'session': [{
      'title': 'deleteSession',
      'icon': 'trash'
    }],
    'home': []
  }

  var llapp = angular.module('llngSessionsExplorer', ['ui.tree', 'ui.bootstrap', 'llApp']);

  llapp.controller('SessionsExplorerCtrl', ['$scope', '$translator', '$location', '$q', '$http', function($scope, $translator, $location, $q, $http) {

    $scope.links = links;
    $scope.menulinks = menulinks;
    $scope.staticPrefix = staticPrefix;
    $scope.scriptname = scriptname;
    $scope.formPrefix = formPrefix;
    $scope.availableLanguages = availableLanguages;
    $scope.waiting = true;
    $scope.showM = false;
    $scope.showT = true;
    $scope.data = [];
    $scope.currentScope = null;
    $scope.currentSession = null;
    $scope.menu = menu;
    $scope.translateP = $translator.translateP;
    $scope.translate = $translator.translate;
    $scope.translateTitle = function(node) {
      return $translator.translateField(node, 'title');
    };
    var sessionType = 'global';

    /* Manage form menu clicks */
    $scope.menuClick = function(button) {
      if (button.popup) {
        window.open(button.popup);
      } else {
        if (!button.action) button.action = button.title;
        //try {
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
        //} catch (e) {
        //  alert("Error: " + e.message);
        //}
      }
      $scope.showM = false;
    };

    $scope.deleteSession = function() {
      $scope.waiting = true;
      $http['delete'](scriptname + "sessions/" + sessionType + "/" + $scope.currentSession.id).then(function(response) {
        $scope.currentSession = null;
        $scope.currentScope.remove();
        $scope.waiting = false;
      },
      function(resp) {
        $scope.currentSession = null;
        $scope.currentScope.remove();
        $scope.waiting = false;
      });
    }

    /* Simple toggle management */
    $scope.stoggle = function(scope) {
      var node = scope.$modelValue;
      if (node.nodes.length == 0) $scope.updateTree(node.value, node.nodes, node.level, node.query);
      scope.toggle();
    };

    $scope.displaySession = function(scope) {
      var transformSession = function(session) {
        /* Private functions */
        var _stToStr = function(s) {
          //TODO
          return s;
        };
        var _insert = function(re, title) {
          var tmp = [];
          var reg = new RegExp(re);
          for (var key in session) {
            if (key.match(reg) && session[key]) {
              tmp.push({
                'title': key,
                'value': session[key]
              });
              delete session[key];
            }
          }
          if (tmp.length > 0) res.push({
            'title': title,
            'nodes': tmp
          });
        };
        var time = session._utime;
        var id = session._session_id;

        /* 1. Transform fields */
        for (var key in session) {
          if (session[key] == null) {
            delete session[key];
            console.log(key + ' ' + session[key]);
          }
          if (session[key] === '') {
            delete session[key];
          } else {
            if (typeof session == 'string' && session[key].match(/; /)) {
              session[key] = session[key].split('; ');
            }
            if (typeof session[key] != 'object') {
              if (hiddenAttributes.match(new RegExp('\b' + key + '\b'))) {
                session[key] = '********'
              } else if (key.match(/^(_utime|_lastAuthnUTime|_lastSeen)$/)) {
                session[key] = $scope.localeDate(session[key]);
              } else if (key.match(/^(startTime|updateTime)$/)) {
                session[key] = _stToStr(session[key]);
              } else if (key.match(/^notification/)) {
                session[key] = $scope.localeDate(session[key]);
              }
            }
          }
        }

        /* 2. Build array */
        var res = [];
        /* 2.1 Classified attributes */
        categories.forEach(function(t) {
          var subres = [],
          category = t[0],
          attrs = t[1];
          attrs.forEach(function(attr) {
            if (session[attr]) {
              subres.push({
                'title': attr,
                'value': session[attr]
              });
              delete session[attr];
            }
          });
          if (subres.length > 0) {
            res.push({
              'title': '__' + category + '__',
              'nodes': subres
            });
          }
        });
        _insert('^_openid', 'OpenID');
        _insert('^notification_(.+)', '__notificationsDone__');
        if (session.loginHistory) {
          var tmp = [];
          if (session.loginHistory.successLogin) {
            session.loginHistory.successLogin.forEach(function(l) {
              tmp.push({
                't': l._utime,
                'title': $scope.localeDate(l._utime),
                'value': 'Success (IP ' + l.ipAddr + ')'
              });
            });
            if (session.loginHistory.failedLogin) session.loginHistory.failedLogin.forEach(function(l) {
              tmp.push({
                't': l._utime,
                'title': $scope.localeDate(l._utime),
                'value': l.error + ' (IP ' + l.ipAddr + ')'
              });
            });
          }
          delete session.loginHistory;
          tmp.sort(function(a, b) {
            return a.t - b.t;
          });
          res.push({
            'title': '__loginHistory__',
            'nodes': tmp
          });
        }
        var tmp = [];
        for (var key in session) {
          tmp.push({
            'title': key,
            'value': session[key]
          });
        }
        /* TODO manage /^_/ */
        tmp.sort(function(a, b) {
          return a.title > b.title ? 1 : a.title < b.title ? -1 : 0;
        });
        res.push({
          'title': '__attributesAndMacros__',
          'nodes': tmp
        });
        return {
          '_utime': time,
          'id': id,
          'nodes': res
        };
      }

      $scope.currentScope = scope;
      var sessionId = scope.$modelValue.session;
      $http.get(scriptname + "sessions/" + sessionType + "/" + sessionId).then(function(response) {
        $scope.currentSession = transformSession(response.data);
      });
      $scope.showT = false;
    }

    $scope.localeDate = function(s) {
      var d = new Date(s * 1000);
      return d.toLocaleString();
    }

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

    /* function `pathEvent(event, next; current)`:
     * Called when $location.path() change, launch getCfg() with the new
     * configuration number
     */
    var pathEvent = function(event, next, current) {
      var n = next.match(/#\/(\w+)/);
      sessionType = 'global';
      if (n === null) {
        $scope.type = '_whatToTrace';
      } else if (n[1].match(/^(persistent)$/)) {
        sessionType = RegExp.$1;
        $scope.type = '_session_uid';
      } else {
        $scope.type = n[1];
      }
      $scope.init();
    }
    $scope.$on('$locationChangeSuccess', pathEvent);

    var autoId = 0;
    $scope.updateTree = function(value, node, level, currentQuery) {
      $scope.waiting = true;
      var query, scheme;
      if (schemes[$scope.type]) {
        scheme = schemes[$scope.type];
      } else {
        scheme = schemes._whatToTrace;
      }
      query = scheme[level]($scope.type, value, currentQuery);

      $http.get(scriptname + "sessions/" + sessionType + "?" + query).then(function(response) {
        var data = response.data;
        if (data.result) {
          data.values.forEach(function(n) {
            autoId++;
            n.id = 'node' + autoId;
            if (level < scheme.length - 1) {
              n.nodes = [];
              n.level = level + 1;
              n.query = query;
            }
            node.push(n);
          });
          if (value === '') $scope.total = data.total;
        }
        $scope.waiting = false;
      },
      function(resp) {
        $scope.waiting = false;
      });
    };

    $scope.init = function() {
      var tmp;
      $scope.waiting = true;
      $scope.data = [];
      $q.all([
      $translator.init($scope.lang), $scope.updateTree('', $scope.data, 0)]).then(function() {
        $scope.waiting = false;
      },
      function(j, e) {
        $scope.waiting = false;
      });
    };

    var c = $location.path().match(/^\/(\w+)/);
    $scope.type = c ? c[1] : '_whatToTrace';
  }]);
})();
