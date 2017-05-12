
/*
 *
 * TableSorter - Client-side table sorting with ease!
 *
 * Copyright (c) 2006 Christian Bach (http://motherrussia.polyester.se)
 * Dual licensed under the MIT (http://www.opensource.org/licenses/mit-license.php)
 * and GPL (http://www.opensource.org/licenses/gpl-license.php) licenses.
 *
 * jQueryDate: 
 * jQueryAuthor: Christian jQuery
 *
 */

(function($) { 

	$.fn.tableModify = function() {
		return this.each(function() {
			
			var oTable = this;
			
			/** add row */
			$(this).bind("addTableRow",function(event,data) {
				
				/** append to table dom structure */
				$("> tbody",oTable).append(data);
				
				/** add new row to column data */
				$(this).trigger("updateColumnData");
				
				/** flush column cache */
				$(this).trigger("flushCache");
				
				/** trigger resort */
				$(this).trigger("resort");
				
				$(this).trigger("enableEdit");
				
				
			});
			
			$(this).bind("restoreRow",function(e,expr,a) {

				var l = a.length;
				var el = $(expr).empty();
				
				for(var i=0; i < l; i++) {
					el.append(a[i]);
				}
			});
			$(this).bind("saveRow",function(e,expr,a,v) {

				var l = a.length;
				var el = $(expr).empty();
				
				for(var i=0; i < l; i++) {
					el.append($(a[i]).text(v[i]));
				}
				
				/** add new row to column data */
				$(this).trigger("updateColumnData");
				
				/** flush column cache */
				$(this).trigger("flushCache");
				
				/** trigger resort */
				$(this).trigger("resort");
			});
			
			$(this).bind("enableEdit",function() {
				$(">tbody>tr",this).click(function(e) {
						
					var aCells = [];
					var o = this;
					
					// get information and append to cell array.
					$("td",this).each(function() {
						
						var o = $(this);
						var val = o.text();
						aCells.push(o);				
					});
					
					var l = aCells.length;
					var el = $("<td>").attr("colspan",l).append("<form><fieldset></fieldset>").click(function() {return false});
					var expr = el.find("fieldset");
					
					for(var i=0; i < l; i++) {
						expr.append($('<input type="text"/>').val(aCells[i].text()));
						
						if(i == (l-1)) {
							expr.append(
								$('<input type="reset">').click(function(e) {
									$(oTable).trigger("restoreRow",[o,aCells]);		
								
									return false
								})						
							).append(
								$('<input type="submit"/>').click(function(e) {
									var d = [];
									$("input:text",o).each(function() {
										d.push($(this).val());
									});	
									
									$(oTable).trigger("saveRow",[o,aCells,d]);
									
									return false
								})
							);
						}
					
					}
					
					$(this).empty().append(el);
								
				});
			});
			
			$(this).trigger("enableEdit");
	
	
		});
	};
	
	 
	$.fn.addTableRow = function(data) {
	
		return this.each(function() {

			$(this).trigger("addTableRow",[data]);
						
		});
	};
	

//jQuery.tableSorter.modify.integer = {};


})(jQuery);