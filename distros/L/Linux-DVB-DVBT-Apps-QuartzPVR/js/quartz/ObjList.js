/*
Object List

Create the ObjList with the name of the key to be used to keep track of the stored objects. You can then iterate over the 
list of objects in the order in which they were added; alternatively you can access each object by it's key.

*/

// Constructor
function ObjList(keyname, objects)
{
	this.keyname = keyname ;
	this.order = [] ;
	this.objects = {} ;

	if (objects)
	{
		for( var i in objects ) 
		{
			this.add(objects[i]) ;
		}
	}
}

// Add an object
ObjList.prototype.add = function (object)
{
	// keep track of the order
	var key = object[this.keyname] ;
	this.order.push(key) ;

	// add
	this.objects[key] = object ;
}

// Access an object
ObjList.prototype.get = function (key)
{
	return this.objects[key] ;
}

// Return the list of keys
ObjList.prototype.keys = function ()
{
	return this.order ;
}

// Return a list of objects in the correct order
ObjList.prototype.values = function ()
{
	var values = [] ;
	for (var keyi in this.keys() )
	{
		values.push(this.get( this.order[keyi] )) ;
	}
	return values ;
}




