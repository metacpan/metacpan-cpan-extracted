/*
 * LemonLDAP::NG Notifications Explorer client
 */
var llapp, max, menu, overScheme, scheme;

// Max number of notifications to display (see overScheme)
max = 25;

scheme = [
  function(v) {
    return "groupBy=substr(uid,1)";
  },
  function(v) {
    return `uid=${v}*&groupBy=uid`;
  },
  function(v) {
    return `uid=${v}`;
  }
];

// When number of children nodes exceeds "max" value
// and does not return "null", a level is added. See
// "$scope.updateTree" method
overScheme = function(v, level, over) {
  // "v.length > over" avoids a loop if one user opened more than "max"
  // notifications
  console.log('overScheme => level', level, 'over', over);
  if (level === 1 && v.length > over) {
    return `uid=${v}*&groupBy=substr(uid,${level + over + 1})`;
  } else {
    return null;
  }
};

// Session menu
menu = {
  actives: [
    {
      title: 'markAsDone',
      icon: 'check'
    }
  ],
  done: [
    {
      title: 'deleteNotification',
      icon: 'trash'
    }
  ],
  new: [
    {
      title: 'save',
      icon: 'save'
    }
  ],
  home: []
};

// AngularJS application
llapp = angular.module('llngNotificationsExplorer', ['ui.tree', 'ui.bootstrap', 'llApp']);

