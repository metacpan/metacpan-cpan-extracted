define([
  'jquery',
  'underscore',
  'backbone',
  'views/expenses/expense',
  'text!templates/expenses/index.html'
], function($, _, Backbone, ExpenseView, listTemplate){
    var ExpensesView = Backbone.View.extend({

      initialize: function() {
        var self = this;

        self.template = _.template(listTemplate);

        this.collection.bind('reset', function() {
          console.log("Reset Expenses - Done, rendering will be triggered");
          self.render();
        });

      },
      
      render: function() {
        var self = this;

        self.collection.models.forEach(function(expense) {
          var expenseView = new ExpenseView({model: expense});
          $('#expenses-container').append(expenseView.render().el);
        });
 
        return self;   
      }
      
    });
    return ExpensesView;
});
