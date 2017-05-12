<?php

/* Create new article entry */
$article = Entity\Article::create(array(
 title => 'Test article',
 content => 'Article content'
));

/* Retrieve the article we just created */
$match = Entity\Article::find(array(
 title => 'Test article'
));
$match->title('Updated title');

?>
