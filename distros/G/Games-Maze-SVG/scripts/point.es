/*
 * File: point.es
 * Encapsulate the concept of a point that is used for positioning in the maze.
 */

function Point( x, y )
{
    if(null == x)
    {
        this.x = 0;
        this.y = 0;
    }
    else if(null == y)
    {
        var parts = x.split( /[, ]+/ );
        if(2 > parts.length)
        {
            this.x = x-0;
            this.y = 0;
        }
        else
	{
             this.x = parts[0]-0;
	     this.y = parts[1]-0;
	 }
    }
    else
    {
        this.x = x-0;
        this.y = y-0;
    }
}


Point.prototype.clone = function()
{
    return new Point( this.x, this.y );
}


Point.prototype.toString = function()
{
    return this.x + "," + this.y;
}


function positionElement( elem, pt )
{
    elem.setAttributeNS( null, 'x', pt.x );
    elem.setAttributeNS( null, 'y', pt.y );
}


Point.prototype.equals = function( pt )
{
    return pt.x == this.x && pt.y == this.y;
}

