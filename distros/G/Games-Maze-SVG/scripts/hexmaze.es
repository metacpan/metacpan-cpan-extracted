/**
 * File: hexmaze.es
 *
 * Provide interactive effects for a hexagonal maze.
 * Depends on maze.es for support.
 */

function move_sprite(evt)
{
    evt.preventDefault();

    switch(evt.keyCode)
    {
	case 16:
            shifted = true;
	    return;
	case 40: // down
	   while(sprite.move_down() && shifted)
	       sprite.show();
	   break;
	case 38: // up
	   while(sprite.move_up() && shifted)
	       sprite.show();
	   break;
	case 37: // left
	   while(move_left() && shifted)
	       sprite.show();
	   break;
	case 39: // right
	   while(move_right() && shifted)
	       sprite.show();
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

function move_left()
{
    return (sprite.move_left()||sprite.move_upleft()||sprite.move_dnleft());
}

function move_right()
{
    return (sprite.move_right()||sprite.move_upright()||sprite.move_dnright());
}


/* Add some methods for the hex maze */
MazeGame.prototype.downright_blocked = function( pt )
{
    return pt.y+1 == this.board.length
        || pt.x+1 == this.board[pt.y+1].length
        || this.board[pt.y+1][pt.x+1]-0;
}

MazeGame.prototype.downleft_blocked = function( pt )
{
    return pt.x < 0 || pt.y+1 == this.board.length
        || this.board[pt.y+1][pt.x-1]-0
        || this.board[pt.y][pt.x-1]-0;
}

MazeGame.prototype.upright_blocked = function( pt )
{
    return pt.y < 0 || pt.x+1 == this.board[pt.y-1].length
    || this.board[pt.y-1][pt.x+1]-0
    || (this.board[pt.y][pt.x+1]-0 && this.board[pt.y-1][pt.x]-0);
}

MazeGame.prototype.upleft_blocked = function( pt )
{
    return pt.x < 0 || pt.y < 0 || this.board[pt.y-1][pt.x-1]-0
     || (this.board[pt.y][pt.x-1]-0 && this.board[pt.y-1][pt.x]-0);
}


/* Overrides for a sprite in a hex maze */

Sprite.prototype.move_dnleft = function()
{
    if(this.game.downleft_blocked( this.curr ))
    {
        return false;
    }
    this.left();
    this.down();
    return true;
}

Sprite.prototype.move_upleft = function()
{
    if(this.game.upleft_blocked( this.curr ))
    {
        return false;
    }
    this.left();
    this.up();
    return true;
}

Sprite.prototype.move_dnright = function()
{
    if(this.game.downright_blocked( this.curr ))
    {
        return false;
    }
    this.right();
    this.down();
    return true;
}

Sprite.prototype.move_upright = function()
{
    if(this.game.upright_blocked( this.curr ))
    {
        return false;
    }
    this.right();
    this.up();
    return true;
}
