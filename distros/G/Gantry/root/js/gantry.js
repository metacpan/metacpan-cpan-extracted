function ajax_action ( url, cb_output ) {

    var html = $.ajax({
        url: url,
        async: false,
        success: function(msg){
            if ( cb_output ) {
                $( cb_output ).innerHTML = msg;
            }
        }
    }).responseText;

}

function livesearch ( url ) {
    
    if ( ! url ) {
        url = "[% self.location %]";
    }
    
    $('tr.livedata').css({ display: 'none' });

    if ( ! $('#livesearch').val() || $('#livesearch').val() == '' ) {
        return
    }

    var html = $.ajax({
        url: ( "?search=" + $('#livesearch').val() + "&json=1" ),
        async: false,
        success: function(msg){
            $('tr.livedata').empty();
        }
    }).responseText;

    $('.livedata').empty();
    
    var json;
    if ( html ) {
        json = eval( '(' + html + ')' );   
    }
    if ( ! json.rows ) { return true; }
            
    var livehtml = '';
    
    for ( var r=0; r < json.rows.length; ++r ) {
        //$.each( json.rows, function( i, item ){
        var item = json.rows[r];
        var row = '';
        
        for ( var j=0; j < item.data.length; ++j ) {                    
            var val = '';
            val = item.data[j];
            
            row += sprintf( '<td class="livedata">%s</td>', ( val ? val : '' ) );                        
        }
        
        row += "<td class='rdta'>";
        
        var links = [];                   
        for ( var k=0; k < item.options.length; ++k ) {
            var link = '';
            if ( item.options[k] ) {
                links.push( 
                    sprintf( '<a href="%s">%s</a>',
                        item.options[k].link,
                        item.options[k].text                            
                    )
                );
            }
        }
        
        var edit_links = links.join( ' | ' );
        row += edit_links ? '[ ' + edit_links + ' ]' : '';
        row += "</td>";
        
        $( 'table#results' ).prepend(
           "<tr class='livedata'>" + row + "</tr>" 
         );
    }
}

function sprintf() {
	if (!arguments || arguments.length < 1 || !RegExp)
	{
		return;
	}
	var str = arguments[0];
	var re = /([^%]*)%('.|0|\x20)?(-)?(\d+)?(\.\d+)?(%|b|c|d|u|f|o|s|x|X)(.*)/;
	var a = b = [], numSubstitutions = 0, numMatches = 0;
	while (a = re.exec(str))
	{
		var leftpart = a[1], pPad = a[2], pJustify = a[3], pMinLength = a[4];
		var pPrecision = a[5], pType = a[6], rightPart = a[7];
		
		//alert(a + '\n' + [a[0], leftpart, pPad, pJustify, pMinLength, pPrecision);

		numMatches++;
		if (pType == '%')
		{
			subst = '%';
		}
		else
		{
			numSubstitutions++;
			if (numSubstitutions >= arguments.length)
			{
				alert('Error! Not enough function arguments (' + (arguments.length - 1) + ', excluding the string)\nfor the number of substitution parameters in string (' + numSubstitutions + ' so far).');
			}
			var param = arguments[numSubstitutions];
			var pad = '';
			       if (pPad && pPad.substr(0,1) == "'") pad = leftpart.substr(1,1);
			  else if (pPad) pad = pPad;
			var justifyRight = true;
			       if (pJustify && pJustify === "-") justifyRight = false;
			var minLength = -1;
			       if (pMinLength) minLength = parseInt(pMinLength);
			var precision = -1;
			       if (pPrecision && pType == 'f') precision = parseInt(pPrecision.substring(1));
			var subst = param;
			       if (pType == 'b') subst = parseInt(param).toString(2);
			  else if (pType == 'c') subst = String.fromCharCode(parseInt(param));
			  else if (pType == 'd') subst = parseInt(param) ? parseInt(param) : 0;
			  else if (pType == 'u') subst = Math.abs(param);
			  else if (pType == 'f') subst = (precision > -1) ? Math.round(parseFloat(param) * Math.pow(10, precision)) / Math.pow(10, precision): parseFloat(param);
			  else if (pType == 'o') subst = parseInt(param).toString(8);
			  else if (pType == 's') subst = param;
			  else if (pType == 'x') subst = ('' + parseInt(param).toString(16)).toLowerCase();
			  else if (pType == 'X') subst = ('' + parseInt(param).toString(16)).toUpperCase();
		}
		str = leftpart + subst + rightPart;
	}
	return str;
}
