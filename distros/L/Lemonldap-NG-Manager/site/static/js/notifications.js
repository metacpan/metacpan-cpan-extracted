/* LemonLDAP::NG Notifications Explorer client
 *
 */

(function() {
  'use strict';
  var scheme = [
  function(v) {
    return "groupBy=substr(uid,1)";
  },
  function(v) {
    return "uid=" + v + "*&groupBy=uid";
  },
  function(v) {
    return "uid=" + v;
  }];
  var menu = {
    'actives': [{
      'title': 'markAsDone',
      'icon': 'eye-close'
    }],
    'done': [{
      'title': 'deleteNotification',
      'icon': 'trash'
    }],
    'new': [{
      'title': 'save',
      'icon': 'save'
    }],
    'home': []
  }

  var llapp = angular.module('llngNotificationsExplorer', ['ui.tree', 'ui.bootstrap', 'llApp']);

  llapp.controller('NotificationsExplorerCtrl', ['$scope', '$translator', '$location', '$q', '$http', '$uibModal', function($scope, $translator, $location, $q, $http, $uibModal) {

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
    $scope.translateP = $translator.translateP;
    $scope.translate = $translator.translate;
    $scope.translateTitle = function(node) {
      return $translator.translateField(node, 'title');
    };

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

    $scope.markAsDone = function() {
      $scope.waiting = true;
      $http.put(scriptname + "notifications/" + $scope.type + "/" + $scope.currentNotification.uid + '_' + $scope.currentNotification.reference, {
        'done': 1
      }).then(function(response) {
        $scope.currentNotification = null;
        $scope.currentScope.remove();
        $scope.message = {
          "title": "notificationDeleted",
        };
        $scope.showModal("alert.html");
        $scope.waiting = false;
      },
      function(response) {
        $scope.message = {
          "title": "notificationNotDeleted",
          "message": response.statusText
        };
        $scope.showModal("alert.html");
        $scope.waiting = false;
      });
    }

    $scope.deleteNotification = function() {
      $scope.waiting = true;
      $http['delete'](scriptname + "notifications/" + $scope.type + "/" + $scope.currentNotification.uid + '_' + $scope.currentNotification.reference + '_' + $scope.currentNotification.done).then(function(response) {
        $scope.currentNotification = null;
        $scope.currentScope.remove();
        $scope.message = {
          "title": "notificationPurged",
        };
        $scope.showModal("alert.html");
        $scope.waiting = false;
      },
      function(response) {
        $scope.message = {
          "title": "notificationNotPurged",
          "message": response.statusText
        };
        $scope.showModal("alert.html");
        $scope.waiting = false;
      });
    }

    /* Simple toggle management */
    $scope.stoggle = function(scope) {
      var node = scope.$modelValue;
      if (node.nodes.length == 0) $scope.updateTree(node.value, node.nodes, node.level, node.query);
      scope.toggle();
    };

    $scope.notifDate = function(s) {
      if (s !== null) {
        /* Manage SQL datetime format */
        if (s.match(/(\d{4})-(\d{2})-(\d{2})/)) {
          s = s.substr(0, 4) + s.substr(5, 2) + s.substr(8, 2);
        }
        var d = new Date(s.substr(0, 4), s.substr(4, 2) - 1, s.substr(6, 2));
        return d.toLocaleDateString();
      }
      return '';
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
      if (n === null) {
        $scope.type = 'actives';
      } else {
        $scope.type = n[1];
      }
      if ($scope.type == 'new') {
        $scope.displayCreateForm();
      }
      else {
        $scope.showForm = false;
        $scope.init();
      }
    }
    $scope.$on('$locationChangeSuccess', pathEvent);

    var autoId = 0;
    $scope.updateTree = function(value, node, level, currentQuery) {
      $scope.waiting = true;
      var query = scheme[level](value, currentQuery);

      $http.get(scriptname + "notifications/" + $scope.type + "?" + query).then(function(response) {
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
        }
        $scope.waiting = false;
      },
      function(resp) {
        $scope.waiting = false;
      });
    };

    $scope.displayNotification = function(scope) {
      $scope.waiting = true;
      $scope.currentScope = scope;
      var node = scope.$modelValue;
      var notificationId = node.notification;
      if ($scope.type == 'actives') {
        notificationId = node.uid + '_' + node.reference;
      }
      $http.get(scriptname + "notifications/" + $scope.type + "/" + notificationId).then(function(response) {
        $scope.currentNotification = {
          'uid': node.uid,
          'reference': node.reference,
          'condition': node.condition
        };
        if ($scope.type == 'actives') {
          $scope.currentNotification.notifications = response.data.notifications
        }
        else {
          $scope.currentNotification.done = response.data.done;
        }
        $scope.waiting = false;
      },
      function(resp) {
        $scope.waiting = false;
      });
      $scope.showT = false;
    }

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
        };
        d.resolve(msgok);
      },
      function(msgnok) {
        $scope.message = {
          title: '',
          message: '',
        };
        d.reject(msgnok);
      });
      return modalInstance.result;
    }

    $scope.save = function() {
      if ($scope.form.uid && $scope.form.reference && $scope.form.xml && $scope.form.date) {
        $scope.waiting = true;
        $scope.formPost.uid = $scope.form.uid;
        $scope.formPost.date = dateToString($scope.form.date);
        $scope.formPost.reference = $scope.form.reference;
        $scope.formPost.condition = $scope.form.condition;
        $scope.formPost.xml = $scope.form.xml;
        $http.post('notifications/actives', $scope.formPost).then(function(response) {
          var data = response.data;
          $scope.form = {};
          if (data.result == 1) {
            $scope.message = {
              "title": "notificationCreated"
            };
            $scope.showModal("alert.html");
          }
          else {
            $scope.message = {
              "title": "notificationNotCreated",
              "message": data.error
            };
            $scope.showModal("alert.html");
          }
          $scope.waiting = false;
        },
        function(response) {
          $scope.message = {
            "title": "notificationNotCreated",
            "message": response.statusText
          };
          $scope.showModal("alert.html");
          $scope.waiting = false;
        });
      }
      else {
        $scope.message = {
          "title": "incompleteForm"
        };
        $scope.showModal("alert.html");
      }
    }

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

    $scope.displayCreateForm = function() {
      $scope.waiting = true;
      $translator.init($scope.lang).then(function() {
        $scope.currentNotification = null;
        $scope.showForm = true;
        $scope.data = [];
        $scope.waiting = false;
        $scope.form.date = new Date();
      });
    }

    var c = $location.path().match(/^\/(\w+)/);
    $scope.type = c ? c[1] : 'actives';

    /* Datepicker */
    $scope.popupopen = function() {
      $scope.popup.opened = true;
    };

    $scope.popup = {
      opened: false
    };

    var dateToString = function(dt) {
      var year = dt.getFullYear();
      var month = dt.getMonth() + 1;
      if (month < 10) {
        month = '0' + month;
      }
      var day = dt.getDate();
      if (day < 10) {
        day = '0' + day;
      }
      var result = year + "-" + month + "-" + day;
      return result;
    }

  }]);
})();