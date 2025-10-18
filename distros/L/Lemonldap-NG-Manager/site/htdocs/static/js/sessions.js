(function () {
  'use strict';

  /*
   * Sessions explorer
   */
  /*
   * AngularJS application
   */
  var categories, hiddenAttributes, llapp, max, menu, overScheme, schemes;

  // Max number of session to display (see overScheme)
  max = 25;

  // Queries to do each type of display: each array item corresponds to the depth
  // of opened nodes in the tree
  schemes = {
    _whatToTrace: [
    // First level: display 1 letter
    function (t, v) {
      return `groupBy=substr(${t},1)`;
    },
    // Second level (if no overScheme), display usernames
    function (t, v) {
      return `${t}=${v}*&groupBy=${t}`;
    }, function (t, v) {
      return `${t}=${v}`;
    }],
    ipAddr: [function (t, v) {
      return `groupBy=net(${t},16,1)`;
    }, function (t, v) {
      if (!v.match(/:/)) {
        v = v + '.';
      }
      return `${t}=${v}*&groupBy=net(${t},32,2)`;
    }, function (t, v) {
      if (!v.match(/:/)) {
        v = v + '.';
      }
      return `${t}=${v}*&groupBy=net(${t},48,3)`;
    }, function (t, v) {
      if (!v.match(/:/)) {
        v = v + '.';
      }
      return `${t}=${v}*&groupBy=net(${t},128,4)`;
    }, function (t, v) {
      return `${t}=${v}&groupBy=_whatToTrace`;
    }, function (t, v, q) {
      return q.replace(/\&groupBy.*$/, '') + `&_whatToTrace=${v}`;
    }],
    _startTime: [function (t, v) {
      return `groupBy=substr(${t},8)`;
    }, function (t, v) {
      return `${t}=${v}*&groupBy=substr(${t},10)`;
    }, function (t, v) {
      return `${t}=${v}*&groupBy=substr(${t},11)`;
    }, function (t, v) {
      return `${t}=${v}*&groupBy=substr(${t},12)`;
    }, function (t, v) {
      return `${t}=${v}*&groupBy=_whatToTrace`;
    }, function (t, v, q) {
      return q.replace(/\&groupBy.*$/, '') + `&_whatToTrace=${v}`;
    }],
    doubleIp: [function (t, v) {
      return t;
    }, function (t, v) {
      return `_whatToTrace=${v}&groupBy=ipAddr`;
    }, function (t, v, q) {
      return q.replace(/\&groupBy.*$/, '') + `&ipAddr=${v}`;
    }],
    _session_uid: [
    // First level: display 1 letter
    function (t, v) {
      return `groupBy=substr(${t},1)`;
    },
    // Second level (if no overScheme), display usernames
    function (t, v) {
      return `${t}=${v}*&groupBy=${t}`;
    }, function (t, v) {
      return `${t}=${v}`;
    }]
  };

  // When number of children nodes exceeds "max" value and if "overScheme.<type>"
  // is available and does not return "null", a level is added. See
  // "$scope.updateTree" method
  overScheme = {
    _whatToTrace: function (t, v, level, over) {
      // "v.length > over" avoids a loop if one user opened more than "max"
      // sessions
      console.debug('overScheme => level', level, 'over', over);

      // no overScheme when over reached the length of previous result
      if (v.length >= level + over) return null;
      if (level === 1 && v.length > over) {
        return `${t}=${v}*&groupBy=substr(${t},${level + over + 1})`;
      } else {
        return null;
      }
    },
    // Note: IPv4 only
    ipAddr: function (t, v, level, over) {
      console.debug('overScheme => level', level, 'over', over);
      if (level > 0 && level < 4 && !v.match(/^\d+\.\d/) && over < 2) {
        return `${t}=${v}*&groupBy=net(${t},${16 * level + 4 * (over + 1)},${1 + level + over})`;
      } else {
        return null;
      }
    },
    _startTime: function (t, v, level, over) {
      console.debug('overScheme => level', level, 'over', over);
      if (level > 3) {
        return `${t}=${v}*&groupBy=substr(${t},${10 + level + over})`;
      } else {
        return null;
      }
    },
    _session_uid: function (t, v, level, over) {
      console.debug('overScheme => level', level, 'over', over);
      if (level === 1 && v.length > over) {
        return `${t}=${v}*&groupBy=substr(${t},${level + over + 1})`;
      } else {
        return null;
      }
    }
  };
  hiddenAttributes = '_password';

  // Attributes to group in session display
  categories = {
    dateTitle: ['_utime', '_startTime', '_updateTime', '_lastAuthnUTime', '_lastSeen'],
    connectionTitle: ['ipAddr', '_timezone', '_url'],
    authenticationTitle: ['_session_id', '_user', '_password', 'authenticationLevel'],
    modulesTitle: ['_auth', '_userDB', '_passwordDB', '_issuerDB', '_authChoice', '_authMulti', '_userDBMulti', '_2f'],
    saml: ['_idp', '_idpConfKey', '_samlToken', '_lassoSessionDump', '_lassoIdentityDump'],
    groups: ['groups', 'hGroups'],
    ldap: ['dn'],
    OpenIDConnect: ['_oidc_id_token', '_oidc_OP', '_oidc_access_token', '_oidc_refresh_token', '_oidc_access_token_eol', '_oidcConnectedRP', '_oidcConnectedRPIDs'],
    sfaTitle: ['_2fDevices'],
    oidcConsents: ['_oidcConsents']
  };

  // Menu entries
  menu = {
    session: [{
      title: 'deleteSession',
      icon: 'trash'
    }, {
      title: 'globalLogout',
      icon: 'trash'
    }],
    home: []
  };
  llapp = angular.module('llngSessionsExplorer', ['ui.tree', 'ui.bootstrap', 'llApp']);

  // Main controller
  llapp.controller('SessionsExplorerCtrl', ['$scope', '$translator', '$location', '$q', '$http', function ($scope, $translator, $location, $q, $http) {
    var autoId, c, pathEvent, sessionType;
    $scope.links = links;
    $scope.menulinks = menulinks;
    $scope.staticPrefix = staticPrefix;
    $scope.scriptname = scriptname;
    $scope.formPrefix = formPrefix;
    $scope.impPrefix = impPrefix;
    $scope.sessionTTL = sessionTTL;
    $scope.availableLanguages = availableLanguages;
    $scope.waiting = true;
    $scope.showM = false;
    $scope.showT = true;
    $scope.data = [];
    $scope.currentScope = null;
    $scope.currentSession = null;
    $scope.menu = menu;
    // Import translations functions
    $scope.translateP = $translator.translateP;
    $scope.translate = $translator.translate;
    $scope.translateTitle = function (node) {
      return $translator.translateField(node, 'title');
    };
    sessionType = 'global';
    // Handle menu items
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
    // SESSION MANAGEMENT

    // Delete RP Consent
    $scope.deleteOIDCConsent = function (rp, epoch) {
      var items;
      items = document.querySelectorAll(`.data-${epoch}`);
      $scope.waiting = true;
      $http['delete'](`${scriptname}sessions/OIDCConsent/${sessionType}/${$scope.currentSession.id}?rp=${rp}&epoch=${epoch}`).then(function (response) {
        var e, i, len, results;
        $scope.waiting = false;
        results = [];
        for (i = 0, len = items.length; i < len; i++) {
          e = items[i];
          results.push(e.remove());
        }
        return results;
      }, function (resp) {
        return $scope.waiting = false;
      });
      return $scope.showT = false;
    };
    // Delete
    $scope.deleteSession = function () {
      $scope.waiting = true;
      return $http['delete'](`${scriptname}sessions/${sessionType}/${$scope.currentSession.id}`).then(function (response) {
        $scope.currentSession = null;
        $scope.currentScope.remove();
        return $scope.waiting = false;
      }, function (resp) {
        return $scope.waiting = false;
      });
    };
    $scope.globalLogout = function () {
      $scope.waiting = true;
      return $http['post'](`${scriptname}sessions/glogout/${sessionType}/${$scope.currentSession.id}`).then(function (response) {
        $scope.currentSession = null;
        $scope.currentScope.remove();
        return $scope.waiting = false;
      }, function (resp) {
        return $scope.waiting = false;
      });
    };
    // Open node
    $scope.stoggle = function (scope) {
      var node;
      node = scope.$modelValue;
      if (node.nodes.length === 0) {
        $scope.updateTree(node.value, node.nodes, node.level, node.over, node.query, node.count);
      }
      return scope.toggle();
    };
    // Display selected session
    $scope.displaySession = function (scope) {
      var sessionId, transformSession;
      // Private functions

      // Session preparation
      transformSession = function (session) {
        var _insert, array, attr, attrs, category, cv, element, epoch, i, j, k, key, l, len, len1, len2, len3, len4, len5, m, name, o, oidcConsent, p, real, ref, ref1, res, sfDevice, spoof, subres, tab, time, title, tmp, value;
        _insert = function (re, title) {
          var cv, i, key, len, reg, tab, tmp, val, value, vk;
          tmp = [];
          reg = new RegExp(re);
          cv = "";
          for (key in session) {
            value = session[key];
            if (key.match(reg) && value) {
              cv += `${value}:${key},`;
              delete session[key];
            }
          }
          if (cv) {
            cv = cv.replace(/,$/, '');
            tab = cv.split(',');
            tab.sort();
            tab.reverse();
            for (i = 0, len = tab.length; i < len; i++) {
              val = tab[i];
              vk = val.split(':');
              tmp.push({
                title: vk[1],
                value: $scope.localeDate(vk[0])
              });
            }
            return res.push({
              title: title,
              nodes: tmp
            });
          }
        };
        time = session._utime;
        // 1. Replace values if needed
        for (key in session) {
          value = session[key];
          if (!value) {
            delete session[key];
          } else {
            if (typeof session === 'string' && value.match(/; /)) {
              session[key] = value.split('; ');
            }
            if (typeof session[key] !== 'object') {
              if (hiddenAttributes.match(new RegExp('\b' + key + '\b'))) {
                session[key] = '********';
              } else if (key.match(/^(_utime|_lastAuthnUTime|_lastSeen|notification)$/)) {
                session[key] = $scope.localeDate(value);
              } else if (key.match(/^(_startTime|_updateTime)$/)) {
                session[key] = $scope.strToLocaleDate(value);
              }
            }
          }
        }
        res = [];
        // 2. Push session keys in result, grouped by categories
        for (category in categories) {
          attrs = categories[category];
          subres = [];
          for (i = 0, len = attrs.length; i < len; i++) {
            attr = attrs[i];
            if (session[attr]) {
              if (attr === "_2fDevices" && session[attr]) {
                array = JSON.parse(session[attr]);
                if (array.length > 0) {
                  subres.push({
                    title: "type",
                    value: "name",
                    epoch: "date",
                    td: "0"
                  });
                  for (j = 0, len1 = array.length; j < len1; j++) {
                    sfDevice = array[j];
                    for (key in sfDevice) {
                      value = sfDevice[key];
                      if (key === 'type') {
                        title = value;
                      }
                      if (key === 'name') {
                        name = value;
                      }
                      if (key === 'epoch') {
                        epoch = value;
                      }
                    }
                    subres.push({
                      title: title,
                      value: name,
                      epoch: epoch,
                      td: "1"
                    });
                  }
                }
                delete session[attr];
              } else if (session[attr].toString().match(/"rp":\s*"[\w-]+"/)) {
                subres.push({
                  title: "RP",
                  value: "scope",
                  epoch: "date",
                  td: "0"
                });
                array = JSON.parse(session[attr]);
                for (k = 0, len2 = array.length; k < len2; k++) {
                  oidcConsent = array[k];
                  for (key in oidcConsent) {
                    value = oidcConsent[key];
                    if (key === 'rp') {
                      title = value;
                    }
                    if (key === 'scope') {
                      name = value;
                    }
                    if (key === 'epoch') {
                      epoch = value;
                    }
                  }
                  subres.push({
                    title: title,
                    value: name,
                    epoch: epoch,
                    td: "2"
                  });
                }
                delete session[attr];
              } else if (session[attr].toString().match(/\w+/)) {
                subres.push({
                  title: attr,
                  value: session[attr],
                  epoch: ''
                });
                delete session[attr];
              } else {
                delete session[attr];
              }
            } else {
              delete session[attr];
            }
          }
          if (subres.length > 0) {
            res.push({
              title: `__${category}__`,
              nodes: subres
            });
          }
        }
        // 3. Add OpenID and notifications already notified
        _insert('^openid', 'OpenID');
        _insert('^notification_(.+)', '__notificationsDone__');
        // 4. Add session history if exists
        if (session._loginHistory) {
          tmp = [];
          if (session._loginHistory.successLogin) {
            ref = session._loginHistory.successLogin;
            for (m = 0, len3 = ref.length; m < len3; m++) {
              l = ref[m];
              // History custom values
              cv = "";
              for (key in l) {
                value = l[key];
                if (!key.match(/^(_utime|ipAddr|error)$/)) {
                  cv += `, ${key} : ${value}`;
                }
              }
              tab = cv.split(', ');
              tab.sort();
              cv = tab.join(', ');
              tmp.push({
                t: l._utime,
                title: $scope.localeDate(l._utime),
                value: `Success (IP ${l.ipAddr})` + cv
              });
            }
          }
          if (session._loginHistory.failedLogin) {
            ref1 = session._loginHistory.failedLogin;
            for (o = 0, len4 = ref1.length; o < len4; o++) {
              l = ref1[o];
              // History custom values
              cv = "";
              for (key in l) {
                value = l[key];
                if (!key.match(/^(_utime|ipAddr|error)$/)) {
                  cv += `, ${key} : ${value}`;
                }
              }
              tab = cv.split(', ');
              tab.sort();
              cv = tab.join(', ');
              tmp.push({
                t: l._utime,
                title: $scope.localeDate(l._utime),
                value: `Error ${l.error} (IP ${l.ipAddr})` + cv
              });
            }
          }
          delete session._loginHistory;
          tmp.sort(function (a, b) {
            return b.t - a.t;
          });
          res.push({
            title: '__loginHistory__',
            nodes: tmp
          });
        }
        // 5. Other keys (attributes and macros)
        tmp = [];
        for (key in session) {
          value = session[key];
          tmp.push({
            title: key,
            value: value
          });
        }
        tmp.sort(function (a, b) {
          if (a.title > b.title) {
            return 1;
          } else if (a.title < b.title) {
            return -1;
          } else {
            return 0;
          }
        });
        // Sort by real and spoofed attributes
        real = [];
        spoof = [];
        for (p = 0, len5 = tmp.length; p < len5; p++) {
          element = tmp[p];
          if (element.title.match(new RegExp('^' + $scope.impPrefix + '.+$'))) {
            console.debug(element, '-> real attribute');
            real.push(element);
          } else {
            //console.debug element, '-> spoofed attribute'
            spoof.push(element);
          }
        }
        tmp = spoof.concat(real);
        res.push({
          title: '__attributesAndMacros__',
          nodes: tmp
        });
        return {
          _utime: time,
          nodes: res
        };
      };
      $scope.currentScope = scope;
      sessionId = scope.$modelValue.session;
      $http.get(`${scriptname}sessions/${sessionType}/${sessionId}`).then(function (response) {
        $scope.currentSession = transformSession(response.data);
        return $scope.currentSession.id = sessionId;
      });
      return $scope.showT = false;
    };
    $scope.localeDate = function (s) {
      var d;
      d = new Date(s * 1000);
      return d.toLocaleString();
    };
    $scope.isValid = function (epoch, type) {
      var isValid, now, path;
      path = $location.path();
      now = Date.now() / 1000;
      console.debug("Path", path);
      console.debug("Session epoch", epoch);
      console.debug("Current date", now);
      console.debug("Session TTL", sessionTTL);
      isValid = now - epoch < sessionTTL || $location.path().match(/^\/persistent/);
      if (type === 'msg') {
        console.debug("Return msg");
        if (isValid) {
          return "info";
        } else {
          return "warning";
        }
      } else if (type === 'style') {
        console.debug("Return style");
        if (isValid) {
          return {};
        } else {
          return {
            'color': '#627990',
            'font-style': 'italic'
          };
        }
      } else {
        console.debug("Return isValid");
        return isValid;
      }
    };
    $scope.strToLocaleDate = function (s) {
      var arrayDate, d;
      arrayDate = s.match(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/);
      if (!arrayDate.length) {
        return s;
      }
      d = new Date(`${arrayDate[1]}-${arrayDate[2]}-${arrayDate[3]}T${arrayDate[4]}:${arrayDate[5]}:${arrayDate[6]}`);
      return d.toLocaleString();
    };
    // Function to change interface language
    $scope.getLanguage = function (lang) {
      $scope.lang = lang;
      $scope.form = 'white';
      $scope.init();
      return $scope.showM = false;
    };
    // URI local path management
    pathEvent = function (event, next, current) {
      var n;
      n = next.match(/#!?\/(\w+)/);
      sessionType = 'global';
      if (n === null) {
        $scope.type = '_whatToTrace';
      } else if (n[1].match(/^(persistent|offline)$/)) {
        sessionType = RegExp.$1;
        $scope.type = '_session_uid';
      } else {
        $scope.type = n[1];
      }
      return $scope.init();
    };
    $scope.$on('$locationChangeSuccess', pathEvent);
    // Function to update tree: download value of opened subkey
    autoId = 0;
    $scope.updateTree = function (value, node, level, over, currentQuery, count) {
      var query, scheme, tmp;
      $scope.waiting = true;
      // Query scheme selection:

      //  - if defined above
      //  - _updateTime must be displayed as startTime
      //  - default to _whatToTrace scheme
      scheme = schemes[$scope.type] ? schemes[$scope.type] : $scope.type === '_updateTime' ? schemes._startTime : schemes._whatToTrace;
      // Build query using schemes
      query = scheme[level]($scope.type, value, currentQuery);
      // If number of session exceeds "max" and overScheme exists, call it
      if (count > max && overScheme[$scope.type]) {
        if (tmp = overScheme[$scope.type]($scope.type, value, level, over, currentQuery)) {
          over++;
          query = tmp;
          level = level - 1;
        } else {
          over = 0;
        }
      } else {
        over = 0;
      }
      // Launch HTTP query
      $http.get(`${scriptname}sessions/${sessionType}?${query}`).then(function (response) {
        var data, i, n;
        data = response.data;
        if (data.result) {
          for (i = 0; i < data.values.length; i++) {
            n = data.values[i];
            autoId++;
            n.id = `node${autoId}`;
            if (level < scheme.length - 1) {
              n.nodes = [];
              n.level = level + 1;
              n.query = query;
              n.over = over;
              // Date display in tree
              if ($scope.type.match(/^(?:start|update)Time$/)) {
                // 12 digits -> 12:34
                n.title = n.value.replace(/^(\d{8})(\d{2})(\d{2})$/,
                // 11 digits -> 12:30
                '$2:$3').replace(/^(\d{8})(\d{2})(\d)$/,
                // 10 digits -> 12h
                '$2:$30').replace(/^(\d{8})(\d{2})$/,
                //  8 digits -> 2016-03-15
                '$2h').replace(/^(\d{4})(\d{2})(\d{2})/, '$1-$2-$3');
              }
            }
            node.push(n);
          }
          if (value === '') {
            $scope.total = data.total;
          }
        }
        return $scope.waiting = false;
      }, function (resp) {
        return $scope.waiting = false;
      });
      // Highlight current selection
      console.debug("Selection", sessionType);
      $scope.navssoStyle = {
        color: '#777'
      };
      $scope.offlineStyle = {
        color: '#777'
      };
      $scope.persistentStyle = {
        color: '#777'
      };
      if (sessionType === 'global') {
        $scope.navssoStyle = {
          color: '#333'
        };
      }
      if (sessionType === 'offline') {
        $scope.offlineStyle = {
          color: '#333'
        };
      }
      if (sessionType === 'persistent') {
        return $scope.persistentStyle = {
          color: '#333'
        };
      }
    };
    // Intialization function
    // Simply set $scope.waiting to false during $translator and tree root
    // initialization
    $scope.init = function () {
      $scope.waiting = true;
      $scope.data = [];
      $scope.currentScope = null;
      $scope.currentSession = null;
      $q.all([$translator.init($scope.lang), $scope.updateTree('', $scope.data, 0, 0)]).then(function () {
        return $scope.waiting = false;
      }, function (resp) {
        return $scope.waiting = false;
      });
      // Colorized link
      $scope.activeModule = "sessions";
      return $scope.myStyle = {
        color: '#ffb84d'
      };
    };
    // Query scheme initialization
    // Default to '_whatToTrace'
    c = $location.path().match(/^\/(\w+)/);
    return $scope.type = c ? c[1] : '_whatToTrace';
  }]);

})();
