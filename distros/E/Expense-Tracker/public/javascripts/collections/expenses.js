define([
  'jquery',
  'underscore',
  'backbone',
  'models/expense'
], function($, _, Backbone, expense){
  var Expenses = Backbone.Collection.extend({
    model: expense,

    url: "expenses",

    initialize: function() {

    },

    expenseCreate: function(data) {
      // TBD
    },

    expenseDelete: function(data) {
      // TBD
    }

    });
    return Expenses;
});