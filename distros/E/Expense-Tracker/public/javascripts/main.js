require.config({
  // optimize: "none",
  
  paths: {
    jquery:     'vendor/jquery/jquery-1.7.2.min',
    underscore: 'vendor/underscore/underscore.min',
    backbone:   'vendor/backbone/backbone.min',
    bootstrap:  'vendor/bootstrap/bootstrap.min',

    text:       'vendor/require/text',
    jqueryui:   'vendor/jquery/jquery-ui-1.8.21.custom.min'
    
  },
  
  shim: {
    
    'underscore': {
      exports: '_'
    },

    'backbone': {
      //These script dependencies should be loaded before loading
      //backbone.js
      deps: ['underscore', 'jquery'],
      //Once loaded, use the global 'Backbone' as the
      //module value.
      exports: 'Backbone'
    },

    'jqueryui': {
      deps: ['jquery']
    },

    'bootstrap': {
      deps: ['jquery']
    }

  }
});

require(['app'], function(App){
  // The "app" dependency is passed in as "App"
  // Again, the other dependencies passed in are not "AMD" therefore don't pass a parameter to this function
  App.start();
});