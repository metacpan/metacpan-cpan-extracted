/* LemonLDAP::NG base app module
 *
 *  This file contains:
 *   - 3 AngularJS directives (HTML attributes):
 *     * `on-read-file` to get file content
 *     * `resizer` to resize HTML div
 *     * `trspan` to set translated message in HTML content
 *   - a AngularJS factory to handle 401 Ajax responses
 */

(function() {
  'use strict';
  var llapp = angular.module('llApp', []);

  /* Translation system
   *
   * This part provides:
   *  - 3 functions to translate:
   *    * translate(word)
   *    * translateP(paragraph)
   *    * translateField(object, property)
   *  - an HTML attribute called 'trspan'. Exemple: <h3 trspan="portal"/>
   */

  llapp.provider('$translator', $Translator);

  function $Translator() {
    var res = {};

    /* Search for default language */
    if (navigator) {
      var nlangs = [navigator.language];
      if (navigator.languages) nlangs = navigator.languages;
      var langs = [],
      langs2 = [];
      nlangs.forEach(function(nl) {
        availableLanguages.forEach(function(al) {
          if (al == nl) {
            langs.push(al)
          } else if (al.substring(0, 1) == nl.substring(0, 1)) {
            langs2.push(al);
          }
        });
      });
      res.lang = langs[0] ? langs[0] : langs2[0] ? langs2[0] : 'en';
    } else {
      res.lang = 'en';
    }

    /* Private properties */
    res.deferredTr = [];
    res.translationFields = {};

    /* Translation methods */

    /* 1 - word translation */
    res.translate = function(s) {
      if (res.translationFields[s]) {
        s = res.translationFields[s];
      }
      return s;
    };

    /* 2 - object key translation */
    res.translateField = function(node, field) {
      return res.translate(node[field]);
    };

    /* 3 - paragraph translation */
    res.translateP = function(s) {
      if (s && res.translationFields.portal) s = s.replace(/__(\w+)__/g, function(match, w) {
        return res.translate(w);
      });
      return s;
    };

    /* Initialization */
    this.$get = ['$q', '$http', function($q, $http) {
      res.last = '';
      res.init = function(lang) {
        if (!lang) lang = res.lang;
        var d = $q.defer();
        if (res.last != lang) {
          res.last = lang;
          $http.get(staticPrefix + 'languages/' + lang + '.json').then(function(response) {
            res.translationFields = response.data;
            res.deferredTr.forEach(function(h) {
              h.e[h.f](res.translationFields[h.m]);
            });
            res.deferredTr = [];
            d.resolve("Translation files loaded");
          },
          function(resp) {
            d.reject('');
          });
        } else {
          d.resolve('No change');
        }
        return d.promise;
      };
      return res;
    }];
  }

  /* Translation directive (HTML trspan tag) */
  llapp.directive('trspan', ['$translator', function($translator) {
    return {
      restrict: 'A',
      replace: false,
      transclude: true,
      scope: {
        trspan: "@"
      },
      link: function(scope, elem, attr) {
        if ($translator.translationFields.portal) {
          attr.trspan = $translator.translate(attr.trspan)
        }
        /* Deferred translations will be done after JSON download */
        else {
          $translator.deferredTr.push({
            e: elem,
            f: 'text',
            m: attr.trspan
          });
        }
        elem.text(attr.trspan);
      },
      template: ""
    }
  }]);

  /* Form menu management
   *
   * Two parts:
   *  - $htmlParams: used to store values inserted as <script type="text/menu">.
   *                 It provides menu() method to get them
   *  - HTML "script" element handler
  */
  llapp.provider('$htmlParams', $HtmlParamsProvider);
  function $HtmlParamsProvider() {
    this.$get = function() {
      var params = {};
      return {
        set: function(key, obj) {
          params[key] = obj;
        },
        menu: function() {
          return params.menu;
        },
        params: function() {
          return params.params;
        }
      };
    };
  }

  llapp.directive('script', ['$htmlParams', function($htmlParams) {
    return {
      restrict: 'E',
      terminal: true,
      compile: function(element, attr) {
        var t;
        if (t = attr.type.match(/text\/(menu|parameters)/)) {
          try {
            return $htmlParams.set(t[1], JSON.parse(element[0].text));
          } catch(e) {
            console.log("Parsing error:", e);
            console.log(element[0].text);
            return;
          }
        }
      }
    }
  }]);

  /* Modal controller
   *
   * Used to display messages
   */
  llapp.controller('ModalInstanceCtrl', ['$scope', '$uibModalInstance', 'elem', 'set', 'init', function($scope, $uibModalInstance, elem, set, init) {
    var oldValue;
    $scope.elem = elem;
    $scope.set = set;
    $scope.result = init;
    $scope.staticPrefix = staticPrefix;
    var currentNode = elem('currentNode');
    $scope.translateP = elem('translateP');
    if (currentNode) {
      oldValue = currentNode.data;
      $scope.currentNode = currentNode;
    }

    $scope.ok = function() {
      set('result', $scope.result);
      $uibModalInstance.close(true);
    };

    $scope.cancel = function() {
      if (currentNode) $scope.currentNode.data = oldValue;
      $uibModalInstance.dismiss('cancel');
    };

    /* test if value is in select */
    $scope.inSelect = function(value) {
      for (var i = 0; i < $scope.currentNode.select.length; i++) {
        if ($scope.currentNode.select[i].k == value) return true;
      }
      return false;
    }

  }]);

  /* File reader directive
   *
   * Add "onReadFile" HTML attribute to be used in a "file" input
   * The content off attribute will be launched.
   *
   * Example:
   * <input type="file" on-read-file="replaceContent($fileContent)"/>
   */
  llapp.directive('onReadFile', ['$parse', function($parse) {
    return {
      restrict: 'A',
      scope: false,
      link: function(scope, element, attrs) {
        var fn = $parse(attrs.onReadFile);
        element.on('change', function(onChangeEvent) {
          var reader = new FileReader();
          reader.onload = function(onLoadEvent) {
            scope.$apply(function() {
              fn(scope, {
                $fileContent: onLoadEvent.target.result
              });
            });
          };
          reader.readAsText((onChangeEvent.srcElement || onChangeEvent.target).files[0]);
        });
      }
    };
  }]);

  /* Resizable system
   *
   * Add a "resizer" HTML attribute
   */
  llapp.directive('resizer', ['$document', function($document) {
    var rsize, hsize;
    return function($scope, $element, $attrs) {
      $element.on('mousedown', function(event) {
        if ($attrs.resizer == 'vertical') {
          rsize = $($attrs.resizerRight).width() + $($attrs.resizerLeft).width();
        } else {
          hsize = $($attrs.resizerTop).height() + $($attrs.resizerBottom).height();
        }
        event.preventDefault();
        $document.on('mousemove', mousemove);
        $document.on('mouseup', mouseup);
      });

      function mousemove(event) {
        if ($attrs.resizer == 'vertical') {
          // Handle vertical resizer
          var x = event.pageX;

          if ($attrs.resizerMax && x > $attrs.resizerMax) {
            x = parseInt($attrs.resizerMax);
          }
          $($attrs.resizerLeft).css({
            width: x + 'px'
          });
          $($attrs.resizerRight).css({
            width: (rsize - x) + 'px'
          });

        } else {
          // Handle horizontal resizer
          var y = event.pageY - $('#navbar').height();
          $($attrs.resizerTop).css({
            height: y + 'px'
          });
          $($attrs.resizerBottom).css({
            height: (hsize - y) + 'px'
          });
        }
      }

      function mouseup() {
        $document.unbind('mousemove', mousemove);
        $document.unbind('mouseup', mouseup);
      }
    };
  }]);
  /* Authentication system
   *
   * If a 401 code is returned and if "Authorization" header contains an url,
   * user is redirected to this url (but target is replaced by location.href)
   */
  llapp.factory('$lmhttp', ['$q', '$location', function($q, $location) {
    return {
      responseError: function(rejection) {
        if (rejection.status == 401 && window.portal) {
          window.location = window.portal + '?url=' + window.btoa(window.location).replace(/\//, '_');
        }
        else {
          return $q.reject(rejection);
        }
      }
    };
  }]);

  llapp.config(['$httpProvider', function($httpProvider) {
    $httpProvider.interceptors.push('$lmhttp');
  }]);

})();