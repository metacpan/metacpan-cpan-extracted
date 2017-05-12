/**
 * File: maze.es
 *
 * Provide common interactive effects for a maze.
 */

var shifted = false;

var game;
var sprite;
var extents;

/*
 * The MazeGame object will maintain the current state of the game and
 * update the display.
 */

function MazeGame( start, end, board, extents )
{
    this.start = start;
    this.end = end;
    this.board = board;

    this.maze = document.getElementById( "maze" );
    this.origin = this.maze.getAttributeNS( null, "viewBox" );

    // The displayable area of the screen
    this.viewport = {
        width: extents.width - this.maze.getAttributeNS( null, "x" ),
        height: extents.height
    };
    // The full extent of the maze.
    this.extents = {
        width: this.maze.getAttributeNS( null, "width" ) - 0,
	heigth: this.maze.getAttributeNS( null, "height" ) - 0
    };
}

MazeGame.prototype.isFinished = function( pt )
{
    return this.end.equals( pt );
}

MazeGame.prototype.reset_origin = function()
{
    this.maze.setAttributeNS( null, "viewBox", this.origin );
}

MazeGame.prototype.center_view = function()
{
    var vctr = new Point( this.viewport.width/2, this.viewport.height/2 );
    var curr = sprite.calc_crumb_position();
    var offset = new Point( curr.x-vctr.x, curr.y-vctr.y );

    this.maze.setAttributeNS(
       null, "viewBox",
       [ offset.x, offset.y,
         this.viewport.width, this.viewport.height
       ].join( " " )
    );
}

MazeGame.prototype.maze_move = function( index, offset )
{
    var box = this.maze.getAttributeNS( null, "viewBox" ).split( ' ' );
    box[index] = +box[index] + offset;
    this.maze.setAttributeNS( null, "viewBox", box.join( ' ' ) );
}

MazeGame.prototype.up_blocked = function( pt )
{
    return (pt.y == 0 || this.board[pt.y-1][pt.x]-0);
}

MazeGame.prototype.left_blocked = function( pt )
{
    return pt.x < 0 || this.board[pt.y][pt.x-1]-0 > 0;
}

MazeGame.prototype.right_blocked = function( pt )
{
    return pt.x+1 == this.board[pt.y].length
        || this.board[pt.y][pt.x+1]-0 > 0;
}

MazeGame.prototype.down_blocked = function( pt )
{
    return pt.y+1 == this.board.length || this.board[pt.y+1][pt.x]-0;
}

/***** Standalone functions *******/

Keys = {
   SHIFT: 16,
   DOWN: 40,
   UP: 38,
   LEFT: 37,
   RIGHT: 39
};

function initialize()
{
    var mazedesc = loadBoard();
    extents = getDisplaySize();

    game = new MazeGame( mazedesc.start, mazedesc.end, mazedesc.board, extents );
    sprite = new Sprite( mazedesc.start, mazedesc.tile, game );
    sprite.reset();

    // Center the message on the screen.
    var msg = document.getElementById( "solvedmsg" );
    msg.setAttributeNS( null, "x", extents.width/2 );
    msg.setAttributeNS( null, "y", extents.height/2 );

    try {
        window.addEventListener("keydown", move_sprite, true);
        window.addEventListener("keyup", unshift, true);
    } catch (e) {
        // MSIE6 compatibility
        try
        {
            document.attachEvent("onkeydown", move_sprite);
            document.attachEvent("onkeyup", unshift);
        } catch(e) {
            // Batik support
            document.documentElement.setAttributeNS( null, "onkeydown", "move_sprite(evt)" );
            document.documentElement.setAttributeNS( null, "onkeyup", "unshift(evt)" );
        }
    }
}

function unshift(evt)
{
    if(Keys.SHIFT == evt.keyCode)
    {
        shifted = false;
    }
}

function finished_msg()
{
    var msg = document.getElementById( "solvedmsg" );
    if(null == msg)
    {
        alert( "Solved!!" );
    }
    else
    {
        msg.setAttributeNS( null, "visibility", "visible" );
        setTimeout( "remove_msg()", 2000 );
    }
}

function remove_msg()
{
    var msg = document.getElementById( "solvedmsg" );
    if(null != msg)
    {
        msg.setAttributeNS( null, "visibility", "hidden" );
    }
}

function  setText(elem, str)
 {
   var text = document.createTextNode( str );
   elem.replaceChild( text, elem.firstChild );
 }

function restart()
{
    sprite.reset();
    sprite.show();
}

function make_visible( name )
{
    var elem = document.getElementById( name );
    if(null != elem)
    {
        elem.setAttributeNS( null, "visibility", "visible" );
    }
}

function maze_up()
{
    game.maze_move( 1, -25 );
}

function maze_down()
{
    game.maze_move( 1, 25 );
}

function maze_left()
{
    game.maze_move( 0, -25 );
}

function maze_right()
{
    game.maze_move( 0, 25 );
}

function maze_reset()
{
    game.center_view();
}

function save_position()
{
    sprite.save();
}

function restore_position()
{
    sprite.restore();
}

function getDisplaySize()
{
    var extents = null;
    var doc = document.documentElement;
    try
    {
        var view = doc.viewport;

        extents = {
            width: view.width,
            height: view.height
        };
    }
    catch(e)
    {
        extents = {
            width: window.innerWidth,
            height: window.innerHeight
        };
    }

    var w = doc.getAttributeNS( null, "width" )-0;
    var h = doc.getAttributeNS( null, "height" )-0;
    if(w < extents.width)
    {
        extents.width = w;
    }
    if(h < extents.height)
    {
        extents.height = h;
    }

    return extents;
}

function loadBoard()
{
    var elem = document.getElementsByTagNameNS( "http://www.anomaly.org/2005/maze",
        "board" ).item( 0 );

    var content = elem.childNodes.item( 0 ).nodeValue;

    // if the content is broken up for some reason.
    for(var i = 1;i < elem.childNodes.length;++i)
    {
        content = content + elem.childNodes.item( i ).nodeValue;
    }

    var lines = content.split( /\s+/ );
    var retval = {
        board: [],
	start: new Point(),
	end: new Point(),
	tile: new Point()
    };

    for(var i=0, j=0;i < lines.length;++i)
    {
        lines[i].replace( /\s+/g, '' );
	if(lines[i].length)
	{
	    retval.board[j++] = lines[i].split( '' );
	}
    }
    
    retval.start = pointFromAttribute( elem, "start" );
    retval.end = pointFromAttribute( elem, "end" );
    retval.tile = pointFromAttribute( elem, "tile" );
    
    return retval;
}


function pointFromAttribute( elem, attr )
{
    var value = elem.getAttributeNS( null, attr );
    if(null == value)
    {
        return null;
    }

    return new Point( value );
}
