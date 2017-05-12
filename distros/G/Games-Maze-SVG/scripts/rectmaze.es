/**
 * File: rectmaze.es
 *
 * Provide interactive effects for a rectangular maze.
 * Depends on maze.es for support.
 */

function move_sprite(evt)
{
    evt.preventDefault();

    switch(evt.keyCode)
    {
	case Keys.SHIFT:
            shifted = true;
	    return;
	case Keys.DOWN:
	   while(sprite.move_down() && shifted)
               ;
	   break;
	case Keys.UP:
	   while(sprite.move_up() && shifted)
               ;
	   break;
	case Keys.LEFT:
	   while(sprite.move_left() && shifted)
               ;
	   break;
	case Keys.RIGHT:
	   while(sprite.move_right() && shifted)
               ;
	   break;
	default:
	   return;
    }
    sprite.show();

    if(game.isFinished( sprite.curr ))
    {
        setTimeout( "finished_msg()", 10 );
    }
}
