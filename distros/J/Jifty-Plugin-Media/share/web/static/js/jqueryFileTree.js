// jQuery File Tree Plugin
//
// Version 1.01
//
// Cory S.N. LaViska
// A Beautiful Site (http://abeautifulsite.net/)
// 24 March 2008
// Yves Agostini patches 6 January 2009
//
// Visit http://abeautifulsite.net/notebook.php?article=58 for more information
//
// Usage: $('.fileTreeDemo').fileTree( options, callback )
//
// Options:  root           - root folder to display; default = /
//           script         - location of the serverside AJAX file to use; default = jqueryFileTree.php
//           folderEvent    - event to trigger expand/collapse; default = click
//           expandSpeed    - default = 500 (ms); use -1 for no animation
//           collapseSpeed  - default = 500 (ms); use -1 for no animation
//           expandEasing   - easing function to use on expand (optional)
//           collapseEasing - easing function to use on collapse (optional)
//           multiFolder    - whether or not to limit the browser to one subfolder at a time
//           loadMessage    - Message to display while initial tree loads (can be HTML)
//           dirOnly        - Yves: return only current dir for upload purpose
//           dirAndFiles    - Yves: return current dir or files for delete purpose
//           open           - Yves: expand dir on load
//
// History:
//
// 1.02 - yves patchs (6 January 2009)
// 1.01 - updated to work with foreign characters in directory/file names (12 April 2008)
// 1.00 - released (24 March 2008)
//
// TERMS OF USE
// 
// This plugin is dual-licensed under the GNU General Public License and the MIT License and
// is copyright 2008 A Beautiful Site, LLC. 
//
if(jQuery) (function($){
	
	$.extend($.fn, {
		fileTree: function(o, h) {
			// Defaults
			if( !o ) var o = {};
			if( o.root == undefined ) o.root = '/';
			if( o.script == undefined ) o.script = 'jqueryFileTree.php';
			if( o.folderEvent == undefined ) o.folderEvent = 'click';
			if( o.expandSpeed == undefined ) o.expandSpeed= 500;
			if( o.collapseSpeed == undefined ) o.collapseSpeed= 500;
			if( o.expandEasing == undefined ) o.expandEasing = null;
			if( o.collapseEasing == undefined ) o.collapseEasing = null;
			if( o.multiFolder == undefined ) o.multiFolder = true;
			if( o.loadMessage == undefined ) o.loadMessage = 'Loading...';
            // Yves patch
            var openarray; var show_current = o.root;
			if( o.open == undefined )  o.open = null;
            if( o.open ) { openarray = o.open.split("/"); openarray.shift(); };
			if( o.dirOnly == undefined ) o.dirOnly = null;
			if( o.dirAndFiles == undefined ) o.dirAndFiles = null;
            if( o.dirAndFiles ) o.dirOnly = true;
        
			
			$(this).each( function() {
				
				function showTree(c, t) {
					$(c).addClass('wait');
					$(".jqueryFileTree.start").remove();
					$.post(o.script, { dir: t }, function(data) {
						$(c).find('.start').html('');
						$(c).removeClass('wait').append(data);
                         if ( t == show_current) {
                            $(c).find('UL:hidden').show(); 
                             // Yves 
                             if (o.open) openTree(c);
                            }
                            else {
                                $(c).find('UL:hidden').slideDown({ duration: o.expandSpeed, easing: o.expandEasing });
                            };
						bindTree(c);
					});
				}
				
                // Yves
				function openTree(t) {
					$(t).find('LI A').show( function() {
                        if( $(this).parent().hasClass('directory') ) {
                            if ($(this).attr('rel') == show_current + openarray[0] + '/' ) {
                                show_current = show_current + openarray[0]+'/'; 
                                openarray.shift();
                                if ( show_current == o.open ) o.open = null;
                                $(this).parent().removeClass('collapsed').addClass('expanded');
                                showTree( $(this).parent(), escape($(this).attr('rel').match( /.*\// )) );
                            }
                        }
                    });
                }

				function bindTree(t) {
					$(t).find('LI A').bind(o.folderEvent, function() {
						if( $(this).parent().hasClass('directory') ) {
							if( $(this).parent().hasClass('collapsed') ) {
								// Expand
								if( !o.multiFolder ) {
									$(this).parent().parent().find('UL').slideUp({ duration: o.collapseSpeed, easing: o.collapseEasing });
									$(this).parent().parent().find('LI.directory').removeClass('expanded').addClass('collapsed');
								}
								$(this).parent().find('UL').remove(); // cleanup
								showTree( $(this).parent(), escape($(this).attr('rel').match( /.*\// )) );
								$(this).parent().removeClass('collapsed').addClass('expanded');
							    // Yves patch to choose current folder
                                if ( o.dirOnly ) h($(this).attr('rel')); 
							} else {
								// Collapse
								$(this).parent().find('UL').slideUp({ duration: o.collapseSpeed, easing: o.collapseEasing });
								$(this).parent().removeClass('expanded').addClass('collapsed');
							    // Yves patch to choose current folder
                                dir = $(this).attr('rel').replace(/^(.*)\/(.*?)\/$/,'$1');
                                if ( o.dirOnly ) h(dir); 
							}
						} else {
							// Yves patch to choose current folder
                              if ( !o.dirOnly || o.dirAndFiles ) h($(this).attr('rel')); 
							// h($(this).attr('rel'));
						}
						return false;
					});
					// Prevent A from triggering the # on non-click events
					if( o.folderEvent.toLowerCase != 'click' ) $(t).find('LI A').bind('click', function() { return false; });
				}
				// Loading message
				$(this).html('<ul class="jqueryFileTree start"><li class="wait">' + o.loadMessage + '<li></ul>');
				// Get the initial file list
				showTree( $(this), escape(o.root) );
			});
		}
	});
	
})(jQuery);
