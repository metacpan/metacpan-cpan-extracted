define([
  'jquery',
  'underscore',
  'backbone',
  'routers/expenses_router',
  'bootstrap'
], function($, _, Backbone, ExpensesRouter){
	var App = {
    start: function(){          
    	
      console.log("apps start");

      var expensesRouter = new ExpensesRouter;

      Backbone.history.start();
    }
  };
  return App;
});