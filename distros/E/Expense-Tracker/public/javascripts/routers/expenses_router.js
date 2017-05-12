define([
  'jquery',
  'underscore',
  'backbone',
  'collections/expenses',
  'views/expenses/expenses'
], function($, _, Backbone, Expenses, ExpensesView){
    var ExpensesRouter = Backbone.Router.extend({
        
        routes:{
            'expenses/:expense_id' : 'select'
        },

        initialize: function(){
          this.data =[
                       {name: "Shampoo1", price: 100, description: "lorem ipsum dolo descrip"},
                       {name: "Shampoo2", price: 112, description: "lorem ipsum dolo descrip"},
                       {name: "Shampoo3", price: 10, description: "lorem ipsum dolo descrip"},
                       {name: "Shampoo4", price: 89, description: "lorem ipsum dolo descrip"},
                       {name: "Shampoo5", price: 74, description: "lorem ipsum dolo descrip"}
                     ];
          
          var expenses = new Expenses(this.data);
          this.expensesView = new ExpensesView({collection: expenses});
          this.expensesView.render();
        },

        select: function(expense_id){
          //this.expensesView.collection.fetch();
          //$('#content-body').html(this.serversView.el);
          //this.expensesView.delegateEvents(); 

        }

        // defaultRoute: function(){
        //   Backbone.history.navigate("expenses", true);
        // }
        
    });

    return ExpensesRouter;

});
