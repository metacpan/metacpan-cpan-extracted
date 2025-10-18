/*
 * 2ndFA Session explorer
 */
/*
 * AngularJS applications
 */
var categories, hiddenAttributes, llapp, max, menu, overScheme, schemes;

// Max number of session to display (see overScheme)
max = 25;

// Queries to do each type of display: each array item corresponds to the depth
// of opened nodes in the tree
schemes = {
  _whatToTrace: [
    function(t,
      v) {
      return `groupBy=substr(${t},1)`;
    },
    function(t,
      v) {
      return `${t}=${v}*`;
    }
  ]
};

overScheme = {
  _whatToTrace: function(t, v, level, over) {
    console.debug('overSchema => level', level, 'over', over);
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
  dateTitle: ['_utime', '_startTime', '_updateTime'],
  sfaTitle: ['_2fDevices']
};

// Menu entries
menu = {
  home: []
};

llapp = angular.module('llngSessionsExplorer', ['ui.tree', 'ui.bootstrap', 'llApp']);

// Main controller
llapp.controller('SessionsExplorerCtrl', [
  '$scope',
  '$translator',
  '$location',
  '$q',
  '$http',
  function($scope,
    $translator,
    $location,
    $q,
    $http) {
    var autoId,
      c,
      pathEvent,
      sessionType;
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
    $scope.searchString = '';
    $scope.sfatypes = {};
    // Import translations functions
    $scope.translateP = $translator.translateP;
    $scope.translate = $translator.translate;
    $scope.translateTitle = function(node) {
      return $translator.translateField(node,
        'title');
    };
    sessionType = 'persistent';
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
            $scope[button.action]();
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
    //# SESSIONS MANAGEMENT
    // Search 2FA sessions
    $scope.search2FA = function(clear) {
      if (clear) {
        $scope.searchString = '';
      }
      $scope.currentSession = null;
      $scope.data = [];
      return $scope.updateTree2('',
        $scope.data,
        0,
        0);
    };

    // Delete 2FA device
    $scope.delete2FA = function(type,
      epoch) {
      var e,
        i,
        items,
        len;
      items = document.querySelectorAll(`.data-${epoch}`);
      for (i = 0, len = items.length; i < len; i++) {
        e = items[i];
        e.remove();
      }
      $scope.waiting = true;
      $http['delete'](`${scriptname}sfa/${sessionType}/${$scope.currentSession.id}?type=${type}&epoch=${epoch}`).then(function(response) {
          return $scope.waiting = false;
        },
        function(resp) {
          return $scope.waiting = false;
        });
      return $scope.showT = false;
    };
    // Open node
    $scope.stoggle = function(scope) {
      var node;
      node = scope.$modelValue;
      if (node.nodes.length === 0) {
        $scope.updateTree(node.value,
          node.nodes,
          node.level,
          node.over,
          node.query,
          node.count);
      }
      return scope.toggle();
    };
    // Display selected session
    $scope.displaySession = function(scope) {
      var sessionId,
        transformSession;
      // Private functions

      // Session preparation
      transformSession = function(session) {
        var _stToStr,
          array,
          arrayDate,
          attr,
          attrs,
          category,
          epoch,
          i,
          k,
          key,
          len,
          len1,
          name,
          pattern,
          res,
          sfDevice,
          subres,
          time,
          type,
          value;
        _stToStr = function(s) {
          return s;
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
                value = _stToStr(value);
                pattern = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;
                arrayDate = value.match(pattern);
                session[key] = `${arrayDate[3]}/${arrayDate[2]}/${arrayDate[1]} à ${arrayDate[4]}:${arrayDate[5]}:${arrayDate[6]}`;
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
                    title: "2fid",
                    value: "name",
                    type: "type",
                    epoch: "date"
                  });
                  for (k = 0, len1 = array.length; k < len1; k++) {
                    sfDevice = array[k];
                    for (key in sfDevice) {
                      value = sfDevice[key];
                      if (key === 'type') {
                        type = value;
                      }
                      if (key === 'name') {
                        name = value;
                      }
                      if (key === 'epoch') {
                        epoch = value;
                      }
                    }
                    subres.push({
                      title: '[' + type + ']' + epoch,
                      type: type,
                      value: name,
                      epoch: epoch,
                      sfrow: true
                    });
                  }
                }
                delete session[attr];
              } else if (session[attr].toString().match(/\w+/)) {
                subres.push({
                  title: attr,
                  value: session[attr]
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
        return {
          _utime: time,
          nodes: res
        };
      };
      $scope.currentScope = scope;
      sessionId = scope.$modelValue.session;
      $http.get(`${scriptname}sfa/${sessionType}/${sessionId}`).then(function(response) {
        $scope.currentSession = transformSession(response.data);
        return $scope.currentSession.id = sessionId;
      });
      return $scope.showT = false;
    };
    $scope.localeDate = function(s) {
      var d;
      d = new Date(s * 1000);
      return d.toLocaleString();
    };
    // Function to change interface language
    $scope.getLanguage = function(lang) {
      $scope.lang = lang;
      $scope.form = 'white';
      $scope.init();
      return $scope.showM = false;
    };
    // URI local path management
    pathEvent = function(event,
      next,
      current) {
      var n;
      n = next.match(/#!?\/(\w+)/);
      if (n === null || n[1].match(/^(persistent)$/)) {
        $scope.type = '_session_uid';
      }
      return $scope.init();
    };
    $scope.$on('$locationChangeSuccess',
      pathEvent);
    // Functions to update tree: download value of opened subkey
    autoId = 0;
    $scope.updateTree = function(value,
      node,
      level,
      over,
      currentQuery,
      count) {
      var query,
        scheme,
        tmp;
      $scope.waiting = true;
      // Query scheme selection:

      //  - if defined above
      //  - default to _whatToTrace scheme
      scheme = schemes[$scope.type] ? schemes[$scope.type] : schemes._whatToTrace;
      // Build query using schemes
      query = scheme[level]($scope.type,
        value,
        currentQuery);
      // If number of session exceeds "max" and overScheme exists, call it
      if (count > max && overScheme[$scope.type]) {
        if (tmp = overScheme[$scope.type]($scope.type,
            value,
            level,
            over,
            currentQuery)) {
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
      return $http.get(`${scriptname}sfa/${sessionType}?${query}` + Object.entries($scope.sfatypes).map(function(x) {
        if (x[1]) {
          return "&type=" + x[0];
        } else {
          return "";
        }
      }).join("")).then(function(response) {
          var data,
            i,
            len,
            n,
            ref;
          data = response.data;
          if (data.result) {
            ref = data.values;
            for (i = 0, len = ref.length; i < len; i++) {
              n = ref[i];
              autoId++;
              n.id = `node${autoId}`;
              if (level < scheme.length - 1) {
                n.nodes = [];
                n.level = level + 1;
                n.query = query;
                n.over = over;
              }
              node.push(n);
            }
            if (value === '') {
              $scope.total = data.total;
            }
          }
          return $scope.waiting = false;
        },
        function(resp) {
          return $scope.waiting = false;
        });
    };

    // Functions to filter U2F sessions tree : download value of opened subkey
    $scope.updateTree2 = function(value,
      node,
      level,
      over,
      currentQuery,
      count) {
      var query,
        scheme,
        tmp;
      $scope.waiting = true;
      // Query scheme selection:

      //  - if defined above
      //  - _updateTime must be displayed as startDate
      //  - default to _whatToTrace scheme
      scheme = schemes[$scope.type] ? schemes[$scope.type] : $scope.type === '_updateTime' ? schemes._startTime : schemes._whatToTrace;
      // Build query using schemes
      query = scheme[level]($scope.type,
        value,
        currentQuery);
      // If number of session exceeds "max" and overScheme exists, call it
      if (count > max && overScheme[$scope.type]) {
        if (tmp = overScheme[$scope.type]($scope.type,
            value,
            level,
            over,
            currentQuery)) {
          over++;
          query = tmp;
          level = level - 1;
        } else {
          over = 0;
        }
      } else {
        over = 0;
      }
      // Launch HTTP
      return $http.get(`${scriptname}sfa/${sessionType}?_session_uid=${$scope.searchString}*&groupBy=substr(_session_uid,${$scope.searchString.length})` + Object.entries($scope.sfatypes).map(function(x) {
        if (x[1]) {
          return "&type=" + x[0];
        } else {
          return "";
        }
      }).join("")).then(function(response) {
          var data,
            i,
            len,
            n,
            ref;
          data = response.data;
          if (data.result) {
            ref = data.values;
            for (i = 0, len = ref.length; i < len; i++) {
              n = ref[i];
              autoId++;
              n.id = `node${autoId}`;
              if (level < scheme.length - 1) {
                n.nodes = [];
                n.level = level + 1;
                n.query = query;
                n.over = over;
              }
              node.push(n);
            }
            if (value === '') {
              $scope.total = data.total;
            }
          }
          return $scope.waiting = false;
        },
        function(resp) {
          return $scope.waiting = false;
        });
    };
    // Intialization function
    // Simply set $scope.waiting to false during $translator and tree root
    // initialization
    $scope.init = function() {
      $scope.waiting = true;
      $scope.data = [];
      $q.all([$translator.init($scope.lang),
        $scope.updateTree('',
          $scope.data,
          0,
          0)
      ]).then(function() {
          return $scope.waiting = false;
        },
        function(resp) {
          return $scope.waiting = false;
        });
      // Colorized link
      $scope.activeModule = "2ndFA";
      return $scope.myStyle = {
        color: '#ffb84d'
      };
    };
    // Query scheme initialization
    // Default to '_whatToTrace'
    c = $location.path().match(/^\/(\w+)/);
    return $scope.type = c ? c[1] : '_whatToTrace';
  }
]);