function showSlot( slotId )
{
	resetConsole();
	var slot = document.getElementsByName( "slot" )[ slotId ];
	slot.style['borderWidth'] = '3px';
	slot.style['margin'] = '0px';
    var code = document.getElementById( "code_"+ slotId );
    code.style['visibility'] = 'visible';
	code.style['display'] = 'block';
}
function showLog()
{
	resetConsole();
	document.getElementsByName( "log" )[ 0 ].style['visibility'] = 'visible';
	document.getElementsByName( "log" )[ 0 ].style['display'] = 'block';
}

function resetConsole()
{
	var slots = document.getElementsByName( "slot" );

	for( var i = 0; i < slots.length; i++ )
	{
		slots[i].style['borderWidth'] = 0;
		slots[i].style['margin'] = '3px';
	}

	var codes = document.getElementsByName( "slotCode" );

	for( i = 0; i < codes.length; i++ )
	{
		codes[i].style['visibility'] = 'hidden';
		codes[i].style['display'] = 'none';
	}
	document.getElementsByName( "log" )[0].style['display'] = 'none';
	document.getElementsByName( "log" )[0].style['visibility'] = 'hidden';

}

function resolve_iteration ()
{
	document.forms[0].action = document.forms[0].elements[0].options[ document.forms[0].elements[0].selectedIndex ].value;	
}
