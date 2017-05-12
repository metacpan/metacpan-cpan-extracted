/*
Sorted Object List

Keeps track of a list of objects, sorted by the specified sort function.

*/

/*
//This prototype is provided by the Mozilla foundation and
//is distributed under the MIT license.
//http://www.ibiblio.org/pub/Linux/LICENSES/mit.license

if (!Array.prototype.filter)
{
  Array.prototype.filter = function(fun //, thisp//)
  {
    var len = this.length;
    if (typeof fun != "function")
      throw new TypeError();

    var res = new Array();
    var thisp = arguments[1];
    for (var i = 0; i < len; i++)
    {
      if (i in this)
      {
        var val = this[i]; // in case fun mutates this
        if (fun.call(thisp, val, i, this))
          res.push(val);
      }
    }

    return res;
  };
}
*/


// Constructor
function SortedObjList(keyname, sortfunc, objects)
{
	this.keyname = keyname ;
	this.length = 0 ;
	
	// wrap sort up in a closure
	var objlist = this ;
	if (sortfunc)
	{
		// sort() calls with the contents of the 'order' array - i.e. a & b are keynames
		this.sortfunc = function (a, b) 
		{ 
			// convert to objects and pass them to sort function
			var obj_a = objlist.objects[a] ;
			var obj_b = objlist.objects[b] ;
			return sortfunc(obj_a, obj_b) ;
		} ;
	}
	else
	{
		// default is to sort by key
		this.sortfunc = function (a, b) 
		{ 
			return a < b ? -1 : (a > b ? 1 : 0) ; 
		} ;
	}
	
	// create empty list
	this.empty() ;
	
	// add any specified objects
	if (objects)
	{
		for( var i in objects ) 
		{
			this.add(objects[i]) ;
		}
	}
}

// Add an object
SortedObjList.prototype.add = function (object)
{
	var key = object[this.keyname] ;

	// check for an existing entry
	if (!this.objects.hasOwnProperty(key))
	{
		// keep track of the order
		this.order.push(key) ;
		this.length = this.order.length ;
	}

	// add
	this.objects[key] = object ;

	// have to re-sort the list
	this._needs_sort = true ;
}
SortedObjList.prototype.push = SortedObjList.prototype.add ;

// Delete an object
SortedObjList.prototype.del = function (object)
{
	// keep track of the order
	var key = object[this.keyname] ;

	// remove
	delete this.objects[key] ;

	// remove from index list
	var idx ;
	for (var i in order)
	{
		if (key == order[i])
		{
			idx = i ;
		}
	}
	if (idx)
		this.order.splice(idx) ;

	this.length = this.order.length ;
}

// Empty the list
SortedObjList.prototype.empty = function ()
{
	this.order = [] ;
	this.objects = {} ;
	this.length = this.order.length ;

	
	// flag used to determine if we must sort the list
	this._needs_sort = false ;
}


// Access an object
SortedObjList.prototype.get = function (key)
{
	return this.objects[key] ;
}

// Return the list of keys
SortedObjList.prototype.filter_keys = function (filter /*, thisp */)
{
	var len = this.order.length;
	
	if (typeof filter != "function")
	  throw new TypeError();
	
    var thisp = arguments[1];
	var keys = new Array();
	for (var i = 0; i < len; i++)
	{
		if (i in this.order)
		{
			var idx = this.order[i]; // in case filter mutates this ??
			var obj = this.get( idx ) ;
			
			if (filter.call(thisp, obj))
				keys.push(idx);
		}
	}

	return keys ;
}


// Return the list of keys
SortedObjList.prototype.keys = function (filter)
{
	// see if we need to sort the list
	if (this._needs_sort)
	{
		this.order.sort(this.sortfunc) ;
		this._needs_sort = false ;
	}

	// if filtering, do it
	var keys = this.order ;
	if (filter)
	{
		keys = this.filter_keys(filter) ;
		
/*
		keys = [] ;
		for (var keyi in this.order)
		{
			var obj = this.get( this.order[keyi] ) ;
			var ok_to_add = filter(obj) ? 1 : 0 ; 
//ok_to_add=0;
			if (ok_to_add > 0) {
				keys.push(this.order[keyi]) ;
			}
		}
*/
	}

	return keys ;
}

// Return a list of objects in the correct order
SortedObjList.prototype.values = function (filter)
{
	var values = [] ;
	var keys = this.keys(filter) ;
	for (var keyi in keys )
	{
		values.push(this.get( keys[keyi] )) ;
	}
	return values ;
}




