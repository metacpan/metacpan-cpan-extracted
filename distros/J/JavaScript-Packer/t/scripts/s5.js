var image = new function() {
	var preloaded_images = new Array();
	
	var check_content = function( item ) {
		if ( ! item.get( 'loc' ) ) return;

		new Ajax.Request(
			'/content' + item.get( 'loc' ) + 'index.htm?' + Math.round( Math.random() * 99999 ) + '=' + Math.round( Math.random() * 99999 ),
			{
				method:	'get',
				onComplete	: function( req ) {
					var div = new Element( 'div' ).update( req.responseText.stripScripts() );

					div.select( 'img' ).each(
						function( img ) {
							var bild = new Image();
							bild.src = img.readAttribute('src');
							
							preloaded_images[preloaded_images.length] = bild;
							//alert( bild.src );
						}
					)
				}
			}
		);

		if ( item.get( 'subs' ) ) {
			item.get( 'subs' ).each(
				function( sub_item ) {
					check_content( sub_item );
				}
			);
		}
	}

	return {
		preload	: function() {
			var menu_hash = menu.get_menu_hash();

			menu_hash.each(
				function( item ) {
					check_content( item );
				}
			);
		}
	}
}

var content = new function() {
	return {
		process	: function() {
			var args = $A( content.process.arguments );

			var loc = args.shift();

			if ( ! loc ) { return; }

			var inner_div = new Element( 'div' );

			inner_div.setStyle(
				{
					'padding'	: '0px',
					'margin'	: '0px'
				}
			);

			if ( $( 'div_content' ).visible() ) {
				new Effect.Fade(
					'div_content',
					{
						afterFinish	: function() {

							new Ajax.Request(
								'/content' + loc + 'index.htm?' + Math.round( Math.random() * 99999 ) + '=' + Math.round( Math.random() * 99999 ),
								{
									method:	'get',
									onComplete	: function( req ) {

										var the_content = inner_div.update( req.responseText );

										$( 'div_content' ).update( the_content );

										new Effect.Appear(
											'div_content',
											{
												from	: 0.01
											}
										);
									}
								}
							)
						},
						to	: 0.01
					}
				);
			}
			else {
				new Ajax.Request(
					'/content' + loc + 'index.htm?' + Math.round( Math.random() * 99999 ) + '=' + Math.round( Math.random() * 99999 ),
					{
						method:	'get',
						onComplete	: function( req ) {

							$( 'div_content' ).update( inner_div.update( req.responseText ) );

							new Effect.Appear(
								'div_content',
								{
									from	: 0.00
								}
							);
						}
					}
				)
			}
		}
	}
}

// ----------------------------------------------------------------------------

var wait = 0;

window.dhtmlHistory.create(
	{
		toJSON: function(o) {
			return Object.toJSON(o);
		},
		fromJSON: function(s) {
			return s.evalJSON();
		}
	}
);

function handle_location( newLocation, historyData ) {
	newLocation = newLocation ? newLocation : '/';

	if ( ! wait && newLocation ) {
		wait = 1;

		content.process( newLocation );
		menu.process( newLocation );

		reset_wait();
	}
}

function handle_click( newLocation, historyData ) {
	if ( ! wait ) {
		dhtmlHistory.add( newLocation, historyData );
	}
	handle_location( newLocation, historyData );
}

function reset_wait() {
	var queue = $A(Effect.Queue);

	if ( queue.length > 0 ) {
		setTimeout( "reset_wait();", 1000 );
	}
	else {
		wait = 0;
	}
}

window.onload = function() {
	dhtmlHistory.initialize();
	dhtmlHistory.addListener(handle_location);

	menu.init();

	initialLocation = dhtmlHistory.getCurrentLocation();

	initialLocation = initialLocation ? initialLocation : '/';

	if ( dhtmlHistory.isFirstLoad() ) {
		if ( ! wait ) {
			dhtmlHistory.add( initialLocation, null );
		}
		handle_location( initialLocation, null );
	}

	image.preload();
	//alert( 'onload' );
}