// Main controller
llapp.controller('NotificationsExplorerCtrl', [
  '$scope',
  '$translator',
  '$location',
  '$q',
  '$http',
  '$uibModal',
  function($scope,
  $translator,
  $location,
  $q,
  $http,
  $uibModal) {
    var autoId,
  c,
  dateToString;
    $scope.links = links;
    $scope.menulinks = menulinks;
    $scope.staticPrefix = staticPrefix;
    $scope.scriptname = scriptname;
    $scope.formPrefix = formPrefix;
    $scope.availableLanguages = availableLanguages;
    $scope.waiting = true;
    $scope.showM = false;
    $scope.showT = true;
    $scope.showForm = false;
    $scope.data = [];
    $scope.form = {};
    $scope.formPost = {};
    $scope.currentScope = null;
    $scope.currentNotification = null;
    $scope.menu = menu;
    // Import translation functions
    $scope.translateP = $translator.translateP;
    $scope.translate = $translator.translate;
    $scope.translateTitle = function(node) {
      return $translator.translateField(node,
  'title');
    };
    // Handler menu items
    $scope.menuClick = function(button) {
      if (button.popup) {
        window.open(button.popup);
      } else {
        button.action || (button.action = button.title);
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
    // Notification management
    $scope.markAsDone = function() {
      $scope.waiting = true;
      return $http.put(`${scriptname}notifications/${$scope.type}/${$scope.currentNotification.uid}_${$scope.currentNotification.reference}`,
  {
        done: 1
      }).then(function(response) {
        $scope.currentNotification = null;
        $scope.currentScope.remove();
        $scope.message = {
          title: 'notificationDeleted'
        };
        $scope.showModal("alert.html");
        $scope.waiting = false;
        return $scope.init();
      },
  function(response) {
        $scope.message = {
          title: 'notificationNotDeleted',
          message: response.statusText
        };
        $scope.showModal("alert.html");
        $scope.waiting = false;
        return $scope.init();
      });
    };
    $scope.deleteNotification = function() {
      $scope.waiting = true;
      return $http['delete'](`${scriptname}notifications/${$scope.type}/${$scope.currentNotification.uid}_${$scope.currentNotification.reference}_${$scope.currentNotification.done}`).then(function(response) {
        $scope.currentNotification = null;
        $scope.currentScope.remove();
        $scope.message = {
          title: 'notificationPurged'
        };
        $scope.showModal("alert.html");
        $scope.waiting = false;
        return $scope.init();
      },
  function(response) {
        $scope.message = {
          title: 'notificationNotPurged',
          message: response.statusText
        };
        $scope.showModal("alert.html");
        $scope.waiting = false;
        return $scope.init();
      });
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
    $scope.notifDate = function(s) {
      var d;
      if (s != null) {
        if (s.match(/(\d{4})-(\d{2})-(\d{2})/)) {
          s = s.substr(0,
  4) + s.substr(5,
  2) + s.substr(8,
  2);
        }
        d = new Date(s.substr(0,
  4),
  s.substr(4,
  2) - 1,
  s.substr(6,
  2));
        return d.toLocaleDateString();
      }
      return '';
    };
    $scope.getLanguage = function(lang) {
      $scope.lang = lang;
      if ($scope.form.date) {
        $scope.form.date = new Date();
      } else {
        $scope.form = 'white';
      }
      $scope.init();
      return $scope.showM = false;
    };
    $scope.$on('$locationChangeSuccess',
  function(event,
  next,
  current) {
      var n;
      n = next.match(/#!?\/(\w+)/);
      $scope.type = n != null ? n[1] : 'actives';
      if ($scope.type === 'new') {
        return $scope.displayCreateForm();
      } else {
        $scope.showForm = false;
        return $scope.init();
      }
    });
    autoId = 0;
    $scope.updateTree = function(value,
  node,
  level,
  over,
  currentQuery,
  count) {
      var query,
  tmp;
      $scope.waiting = true;
      query = scheme[level](value,
  currentQuery);
      // If number of notifications exceeds "max", call it
      if (count > max) {
        if (tmp = overScheme(value,
  level,
  over)) {
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
      if ($scope.type === 'done' || $scope.type === 'actives') {
        $http.get(`${scriptname}notifications/${$scope.type}?${query}`).then(function(response) {
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
      }
      // Highlight current selection
      console.log("Selection",
  $scope.type);
      $scope.activesStyle = {
        color: '#777'
      };
      $scope.doneStyle = {
        color: '#777'
      };
      $scope.newStyle = {
        color: '#777'
      };
      if ($scope.type === 'actives') {
        $scope.activesStyle = {
          color: '#333'
        };
      }
      if ($scope.type === 'done') {
        return $scope.doneStyle = {
          color: '#333'
        };
      }
    };
    $scope.displayNotification = function(scope) {
      var node,
  notificationId;
      $scope.waiting = true;
      $scope.currentScope = scope;
      node = scope.$modelValue;
      notificationId = node.notification.replace(/#/g,
  '_');
      if ($scope.type === 'actives') {
        notificationId = `${node.uid}_${node.reference}`;
      }
      $http.get(`${scriptname}notifications/${$scope.type}/${notificationId}`).then(function(response) {
        var notif;
        $scope.currentNotification = {
          uid: node.uid,
          reference: node.reference
        };
        if ($scope.type === 'done') {
          $scope.currentNotification.done = response.data.done;
        }
        try {
          console.log("Try to parse a JSON formated notification...");
          notif = JSON.parse(response.data.notifications);
          $scope.currentNotification.date = $scope.notifDate(notif.date);
          $scope.currentNotification.condition = notif.condition;
          $scope.currentNotification.text = notif.text;
          $scope.currentNotification.title = notif.title;
          $scope.currentNotification.subtitle = notif.subtitle;
          $scope.currentNotification.check = notif.check;
        } catch (error) {
          console.log("Unable to parse JSON");
          $scope.currentNotification.notifications = response.data.notifications;
        }
        return $scope.waiting = false;
      },
  function(resp) {
        return $scope.waiting = false;
      });
      return $scope.showT = false;
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
      return modalInstance.result.then(function(msgok) {
        $scope.message = {
          title: '',
          message: ''
        };
        return d.resolve(msgok);
      },
  function(msgnok) {
        $scope.message = {
          title: '',
          message: ''
        };
        return d.reject(msgnok);
      });
    };
    $scope.save = function() {
      if ($scope.form.uid && $scope.form.reference && $scope.form.xml) {
        $scope.waiting = true;
        $scope.formPost.uid = $scope.form.uid;
        if ($scope.form.date) {
          $scope.formPost.date = dateToString($scope.form.date);
        }
        $scope.formPost.reference = $scope.form.reference;
        $scope.formPost.condition = $scope.form.condition;
        $scope.formPost.xml = $scope.form.xml;
        $http.post('notifications/actives',
  $scope.formPost).then(function(response) {
          var data;
          data = response.data;
          $scope.form = {};
          if (data.result === 1) {
            $scope.message = {
              title: 'notificationCreated'
            };
          } else {
            $scope.message = {
              title: 'notificationNotCreated',
              message: data.error
            };
          }
          $scope.showModal("alert.html");
          $scope.waiting = false;
          return $scope.form.date = new Date();
        },
  function(response) {
          $scope.message = {
            title: 'notificationNotCreated',
            message: response.statusText
          };
          $scope.showModal("alert.html");
          $scope.waiting = false;
          return $scope.form.date = new Date();
        });
      } else {
        $scope.message = {
          title: 'incompleteForm'
        };
        $scope.showModal("alert.html");
      }
      return $scope.form.date = new Date();
    };
    $scope.init = function() {
      $scope.waiting = true;
      $scope.showM = false;
      $scope.showT = false;
      $scope.data = [];
      $scope.currentScope = null;
      $scope.currentNotification = null;
      $q.all([$translator.init($scope.lang),
  $scope.updateTree('',
  $scope.data,
  0,
  0)]).then(function() {
        return $scope.waiting = false;
      },
  function(resp) {
        return $scope.waiting = false;
      });
      // Colorized link
      $scope.activeModule = "notifications";
      return $scope.myStyle = {
        color: '#ffb84d'
      };
    };
    $scope.displayCreateForm = function() {
      $scope.activesStyle = {
        color: '#777'
      };
      $scope.doneStyle = {
        color: '#777'
      };
      $scope.newStyle = {
        color: '#333'
      };
      $scope.waiting = true;
      return $translator.init($scope.lang).then(function() {
        $scope.currentNotification = null;
        $scope.showForm = true;
        $scope.data = [];
        $scope.waiting = false;
        return $scope.form.date = new Date();
      });
    };
    c = $location.path().match(/^\/(\w+)/);
    $scope.type = c ? c[1] : 'actives';
    // Datepicker
    $scope.popupopen = function() {
      return $scope.popup.opened = true;
    };
    $scope.dateOptions = {
      startingDay: 1,
      minDate: new Date()
    };
    $scope.popup = {
      opened: false
    };
    // Date conversion
    return dateToString = function(dt) {
      var day,
  month,
  year;
      year = dt.getFullYear();
      month = dt.getMonth() + 1;
      if (month < 10) {
        month = `0${month}`;
      }
      day = dt.getDate();
      if (day < 10) {
        day = `0${day}`;
      }
      return `${year}-${month}-${day}`;
    };
  }
]);
