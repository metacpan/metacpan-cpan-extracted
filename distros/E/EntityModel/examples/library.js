

/* Create a new article entry */
var article = Entity.Article.create({
 title   : 'Test article',
 content : 'Article content'
});
/* Locate the item we just inserted */
Entity.Article.find({
 title : 'Test article'
}).item(function(article) {
 alert("Had article ID " . article.id());
 article.title('Updated title').done(function() {
  alert("Have updated title");
 });
});

