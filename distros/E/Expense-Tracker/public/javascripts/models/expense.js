define([
  'jquery',
  'underscore',
  'backbone'
], function($, _,Backbone) {
  var Expense = Backbone.Model.extend({
    //urlRoot: 'expense'
  });	
  return Expense;
});
