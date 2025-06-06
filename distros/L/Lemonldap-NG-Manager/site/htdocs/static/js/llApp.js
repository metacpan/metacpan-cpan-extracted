(function () {
  'use strict';

  /*
  LemonLDAP::NG base app module

   This file contains:
    - 3 AngularJS directives (HTML attributes):
  	* `on-read-file` to get file content
  	* `resizer` to resize HTML div
  	* `trspan` to set translated message in HTML content
    - a AngularJS factory to handle 401 Ajax responses
   */
  var llapp;
  llapp = angular.module('llApp', ['ngAria']);

  // TRANSLATION SYSTEM

  // It provides:
  //  - 3 functions to translate:
  //    * translate(word)
  //    * translateP(paragraph): only __words__ are translated
  //    * translateField(object, property)
  //  - an HTML attribute called 'trspan'. Example: <h3 trspan="portal"/>

  // $translator provider
  llapp.provider('$translator', function () {
    var al, c, j, k, langs, langs2, len, len1, nl, nlangs, re, ref, res;
    res = {};
    // Language detection
    c = decodeURIComponent(document.cookie);
    if (c.match(/llnglanguage=(\w+)/)) {
      res.lang = RegExp.$1;
    } else if (navigator) {
      langs = [];
      langs2 = [];
      nlangs = [navigator.language];
      if (navigator.languages) {
        nlangs = navigator.languages;
      }
      for (j = 0, len = nlangs.length; j < len; j++) {
        nl = nlangs[j];
        console.log('Navigator lang', nl);
        ref = window.availableLanguages;
        for (k = 0, len1 = ref.length; k < len1; k++) {
          al = ref[k];
          console.log(' Available lang', al);
          re = new RegExp('^' + al + '-?');
          if (nl.match(re)) {
            console.log('  Matching lang =', al);
            langs.push(al);
          } else if (al.substring(0, 1) === nl.substring(0, 1)) {
            langs2.push(al);
          }
        }
      }
      res.lang = langs[0] ? langs[0] : langs2[0] ? langs2[0] : 'en';
    } else {
      res.lang = 'en';
    }
    console.log('Selected lang ->', res.lang);
    // Internal properties
    res.deferredTr = [];
    res.translationFields = {};
    // Translation methods
    //  1. word translation
    res.translate = function (s) {
      if (res.translationFields[s]) {
        s = res.translationFields[s];
      }
      return s;
    };
    //  2. node field translation
    res.translateField = function (node, field) {
      return res.translate(node[field]);
    };
    //  3. paragraph translation (verify that json is available
    res.translateP = function (s) {
      if (s && res.translationFields.portal) {
        s = s.replace(/__(\w+)__/g, function (match, w) {
          return res.translate(w);
        });
      }
      return s;
    };
    // Initialization
    this.$get = ['$q', '$http', function ($q, $http) {
      res.last = '';
      res.init = function (lang) {
        var d;
        if (!lang) {
          lang = res.lang;
        }
        d = new Date();
        d.setTime(d.getTime() + 30 * 86400000);
        document.cookie = `llnglanguage=${lang}; expires=${d.toUTCString()}; path=/`;
        d = $q.defer();
        if (res.last !== lang) {
          res.last = lang;
          $http.get(`${window.staticPrefix}languages/${lang}.json`).then(function (response) {
            var h, l, len2, ref1;
            res.translationFields = response.data;
            ref1 = res.deferredTr;
            for (l = 0, len2 = ref1.length; l < len2; l++) {
              h = ref1[l];
              h.e[h.f](res.translationFields[h.m]);
            }
            res.deferredTr = [];
            return d.resolve("Translation files loaded");
          }, function (response) {
            return d.reject('');
          });
        } else {
          d.resolve("No change");
        }
        return d.promise;
      };
      return res;
    }];
    return this;
  });

  // Translation directive (HTML trspan tag)
  llapp.directive('trspan', ['$translator', function ($translator) {
    return {
      restrict: 'A',
      replace: false,
      transclude: true,
      scope: {
        trspan: "@"
      },
      link: function (scope, elem, attr) {
        if ($translator.translationFields.portal) {
          attr.trspan = $translator.translate(attr.trspan);
        } else {
          // Deferred translations will be done after JSON download
          $translator.deferredTr.push({
            e: elem,
            f: 'text',
            m: attr.trspan
          });
        }
        return elem.text(attr.trspan);
      },
      template: ''
    };
  }]);

  // Form menu management

  // Two parts:
  //  - $htmlParams: used to store values inserted as <script type="text/menu">.
  //                 It provides menu() method to get them
  //  - HTML "script" element handler
  llapp.provider('$htmlParams', function () {
    this.$get = function () {
      var params;
      params = {};
      return {
        set: function (key, obj) {
          return params[key] = obj;
        },
        menu: function () {
          return params.menu;
        },
        // To be used later
        params: function () {
          return params.params;
        }
      };
    };
    return this;
  });
  llapp.directive('script', ['$htmlParams', function ($htmlParams) {
    return {
      restrict: 'E',
      terminal: true,
      compile: function (element, attr) {
        var e, t;
        if (attr.type && (t = attr.type.match(/text\/(menu|parameters)/))) {
          try {
            return $htmlParams.set(t[1], JSON.parse(element[0].text));
          } catch (error) {
            e = error;
            console.log("Parsing error:", e);
          }
        }
      }
    };
  }]);

  // Modal controller used to display messages
  llapp.controller('ModalInstanceCtrl', ['$scope', '$uibModalInstance', 'elem', 'set', 'init', function ($scope, $uibModalInstance, elem, set, init) {
    var currentNode, oldValue;
    $scope.elem = elem;
    $scope.set = set;
    $scope.result = init;
    $scope.staticPrefix = window.staticPrefix;
    currentNode = elem('currentNode');
    $scope.translateP = elem('translateP');
    if (currentNode) {
      oldValue = currentNode.data;
      $scope.currentNode = currentNode;
    }
    $scope.ok = function () {
      set('result', $scope.result);
      return $uibModalInstance.close(true);
    };
    $scope.cancel = function () {
      if (currentNode) {
        $scope.currentNode.data = oldValue;
      }
      return $uibModalInstance.dismiss('cancel');
    };
    // test if value is in select
    return $scope.inSelect = function (value) {
      var i, j, len, ref;
      ref = $scope.currentNode.select;
      for (j = 0, len = ref.length; j < len; j++) {
        i = ref[j];
        if (i.k === value) {
          return true;
        }
      }
      return false;
    };
  }]);

  // File reader directive

  // Add "onReadFile" HTML attribute to be used in a "file" input
  // The content off attribute will be launched.

  // Example:
  // <input type="file" on-read-file="replaceContent($fileContent)"/>
  llapp.directive('onReadFile', ['$parse', function ($parse) {
    return {
      restrict: 'A',
      scope: false,
      link: function (scope, element, attrs) {
        var fn;
        fn = $parse(attrs.onReadFile);
        return element.on('change', function (onChangeEvent) {
          var reader;
          reader = new FileReader();
          reader.onload = function (onLoadEvent) {
            return scope.$apply(function () {
              return fn(scope, {
                $fileContent: onLoadEvent.target.result
              });
            });
          };
          return reader.readAsText((onChangeEvent.srcElement || onChangeEvent.target).files[0]);
        });
      }
    };
  }]);

  // Resize system

  // Add a "resizer" HTML attribute
  llapp.directive('resizer', ['$document', function ($document) {
    var hsize, rsize;
    hsize = null;
    rsize = null;
    return function ($scope, $element, $attrs) {
      var mousemove, mouseup;
      $element.on('mousedown', function (event) {
        if ($attrs.resizer === 'vertical') {
          rsize = $($attrs.resizerRight).width() + $($attrs.resizerLeft).width();
        } else {
          hsize = $($attrs.resizerTop).height() + $($attrs.resizerBottom).height();
        }
        event.preventDefault();
        $document.on('mousemove', mousemove);
        return $document.on('mouseup', mouseup);
      });
      mousemove = function (event) {
        var x, y;
        // Handle vertical resizer
        if ($attrs.resizer === 'vertical') {
          x = event.pageX;
          if ($attrs.resizerMax && x > $attrs.resizerMax) {
            x = parseInt($attrs.resizerMax);
          }
          $($attrs.resizerLeft).css({
            width: `${x}px`
          });
          return $($attrs.resizerRight).css({
            width: `${rsize - x}px`
          });
        } else {
          // Handle horizontal resizer
          y = event.pageY - $('#navbar').height();
          $($attrs.resizerTop).css({
            height: `${y}px`
          });
          return $($attrs.resizerBottom).css({
            height: `${hsize - y}px`
          });
        }
      };
      return mouseup = function () {
        $document.unbind('mousemove', mousemove);
        return $document.unbind('mouseup', mouseup);
      };
    };
  }]);

  /*
   * Authentication system
   *
   * If a 401 code is returned and if "Authorization" header contains an url,
   * user is redirected to this url (but target is replaced by location.href
   */
  llapp.factory('$lmhttp', ['$q', '$location', function ($q, $location) {
    return {
      responseError: function (rejection) {
        if (rejection.status === 401 && window.portal) {
          return window.location = `${window.portal}?url=` + window.btoa(window.location).replace(/\//, '_');
        } else {
          return $q.reject(rejection);
        }
      }
    };
  }]);
  llapp.config(['$httpProvider', function ($httpProvider) {
    return $httpProvider.interceptors.push('$lmhttp');
  }]);

})();
